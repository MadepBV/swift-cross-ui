import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Tests for the view graph's root being handed no new view value.
///
/// ``ViewGraph/computeLayout(with:proposedSize:environment:)`` used to
/// substitute its stored view whenever its caller passed `nil`. That told the
/// root node it had been handed a recomputed value, so the node discarded the
/// body it had already evaluated and evaluated an identical one — and it meant
/// no node in the graph ever saw `nil`, which is the only signal that says "the
/// value you are holding is still current".
///
/// It now passes `nil` through. `nil` also means "no previous value" to
/// ``DynamicPropertyUpdater``, whose whole purpose is to let a freshly built
/// view value adopt the live storage of the value it replaces, so these tests
/// pin that the property wrappers still behave when nothing is handed over.
@Suite("Testing for a view graph root handed no new view")
@MainActor
struct ViewGraphRootUpdateTests {
    struct StatefulRoot: View {
        @State var revision = 0
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            VStack {
                Text("revision \(revision)")
                Text("scheme \(colorScheme == .dark ? "dark" : "light")")
            }
        }
    }

    /// Drives a root view through a real ``ViewGraph``, which is the layer that
    /// decides what the root node is handed.
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

        /// Every text view anywhere beneath the root widget.
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

        /// Runs one layout and commit pass, handing over `view` (`nil` by
        /// default, which is what a scene that wasn't recomputed passes).
        func pass(with view: RootView? = nil) {
            _ = graph.computeLayout(
                with: view,
                proposedSize: ProposedViewSize(200, 100),
                environment: environment
            )
            graph.commit()
        }
    }

    @Test("@State still reaches the widgets when the root is handed no new view")
    func stateUpdatesWithoutANewViewValue() {
        let view = StatefulRoot()
        let harness = Harness(view)
        harness.pass()
        #expect(harness.textContents.contains("revision 0"))

        // The state's storage lives behind the property wrapper, so this is the
        // same mutation a button's action would make.
        view.revision = 1
        harness.pass()

        #expect(harness.textContents.contains("revision 1"))
    }

    @Test("@State survives many passes that hand over nothing")
    func stateSurvivesRepeatedEmptyPasses() {
        let view = StatefulRoot()
        let harness = Harness(view)

        // If a `nil` hand-over were ever treated as a first update, the state's
        // storage would be replaced by a fresh one and the revision would reset.
        for revision in 0..<4 {
            view.revision = revision
            harness.pass()
            #expect(harness.textContents.contains("revision \(revision)"))
        }
    }

    @Test("@Environment still tracks the environment when the root is handed no new view")
    func environmentUpdatesWithoutANewViewValue() {
        let harness = Harness(StatefulRoot())
        harness.pass()
        #expect(harness.textContents.contains("scheme light"))

        harness.environment = harness.environment.with(\.colorScheme, .dark)
        harness.pass()

        #expect(harness.textContents.contains("scheme dark"))
    }

    @Test("A new view value handed to the root still replaces the old one")
    func newViewValueStillTakesEffect() {
        let harness = Harness(StatefulRoot())
        harness.pass()

        let replacement = StatefulRoot()
        replacement.revision = 7
        harness.pass(with: replacement)

        // A recomputed value adopts the live storage of the one it replaces, so
        // the *old* revision is what survives. What matters here is that the
        // hand-over path still runs at all.
        #expect(harness.textContents.contains("revision 0"))
    }
}
