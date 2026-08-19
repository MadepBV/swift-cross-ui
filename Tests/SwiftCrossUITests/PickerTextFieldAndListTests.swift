import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit
    @testable import AppKitBackend
#endif

/// An element of a list that identifies itself, standing in for the catalogue
/// records an application lists.
private struct MeshDefinition: Identifiable {
    /// The definition's designation, which is also its identity.
    var id: String
}

/// The identity of a ``ProfileSnapshot``.
///
/// A type of its own, rather than a `String`, because the application's own
/// identifiers are wrappers like this one and a list has to accept them.
private struct ProfileID: Hashable {
    /// The identifier's underlying value.
    var rawValue: String
}

/// An element of a list that has an identity but doesn't conform to
/// `Identifiable`, so that a list over it has to be given a key path.
private struct ProfileSnapshot {
    /// The snapshot's identity.
    var id: ProfileID
    /// The text a row displays for the snapshot.
    var displayDesignation: String
}

/// A mutable source of truth for a string, standing in for the `@State`
/// property an application would bind a field to.
private final class TextSource {
    /// The current text.
    var value: String

    /// A binding to ``TextSource/value``.
    var binding: Binding<String> {
        Binding(
            get: { self.value },
            set: { newValue in self.value = newValue }
        )
    }

    /// Creates a source.
    ///
    /// - Parameter value: The initial text.
    init(_ value: String) {
        self.value = value
    }
}

/// A view that hands the environment it was rendered in back to the test.
///
/// The modifiers under test here record their settings in the environment, and
/// this is how a test reads one back without reaching into the view graph.
private struct EnvironmentProbe: View {
    /// Called with the environment every time the probe's body is evaluated.
    var record: (EnvironmentValues) -> Void

    @Environment(\.self) private var environment

    var body: some View {
        Text(recordEnvironment())
    }

    /// Records the environment and returns the text the probe displays.
    ///
    /// - Returns: The probe's text.
    private func recordEnvironment() -> String {
        record(environment)
        return "Probe"
    }
}

/// Every call shape that the gap list measured, written exactly as the
/// application writes it.
///
/// Nothing renders this view; constructing it is the point. Each of these
/// spellings failed to compile before, and a regression would break the build
/// of this test rather than one of its assertions.
private struct ApplicationCallShapes: View {
    /// The definitions listed by the mesh stock picker.
    var definitions: [MeshDefinition]
    /// The font families listed by the font family picker.
    var filteredFamilies: [String]
    /// The profiles listed by the steel profile library.
    var projectResults: [ProfileSnapshot]
    /// The text edited by every field below.
    @Binding var draft: String

    var body: some View {
        VStack {
            // Inspector/MeshPlacementInspectorView.swift:1404
            List(definitions) { definition in
                Text(definition.id)
            }

            // Panels/DrawingFontFamilyPicker.swift:72
            List(filteredFamilies, id: \.self) { family in
                Text(family)
            }

            // Steel/SteelProfileLibraryView.swift:169
            List(projectResults, id: \.id) { profile in
                Text(profile.displayDesignation)
            }

            // Inspector/DimensionTextInspectorView.swift:36
            TextField(
                "Override",
                text: $draft,
                prompt: Text("Automatic")
            )

            // Inspector/SheetRevisionLedgerEditorView.swift:455
            TextField(
                "Description",
                text: $draft,
                axis: .vertical
            )
            .lineLimit(2...4)

            // Panels/ViewLibraryPanel.swift:74
            Text("Empty")
                .listRowSeparator(.hidden)

            // Panels/MeshDefinitionLibraryManagerView.swift:117
            NavigationStack {
                List(definitions) { definition in
                    NavigationLink(value: definition.id) {
                        Text(definition.id)
                    }
                }
            }
        }
    }
}

@Suite("Testing for selection-less lists, field prompts and axes, and row separators")
struct PickerTextFieldAndListTests {
    /// The size proposed to every view under test.
    static let proposal = ProposedViewSize(400, 300)

    /// The backend every test renders with.
    let backend: DummyBackend
    /// The window every test renders into.
    let window: DummyBackend.Window
    /// The environment every test renders in.
    let environment: EnvironmentValues

    /// Creates a test case.
    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    // MARK: The measured call shapes

    @MainActor
    @Test("Every measured application call shape compiles")
    func everyMeasuredCallShapeCompiles() {
        let draft = TextSource("Draft")
        let shapes = ApplicationCallShapes(
            definitions: [MeshDefinition(id: "A")],
            filteredFamilies: ["Helvetica"],
            projectResults: [
                ProfileSnapshot(
                    id: ProfileID(rawValue: "1"),
                    displayDesignation: "IPE 200"
                )
            ],
            draft: draft.binding
        )

        #expect(shapes.definitions.count == 1)
    }

    // MARK: Selection-less lists

    @MainActor
    @Test("A list of identifiable elements needs no selection binding")
    func listOfIdentifiableElementsNeedsNoSelection() {
        let list = List([MeshDefinition(id: "A"), MeshDefinition(id: "B")]) { definition in
            Text(definition.id)
        }

        guard case .items = list.storage else {
            Issue.record("A collection list should store a selectable list")
            return
        }

        let node = committedNode(for: list)

        #expect(node.widget.firstWidget(ofType: DummyBackend.SelectableListView.self) != nil)
        #expect(texts(in: node.widget) == ["A", "B"])
    }

    @MainActor
    @Test("A list identified by a key path needs no selection binding")
    func listIdentifiedByAKeyPathNeedsNoSelection() {
        let list = List(["Helvetica", "Menlo"], id: \.self) { family in
            Text(family)
        }

        let node = committedNode(for: list)

        #expect(node.widget.firstWidget(ofType: DummyBackend.SelectableListView.self) != nil)
        #expect(texts(in: node.widget) == ["Helvetica", "Menlo"])
    }

    @MainActor
    @Test("A key path identity can be any hashable value")
    func aKeyPathIdentityCanBeAnyHashableValue() {
        let profiles = [
            ProfileSnapshot(id: ProfileID(rawValue: "1"), displayDesignation: "IPE 200"),
            ProfileSnapshot(id: ProfileID(rawValue: "2"), displayDesignation: "HEA 100"),
        ]
        let node = committedNode(
            for: List(profiles, id: \.id) { profile in
                Text(profile.displayDesignation)
            }
        )

        #expect(texts(in: node.widget) == ["IPE 200", "HEA 100"])
    }

    @MainActor
    @Test("A selection-less list never reports a selection")
    func selectionLessListNeverReportsASelection() {
        let node = committedNode(
            for: List([MeshDefinition(id: "A"), MeshDefinition(id: "B")]) { definition in
                Text(definition.id)
            }
        )

        let listView = node.widget.firstWidget(ofType: DummyBackend.SelectableListView.self)

        #expect(listView?.selectedIndex == nil)

        // The backend still reports clicks; the list just has nowhere to put
        // them. This would trap if a row had to stand for a selection value.
        listView?.selectionHandler?(1)

        #expect(listView?.selectedIndex == nil)
    }

    @MainActor
    @Test("A list with a selection binding still tracks its selection")
    func listWithASelectionBindingStillTracksItsSelection() {
        let selection = SelectionSource<String>(nil)
        let node = committedNode(
            for: List(["Alpha", "Beta"], id: \.self, selection: selection.binding)
        )

        let listView = node.widget.firstWidget(ofType: DummyBackend.SelectableListView.self)
        listView?.selectionHandler?(1)

        #expect(selection.value == "Beta")
    }

    // MARK: Field prompts

    @MainActor
    @Test("A prompt stands in for the field's placeholder")
    func promptStandsInForThePlaceholder() {
        let text = TextSource("")
        let node = committedNode(
            for: TextField("Override", text: text.binding, prompt: Text("Automatic"))
        )

        let field = node.widget.firstWidget(ofType: DummyBackend.TextField.self)

        #expect(field?.placeholder == "Automatic")
    }

    @MainActor
    @Test("A field without a prompt still shows its title")
    func fieldWithoutAPromptStillShowsItsTitle() {
        let text = TextSource("")
        let node = committedNode(for: TextField("Override", text: text.binding))

        let field = node.widget.firstWidget(ofType: DummyBackend.TextField.self)

        #expect(field?.placeholder == "Override")
    }

    @MainActor
    @Test("An alert still finds a prompted field's placeholder")
    func alertStillFindsAPromptedFieldsPlaceholder() {
        let text = TextSource("Draft")
        let entry = AlertActions.textEntry(
            in: TextField("Override", text: text.binding, prompt: Text("Automatic"))
        )

        #expect(entry?.backendDescription.placeholder == "Automatic")
        #expect(entry?.backendDescription.initialValue == "Draft")
    }

    // MARK: Line limits

    @MainActor
    @Test("A closed range line limit caps at its upper bound")
    func closedRangeLineLimitCapsAtItsUpperBound() {
        var recorded: LineLimit?
        _ = committedNode(
            for: EnvironmentProbe { environment in
                recorded = environment.lineLimitSettings
            }
            .lineLimit(2...4)
        )

        #expect(recorded?.limit == 4)
        #expect(recorded?.reservesSpace == false)
    }

    @MainActor
    @Test("A plain line limit is untouched by the range overload")
    func plainLineLimitIsUntouchedByTheRangeOverload() {
        var recorded: LineLimit?
        _ = committedNode(
            for: EnvironmentProbe { environment in
                recorded = environment.lineLimitSettings
            }
            .lineLimit(3, reservesSpace: true)
        )

        #expect(recorded?.limit == 3)
        #expect(recorded?.reservesSpace == true)
    }

    // MARK: Row separators

    @MainActor
    @Test("A hidden row separator is recorded in the environment")
    func hiddenRowSeparatorIsRecordedInTheEnvironment() {
        var recorded: ListRowSeparator?
        _ = committedNode(
            for: EnvironmentProbe { environment in
                recorded = environment.listRowSeparator
            }
            .listRowSeparator(.hidden)
        )

        #expect(recorded?.visibility == .hidden)
        #expect(recorded?.edges == .all)
    }

    @MainActor
    @Test("A row separator can be asked for on one edge")
    func rowSeparatorCanBeAskedForOnOneEdge() {
        var recorded: ListRowSeparator?
        _ = committedNode(
            for: EnvironmentProbe { environment in
                recorded = environment.listRowSeparator
            }
            .listRowSeparator(.visible, edges: .bottom)
        )

        #expect(recorded?.visibility == .visible)
        #expect(recorded?.edges == .bottom)
    }

    @MainActor
    @Test("Hiding a row separator leaves the row itself alone")
    func hidingARowSeparatorLeavesTheRowAlone() {
        let node = committedNode(
            for: List {
                Text("Empty")
                    .listRowSeparator(.hidden)
            }
        )

        #expect(texts(in: node.widget) == ["Empty"])
    }

    // MARK: Path-less navigation links

    @MainActor
    @Test("A path-less value link appends to the enclosing stack's path")
    func pathlessValueLinkAppendsToTheEnclosingStacksPath() {
        let path = PathSource()
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack(path: path.binding) {
                NavigationLink(value: NavigationSubject(name: "Physics")) {
                    Text("Link")
                }
            }
            .navigationDestination(for: NavigationSubject.self) { subject in
                Text(subject.name)
            }
        }

        harness.render()
        #expect(texts(in: harness.widget) == ["Link"])

        harness.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()

        #expect(texts(in: harness.widget) == ["Physics"])
    }

    @MainActor
    @Test("A path-less text link appends to the enclosing stack's path")
    func pathlessTextLinkAppendsToTheEnclosingStacksPath() {
        let path = PathSource()
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack(path: path.binding) {
                NavigationLink("Science", value: NavigationSubject(name: "Physics"))
            }
            .navigationDestination(for: NavigationSubject.self) { subject in
                Text(subject.name)
            }
        }

        harness.render()
        #expect(texts(in: harness.widget) == ["Science"])

        harness.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()

        #expect(texts(in: harness.widget) == ["Physics"])
    }

    @MainActor
    @Test("A path-less value link navigates a stack that owns its own path")
    func pathlessValueLinkNavigatesAStackThatOwnsItsPath() {
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack {
                NavigationLink(value: NavigationSubject(name: "Physics")) {
                    Text("Link")
                }
            }
            .navigationDestination(for: NavigationSubject.self) { subject in
                Text(subject.name)
            }
        }

        harness.render()
        harness.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()

        #expect(texts(in: harness.widget) == ["Physics"])
    }

    @MainActor
    @Test("A path-less value link outside a stack does nothing")
    func pathlessValueLinkOutsideAStackDoesNothing() {
        let node = committedNode(
            for: NavigationLink(value: NavigationSubject(name: "Physics")) {
                Text("Link")
            }
        )

        node.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()

        #expect(texts(in: node.widget) == ["Link"])
    }

    @MainActor
    @Test("A value link with a path is unchanged by the path-less one")
    func valueLinkWithAPathIsUnchangedByThePathlessOne() {
        let path = PathSource()
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack(path: path.binding) {
                Text("Root")
            }
            .navigationDestination(for: NavigationSubject.self) { subject in
                Text(subject.name)
            }
        }
        let link = NavigationLink(
            value: NavigationSubject(name: "Physics"),
            path: path.binding
        ) {
            Text("Link")
        }

        harness.render()

        let linkNode = committedNode(for: link)
        linkNode.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()

        #expect(texts(in: harness.widget) == ["Physics"])
    }

    // MARK: Helpers

    /// Renders a view once and hands back its node.
    ///
    /// - Parameters:
    ///   - view: The view to render.
    ///   - proposedSize: The size to propose to it.
    /// - Returns: The view's node in the view graph.
    @MainActor
    func committedNode<V: View>(
        for view: V,
        proposedSize: ProposedViewSize = PickerTextFieldAndListTests.proposal
    ) -> ViewGraphNode<V, DummyBackend> {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        _ = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        return node
    }

    /// Collects the content of every text widget in a widget hierarchy.
    ///
    /// - Parameter widget: The root of the hierarchy.
    /// - Returns: The content of every text widget, in tree order.
    @MainActor
    func texts(in widget: DummyBackend.Widget) -> [String] {
        var result: [String] = []
        if let textView = widget as? DummyBackend.TextView {
            result.append(textView.content)
        }
        if let button = widget as? DummyBackend.Button, let label = button.label {
            result += texts(in: label)
        }
        if let button = widget as? DummyBackend.SimpleButton {
            result.append(button.label)
        }
        for child in widget.getChildren() {
            result += texts(in: child)
        }
        return result
    }
}

#if canImport(AppKitBackend)
    @Suite("Testing for text field axes on a backend with a real multi-line editor")
    @MainActor
    struct TextFieldAxisTests {
        @Test("A horizontal field is a single-line text field")
        func horizontalFieldIsASingleLineTextField() {
            let text = TextSource("Alpha")
            let render = AppKitRender(TextField("Title", text: text.binding))

            #expect(render.find(NSTextView.self) == nil)
            #expect(render.find(NSTextField.self)?.stringValue == "Alpha")
        }

        @Test("A vertical field is backed by the multi-line editor")
        func verticalFieldIsBackedByTheMultiLineEditor() {
            let text = TextSource("Alpha")
            let render = AppKitRender(
                TextField("Title", text: text.binding, axis: .vertical)
            )

            #expect(render.find(NSTextView.self)?.string == "Alpha")
        }

        @Test("A vertical field grows with its content")
        func verticalFieldGrowsWithItsContent() {
            let short = TextSource("Alpha")
            let long = TextSource(String(repeating: "Alpha beta gamma delta ", count: 20))
            let shortRender = AppKitRender(
                TextField("Title", text: short.binding, axis: .vertical)
            )
            let longRender = AppKitRender(
                TextField("Title", text: long.binding, axis: .vertical)
            )

            #expect(longRender.size.height > shortRender.size.height)
        }

        @Test("A vertical field writes edits back to its binding")
        func verticalFieldWritesEditsBackToItsBinding() {
            let text = TextSource("Alpha")
            let render = AppKitRender(
                TextField("Title", text: text.binding, axis: .vertical)
            )

            let editor = try? #require(render.find(NSTextView.self))
            editor?.string = "Beta"
            editor?.didChangeText()

            #expect(text.value == "Beta")
        }
    }

    /// A view rendered with an ``AppKitBackend``.
    ///
    /// ``DummyBackend`` doesn't implement text editors, so the multi-line side
    /// of ``TextField`` can only be exercised against a backend that does.
    @MainActor
    private final class AppKitRender {
        /// The rendered view's graph node.
        private let node: ErasedViewGraphNode
        /// The environment that the view is rendered in.
        private let environment: EnvironmentValues
        /// The size the view laid itself out at.
        private(set) var size = ViewSize.zero

        /// The root of the rendered widget hierarchy.
        var widget: NSView {
            node.getWidget().into()
        }

        /// Renders a view.
        ///
        /// - Parameter view: The view to render.
        init<Content: View>(_ view: Content) {
            let backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(400, 200),
                id: "window"
            )
            environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            node = ErasedViewGraphNode(
                for: view,
                backend: backend,
                environment: environment
            )
            _ = node.computeLayoutWithNewView(
                nil,
                ProposedViewSize(400, nil),
                environment
            )
            size = node.commit().size
        }

        /// Finds the first widget of the given type in the rendered hierarchy.
        ///
        /// - Parameter type: The type of widget to look for.
        /// - Returns: The first matching widget, or `nil` if there is none.
        func find<Widget: NSView>(_ type: Widget.Type) -> Widget? {
            var queue = [widget]
            while let next = queue.first {
                queue.removeFirst()
                if let match = next as? Widget {
                    return match
                }
                queue.append(contentsOf: next.subviews)
            }
            return nil
        }
    }
#endif
