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

        var results: [Result] = []

        func scenario(_ name: String, passes: Int? = nil, _ setUp: () -> Pass) {
            guard selected.isEmpty || selected.contains(name) else {
                return
            }
            FileHandle.standardError.write(Data("running \(name)\n".utf8))
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
            committedSize: size
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

    /// Prints the results as CSV.
    ///
    /// The first line names the format so that a parser can be pinned to a
    /// version of these columns.
    private static func report(_ results: [Result]) {
        print("scui-harness-csv v1")
        print(
            "scenario,phase,passes,median_ms,mean_ms,p95_ms,min_ms,max_ms,"
                + "committed_width,committed_height"
        )
        for result in results {
            emit(result, phase: "layout", samples: result.layoutSamples)
            emit(result, phase: "commit", samples: result.commitSamples)
            emit(
                result,
                phase: "pass",
                samples: zip(result.layoutSamples, result.commitSamples).map(+)
            )
        }
    }

    private static func emit(_ result: Result, phase: String, samples: [Double]) {
        let mean = samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count)
        print(
            [
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
        )
    }
}
