import DefaultBackend
import Foundation
import ImageFormats
@_spi(Backends) import SwiftCrossUI

/// Measures SwiftCrossUI's update+layout+commit loop against the platform's
/// real backend.
///
/// The point of this target is to get the same per-phase numbers on Windows
/// that `LayoutPerformanceBenchmark`'s `SCUI_PROFILE` mode gets on macOS, but
/// with the real backend attached, so that the cost of crossing the WinRT/COM
/// projection is included rather than stubbed out.
///
/// It drives the view graph directly rather than through `App`/`Scene`, because
/// the two phases have to be timed separately and a scene would run them under
/// its own scheduling. A real window is created and shown first so that the
/// backend's widgets are in a live visual tree, which is what makes its
/// measurement and layout invalidation behave as it does in an app.
///
/// Output is CSV on stdout, prefixed with a version line so that a parser can
/// tell which columns to expect. Everything else goes to stderr.
///
/// ## Running it
///
/// ```
/// swift build -c release --product PerformanceHarness
/// .build/release/PerformanceHarness
/// ```
///
/// Environment variables:
///
/// - `SCUI_HARNESS_PASSES`: number of measured passes per scenario (default 60).
/// - `SCUI_HARNESS_SCENARIOS`: comma-separated subset of scenario names to run.
/// - `SCUI_HARNESS_OUTPUT`: path to write the CSV to. Required on Windows,
///   where a GUI-subsystem binary has no console and `stdout` is discarded.
@main
struct PerformanceHarness {
    static func main() {
        let backend = DefaultBackend()
        backend.runMainLoop {
            run(backend: backend)
            exit(0)
        }
    }

    /// One measured pass, split into its two phases.
    struct Pass {
        var layout: () -> Void
        var commit: () -> ViewSize
    }

    /// The timings of one scenario.
    struct Result {
        var scenario: String
        var passes: Int
        var layoutSamples: [Double]
        var commitSamples: [Double]
        var committedSize: ViewSize
        /// What one pass asked of the backend, so that a phase's cost can be
        /// attributed instead of guessed at.
        var callCounts: [String: Int]
    }

    @MainActor
    static func run(backend: DefaultBackend) {
        let windowSize = SIMD2(1600, 1100)
        let window = backend.createWindow(
            withDefaultSize: windowSize,
            id: "performance-harness"
        )
        backend.setTitle(ofWindow: window, to: "SwiftCrossUI performance harness")

        let rootEnvironment = backend.computeRootEnvironment(
            defaultEnvironment: EnvironmentValues(backend: backend)
        )
        let environment = backend
            .computeWindowEnvironment(window: window, rootEnvironment: rootEnvironment)
            .with(\.window, window)

        let proposal = ProposedViewSize(
            Double(windowSize.x),
            Double(windowSize.y)
        )
        let passCount = passCountFromEnvironment()
        let selected = selectedScenarios()

        /// Builds a pass over a freshly created graph, attaching its root
        /// widget to the window so that the backend lays it out for real.
        @MainActor
        func steadyPass<V: View>(
            _ makeView: @escaping () -> V,
            proposedSize: @escaping () -> ProposedViewSize = { proposal }
        ) -> Pass {
            let node = ViewGraphNode(
                for: makeView(),
                backend: backend,
                snapshot: nil,
                environment: environment
            )
            backend.setChild(ofWindow: window, to: node.widget)
            backend.show(window: window)
            _ = node.computeLayout(proposedSize: proposedSize(), environment: environment)
            _ = node.commit()
            return Pass(
                layout: {
                    // A scene begins a pass whenever it enters the graph; this
                    // driver stands in for one, so it has to do the same or it
                    // would measure a body cache that a real app never gets.
                    LayoutPass.begin()
                    _ = node.computeLayout(
                        with: makeView(),
                        proposedSize: proposedSize(),
                        environment: environment
                    )
                },
                commit: { node.commit().size }
            )
        }

        /// Builds a pass that drives a whole window update, which is the path a
        /// real app runs, rather than the view graph on its own.
        ///
        /// ``WindowReference`` lays the whole graph out at a proposal of
        /// `.zero` to derive the window's minimum size before it lays it out at
        /// the real proposal, and each of those begins its own ``LayoutPass``.
        /// The view-graph scenarios above drive one layout and one commit, so
        /// they can't show that second walk; these can.
        ///
        /// A window update runs both of its phases inside `update`, so the
        /// whole update is timed as the `layout` phase and the `commit` phase
        /// is empty. Read the `pass` row for these scenarios.
        ///
        /// - Parameters:
        ///   - makeView: Builds the window's content.
        ///   - isSceneUpdate: Whether each pass hands the window a new scene
        ///     value (a scene-level update) or only a new proposed size (a
        ///     resize).
        ///   - proposedSize: The size to lay the content out at, per pass.
        @MainActor
        func windowPass<V: View>(
            _ makeView: @escaping () -> V,
            isSceneUpdate: Bool = true,
            proposedSize: @escaping () -> SIMD2<Int> = { windowSize }
        ) -> Pass {
            let node = WindowGroupNode(
                from: WindowGroup("performance-harness-window") { makeView() },
                backend: backend,
                environment: rootEnvironment
            )
            node.updateForBenchmarking(
                proposedSize: proposedSize(),
                isSceneUpdate: true,
                backend: backend,
                environment: rootEnvironment
            )
            return Pass(
                layout: {
                    node.updateForBenchmarking(
                        proposedSize: proposedSize(),
                        isSceneUpdate: isSceneUpdate,
                        backend: backend,
                        environment: rootEnvironment
                    )
                },
                commit: { .zero }
            )
        }

        var results: [Result] = []

        func scenario(_ name: String, passes: Int? = nil, _ setUp: () -> Pass) {
            guard selected.isEmpty || selected.contains(name) else {
                return
            }
            log("running \(name)")
            results.append(
                measure(scenario: name, passes: passes ?? passCount, setUp: setUp)
            )
        }

        // A window that is on screen and unchanged. This is the case that
        // decides how an app feels while the user is doing nothing in
        // particular, and where a framework that re-pushes unchanged state
        // across the projection shows up worst.
        let idleViewport = HarnessData.makeViewport(frame: 0)
        scenario("cad/idle") {
            steadyPass { CADWindow(frame: 0, viewport: idleViewport) }
        }

        // The inspector selection moves and the viewport pixels change every
        // frame, as they would while orbiting a model.
        let viewports = (0..<16).map { HarnessData.makeViewport(frame: $0) }
        scenario("cad/animating") {
            var frame = 0
            return steadyPass {
                frame += 1
                return CADWindow(
                    frame: frame,
                    viewport: viewports[frame % viewports.count]
                )
            }
        }

        // A new proposal every frame, which defeats the per-proposal layout
        // cache. This is what dragging a window edge costs.
        scenario("cad/resize") {
            var frame = 0
            return steadyPass(
                { CADWindow(frame: 0, viewport: idleViewport) },
                proposedSize: {
                    frame += 1
                    return ProposedViewSize(
                        Double(windowSize.x) + Double(frame % 8),
                        Double(windowSize.y) + Double(frame % 8)
                    )
                }
            )
        }

        // A drafting overlay: 440 drawing commands, so 440 backend widgets.
        scenario("canvas/idle", passes: max(passCount / 2, 5)) {
            steadyPass { DraftingOverlay(phase: 0) }
        }

        scenario("canvas/animating", passes: max(passCount / 2, 5)) {
            var frame = 0
            return steadyPass {
                frame += 1
                return DraftingOverlay(phase: Double(frame) * 0.05)
            }
        }

        // The same geometry as canvas/animating through two widgets instead of
        // four hundred. See `MergedDraftingOverlay`.
        scenario("canvas/merged", passes: max(passCount / 2, 5)) {
            var frame = 0
            return steadyPass {
                frame += 1
                return MergedDraftingOverlay(phase: Double(frame) * 0.05)
            }
        }

        // The same CAD window, driven through the scene layer the way a real
        // app drives it. Compare against `cad/idle`: the difference is the
        // second full walk of the graph that a window update performs.
        scenario("window/update", passes: max(passCount / 2, 5)) {
            windowPass { CADWindow(frame: 0, viewport: idleViewport) }
        }

        // A window being resized: the content is unchanged and only the
        // proposal moves, which is what dragging a window edge does.
        scenario("window/resize", passes: max(passCount / 2, 5)) {
            var frame = 0
            return windowPass(
                { CADWindow(frame: 0, viewport: idleViewport) },
                isSceneUpdate: false,
                proposedSize: {
                    frame += 1
                    return SIMD2(
                        windowSize.x + frame % 8,
                        windowSize.y + frame % 8
                    )
                }
            )
        }

        // A long uniform list, proposed an unbounded height as a scroll view
        // would.
        scenario("list/idle", passes: max(passCount / 4, 5)) {
            steadyPass(
                { LongList() },
                proposedSize: { ProposedViewSize(Double(windowSize.x), nil) }
            )
        }

        report(results)
    }

    /// Runs the warm-up and then times each phase of `passes` passes.
    @MainActor
    private static func measure(
        scenario: String,
        passes: Int,
        setUp: () -> Pass
    ) -> Result {
        let pass = setUp()

        for _ in 0..<5 {
            pass.layout()
            _ = pass.commit()
        }

        // One untimed pass with counting on, so that the counters themselves
        // are never part of a timing.
        BackendCallStatistics.startCounting()
        pass.layout()
        _ = pass.commit()
        let callCounts = BackendCallStatistics.stopCounting()

        var layoutSamples: [Double] = []
        var commitSamples: [Double] = []
        var size = ViewSize.zero
        layoutSamples.reserveCapacity(passes)
        commitSamples.reserveCapacity(passes)
        for _ in 0..<passes {
            let start = DispatchTime.now().uptimeNanoseconds
            pass.layout()
            let afterLayout = DispatchTime.now().uptimeNanoseconds
            size = pass.commit()
            let end = DispatchTime.now().uptimeNanoseconds
            layoutSamples.append(Double(afterLayout - start) / 1_000_000)
            commitSamples.append(Double(end - afterLayout) / 1_000_000)
        }

        return Result(
            scenario: scenario,
            passes: passes,
            layoutSamples: layoutSamples,
            commitSamples: commitSamples,
            committedSize: size,
            callCounts: callCounts
        )
    }

    private static func passCountFromEnvironment() -> Int {
        if let raw = ProcessInfo.processInfo.environment["SCUI_HARNESS_PASSES"],
           let value = Int(raw), value > 0
        {
            return value
        }
        return 60
    }

    private static func selectedScenarios() -> Set<String> {
        guard let raw = ProcessInfo.processInfo.environment["SCUI_HARNESS_SCENARIOS"] else {
            return []
        }
        return Set(
            raw.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
        )
    }

    // MARK: Reporting

    private static func percentile(_ samples: [Double], _ fraction: Double) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sorted = samples.sorted()
        let index = min(
            sorted.count - 1,
            max(0, Int((Double(sorted.count - 1) * fraction).rounded()))
        )
        return sorted[index]
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.4f", value)
    }

    /// Reports the results as CSV.
    ///
    /// The first line names the format so that a parser can be pinned to a
    /// version of these columns.
    ///
    /// ## Where the CSV goes
    ///
    /// A WinUI app is a GUI-subsystem binary with no console attached, so
    /// `stdout` goes nowhere even when the parent process redirects it —
    /// the run produces an empty file and no error. `stderr` still works.
    ///
    /// So the CSV is written to, in order:
    ///
    /// 1. the file named by `SCUI_HARNESS_OUTPUT`, if it is set;
    /// 2. `stdout`, which is what a terminal run wants;
    /// 3. `stderr`, always, wrapped in `BEGIN`/`END` markers so that a run
    ///    with no console still reports and a parser can find it among the
    ///    progress lines.
    ///
    /// On Windows, pass `SCUI_HARNESS_OUTPUT` and read the file; that is the
    /// only sink guaranteed to survive.
    private static func report(_ results: [Result]) {
        var lines: [String] = ["scui-harness-csv v1"]
        lines.append(
            "scenario,phase,passes,median_ms,mean_ms,p95_ms,min_ms,max_ms,"
                + "committed_width,committed_height"
        )
        for result in results {
            lines.append(row(result, phase: "layout", samples: result.layoutSamples))
            lines.append(row(result, phase: "commit", samples: result.commitSamples))
            lines.append(
                row(
                    result,
                    phase: "pass",
                    samples: zip(result.layoutSamples, result.commitSamples).map(+)
                )
            )
        }

        // What one pass asked of the backend. Same CSV, `count` in the phase
        // column, so an existing parser sees rows it can ignore by phase.
        for result in results {
            for (event, count) in result.callCounts.sorted(by: { $0.key < $1.key }) {
                lines.append(
                    [
                        result.scenario,
                        "count:" + event,
                        "1",
                        "\(count)",
                        "",
                        "",
                        "",
                        "",
                        "\(Int(result.committedSize.width))",
                        "\(Int(result.committedSize.height))",
                    ].joined(separator: ",")
                )
            }
        }

        let csv = lines.joined(separator: "\n") + "\n"

        if let path = ProcessInfo.processInfo.environment["SCUI_HARNESS_OUTPUT"],
           !path.isEmpty
        {
            do {
                try Data(csv.utf8).write(to: URL(fileURLWithPath: path))
                log("wrote CSV to \(path)")
            } catch {
                log("failed to write CSV to \(path): \(error)")
            }
        } else {
            print(csv, terminator: "")
        }

        // Always mirror to stderr: it is the sink that works when there is no
        // console, and the markers keep it apart from the progress lines.
        log("scui-harness-csv BEGIN")
        FileHandle.standardError.write(Data(csv.utf8))
        log("scui-harness-csv END")
    }

    /// Writes a progress line to stderr.
    ///
    /// - Parameter message: The line to write, without a trailing newline.
    private static func log(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }

    /// Formats one result row.
    private static func row(
        _ result: Result,
        phase: String,
        samples: [Double]
    ) -> String {
        let mean = samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count)
        return [
            result.scenario,
            phase,
            "\(result.passes)",
            format(percentile(samples, 0.5)),
            format(mean),
            format(percentile(samples, 0.95)),
            format(samples.min() ?? 0),
            format(samples.max() ?? 0),
            "\(Int(result.committedSize.width))",
            "\(Int(result.committedSize.height))",
        ].joined(separator: ",")
    }
}
