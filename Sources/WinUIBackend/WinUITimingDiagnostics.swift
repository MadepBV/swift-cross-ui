import Foundation
@_spi(Backends) import SwiftCrossUI
import WinSDK

/// Opt-in, bounded diagnostics for native queue and image-update boundaries.
/// Set SCUI_WINUI_TIMING_FILE to a local JSONL output path before launch. No
/// stderr fallback or per-event I/O is performed. A private utility queue writes
/// once per second; a failed sink disables further writes, not application work.
///
/// Wall durations include preemption/native waiting. GetThreadTimes reports CPU
/// charged to the executing Windows thread, including nested work in a drain or
/// callback. Signals can nest and must not be summed into exclusive CPU totals.
/// Neither an image invalidation nor a published frame measures display scanout.
/// The monotonic uptime_ns clock matches DispatchTime-based application probes.
enum WinUITimingDiagnostics {
    enum Signal: String, Sendable {
        case mainQueueForward = "mainQueue.forward"
        case mainQueueWait = "mainQueue.wait"
        case mainQueueDrain = "mainQueue.drain"
        case updateWait = "backend.update.wait"
        case updateExecute = "backend.update.execute"
        case imageLookup = "image.lookup"
        case imageBuffer = "image.buffer"
        case imageCopy = "image.copy"
        case imageInvalidate = "image.invalidate"
        case imageSource = "image.source"
        case imageUpload = "image.upload"
    }

    struct Stamp: Sendable {
        fileprivate let wall: UInt64
        fileprivate let cpu: UInt64?
    }

    private static let state: State? = {
        guard let path = ProcessInfo.processInfo.environment["SCUI_WINUI_TIMING_FILE"],
            !path.isEmpty
        else { return nil }
        return State(path: path)
    }()

    /// Resolve configuration during launch, rather than the first hot callback.
    static func start() { _ = state }

    /// Schedules a best-effort final partial report without blocking the UI.
    /// A process terminated immediately afterwards can lose that final interval.
    static func stop() { state?.stop() }

    @inline(__always)
    static func begin(cpu: Bool = false) -> Stamp? {
        guard state != nil else { return nil }
        return Stamp(wall: DispatchTime.now().uptimeNanoseconds,
                     cpu: cpu ? threadCPUNanoseconds() : nil)
    }

    @inline(__always)
    static func end(_ signal: Signal, _ stamp: Stamp?) {
        guard let stamp, let state else { return }
        let ended = DispatchTime.now().uptimeNanoseconds
        let cpu: UInt64?
        if let startedCPU = stamp.cpu, let endedCPU = threadCPUNanoseconds(), endedCPU >= startedCPU {
            cpu = endedCPU - startedCPU
        } else {
            cpu = nil
        }
        state.record(signal, wall: ended &- stamp.wall, cpu: cpu, startTick: stamp.wall)
    }

    @inline(__always)
    static func count(_ name: String, _ value: UInt64 = 1) {
        state?.count(name, value)
    }

    private static func threadCPUNanoseconds() -> UInt64? {
        var creation = FILETIME()
        var exit = FILETIME()
        var kernel = FILETIME()
        var user = FILETIME()
        guard GetThreadTimes(GetCurrentThread(), &creation, &exit, &kernel, &user) else {
            return nil
        }
        func ticks(_ value: FILETIME) -> UInt64 {
            (UInt64(value.dwHighDateTime) << 32) | UInt64(value.dwLowDateTime)
        }
        return (ticks(kernel) &+ ticks(user)) &* 100
    }

    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var timings: [Signal: BackendTimingAccumulator] = [:]
        private var counters: [String: UInt64] = [:]
        private var windowStart = DispatchTime.now().uptimeNanoseconds
        private var recording = true
        private let path: String
        private let writer = DispatchQueue(label: "org.swiftcrossui.winui.timings", qos: .utility)
        private let timer: DispatchSourceTimer
        // These properties are accessed only on writer.
        private var sink: FileHandle?
        private var sinkResolved = false
        private var sinkFailed = false

        init(path: String) {
            self.path = path
            timer = DispatchSource.makeTimerSource(queue: writer)
            timer.setEventHandler { [weak self] in self?.flush() }
            timer.schedule(deadline: .now() + 1, repeating: 1)
            timer.resume()
        }

        func record(_ signal: Signal, wall: UInt64, cpu: UInt64?, startTick: UInt64) {
            lock.lock()
            defer { lock.unlock() }
            guard recording else { return }
            timings[signal, default: BackendTimingAccumulator()].record(
                wallNanoseconds: wall, cpuNanoseconds: cpu, startTick: startTick)
        }

        func count(_ name: String, _ value: UInt64) {
            lock.lock()
            defer { lock.unlock() }
            guard recording else { return }
            counters[name, default: 0] &+= value
        }

        func stop() {
            lock.lock()
            let wasRecording = recording
            recording = false
            lock.unlock()
            guard wasRecording else { return }
            timer.cancel()
            writer.async { [self] in flush() }
        }

        private func flush() {
            lock.lock()
            let ended = DispatchTime.now().uptimeNanoseconds
            let started = windowStart
            let timings = self.timings
            let counters = self.counters
            self.timings = [:]
            self.counters = [:]
            windowStart = ended
            lock.unlock()

            guard !sinkFailed else { return }
            var values: [String: Any] = [:]
            for (signal, accumulator) in timings {
                let value = accumulator.summary
                values[signal.rawValue] = [
                    "n": value.count,
                    "wall_ns": value.wallNanoseconds,
                    "wall_max_ns": value.maximumWallNanoseconds,
                    "wall_max_start_tick": value.maximumWallStartTick,
                    "cpu_at_wall_max_ns": value.cpuAtMaximumWallNanoseconds.map { $0 as Any } ?? NSNull(),
                    "cpu_n": value.cpuSampleCount,
                    "cpu_ns": value.cpuNanoseconds,
                    "cpu_max_ns": value.maximumCPUNanoseconds,
                    "samples_n": value.retainedSampleCount,
                    "wall_p50_ns": value.p50WallNanoseconds,
                    "wall_p95_ns": value.p95WallNanoseconds,
                ] as [String: Any]
            }
            let report: [String: Any] = [
                "v": 1, "pid": ProcessInfo.processInfo.processIdentifier,
                "uptime_ns": ended, "window_start_ns": started,
                "window_ns": ended &- started, "sample_limit": 512,
                "timings": values, "counts": counters,
            ]
            do {
                if !sinkResolved {
                    sinkResolved = true
                    if !FileManager.default.fileExists(atPath: path) {
                        guard FileManager.default.createFile(atPath: path, contents: nil) else {
                            sinkFailed = true
                            return
                        }
                    }
                    sink = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
                    try sink?.seekToEnd()
                }
                var data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
                data.append(10)
                try sink?.write(contentsOf: data)
            } catch {
                // Never route diagnostics failure into stdout/stderr or UI work.
                sinkFailed = true
                try? sink?.close()
                sink = nil
            }
        }
    }
}
