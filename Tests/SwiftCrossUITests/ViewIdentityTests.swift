import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing explicit view identity")
@MainActor
struct ViewIdentityTests {
    struct Editor: View {
        var title: String
        @State private var draft: String

        init(title: String) {
            self.title = title
            _draft = State(wrappedValue: title)
        }

        var body: some View {
            VStack {
                Text("title: \(title)")
                Text("draft: \(draft)")
                Button("Edit") { draft += "!" }
            }
        }
    }

    struct SelectedEditor: View {
        var selection: Int
        var title: String

        var body: some View {
            Editor(title: title).id(selection)
        }
    }

    @MainActor
    final class Harness<Content: View> {
        let backend: DummyBackend
        let graph: ViewGraph<Content>
        var environment: EnvironmentValues

        init(_ content: Content) {
            backend = DummyBackend()
            environment = backend.computeRootEnvironment(
                defaultEnvironment: EnvironmentValues(backend: backend)
            ).with(\.window, backend.createWindow(withDefaultSize: nil, id: "test"))
            graph = ViewGraph(for: content, backend: backend, environment: environment)
        }

        var widgets: [DummyBackend.Widget] {
            func collect(_ widget: DummyBackend.Widget) -> [DummyBackend.Widget] {
                [widget] + widget.getChildren().flatMap(collect)
            }
            return collect(graph.rootNode.concreteNode(for: DummyBackend.self).widget)
        }

        var text: [String] {
            widgets.compactMap { ($0 as? DummyBackend.TextView)?.content }
        }

        var buttons: [DummyBackend.Button] {
            widgets.compactMap { $0 as? DummyBackend.Button }
        }

        @discardableResult
        func pass(_ content: Content? = nil) -> ViewLayoutResult {
            let result = graph.computeLayout(
                with: content,
                proposedSize: ProposedViewSize(300, 200),
                environment: environment
            )
            graph.commit()
            return result
        }
    }

    @Test("An unchanged identity retains edits while receiving new view inputs")
    func sameIdentityPreservesState() throws {
        let harness = Harness(SelectedEditor(selection: 1, title: "first"))
        harness.pass()
        let button = try #require(harness.buttons.first)
        button.action?()
        harness.pass(SelectedEditor(selection: 1, title: "renamed"))

        #expect(harness.text.contains("title: renamed"))
        #expect(harness.text.contains("draft: first!"))
        #expect(harness.buttons.first === button)
    }

    @Test("Changing identity resets a selected editor and does not resurrect old drafts")
    func changedIdentityResetsState() throws {
        let harness = Harness(SelectedEditor(selection: 1, title: "first"))
        harness.pass()
        let firstButton = try #require(harness.buttons.first)
        firstButton.action?()
        harness.pass()
        #expect(harness.text.contains("draft: first!"))

        harness.pass(SelectedEditor(selection: 2, title: "second"))
        #expect(harness.text.contains("draft: second"))
        #expect(!harness.text.contains("draft: first!"))
        #expect(harness.buttons.count == 1)
        #expect(harness.buttons.first !== firstButton)

        harness.pass(SelectedEditor(selection: 1, title: "first again"))
        #expect(harness.text.contains("draft: first again"))
        #expect(harness.buttons.count == 1)
    }

    struct Siblings: View {
        var selection: Int

        var body: some View {
            HStack {
                Editor(title: "selected \(selection)").id(selection)
                Editor(title: "independent").id("sibling")
            }
        }
    }

    @Test("Replacing an identity preserves state outside its subtree")
    func identityDoesNotResetSibling() throws {
        let harness = Harness(Siblings(selection: 1))
        harness.pass()
        let siblingButton = try #require(harness.buttons.last)
        siblingButton.action?()
        harness.pass(Siblings(selection: 2))

        #expect(harness.text.contains("draft: selected 2"))
        #expect(harness.text.contains("draft: independent!"))
        #expect(harness.buttons.last === siblingButton)
    }

    @Test("Identity preserves the content's size and receives environment changes")
    func layoutAndEnvironmentArePreserved() throws {
        let plain = Harness(Text("label").frame(width: 70, height: 35))
        let identified = Harness(Text("label").frame(width: 70, height: 35).id(1))
        #expect(identified.pass().size == plain.pass().size)
        #expect(identified.graph.rootNode.concreteNode(for: DummyBackend.self).currentLayout?.size == ViewSize(70, 35))

        identified.environment = identified.environment.with(\.foregroundColor, .red)
        identified.pass()
        let text = try #require(identified.widgets.compactMap { $0 as? DummyBackend.TextView }.first)
        #expect(text.color == Color.red.resolve(in: identified.environment))
    }
}
