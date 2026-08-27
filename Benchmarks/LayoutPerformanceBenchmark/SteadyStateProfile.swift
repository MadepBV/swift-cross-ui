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
/// Run with `SCUI_PROFILE=1 .build/release/LayoutPerformanceBenchmark`.
@MainActor
enum SteadyStateProfile {
    struct Stats {
        var label: String
        var samples: [Double]
        var bodyEvaluationsPerPass: Double
        /// The size the root view committed to. Reported so that a change to
        /// the layout system can be shown not to have changed any layout.
        var committedSize: ViewSize

        var median: Double {
            let sorted = samples.sorted()
            return sorted[sorted.count / 2]
        }

        var mean: Double {
            samples.reduce(0, +) / Double(samples.count)
        }

        var minimum: Double {
            samples.min() ?? 0
        }
    }

    static func run() {
        let backend = DummyBackend()
        let defaultEnvironment = EnvironmentValues(backend: backend)
        let environment = backend.computeRootEnvironment(defaultEnvironment: defaultEnvironment)
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))

        let proposal = ProposedViewSize(1600, 1100)
        let passes = profileIterationCount()

        var results: [Stats] = []

        // MARK: Idle pass — nothing changed, the graph is just re-run.
        //
        // This is the case a CAD app hits when something re-triggers an update
        // while the model is unchanged, which is where the reported sluggishness
        // lives.
        results.append(
            measure(label: "cad/idle", passes: passes) {
                let viewport = CADView.makeViewport(frame: 0)
                let node = ViewGraphNode(
                    for: CADView(frame: 0, viewport: viewport),
                    backend: backend,
                    snapshot: nil,
                    environment: environment
                )
                _ = node.computeLayout(proposedSize: proposal, environment: environment)
                _ = node.commit()
                return {
                    _ = node.computeLayout(
                        with: CADView(frame: 0, viewport: viewport),
                        proposedSize: proposal,
                        environment: environment
                    )
                    return node.commit().size
                }
            }
        )

        // MARK: Animating pass — the inspector selection moves and the viewport
        // pixels change every frame, as they would while orbiting a model.
        results.append(
            measure(label: "cad/animating", passes: passes) {
                var frame = 0
                let node = ViewGraphNode(
                    for: CADView(frame: 0, viewport: CADView.makeViewport(frame: 0)),
                    backend: backend,
                    snapshot: nil,
                    environment: environment
                )
                _ = node.computeLayout(proposedSize: proposal, environment: environment)
                _ = node.commit()
                // Pre-generate the frames so that buffer allocation isn't part
                // of the measurement.
                let viewports = (0..<16).map(CADView.makeViewport(frame:))
                return {
                    frame += 1
                    _ = node.computeLayout(
                        with: CADView(
                            frame: frame,
                            viewport: viewports[frame % viewports.count]
                        ),
                        proposedSize: proposal,
                        environment: environment
                    )
                    return node.commit().size
                }
            }
        )

        // MARK: Resize pass — a new proposal every frame, which defeats the
        // per-proposal layout cache and is what a window drag costs.
        results.append(
            measure(label: "cad/resize", passes: passes) {
                var frame = 0
                let viewport = CADView.makeViewport(frame: 0)
                let node = ViewGraphNode(
                    for: CADView(frame: 0, viewport: viewport),
                    backend: backend,
                    snapshot: nil,
                    environment: environment
                )
                _ = node.computeLayout(proposedSize: proposal, environment: environment)
                _ = node.commit()
                return {
                    frame += 1
                    let size = ProposedViewSize(
                        1600 + Double(frame % 8),
                        1100 + Double(frame % 8)
                    )
                    _ = node.computeLayout(
                        with: CADView(frame: 0, viewport: viewport),
                        proposedSize: size,
                        environment: environment
                    )
                    return node.commit().size
                }
            }
        )

        // MARK: The stock cases, but measured as steady-state passes rather
        // than as graph construction.
        results.append(
            measure(label: "grid/idle", passes: passes) {
                let node = ViewGraphNode(
                    for: GridView(),
                    backend: backend,
                    snapshot: nil,
                    environment: environment
                )
                _ = node.computeLayout(
                    proposedSize: ProposedViewSize(800, 800),
                    environment: environment
                )
                _ = node.commit()
                return {
                    _ = node.computeLayout(
                        with: GridView(),
                        proposedSize: ProposedViewSize(800, 800),
                        environment: environment
                    )
                    return node.commit().size
                }
            }
        )

        // MARK: A long uniform list — a schedule or bar list, the other shape
        // a CAD app leans on heavily.
        results.append(
            measure(label: "list/idle", passes: max(passes / 4, 5)) {
                let node = ViewGraphNode(
                    for: LongListView(),
                    backend: backend,
                    snapshot: nil,
                    environment: environment
                )
                _ = node.computeLayout(
                    proposedSize: ProposedViewSize(800, nil),
                    environment: environment
                )
                _ = node.commit()
                return {
                    _ = node.computeLayout(
                        with: LongListView(),
                        proposedSize: ProposedViewSize(800, nil),
                        environment: environment
                    )
                    return node.commit().size
                }
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

    /// Builds a graph with `setUp`, warms it, then times `passes` calls of the
    /// closure that `setUp` returns.
    private static func measure(
        label: String,
        passes: Int,
        setUp: () -> () -> ViewSize
    ) -> Stats {
        let pass = setUp()

        // Warm up: let the allocator and the branch predictors settle, and get
        // any first-pass-only work (widget creation, symbol resolution) out of
        // the way.
        for _ in 0..<5 {
            _ = pass()
        }

        // Count body evaluations over a single pass, separately from the timed
        // run so that the counter itself isn't measured.
        BodyCounter.reset()
        _ = pass()
        let bodyEvaluations = Double(BodyCounter.count)

        var samples: [Double] = []
        var size = ViewSize.zero
        samples.reserveCapacity(passes)
        for _ in 0..<passes {
            let start = DispatchTime.now().uptimeNanoseconds
            size = pass()
            let end = DispatchTime.now().uptimeNanoseconds
            samples.append(Double(end - start) / 1_000_000)
        }

        return Stats(
            label: label,
            samples: samples,
            bodyEvaluationsPerPass: bodyEvaluations,
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
            pad("benchmark", 18) + padLeft("median ms", 12) + padLeft("mean ms", 12)
                + padLeft("min ms", 12) + padLeft("bodies/pass", 14)
        )
        print(String(repeating: "-", count: 68))
        for result in results {
            print(
                pad(result.label, 18)
                    + padLeft(format(result.median), 12)
                    + padLeft(format(result.mean), 12)
                    + padLeft(format(result.minimum), 12)
                    + padLeft("\(Int(result.bodyEvaluationsPerPass))", 14)
                    + padLeft(
                        "\(Int(result.committedSize.width))x\(Int(result.committedSize.height))",
                        18
                    )
            )
        }
        print("")
    }
}
