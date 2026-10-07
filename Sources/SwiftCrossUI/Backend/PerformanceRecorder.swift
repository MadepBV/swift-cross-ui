import Dispatch
import Foundation

/// Opt-in timings of the framework's main-thread work, for finding what makes
/// an app slow on a machine where only files can be collected.
///
/// Set `SCUI_PERF_FILE` to a path before launch. Nothing is recorded, and
/// every hook costs one static read, without it. With it, the file receives
/// CSV rows (`kind,t_ms,dur_ms,bodies,layouts,commits,detail`), written once a
/// second from a utility queue:
///
/// - `seg`: one stretch of framework work entered from outside (a window
///   update, a node updating after its state changed), with the bodies it
///   evaluated, the layouts it computed and the nodes it committed, the
///   busiest body types and backend calls. Stretches shorter than 1 ms are
///   only summed into `sec`.
/// - `stall`: the main queue answered a ping late. A pinger thread sends one
///   ping at a time (every `SCUI_PERF_PING_MS`, default 10, 0 turns it off),
///   so a stall counts everything that held the main thread: the framework,
///   the app, the platform's own layout and rendering, input handling.
/// - `img`: an image decoded for display, with its size and time.
/// - `sec`: a per-second summary, written for every second something ran.
///
/// `t_ms` is milliseconds since 1970, so rows line up with a driver's own log.
@_spi(Backends)
@MainActor
public enum PerformanceRecorder {
    /// Whether recording is on. Read by every hook.
    public static let isEnabled: Bool = {
        guard let path = ProcessInfo.processInfo.environment["SCUI_PERF_FILE"], !path.isEmpty else {
            return false
        }
        return true
    }()

    private static var depth = 0
    private static var segmentStart: UInt64 = 0
    private static var segmentLabel = ""
    private static var segmentCounts: [String: Int] = [:]
    private static var bodyTypes: [ObjectIdentifier: (type: Any.Type, count: Int)] = [:]
    private static var bodies = 0
    private static var layouts = 0
    private static var commits = 0
    private static var started = false

    /// Starts the pinger and the writer. Idempotent; cheap when disabled.
    public static func start() {
        guard isEnabled, !started else { return }
        started = true
        BackendCallStatistics.startCounting()
        Sink.shared.start()
    }

    /// Marks the start of framework work entered from outside. Nested entries
    /// belong to the outermost one.
    @inline(__always)
    public static func enter(_ label: @autoclosure () -> String) {
        guard isEnabled else { return }
        if !started { start() }
        depth += 1
        guard depth == 1 else { return }
        segmentStart = DispatchTime.now().uptimeNanoseconds
        segmentLabel = label()
        segmentCounts = BackendCallStatistics.snapshot()
        bodyTypes.removeAll(keepingCapacity: true)
        bodies = 0
        layouts = 0
        commits = 0
    }

    /// Marks the end of the work begun by the matching ``enter(_:)``.
    @inline(__always)
    public static func exit() {
        guard isEnabled, depth > 0 else { return }
        depth -= 1
        guard depth == 0 else { return }
        let ended = DispatchTime.now().uptimeNanoseconds
        let duration = Double(ended &- segmentStart) / 1_000_000
        var detail = ""
        if duration >= 1 {
            let topBodies = bodyTypes.values.sorted { $0.count > $1.count }.prefix(6)
                .map { "\(shortName($0.type))=\($0.count)" }.joined(separator: " ")
            let after = BackendCallStatistics.snapshot()
            var calls: [(String, Int)] = []
            for (key, value) in after {
                let delta = value - (segmentCounts[key] ?? 0)
                if delta > 0, !key.hasPrefix("viewgraph.") { calls.append((key, delta)) }
            }
            let topCalls = calls.sorted { $0.1 > $1.1 }.prefix(8).map { "\($0.0)=\($0.1)" }
                .joined(separator: " ")
            detail = "\(segmentLabel) | \(topBodies) | \(topCalls)"
        }
        Sink.shared.segment(
            durationMs: duration, bodies: bodies, layouts: layouts, commits: commits, detail: detail)
    }

    /// Counts one body evaluation of a view type.
    @inline(__always)
    public static func bodyEvaluated(_ type: Any.Type) {
        guard isEnabled, depth > 0 else { return }
        bodies += 1
        let key = ObjectIdentifier(type)
        if let entry = bodyTypes[key] {
            bodyTypes[key] = (entry.type, entry.count + 1)
        } else {
            bodyTypes[key] = (type, 1)
        }
    }

    /// Counts one layout computation that wasn't served from a cache.
    @inline(__always)
    public static func layoutComputed() {
        guard isEnabled else { return }
        layouts += 1
    }

    /// Counts one node commit.
    @inline(__always)
    public static func nodeCommitted() {
        guard isEnabled else { return }
        commits += 1
    }

    /// The texts whose first write to a widget is recorded as a `ready` row
    /// (`SCUI_PERF_READY`, separated by `|`): the moment a screen's content
    /// is committed, without dumping the widget tree to look for it.
    private static var readyTexts: Set<String> = {
        guard isEnabled, let value = ProcessInfo.processInfo.environment["SCUI_PERF_READY"] else { return [] }
        return Set(value.split(separator: "|").map(String.init))
    }()

    /// Called by backends with every text written to a label.
    @inline(__always)
    public static func textWritten(_ text: String) {
        guard isEnabled, !readyTexts.isEmpty, readyTexts.contains(text) else { return }
        readyTexts.remove(text)
        Sink.shared.mark("ready", text)
    }

    /// Records an image decode. Callable from any thread.
    nonisolated public static func imageDecoded(
        what: String, width: Int, height: Int, nanoseconds: UInt64
    ) {
        guard Sink.isEnabled else { return }
        Sink.shared.image(what: what, width: width, height: height, nanoseconds: nanoseconds)
    }

    /// The name of a type without its generic arguments' module paths, short
    /// enough for a CSV cell.
    static func shortName(_ type: Any.Type) -> String {
        let full = String(describing: type)
        guard let bracket = full.firstIndex(of: "<") else { return full }
        let head = full[..<bracket]
        // Keep the innermost meaningful name for modifier wrappers.
        if head == "ModifiedContent" || head == "ViewGraphNode" {
            return String(full.prefix(60))
        }
        return String(head)
    }

    /// Accumulates rows and writes them once a second off the main thread.
    final class Sink: @unchecked Sendable {
        nonisolated static let isEnabled: Bool = {
            guard let path = ProcessInfo.processInfo.environment["SCUI_PERF_FILE"], !path.isEmpty else {
                return false
            }
            return true
        }()
        nonisolated static let shared = Sink()

        private let lock = NSLock()
        private var rows: [String] = []
        private var second: Int64 = -1
        private var secSegments = 0
        private var secBusyMs = 0.0
        private var secBodies = 0
        private var secLayouts = 0
        private var secCommits = 0
        private var secMaxStallMs = 0.0
        private var secStalls = 0
        private let writer = DispatchQueue(label: "org.swiftcrossui.perf", qos: .utility)
        private var handle: FileHandle?
        private var failed = false
        private var timer: DispatchSourceTimer?

        nonisolated init() {}

        nonisolated func start() {
            let path = ProcessInfo.processInfo.environment["SCUI_PERF_FILE"] ?? ""
            writer.async { [self] in
                FileManager.default.createFile(atPath: path, contents: nil)
                handle = FileHandle(forWritingAtPath: path)
                handle?.write(Data("kind,t_ms,dur_ms,bodies,layouts,commits,detail\n".utf8))
            }
            let timer = DispatchSource.makeTimerSource(queue: writer)
            timer.setEventHandler { [weak self] in self?.flush() }
            timer.schedule(deadline: .now() + 1, repeating: 1)
            timer.resume()
            self.timer = timer
            let interval = Int(ProcessInfo.processInfo.environment["SCUI_PERF_PING_MS"] ?? "") ?? 10
            if interval > 0 {
                let thread = Thread { [self] in pingLoop(intervalMs: interval) }
                thread.name = "scui-perf-ping"
                thread.start()
            }
        }

        private static func nowMs() -> Double { Date().timeIntervalSince1970 * 1000 }

        private func rollSecond(_ nowMs: Double) {
            let current = Int64(nowMs / 1000)
            if current != second {
                if second >= 0 && (secSegments > 0 || secStalls > 0) {
                    rows.append(
                        "sec,\(second * 1000),\(fmt(secBusyMs)),\(secBodies),\(secLayouts),\(secCommits),"
                            + "segments=\(secSegments) stalls=\(secStalls) maxStall=\(fmt(secMaxStallMs))")
                }
                second = current
                secSegments = 0; secBusyMs = 0; secBodies = 0; secLayouts = 0; secCommits = 0
                secMaxStallMs = 0; secStalls = 0
            }
        }

        func segment(durationMs: Double, bodies: Int, layouts: Int, commits: Int, detail: String) {
            let now = Self.nowMs()
            lock.lock()
            defer { lock.unlock() }
            rollSecond(now)
            secSegments += 1; secBusyMs += durationMs; secBodies += bodies; secLayouts += layouts
            secCommits += commits
            if durationMs >= 1 {
                rows.append(
                    "seg,\(fmt(now - durationMs)),\(fmt(durationMs)),\(bodies),\(layouts),\(commits),\"\(detail.replacingOccurrences(of: "\"", with: "'"))\""
                )
            }
        }

        func image(what: String, width: Int, height: Int, nanoseconds: UInt64) {
            let now = Self.nowMs()
            let ms = Double(nanoseconds) / 1_000_000
            lock.lock()
            defer { lock.unlock() }
            rows.append("img,\(fmt(now - ms)),\(fmt(ms)),0,0,0,\"\(what) \(width)x\(height) main=\(Thread.isMainThread)\"")
        }

        func mark(_ kind: String, _ detail: String) {
            let now = Self.nowMs()
            lock.lock()
            defer { lock.unlock() }
            rows.append("\(kind),\(fmt(now)),0,0,0,0,\"\(detail)\"")
        }

        private func stall(sentMs: Double, latencyMs: Double) {
            lock.lock()
            defer { lock.unlock() }
            rollSecond(sentMs)
            secStalls += 1
            secMaxStallMs = max(secMaxStallMs, latencyMs)
            rows.append("stall,\(fmt(sentMs)),\(fmt(latencyMs)),0,0,0,")
        }

        private func pingLoop(intervalMs: Int) {
            let answered = DispatchSemaphore(value: 0)
            while true {
                Thread.sleep(forTimeInterval: Double(intervalMs) / 1000)
                let sent = Self.nowMs()
                DispatchQueue.main.async { answered.signal() }
                answered.wait()
                let latency = Self.nowMs() - sent
                if latency >= 16 { stall(sentMs: sent, latencyMs: latency) }
            }
        }

        private func flush() {
            lock.lock()
            rollSecond(Self.nowMs())
            let pending = rows
            rows.removeAll(keepingCapacity: true)
            lock.unlock()
            guard !failed, !pending.isEmpty, let handle else { return }
            do {
                try handle.write(contentsOf: Data((pending.joined(separator: "\n") + "\n").utf8))
            } catch {
                failed = true
            }
        }

        private func fmt(_ value: Double) -> String { String(format: "%.1f", value) }
    }
}
