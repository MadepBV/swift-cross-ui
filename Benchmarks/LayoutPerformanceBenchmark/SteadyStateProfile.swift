import DummyBackend
import Foundation
import ImageFormats
@_spi(Backends) import SwiftCrossUI

/// A steady-state profile of the update+layout+commit loop.
///
/// The stock `swift-benchmark` cases measure *building* a view graph from
/// scratch, which is a one-off cost. What makes an app feel sluggish is the
/// cost of every subsequent pass over an already-built graph, so this driver
/// builds the graph once and then measures repeated passes.
///
/// The two phases are timed separately, and the number of backend calls a pass
/// makes is reported alongside them. That call count is the number that
/// predicts Windows behaviour: `DummyBackend` answers a call in nanoseconds,
/// but every one of them is a WinRT/COM crossing on `WinUIBackend`, so a
/// change that halves the call count halves a large part of the Windows frame
/// time even when it barely moves the macOS timings.
///
/// Run with `SCUI_PROFILE=1 .build/release/LayoutPerformanceBenchmark`.
@MainActor
enum SteadyStateProfile {
    /// One measured pass, split into its two phases.
    struct Pass {
        /// Recomputes the view graph's layout.
        var layout: () -> Void
        /// Commits the computed layout to the widget hierarchy, returning the
        /// root's committed size.
        var commit: () -> ViewSize
    }

    struct Stats {
        var label: String
        /// Whole-pass timings, in milliseconds.
        var samples: [Double]
        /// Layout-phase timings, in milliseconds.
        var layoutSamples: [Double]
        /// Commit-phase timings, in milliseconds.
        var commitSamples: [Double]
        var bodyEvaluationsPerPass: Int
        /// The number of backend calls one pass makes.
        var backendCallsPerPass: Int
        /// The size the root view committed to. Reported so that an
        /// optimisation can be shown not to have changed any layout.
        var committedSize: ViewSize

        static func median(_ samples: [Double]) -> Double {
            let sorted = samples.sorted()
            return sorted.isEmpty ? 0 : sorted[sorted.count / 2]
        }

        var median: Double { Self.median(samples) }
        var layoutMedian: Double { Self.median(layoutSamples) }
        var commitMedian: Double { Self.median(commitSamples) }
        var minimum: Double { samples.min() ?? 0 }
    }

    static func run() {
        let backend = DummyBackend()
        let defaultEnvironment = EnvironmentValues(backend: backend)
        let environment = backend.computeRootEnvironment(defaultEnvironment: defaultEnvironment)
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))

        let proposal = ProposedViewSize(1600, 1100)
        let passes = profileIterationCount()

        /// Builds a pass that lays a root view out at a fixed proposal and
        /// commits it, taking a fresh view value from `nextView` each time.
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
            _ = node.computeLayout(proposedSize: proposedSize(), environment: environment)
            _ = node.commit()
            return Pass(
                layout: {
                    _ = node.computeLayout(
                        with: makeView(),
                        proposedSize: proposedSize(),
                        environment: environment
                    )
                },
                commit: {
                    node.commit().size
                }
            )
        }

        var results: [Stats] = []

        // MARK: Idle pass — nothing changed, the graph is just re-run.
        //
        // This is the case a CAD app hits when something re-triggers an update
        // while the model is unchanged, which is where the reported sluggishness
        // lives.
        let idleViewport = CADView.makeViewport(frame: 0)
        results.append(
            measure(label: "cad/idle", passes: passes, backend: backend) {
                steadyPass { CADView(frame: 0, viewport: idleViewport) }
            }
        )

        // MARK: Animating pass — the inspector selection moves and the viewport
        // pixels change every frame, as they would while orbiting a model.
        let viewports = (0..<16).map(CADView.makeViewport(frame:))
        results.append(
            measure(label: "cad/animating", passes: passes, backend: backend) {
                var frame = 0
                return steadyPass {
                    frame += 1
                    return CADView(
                        frame: frame,
                        viewport: viewports[frame % viewports.count]
                    )
                }
            }
        )

        // MARK: Resize pass — a new proposal every frame, which defeats the
        // per-proposal layout cache and is what a window drag costs.
        results.append(
            measure(label: "cad/resize", passes: passes, backend: backend) {
                var frame = 0
                return steadyPass(
                    { CADView(frame: 0, viewport: idleViewport) },
                    proposedSize: {
                        frame += 1
                        return ProposedViewSize(
                            1600 + Double(frame % 8),
                            1100 + Double(frame % 8)
                        )
                    }
                )
            }
        )

        // MARK: A deeply nested tree of stacks, which is where the layout
        // system's per-level probing multiplies.
        results.append(
            measure(label: "grid/idle", passes: passes, backend: backend) {
                steadyPass({ GridView() }, proposedSize: { ProposedViewSize(800, 800) })
            }
        )

        // MARK: A long uniform list — a schedule or a bar list, the other shape
        // a CAD app leans on heavily.
        results.append(
            measure(label: "list/idle", passes: max(passes / 4, 5), backend: backend) {
                steadyPass({ LongListView() }, proposedSize: { ProposedViewSize(800, nil) })
            }
        )

        // MARK: A drafting overlay drawn through `Canvas`, which costs one
        // backend widget per drawing command.
        results.append(
            measure(label: "canvas/idle", passes: max(passes / 2, 5), backend: backend) {
                steadyPass { DraftingOverlayView(phase: 0) }
            }
        )

        results.append(
            measure(label: "canvas/animating", passes: max(passes / 2, 5), backend: backend) {
                var frame = 0
                return steadyPass {
                    frame += 1
                    return DraftingOverlayView(phase: Double(frame) * 0.05)
                }
            }
        )

        // The same overlay, but declaring its inputs so that the canvas can
        // skip the renderer entirely while nothing has moved.
        results.append(
            measure(label: "canvas/declared", passes: max(passes / 2, 5), backend: backend) {
                steadyPass { DeclaredDraftingOverlayView(phase: 0) }
            }
        )

        report(results)
    }

    /// How many measured passes to run. Overridable so that a noisy machine can
    /// be given more samples.
    private static func profileIterationCount() -> Int {
        if let raw = ProcessInfo.processInfo.environment["SCUI_PROFILE_PASSES"],
            let value = Int(raw), value > 0
        {
            return value
        }
        return 60
    }

    /// Builds a graph with `setUp`, warms it, then times `passes` runs of the
    /// pass that `setUp` returns.
    private static func measure(
        label: String,
        passes: Int,
        backend: DummyBackend,
        setUp: () -> Pass
    ) -> Stats {
        let pass = setUp()

        // Warm up: let the allocator and the branch predictors settle, and get
        // any first-pass-only work (widget creation, symbol resolution) out of
        // the way.
        for _ in 0..<5 {
            pass.layout()
            _ = pass.commit()
        }

        // Body evaluations and backend calls are counted over a single
        // untimed pass so that the counters themselves aren't measured.
        BodyCounter.reset()
        backend.resetCallCounts()
        pass.layout()
        _ = pass.commit()
        let bodyEvaluations = BodyCounter.count
        let backendCalls = backend.totalCallCount

        var samples: [Double] = []
        var layoutSamples: [Double] = []
        var commitSamples: [Double] = []
        var size = ViewSize.zero
        samples.reserveCapacity(passes)
        for _ in 0..<passes {
            let start = DispatchTime.now().uptimeNanoseconds
            pass.layout()
            let afterLayout = DispatchTime.now().uptimeNanoseconds
            size = pass.commit()
            let end = DispatchTime.now().uptimeNanoseconds
            layoutSamples.append(Double(afterLayout - start) / 1_000_000)
            commitSamples.append(Double(end - afterLayout) / 1_000_000)
            samples.append(Double(end - start) / 1_000_000)
        }

        return Stats(
            label: label,
            samples: samples,
            layoutSamples: layoutSamples,
            commitSamples: commitSamples,
            bodyEvaluationsPerPass: bodyEvaluations,
            backendCallsPerPass: backendCalls,
            committedSize: size
        )
    }

    private static func report(_ results: [Stats]) {
        func pad(_ string: String, _ width: Int) -> String {
            string.count >= width
                ? string
                : string + String(repeating: " ", count: width - string.count)
        }

        func padLeft(_ string: String, _ width: Int) -> String {
            string.count >= width
                ? string
                : String(repeating: " ", count: width - string.count) + string
        }

        func format(_ value: Double) -> String {
            String(format: "%.3f", value)
        }

        print("")
        print(
            pad("benchmark", 18) + padLeft("pass ms", 10) + padLeft("layout ms", 11)
                + padLeft("commit ms", 11) + padLeft("min ms", 10)
                + padLeft("bodies", 9) + padLeft("backend calls", 15)
                + padLeft("size", 14)
        )
        print(String(repeating: "-", count: 98))
        for result in results {
            print(
                pad(result.label, 18)
                    + padLeft(format(result.median), 10)
                    + padLeft(format(result.layoutMedian), 11)
                    + padLeft(format(result.commitMedian), 11)
                    + padLeft(format(result.minimum), 10)
                    + padLeft("\(result.bodyEvaluationsPerPass)", 9)
                    + padLeft("\(result.backendCallsPerPass)", 15)
                    + padLeft(
                        "\(Int(result.committedSize.width))x\(Int(result.committedSize.height))",
                        14
                    )
            )
        }
        print("")
    }
}
