import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A source of truth for a presentation's `isPresented` state, standing in for
/// the `@State` property that an app would usually use.
final class AlertPresentationSource {
    /// Whether the alert is presented.
    var isPresented: Bool

    /// A binding to ``AlertPresentationSource/isPresented``.
    var binding: Binding<Bool> {
        Binding(
            get: { self.isPresented },
            set: { newValue in self.isPresented = newValue }
        )
    }

    /// Creates a source.
    ///
    /// - Parameter isPresented: Whether the alert starts out presented.
    init(_ isPresented: Bool) {
        self.isPresented = isPresented
    }
}

/// A mutable box, so that tests can record what happened inside a closure that
/// the view graph owns.
final class ActionRecorder {
    /// How many times the recorded action ran.
    var count = 0

    /// Whether the recorded action ever ran.
    var didRun: Bool { count > 0 }
}

/// A view that takes a plain escaping closure and forwards it to a ``Button``.
///
/// This is the shape that made ``Button``'s `@Sendable` action a problem: an
/// application's own row, toolbar, and inspector views declare their callbacks
/// as plain `@escaping () -> Void`, exactly as SwiftUI lets them, and then hand
/// them straight to a button.
struct ActionForwardingRow: View {
    /// The button's title.
    var title: String

    /// The button's action, which is deliberately neither `@Sendable` nor
    /// actor-isolated.
    var action: () -> Void

    var body: some View {
        Button(title, action: action)
    }
}

/// A view that takes plain escaping closures for both a button's action and its
/// label.
struct LabelForwardingRow: View {
    /// Builds the button's label.
    var makeLabel: () -> Text

    /// The button's action.
    var action: () -> Void

    var body: some View {
        Button(action: action, label: makeLabel)
    }
}

/// A value that a navigation path can carry.
struct NavigationSubject: Codable {
    /// The subject's name, rendered by the destination.
    var name: String
}

@Suite("Testing for row-built lists, closure navigation, and modern alerts")
struct ListNavigationAndAlertTests {
    /// The size proposed to every view under test.
    static let proposal = ProposedViewSize(400, 300)

    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    // MARK: Button actions

    @MainActor
    @Test("Button accepts a plain escaping closure as its action")
    func buttonAcceptsAPlainEscapingClosure() {
        let recorder = ActionRecorder()
        let node = committedNode(
            for: ActionForwardingRow(title: "Apply") { recorder.count += 1 }
        )

        let button = node.widget.firstWidget(ofType: DummyBackend.Button.self)
        button?.action?()

        #expect(button != nil)
        #expect(recorder.didRun)
    }

    @MainActor
    @Test("Button accepts a plain escaping closure as its label")
    func buttonAcceptsAPlainLabelClosure() {
        let recorder = ActionRecorder()
        let node = committedNode(
            for: LabelForwardingRow(
                makeLabel: { Text("Apply") },
                action: { recorder.count += 1 }
            )
        )

        let button = node.widget.firstWidget(ofType: DummyBackend.Button.self)
        button?.action?()

        #expect(texts(in: node.widget) == ["Apply"])
        #expect(recorder.didRun)
    }

    @MainActor
    @Test("Button's own spellings still resolve unambiguously")
    func buttonSpellingsRemainUnambiguous() {
        // Dropping `@Sendable` must not have introduced a second candidate at
        // any of these call sites.
        let recorder = ActionRecorder()
        let plainTitle = Button("Save")
        let titleWithAction = Button("Save") { recorder.count += 1 }
        let labelOnly = Button {
            Text("Save")
        }
        let actionAndLabel = Button(action: { recorder.count += 1 }) {
            Text("Save")
        }

        titleWithAction.action()
        actionAndLabel.action()

        #expect(plainTitle.role == nil)
        #expect(labelOnly.role == nil)
        #expect(recorder.count == 2)
    }

    // MARK: Row-built lists

    @MainActor
    @Test("List built from a view builder stores its rows")
    func rowBuiltListStoresItsRows() {
        let list = List {
            Text("Alpha")
        }

        guard case .rows = list.storage else {
            Issue.record("A row-built list should store its content as rows")
            return
        }
    }

    @MainActor
    @Test("List built from a collection still uses the selectable list widget")
    func collectionListStillUsesTheSelectableListWidget() {
        let selection = SelectionSource<String>(nil)
        let list = List(["Alpha", "Beta"], id: \.self, selection: selection.binding)

        guard case .items = list.storage else {
            Issue.record("A collection list should store a selectable list")
            return
        }

        let node = committedNode(for: list)

        #expect(node.widget.firstWidget(ofType: DummyBackend.SelectableListView.self) != nil)
        #expect(texts(in: node.widget) == ["Alpha", "Beta"])
    }

    @MainActor
    @Test("List built from a view builder renders every row")
    func rowBuiltListRendersEveryRow() {
        let node = committedNode(
            for: List {
                Text("Alpha")
                Text("Beta")
            }
        )

        #expect(texts(in: node.widget) == ["Alpha", "Beta"])
    }

    @MainActor
    @Test("List built from a view builder renders sections")
    func rowBuiltListRendersSections() {
        let node = committedNode(
            for: List {
                Section("Layers") {
                    Text("Alpha")
                }
            }
        )

        #expect(texts(in: node.widget) == ["Layers", "Alpha"])
    }

    @MainActor
    @Test("List built from a view builder accepts a selection binding")
    func rowBuiltListAcceptsASelection() {
        let selection = SelectionSource<String>("Alpha")
        let list = List(selection: selection.binding) {
            Text("Alpha")
            Text("Beta")
        }

        guard case .rows = list.storage else {
            Issue.record("A row-built list should store its content as rows")
            return
        }

        let node = committedNode(for: list)

        #expect(texts(in: node.widget) == ["Alpha", "Beta"])
        #expect(selection.value == "Alpha")
    }

    // MARK: Alert actions

    @MainActor
    @Test("Alert actions read labels and roles from buttons")
    func alertActionsCarryLabelsAndRoles() {
        let actions = AlertActions.actions(from: TupleView2(
            Button("Discard", role: .destructive) {},
            Button("Cancel", role: .cancel) {}
        ))

        #expect(actions.map(\.label) == ["Discard", "Cancel"])
        #expect(actions.map(\.role) == [.destructive, .cancel])
    }

    @MainActor
    @Test("Alert actions see through view modifiers")
    func alertActionsSeeThroughModifiers() {
        let recorder = ActionRecorder()
        let actions = Self.buildAlertActions {
            Button("Save") { recorder.count += 1 }
                .disabled(true)
        }

        actions.first?.action()

        #expect(actions.map(\.label) == ["Save"])
        #expect(recorder.didRun)
    }

    @MainActor
    @Test("Alert actions support conditionals")
    func alertActionsSupportConditionals() {
        let includeReset = true
        let actions = Self.buildAlertActions {
            Button("Save") {}
            if includeReset {
                Button("Reset", role: .destructive) {}
            }
        }

        #expect(actions.map(\.label) == ["Save", "Reset"])
    }

    @MainActor
    @Test("An empty alert actions block gets a default OK button")
    func alertActionsDefaultToOK() {
        let actions = Self.buildAlertActions {}

        #expect(actions.map(\.label) == ["OK"])
        #expect(actions.map(\.role) == [nil])
    }

    @MainActor
    @Test("A text field in an alert actions block is detected and dropped")
    func alertActionsDropTextFields() {
        let text = SelectionSource<String>("")
        let textBinding = Binding<String>(
            get: { text.value ?? "" },
            set: { newValue in text.value = newValue }
        )
        let actions = Self.buildAlertActions {
            TextField("Name", text: textBinding)
            Button("Rename") {}
        }

        #expect(actions.map(\.label) == ["Rename"])
        #expect(
            AlertActions.containsTextEntry(
                TupleView2<TextField, Button<TupleView1<Text>>>.self
            )
        )
        #expect(!AlertActions.containsTextEntry(TupleView1<Button<TupleView1<Text>>>.self))
    }

    // MARK: Alert modifiers

    @MainActor
    @Test("An alert with a message carries its title, message, and actions")
    func alertCarriesItsTitleMessageAndActions() {
        let source = AlertPresentationSource(false)
        let view = Text("Content")
            .alert("Unsaved changes", isPresented: source.binding) {
                Button("Recover") {}
                Button("Discard", role: .destructive) {}
            } message: {
                Text("Two transactions were not saved.")
            }

        let modifier = view as? AlertModifierView<Text>

        #expect(modifier?.title == "Unsaved changes")
        #expect(modifier?.message == "Two transactions were not saved.")
        #expect(modifier?.actions.map(\.label) == ["Recover", "Discard"])
        #expect(modifier?.actions.map(\.role) == [nil, .destructive])
    }

    @MainActor
    @Test("An alert without a message has none")
    func alertWithoutAMessageHasNone() {
        let source = AlertPresentationSource(false)
        let view = Text("Content")
            .alert("Couldn't save", isPresented: source.binding) {
                Button("OK") {}
            }

        let modifier = view as? AlertModifierView<Text>

        #expect(modifier?.title == "Couldn't save")
        #expect(modifier?.message == nil)
        #expect(modifier?.actions.map(\.label) == ["OK"])
    }

    @MainActor
    @Test("An alert bound to an optional title presents while it is non-nil")
    func optionalTitleAlertFollowsItsTitle() {
        let title = SelectionSource<String>("Couldn't load")
        let view = Text("Content")
            .alert(title.binding) {
                Button("OK") {}
            }

        let modifier = view as? AlertModifierView<Text>
        #expect(modifier?.title == "Couldn't load")
        #expect(modifier?.isPresented.wrappedValue == true)

        modifier?.isPresented.wrappedValue = false
        #expect(title.value == nil)
    }

    @MainActor
    @Test("An alert is transparent to layout")
    func alertDoesNotAffectLayout() {
        let source = AlertPresentationSource(true)
        let plain = Color.blue.frame(width: 120, height: 60)
        let withAlert = Color.blue
            .frame(width: 120, height: 60)
            .alert("Couldn't save", isPresented: source.binding) {
                Button("OK") {}
            } message: {
                Text("The disk is full.")
            }

        #expect(computeLayout(of: plain).size == computeLayout(of: withAlert).size)
    }

    @MainActor
    @Test("An alert degrades gracefully on a backend without alerts")
    func alertDegradesGracefullyWithoutBackendSupport() {
        // DummyBackend implements neither `ConfirmationDialogs` nor `Alerts`,
        // so presenting an alert must be a no-op rather than a trap.
        let source = AlertPresentationSource(true)
        let node = committedNode(
            for: Text("Content")
                .alert("Couldn't save", isPresented: source.binding) {
                    Button("OK") {}
                } message: {
                    Text("The disk is full.")
                }
        )

        #expect(texts(in: node.widget) == ["Content"])
        #expect(source.isPresented)
    }

    // MARK: Navigation

    @MainActor
    @Test("A path-less NavigationStack manages its own navigation state")
    func pathlessNavigationStackManagesItsOwnPath() {
        let stack = NavigationStack {
            Text("Root")
        }

        #expect(stack.externalPath == nil)
        #expect(texts(in: committedNode(for: stack).widget) == ["Root"])
    }

    @MainActor
    @Test("A NavigationStack with a path still navigates by value")
    func navigationStackWithAPathStillNavigatesByValue() {
        let path = PathSource()
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack(path: path.binding) {
                Text("Root")
            }
            .navigationDestination(for: NavigationSubject.self) { subject in
                Text(subject.name)
            }
        }

        harness.render()
        #expect(texts(in: harness.widget) == ["Root"])

        path.value.append(NavigationSubject(name: "Physics"))
        harness.render()

        #expect(texts(in: harness.widget) == ["Physics"])
    }

    @MainActor
    @Test("A closure NavigationLink stores its destination and label")
    func closureNavigationLinkStoresItsDestination() {
        let link = NavigationLink {
            Text("Destination")
        } label: {
            Text("Link")
        }

        guard case .destination = link.storage else {
            Issue.record("A closure link should store a destination")
            return
        }

        #expect(texts(in: committedNode(for: link).widget) == ["Link"])
    }

    @MainActor
    @Test("A closure NavigationLink pushes its destination onto the stack")
    func closureNavigationLinkPushesOntoTheStack() {
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack {
                NavigationLink {
                    Text("Destination")
                } label: {
                    Text("Link")
                }
            }
        }

        harness.render()
        #expect(texts(in: harness.widget) == ["Link"])

        harness.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()

        #expect(texts(in: harness.widget) == ["Back", "Destination"])
    }

    @MainActor
    @Test("The back button returns to the previous view")
    func backButtonReturnsToThePreviousView() {
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack {
                NavigationLink {
                    Text("Destination")
                } label: {
                    Text("Link")
                }
            }
        }

        harness.render()
        harness.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()
        // The back button is the first button once a destination is on top.
        harness.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()

        #expect(texts(in: harness.widget) == ["Link"])
    }

    @MainActor
    @Test("A closure NavigationLink outside a stack does nothing")
    func closureNavigationLinkOutsideAStackDoesNothing() {
        let node = committedNode(
            for: NavigationLink {
                Text("Destination")
            } label: {
                Text("Link")
            }
        )

        node.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()

        #expect(texts(in: node.widget) == ["Link"])
    }

    @MainActor
    @Test("The environment carries a navigation stack's pusher")
    func environmentCarriesTheNavigationPusher() {
        let recorder = ActionRecorder()
        let pusher = NavigationDestinationPusher { _ in recorder.count += 1 }
        let modified = environment.with(\.pushNavigationDestination, pusher)

        #expect(environment.pushNavigationDestination == nil)

        modified.pushNavigationDestination?(AnyView(Text("Destination")))

        #expect(recorder.count == 1)
    }

    // MARK: Helpers

    /// Runs an alert actions block, so that the extraction can be tested
    /// without presenting an alert.
    ///
    /// - Parameter actions: The alert's actions.
    /// - Returns: The extracted actions.
    @MainActor
    static func buildAlertActions<Actions: View>(
        @ViewBuilder _ actions: () -> Actions
    ) -> [ConfirmationDialogAction] {
        AlertActions.actions(from: actions())
    }

    /// Lays a view out without committing it.
    ///
    /// - Parameters:
    ///   - view: The view to lay out.
    ///   - proposedSize: The size to propose to it.
    /// - Returns: The result of laying the view out.
    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = ListNavigationAndAlertTests.proposal
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        return node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }

    /// Renders a view once and hands back its node.
    ///
    /// - Parameters:
    ///   - view: The view to render.
    ///   - proposedSize: The size to propose to it.
    /// - Returns: The view's node in the view graph.
    @MainActor
    func committedNode<V: View>(
        for view: V,
        proposedSize: ProposedViewSize = ListNavigationAndAlertTests.proposal
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
    /// A button's label isn't one of its children as far as `DummyBackend` is
    /// concerned, so it's descended into explicitly.
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

/// A source of truth for a selection, standing in for the `@State` property an
/// app would drive one with.
final class SelectionSource<Value> {
    /// The current selection.
    var value: Value?

    /// A binding to ``SelectionSource/value``.
    var binding: Binding<Value?> {
        Binding(
            get: { self.value },
            set: { newValue in self.value = newValue }
        )
    }

    /// Creates a source.
    ///
    /// - Parameter value: The initial selection.
    init(_ value: Value?) {
        self.value = value
    }
}

/// A source of truth for a navigation path.
final class PathSource {
    /// The current path.
    var value = NavigationPath()

    /// A binding to ``PathSource/value``.
    var binding: Binding<NavigationPath> {
        Binding(
            get: { self.value },
            set: { newValue in self.value = newValue }
        )
    }
}

/// Renders a view with ``DummyBackend`` and re-renders it on demand, so that
/// tests can watch it respond to state changes the way the view graph would.
@MainActor
final class Harness<Content: View> {
    /// The widget the view rendered into.
    var widget: DummyBackend.Widget { node.widget }

    /// The environment the view is rendered with.
    private let environment: EnvironmentValues
    /// The view's node in the view graph.
    private let node: ViewGraphNode<Content, DummyBackend>
    /// Recomputes the view from the test's current state.
    private let makeView: () -> Content

    /// Renders a view for the first time.
    ///
    /// - Parameters:
    ///   - backend: The backend to render with.
    ///   - environment: The environment to render in.
    ///   - makeView: Recomputes the view from the test's current state. Called
    ///     once per render, exactly as the view graph would.
    init(
        backend: DummyBackend,
        environment: EnvironmentValues,
        _ makeView: @escaping () -> Content
    ) {
        self.environment = environment
        self.makeView = makeView
        node = ViewGraphNode(
            for: makeView(),
            backend: backend,
            environment: environment
        )
    }

    /// Recomputes and commits the view's layout, picking up any state changes
    /// the test has made since the last render.
    @discardableResult
    func render() -> ViewLayoutResult {
        _ = node.computeLayout(
            with: makeView(),
            proposedSize: ListNavigationAndAlertTests.proposal,
            environment: environment
        )
        return node.commit()
    }
}
