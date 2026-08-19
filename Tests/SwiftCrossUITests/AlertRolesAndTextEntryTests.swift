import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

/// A view that forwards a plain escaping closure into a ``Button`` inside a
/// confirmation dialog.
///
/// This is the shape that made the alert action types' `@Sendable` actions a
/// problem: an application's own view declares its callback as a plain
/// `@escaping () -> Void`, exactly as SwiftUI lets it, and then hands it to a
/// button inside a dialog.
struct ConfirmingRow: View {
    /// Whether the dialog is presented.
    var isPresented: Binding<Bool>

    /// What to do when the user confirms.
    var confirm: () -> Void

    var body: some View {
        Text("Row")
            .confirmationDialog("Delete placement?", isPresented: isPresented) {
                Button("Delete", role: .destructive, action: confirm)
                Button("Cancel", role: .cancel) {}
            }
    }
}

/// A view that forwards a plain escaping closure into a ``Button`` inside an
/// alert.
struct AlertingRow: View {
    /// Whether the alert is presented.
    var isPresented: Binding<Bool>

    /// What to do when the user retries.
    var retry: () -> Void

    var body: some View {
        Text("Row")
            .alert("Couldn't save", isPresented: isPresented) {
                Button("Retry", action: retry)
                Button("Cancel", role: .cancel) {}
            }
    }
}

/// A view that forwards a plain escaping closure to ``View/onDisappear(perform:)``.
struct DisappearingRow: View {
    /// What to do once the row goes away.
    var vanish: () -> Void

    var body: some View {
        Text("Row").onDisappear(perform: vanish)
    }
}

@Suite("Testing for alert roles, text-entry alerts, and labelled value links")
struct AlertRolesAndTextEntryTests {
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

    // MARK: Plain escaping closures

    @MainActor
    @Test("A dialog Button accepts a plain escaping closure as its action")
    func dialogButtonAcceptsAPlainEscapingClosure() {
        let presented = AlertPresentationSource(false)
        let recorder = ActionRecorder()
        let view = ConfirmingRow(isPresented: presented.binding) {
            recorder.count += 1
        }

        let wrapper = view.body as? TupleView1<ConfirmationDialogModifierView<Text>>
        let modifier = wrapper?.view0
        modifier?.actions.first?.action()

        #expect(modifier?.actions.map(\.label) == ["Delete", "Cancel"])
        #expect(recorder.didRun)
    }

    @MainActor
    @Test("An alert Button accepts a plain escaping closure as its action")
    func alertButtonAcceptsAPlainEscapingClosure() {
        let presented = AlertPresentationSource(false)
        let recorder = ActionRecorder()
        let view = AlertingRow(isPresented: presented.binding) {
            recorder.count += 1
        }

        let wrapper = view.body as? TupleView1<AlertModifierView<Text>>
        let modifier = wrapper?.view0
        modifier?.actions.first?.action()

        #expect(modifier?.actions.map(\.label) == ["Retry", "Cancel"])
        #expect(recorder.didRun)
    }

    @MainActor
    @Test("onDisappear accepts a plain escaping closure")
    func onDisappearAcceptsAPlainEscapingClosure() {
        let recorder = ActionRecorder()
        let node = committedNode(for: DisappearingRow { recorder.count += 1 })

        #expect(texts(in: node.widget) == ["Row"])
    }

    // MARK: Role conversion

    @MainActor
    @Test("A button role converts to the matching dialog role")
    func buttonRolesConvertToDialogRoles() {
        #expect(ConfirmationDialogAction.Role(ButtonRole.destructive) == .destructive)
        #expect(ConfirmationDialogAction.Role(ButtonRole.cancel) == .cancel)
        #expect(ConfirmationDialogAction.Role(nil) == nil)
    }

    // MARK: Confirmation dialog roles

    @MainActor
    @Test("A confirmation dialog keeps the roles its buttons were given")
    func confirmationDialogKeepsButtonRoles() {
        let source = AlertPresentationSource(false)
        let view = Text("Content")
            .confirmationDialog("Delete placement?", isPresented: source.binding) {
                Button("Delete", role: .destructive) {}
                Button("Keep") {}
                Button("Cancel", role: .cancel) {}
            }

        let modifier = view as? ConfirmationDialogModifierView<Text>

        #expect(modifier?.actions.map(\.label) == ["Delete", "Keep", "Cancel"])
        #expect(modifier?.actions.map(\.role) == [.destructive, nil, .cancel])
    }

    @MainActor
    @Test("A confirmation dialog with a message keeps its button roles too")
    func confirmationDialogWithAMessageKeepsButtonRoles() {
        let source = AlertPresentationSource(false)
        let view = Text("Content")
            .confirmationDialog(
                "Reset preset?",
                isPresented: source.binding,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }

        let modifier = view as? ConfirmationDialogModifierView<Text>

        #expect(modifier?.message == "This can't be undone.")
        #expect(modifier?.actions.map(\.role) == [.destructive, .cancel])
    }

    @MainActor
    @Test("A dialog button's role doesn't disturb its action")
    func dialogButtonRoleDoesNotDisturbTheAction() {
        let recorder = ActionRecorder()
        let actions = Self.buildDialogActions {
            Button("Delete", role: .destructive) { recorder.count += 1 }
        }

        actions.first?.action()

        #expect(actions.map(\.role) == [.destructive])
        #expect(recorder.didRun)
    }

    @MainActor
    @Test("Button.role(_:) still wins over the button's own role")
    func explicitDialogRoleStillWins() {
        // `Button.role(_:)` produces an action directly, so it never reaches
        // the builder's button overloads. It must keep working; four existing
        // tests spell dialogs that way.
        let actions = Self.buildDialogActions {
            Button("Delete") {}.role(.destructive)
            Button("Cancel") {}.role(.cancel)
        }

        #expect(actions.map(\.role) == [.destructive, .cancel])
    }

    // MARK: Text entry extraction

    @MainActor
    @Test("An alert's text field is found in its actions block")
    func alertFindsItsTextField() {
        let draft = SelectionSource<String>("Old name")
        let view = Text("Content")
            .alert("Rename", isPresented: AlertPresentationSource(false).binding) {
                TextField("Name", text: Self.binding(to: draft))
                Button("Rename") {}
            }

        let modifier = view as? AlertModifierView<Text>

        #expect(modifier?.textEntry?.placeholder == "Name")
        #expect(modifier?.textEntry?.isSecure == false)
        #expect(modifier?.textEntry?.backendDescription.initialValue == "Old name")
        #expect(modifier?.actions.map(\.label) == ["Rename"])
    }

    @MainActor
    @Test("An alert's secure field is found and marked secure")
    func alertFindsItsSecureField() {
        let draft = SelectionSource<String>("")
        let view = Text("Content")
            .alert("Unlock", isPresented: AlertPresentationSource(false).binding) {
                SecureField("Password", text: Self.binding(to: draft))
                Button("Unlock") {}
            }

        let modifier = view as? AlertModifierView<Text>

        #expect(modifier?.textEntry?.placeholder == "Password")
        #expect(modifier?.textEntry?.isSecure == true)
    }

    @MainActor
    @Test("An alert without a text field has no text entry")
    func alertWithoutATextFieldHasNoTextEntry() {
        let source = AlertPresentationSource(false)
        let view = Text("Content")
            .alert("Couldn't save", isPresented: source.binding) {
                Button("OK") {}
            }

        let modifier = view as? AlertModifierView<Text>

        #expect(modifier?.textEntry == nil)
    }

    @MainActor
    @Test("An alert's text field survives being wrapped in a modifier")
    func alertFindsATextFieldBehindAModifier() {
        let draft = SelectionSource<String>("Old name")
        let view = Text("Content")
            .alert("Rename", isPresented: AlertPresentationSource(false).binding) {
                TextField("Name", text: Self.binding(to: draft))
                    .disabled(false)
                Button("Rename") {}
            }

        let modifier = view as? AlertModifierView<Text>

        #expect(modifier?.textEntry?.placeholder == "Name")
    }

    // MARK: Text entry on AppKit

    #if canImport(AppKitBackend)
        @MainActor
        @Test("AppKit gives a text-entry alert a field with its initial value")
        func appKitAddsATextFieldToAnAlert() {
            let backend = AppKitBackend()
            let alert = backend.createAlert()
            let added = backend.addTextField(
                AlertTextField(placeholder: "Name", initialValue: "Old name"),
                to: alert
            )

            #expect(added)
            #expect(backend.textFieldContents(of: alert) == "Old name")

            let field = alert.accessoryView as? NSTextField
            #expect(field?.placeholderString == "Name")
            #expect(field?.isKind(of: NSSecureTextField.self) == false)
        }

        @MainActor
        @Test("AppKit gives a secure text-entry alert a secure field")
        func appKitAddsASecureTextFieldToAnAlert() {
            let backend = AppKitBackend()
            let alert = backend.createAlert()
            let added = backend.addTextField(
                AlertTextField(placeholder: "Password", initialValue: "", isSecure: true),
                to: alert
            )

            #expect(added)
            #expect(alert.accessoryView is NSSecureTextField)
        }

        @MainActor
        @Test("An AppKit text-entry alert returns the typed string")
        func appKitTextEntryReturnsTheTypedString() {
            let draft = SelectionSource<String>("Old name")
            let recorder = ActionRecorder()
            let view = Text("Content")
                .alert("Rename", isPresented: AlertPresentationSource(true).binding) {
                    TextField("Name", text: Self.binding(to: draft))
                    Button("Rename") { recorder.count += 1 }
                }

            guard let modifier = view as? AlertModifierView<Text> else {
                Issue.record("An alert should produce an alert modifier view")
                return
            }

            let backend = AppKitBackend()
            let alert = backend.createAlert()
            backend.updateAlert(
                alert,
                title: modifier.title,
                actionLabels: modifier.actions.map(\.label),
                environment: EnvironmentValues(backend: backend)
            )

            #expect(modifier.addTextField(to: alert, backend: backend))

            // Stand in for the user typing into the alert's field.
            (alert.accessoryView as? NSTextField)?.stringValue = "New name"
            modifier.commitTextField(of: alert, backend: backend)
            modifier.actions.first?.action()

            #expect(draft.value == "New name")
            #expect(recorder.didRun)
        }

        @MainActor
        @Test("An alert without a text field adds none")
        func appKitAlertWithoutATextFieldAddsNone() {
            let source = AlertPresentationSource(true)
            let view = Text("Content")
                .alert("Couldn't save", isPresented: source.binding) {
                    Button("OK") {}
                }

            guard let modifier = view as? AlertModifierView<Text> else {
                Issue.record("An alert should produce an alert modifier view")
                return
            }

            let backend = AppKitBackend()
            let alert = backend.createAlert()

            #expect(!modifier.addTextField(to: alert, backend: backend))
            #expect(alert.accessoryView == nil)
            #expect(backend.textFieldContents(of: alert) == nil)
        }

        @MainActor
        @Test("A destructive dialog button reaches AppKit with its role")
        func destructiveDialogButtonReachesAppKit() {
            guard #available(macOS 11, *) else {
                return
            }

            let source = AlertPresentationSource(false)
            let view = Text("Content")
                .confirmationDialog("Delete placement?", isPresented: source.binding) {
                    Button("Delete", role: .destructive) {}
                    Button("Cancel", role: .cancel) {}
                }

            guard let modifier = view as? ConfirmationDialogModifierView<Text> else {
                Issue.record("A dialog should produce a dialog modifier view")
                return
            }

            let backend = AppKitBackend()
            let dialog = backend.createConfirmationDialog()
            backend.updateConfirmationDialog(
                dialog,
                title: "Delete placement?",
                titleVisibility: .visible,
                message: nil,
                actions: modifier.actions,
                environment: EnvironmentValues(backend: backend)
            )

            #expect(dialog.alertStyle == .critical)
            #expect(dialog.buttons.count == 2)
            #expect(dialog.buttons.first?.hasDestructiveAction == true)
            #expect(dialog.buttons.last?.hasDestructiveAction == false)
            #expect(dialog.buttons.last?.keyEquivalent == "\u{1b}")
        }

        @MainActor
        @Test("A role-less dialog button reaches AppKit unstyled")
        func rolelessDialogButtonReachesAppKitUnstyled() {
            guard #available(macOS 11, *) else {
                return
            }

            let backend = AppKitBackend()
            let dialog = backend.createConfirmationDialog()
            backend.updateConfirmationDialog(
                dialog,
                title: "Save changes?",
                titleVisibility: .visible,
                message: nil,
                actions: Self.buildDialogActions {
                    Button("Save") {}
                },
                environment: EnvironmentValues(backend: backend)
            )

            #expect(dialog.alertStyle == .warning)
            #expect(dialog.buttons.first?.hasDestructiveAction == false)
        }
    #endif

    // MARK: Labelled value navigation links

    @MainActor
    @Test("A NavigationLink with a value and a label stores both")
    func labelledValueLinkStoresItsValueAndLabel() {
        let path = PathSource()
        let link = NavigationLink(
            value: NavigationSubject(name: "Physics"),
            path: path.binding
        ) {
            Text("Open physics")
        }

        guard case .labelledValue = link.storage else {
            Issue.record("A value link with a label should store a labelled value")
            return
        }

        #expect(texts(in: committedNode(for: link).widget) == ["Open physics"])
    }

    @MainActor
    @Test("A NavigationLink with a value and a label navigates by value")
    func labelledValueLinkNavigatesByValue() {
        let path = PathSource()
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack(path: path.binding) {
                NavigationLink(
                    value: NavigationSubject(name: "Physics"),
                    path: path.binding
                ) {
                    Text("Open physics")
                }
            }
            .navigationDestination(for: NavigationSubject.self) { subject in
                Text(subject.name)
            }
        }

        harness.render()
        #expect(texts(in: harness.widget) == ["Open physics"])

        harness.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()
        harness.render()

        #expect(texts(in: harness.widget) == ["Physics"])
    }

    @MainActor
    @Test("The text NavigationLink value form still works")
    func textValueLinkStillNavigatesByValue() {
        let path = PathSource()
        let harness = Harness(backend: backend, environment: environment) {
            NavigationStack(path: path.binding) {
                NavigationLink(
                    "Open physics",
                    value: NavigationSubject(name: "Physics"),
                    path: path.binding
                )
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

    // MARK: Helpers

    /// Runs a confirmation dialog actions block, so that the builder can be
    /// tested without presenting a dialog.
    ///
    /// - Parameter actions: The dialog's actions.
    /// - Returns: The built actions.
    @MainActor
    static func buildDialogActions(
        @ConfirmationDialogActionsBuilder _ actions: () -> [ConfirmationDialogAction]
    ) -> [ConfirmationDialogAction] {
        actions()
    }

    /// Makes a non-optional string binding out of a selection source.
    ///
    /// ``SelectionSource`` holds an optional so that it can stand in for a list
    /// selection, but a ``TextField`` needs a plain `String`.
    ///
    /// - Parameter source: The source to bind to.
    /// - Returns: A binding to the source's value.
    @MainActor
    static func binding(to source: SelectionSource<String>) -> Binding<String> {
        Binding(
            get: { source.value ?? "" },
            set: { newValue in source.value = newValue }
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
        proposedSize: ProposedViewSize = AlertRolesAndTextEntryTests.proposal
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
