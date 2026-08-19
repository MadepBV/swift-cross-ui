extension View {
    /// Presents an alert when a binding to a Boolean value is `true`.
    ///
    /// ```swift
    /// content.alert("Couldn't save", isPresented: $saveFailed) {
    ///     Button("Retry") { save() }
    ///     Button("Cancel", role: .cancel) {}
    /// }
    /// ```
    ///
    /// The `actions` block is a regular ``ViewBuilder``, so `if` statements and
    /// view modifiers work inside it. Only ``Button``s with text labels become
    /// buttons of the alert, and a single ``TextField`` becomes the alert's
    /// line of text entry (see ``View/alert(_:isPresented:actions:message:)``);
    /// anything else in the block is ignored. A block with no buttons produces
    /// a single "OK" button.
    ///
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - isPresented: A binding controlling whether the alert is presented.
    ///     It's set back to `false` once the user chooses an action.
    ///   - actions: The alert's action buttons.
    /// - Returns: A view that presents the described alert while `isPresented`
    ///   is `true`.
    public func alert<Actions: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        let content = actions()
        return AlertModifierView(
            child: self,
            title: title,
            message: nil,
            isPresented: isPresented,
            actions: AlertActions.actions(from: content),
            textEntry: AlertActions.textEntry(in: content),
            actionsType: Actions.self
        )
    }

    /// Presents an alert with a message when a binding to a Boolean value is
    /// `true`.
    ///
    /// ```swift
    /// content.alert("Unsaved changes", isPresented: $hasRecovery) {
    ///     Button("Recover") { recover() }
    ///     Button("Discard", role: .destructive) { discard() }
    /// } message: {
    ///     Text("This document has \(count) unsaved transactions.")
    /// }
    /// ```
    ///
    /// - Note: A ``TextField`` in the `actions` block makes the alert a
    ///   text-entry alert, as it does in SwiftUI. The field's binding receives
    ///   what the user typed just before the chosen action runs, so an action
    ///   can read it. Backends that can't put a field in an alert drop it with
    ///   a warning; the alert's buttons still work.
    ///
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - isPresented: A binding controlling whether the alert is presented.
    ///     It's set back to `false` once the user chooses an action.
    ///   - actions: The alert's action buttons.
    ///   - message: An explanatory message shown below the title. Only ``Text``
    ///     messages can be displayed; anything else is ignored.
    /// - Returns: A view that presents the described alert while `isPresented`
    ///   is `true`.
    public func alert<Actions: View, Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder message: () -> Message
    ) -> some View {
        let content = actions()
        return AlertModifierView(
            child: self,
            title: title,
            message: ConfirmationDialogModifierView<Self>.string(ofMessage: message()),
            isPresented: isPresented,
            actions: AlertActions.actions(from: content),
            textEntry: AlertActions.textEntry(in: content),
            actionsType: Actions.self
        )
    }

    /// Presents an alert whenever a binding to an optional title is non-`nil`.
    ///
    /// Unlike the other alert modifiers this one has no SwiftUI counterpart. It
    /// exists because reporting an error usually means storing the error's
    /// message, and this saves the caller from keeping a separate `Bool`
    /// alongside it. The binding is set back to `nil` once the user chooses an
    /// action.
    ///
    /// - Parameters:
    ///   - title: A binding to the alert's title. The alert is presented while
    ///     it's non-`nil`.
    ///   - actions: The alert's action buttons.
    /// - Returns: A view that presents the described alert while `title` is
    ///   non-`nil`.
    public func alert<Actions: View>(
        _ title: Binding<String?>,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        let content = actions()
        return AlertModifierView(
            child: self,
            title: title.wrappedValue ?? "",
            message: nil,
            isPresented: Binding {
                title.wrappedValue != nil
            } set: { newValue in
                if !newValue {
                    title.wrappedValue = nil
                }
            },
            actions: AlertActions.actions(from: content),
            textEntry: AlertActions.textEntry(in: content),
            actionsType: Actions.self
        )
    }
}

/// The implementation of ``View/alert(_:isPresented:actions:message:)`` and its
/// siblings.
///
/// Alerts and confirmation dialogs share their backend surface: an alert is
/// presented through ``BackendFeatures/ConfirmationDialogs`` when the backend
/// implements it (which gets it a message and button roles) and falls back to
/// plain ``BackendFeatures/Alerts`` otherwise.
struct AlertModifierView<Child: View>: TypeSafeView {
    typealias Children = AlertModifierViewChildren<Child>

    var body = EmptyView()

    /// The view the alert is attached to.
    var child: Child
    /// The alert's title.
    var title: String
    /// The alert's explanatory message, if any.
    var message: String?
    /// Whether the alert is presented.
    var isPresented: Binding<Bool>
    /// The alert's action buttons.
    var actions: [ConfirmationDialogAction]
    /// The alert's line of text entry, if the `actions` block declared one.
    var textEntry: AlertActions.TextEntry?
    /// The static type of the `actions` block, used to notice a text field that
    /// ``textEntry`` couldn't reach.
    var actionsType: Any.Type

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        AlertModifierViewChildren(
            childNode: AnyViewGraphNode(
                ViewGraphNode(
                    for: child,
                    backend: backend,
                    environment: environment
                )
            ),
            alert: nil
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        children.childNode.widget.into()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        children.childNode.computeLayout(
            with: child,
            proposedSize: proposedSize,
            environment: environment
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        _ = children.childNode.commit()

        // Manual casts rather than @CastBackend, so that a backend without
        // dialog support degrades instead of trapping, and so that backends
        // implementing the richer protocol get the message and button roles.
        if let backend = backend as? any BaseAppBackend & BackendFeatures.ConfirmationDialogs {
            synchronizeDialog(children: children, environment: environment, backend: backend)
        } else if let backend = backend as? any BaseAppBackend & BackendFeatures.Alerts {
            synchronizeAlert(children: children, environment: environment, backend: backend)
        } else {
            logger.warnOnce(
                """
                alert is unsupported by the current backend, which implements \
                neither 'ConfirmationDialogs' nor 'Alerts'
                """
            )
        }
    }

    /// Gives the alert its text field, if it has one the backend can show.
    ///
    /// Anything that couldn't be presented is reported once, so that a dropped
    /// field is never silent.
    ///
    /// - Parameters:
    ///   - alert: The alert to add the field to.
    ///   - backend: The app's backend.
    /// - Returns: Whether the alert ended up with a text field.
    func addTextField<Backend: BaseAppBackend & BackendFeatures.Alerts>(
        to alert: Backend.Alert,
        backend: Backend
    ) -> Bool {
        guard let textEntry else {
            guard AlertActions.containsTextEntry(actionsType) else {
                return false
            }
            logger.warnOnce(
                """
                an alert's text field couldn't be read out of its actions \
                block, so it's being dropped. Present a sheet instead when the \
                entry matters.
                """
            )
            return false
        }

        guard backend.addTextField(textEntry.backendDescription, to: alert) else {
            logger.warnOnce(
                """
                text-entry alerts are unsupported by the current backend, so \
                the field is being dropped. The alert's buttons still work. \
                Present a sheet instead when the entry matters.
                """
            )
            return false
        }
        return true
    }

    /// Writes what the user typed back into the text field's binding.
    ///
    /// Called before the chosen action runs, so that an action which reads the
    /// bound state sees the final contents of the field.
    ///
    /// - Parameters:
    ///   - alert: The alert that was just dismissed.
    ///   - backend: The app's backend.
    func commitTextField<Backend: BaseAppBackend & BackendFeatures.Alerts>(
        of alert: Backend.Alert,
        backend: Backend
    ) {
        guard
            let textEntry,
            let contents = backend.textFieldContents(of: alert)
        else {
            return
        }
        textEntry.text.wrappedValue = contents
    }

    /// Presents or dismisses the alert using a backend that understands
    /// messages and button roles.
    ///
    /// - Parameters:
    ///   - children: The view's children.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private func synchronizeDialog<
        Backend: BaseAppBackend & BackendFeatures.ConfirmationDialogs
    >(
        children: Children,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let window = environment.window.flatMap { $0 as? Backend.Window }

        if isPresented.wrappedValue && children.alert == nil {
            // A text-entry alert is created as an alert rather than as a
            // confirmation dialog, because a backend whose dialogs are a
            // different kind of thing (UIKit's action sheets, for instance)
            // can't put a text field in one. The dialog update is still used,
            // so button roles survive either way.
            let alert =
                textEntry == nil
                ? backend.createConfirmationDialog()
                : backend.createAlert()
            backend.updateConfirmationDialog(
                alert,
                title: title,
                titleVisibility: .visible,
                message: message,
                actions: actions,
                environment: environment
            )
            let hasTextField = addTextField(to: alert, backend: backend)
            let actions = actions
            let isPresented = isPresented
            backend.showAlert(alert, window: window) { response in
                children.alert = nil
                if hasTextField {
                    commitTextField(of: alert, backend: backend)
                }
                isPresented.wrappedValue = false

                guard
                    let index = backend.confirmationDialogActionIndex(
                        forResponse: response,
                        actions: actions
                    )
                else {
                    return
                }
                actions[index].action()
            }
            children.alert = alert
        } else if !isPresented.wrappedValue, let alert = children.alert {
            backend.dismissAlert(alert as! Backend.Alert, window: window)
            children.alert = nil
        }
    }

    /// Presents or dismisses the alert on a backend that only implements
    /// ``BackendFeatures/Alerts``, folding the message into the title and
    /// dropping button roles.
    ///
    /// - Parameters:
    ///   - children: The view's children.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private func synchronizeAlert<Backend: BaseAppBackend & BackendFeatures.Alerts>(
        children: Children,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let window = environment.window.flatMap { $0 as? Backend.Window }

        if isPresented.wrappedValue && children.alert == nil {
            let alert = backend.createAlert()
            backend.updateAlert(
                alert,
                title: title,
                actionLabels: actions.map(\.label),
                environment: environment
            )
            let hasTextField = addTextField(to: alert, backend: backend)
            let actions = actions
            let isPresented = isPresented
            backend.showAlert(alert, window: window) { response in
                children.alert = nil
                if hasTextField {
                    commitTextField(of: alert, backend: backend)
                }
                isPresented.wrappedValue = false

                guard actions.indices.contains(response) else {
                    return
                }
                actions[response].action()
            }
            children.alert = alert
        } else if !isPresented.wrappedValue, let alert = children.alert {
            backend.dismissAlert(alert as! Backend.Alert, window: window)
            children.alert = nil
        }
    }
}

/// The children of an ``AlertModifierView``.
class AlertModifierViewChildren<Child: View>: ViewGraphNodeChildren {
    /// The node of the view that the alert is attached to.
    var childNode: AnyViewGraphNode<Child>
    /// The currently presented alert, if any. Type-erased because its type
    /// depends on the backend.
    var alert: Any?

    var widgets: [AnyWidget] {
        [childNode.widget]
    }

    var erasedNodes: [ErasedViewGraphNode] {
        [ErasedViewGraphNode(wrapping: childNode)]
    }

    /// Creates the children.
    ///
    /// - Parameters:
    ///   - childNode: The node of the view the alert is attached to.
    ///   - alert: The currently presented alert, if any.
    init(
        childNode: AnyViewGraphNode<Child>,
        alert: Any?
    ) {
        self.childNode = childNode
        self.alert = alert
    }
}
