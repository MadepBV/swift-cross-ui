import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Tests for how often a view's body is evaluated.
///
/// A body doesn't depend on the size a view is proposed, but the layout system
/// lays a view out several times per update pass — at its minimum, at its
/// maximum, and at the size its container settles on — and then commits it.
/// The node evaluates the body once per pass and reuses it, which is only safe
/// while every reason the body could produce something different also discards
/// it. These tests pin both halves: the reuse, and each of the invalidations.
@Suite("Testing for body evaluation")
@MainActor
struct BodyEvaluationTests {
    /// Counts body evaluations per view type.
    final class Counter {
        var counts: [String: Int] = [:]

        func record(_ name: String) {
            counts[name, default: 0] += 1
        }

        func count(_ name: String) -> Int {
            counts[name, default: 0]
        }

        func reset() {
            counts.removeAll()
        }
    }

    /// The counter the views under test report to.
    ///
    /// A global because a `View` is a value type rebuilt on every pass, so it
    /// can't own the counter without changing what is being measured.
    nonisolated(unsafe) static let counter = Counter()

    struct CountedLeaf: View {
        var label: String

        var body: some View {
            BodyEvaluationTests.counter.record("leaf")
            return Text(label)
        }
    }

    struct CountedParent: View {
        var label: String

        var body: some View {
            BodyEvaluationTests.counter.record("parent")
            return HStack {
                CountedLeaf(label: label)
                CountedLeaf(label: label + "!")
            }
        }
    }

    struct StatefulView: View {
        @State var revision = 0

        var body: some View {
            BodyEvaluationTests.counter.record("stateful")
            return HStack {
                Text("revision \(revision)")
                Text("padding")
            }
        }
    }

    /// Drives a root view through `DummyBackend`.
    @MainActor
    final class Harness<RootView: View> {
        let backend: DummyBackend
        let environment: EnvironmentValues
        let node: ViewGraphNode<RootView, DummyBackend>

        init(_ view: RootView) {
            backend = DummyBackend()
            environment = backend
                .computeRootEnvironment(
                    defaultEnvironment: EnvironmentValues(backend: backend)
                )
                .with(
                    \.window,
                    backend.createWindow(withDefaultSize: nil, id: "window")
                )
            node = ViewGraphNode(
                for: view,
                backend: backend,
                snapshot: nil,
                environment: environment
            )
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
            return collect(node.widget)
        }

        /// Runs one layout and commit pass.
        func pass(with view: RootView? = nil) {
            _ = node.computeLayout(
                with: view,
                proposedSize: ProposedViewSize(200, 100),
                environment: environment
            )
            _ = node.commit()
        }
    }

    @Test("A body is evaluated once per pass, however often the view is laid out")
    func bodyIsEvaluatedOncePerPass() {
        let harness = Harness(CountedParent(label: "a"))
        harness.pass()

        Self.counter.reset()
        harness.pass()

        // The stack lays each child out at its minimum and its maximum before
        // proposing a size, and then commits it. That must not cost four
        // evaluations of the same body.
        #expect(Self.counter.count("parent") == 1)
        #expect(Self.counter.count("leaf") == 2)
    }

    @Test("A new view value from the parent re-evaluates the body")
    func newViewValueReevaluatesBody() {
        let harness = Harness(CountedParent(label: "a"))
        harness.pass()

        Self.counter.reset()
        harness.pass(with: CountedParent(label: "b"))

        #expect(Self.counter.count("parent") == 1)
        #expect(Self.counter.count("leaf") == 2)
    }

    @Test("A state change re-evaluates the body on the next pass")
    func stateChangeReevaluatesBody() {
        let view = StatefulView()
        let harness = Harness(view)
        harness.pass()

        view.revision = 1

        Self.counter.reset()
        harness.pass()
        #expect(Self.counter.count("stateful") >= 1)

        // And the change actually reached the widget hierarchy.
        #expect(harness.textContents.contains("revision 1"))
    }

    @Test("Repeated passes keep committing the current state")
    func repeatedPassesKeepCommittingState() {
        let view = StatefulView()
        let harness = Harness(view)

        for revision in 0..<4 {
            view.revision = revision
            harness.pass()

            #expect(harness.textContents.contains("revision \(revision)"))
        }
    }
}
