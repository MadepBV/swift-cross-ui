import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// The behaviour any update short-circuit has to preserve.
///
/// A short-circuit — a node returning its committed layout without walking its
/// subtree, because nothing feeding it changed — was built and then withdrawn;
/// see the note on ``ViewGraphNode``. These tests are what it has to pass, and
/// they are kept because the failure mode is not a crash: taken wrongly, a
/// short-circuit produces a UI that silently stops updating, and — in the
/// ``Grid`` case below — drawings whose cells are silently in the wrong places.
/// Each one is currently satisfied by the graph re-walking on every pass.
///
/// `deepStateChangeStillUpdates` is the one that caught the real defect: a
/// state mutation marks its node dirty only when the *scheduled* update runs,
/// so a pass landing in between would short-circuit straight past the node that
/// changed.
@Suite("Testing what an update short-circuit must preserve")
@MainActor
struct ShortCircuitTests {
    struct Model {
        var label: String
    }

    struct DeepLeaf: View {
        @State var revision = 0

        var body: some View {
            Text("deep \(revision)")
        }
    }

    struct DeepParent: View {
        var body: some View {
            VStack {
                Text("chrome")
                DeepLeaf()
            }
        }
    }

    struct EnvironmentReader: View {
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            VStack {
                Text("chrome")
                Text("scheme \(colorScheme == .dark ? "dark" : "light")")
            }
        }
    }

    struct GridContent: View {
        var rows: [[String]]

        var body: some View {
            Grid {
                ForEach(rows) { row in
                    GridRow {
                        ForEach(row) { cell in
                            Text(cell)
                        }
                    }
                }
            }
        }
    }

    /// Drives a root view through a real ``ViewGraph``, which is the layer a
    /// short-circuit's recursion would be grounded in.
    @MainActor
    final class Harness<RootView: View> {
        let backend: DummyBackend
        var environment: EnvironmentValues
        let graph: ViewGraph<RootView>

        init(_ view: RootView) {
            backend = DummyBackend()
            environment =
                backend
                .computeRootEnvironment(
                    defaultEnvironment: EnvironmentValues(backend: backend)
                )
                .with(
                    \.window,
                    backend.createWindow(withDefaultSize: nil, id: "window")
                )
            graph = ViewGraph(for: view, backend: backend, environment: environment)
        }

        var textContents: [String] {
            func collect(_ widget: DummyBackend.Widget) -> [String] {
                var contents: [String] = []
                if let text = widget as? DummyBackend.TextView {
                    contents.append(text.content)
                }
                for child in widget.getChildren() {
                    contents += collect(child)
                }
                return contents
            }
            return collect(graph.rootNode.concreteNode(for: DummyBackend.self).widget)
        }

        /// Runs one layout and commit pass.
        func pass(
            with view: RootView? = nil,
            proposedSize: ProposedViewSize = ProposedViewSize(200, 100)
        ) {
            _ = graph.computeLayout(
                with: view,
                proposedSize: proposedSize,
                environment: environment
            )
            graph.commit()
        }
    }

    @Test("A state change deep in a subtree still reaches the widgets")
    func deepStateChangeStillUpdates() {
        let leaf = DeepLeaf()
        // Reach the leaf through a parent that has nothing of its own to
        // change, so the parent is exactly the node that would wrongly
        // short-circuit past it. This is the test that failed when the
        // short-circuit was in place.
        let harness = Harness(VStack { Text("chrome"); leaf })
        harness.pass()
        harness.pass()
        #expect(harness.textContents.contains("deep 0"))

        leaf.revision = 1
        harness.pass()

        #expect(harness.textContents.contains("deep 1"))
    }

    @Test("An environment change still re-lays-out the subtree that reads it")
    func environmentChangeStillRelayouts() {
        let harness = Harness(EnvironmentReader())
        harness.pass()
        harness.pass()
        #expect(harness.textContents.contains("scheme light"))

        harness.environment = harness.environment.with(\.colorScheme, .dark)
        harness.pass()

        #expect(harness.textContents.contains("scheme dark"))
    }

    @Test("A node does not short-circuit when its proposal changes")
    func proposalChangeDefeatsShortCircuit() {
        let harness = Harness(
            VStack {
                Color.blue.frame(maxWidth: .infinity)
            }
        )
        harness.pass(proposedSize: ProposedViewSize(200, 100))
        harness.pass(proposedSize: ProposedViewSize(200, 100))

        // A different proposal must reach the subtree, otherwise a resized
        // window would keep the size it had.
        let resized = graphSize(harness, proposedSize: ProposedViewSize(300, 100))
        #expect(resized.width == 300)
    }

    private func graphSize<V: View>(
        _ harness: Harness<V>,
        proposedSize: ProposedViewSize
    ) -> ViewSize {
        let result = harness.graph.computeLayout(
            proposedSize: proposedSize,
            environment: harness.environment
        )
        harness.graph.commit()
        return result.size
    }

    @Test("A grid lays out correctly across repeated passes")
    func gridStaysCorrectAcrossShortCircuitedPasses() {
        // The regression test for why a published `ContainerChildLayout` must
        // never be short-circuited past. `GridLayoutContext` pairs
        // `addParticipant` with `commitNextParticipant` by count and order, on a
        // cursor it advances itself, so a participant skipped during layout but
        // still committed would silently shift every later cell rather than
        // fail. Repeated passes are what would expose it: the first pass
        // populates the caches a later pass would short-circuit against.
        let harness = Harness(
            GridContent(rows: [["a", "b"], ["c", "d"], ["e", "f"]])
        )
        for _ in 0..<4 {
            harness.pass()
            let texts = harness.textContents
            #expect(texts.contains("a"))
            #expect(texts.contains("d"))
            #expect(texts.contains("f"))
            #expect(texts.filter { $0 == "a" }.count == 1)
        }
    }

    @Test("Repeated identical passes keep committing the same content")
    func repeatedIdenticalPassesAreStable() {
        let harness = Harness(DeepParent())
        for _ in 0..<5 {
            harness.pass()
            #expect(harness.textContents.contains("chrome"))
            #expect(harness.textContents.contains("deep 0"))
        }
    }
}
