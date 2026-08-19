extension View {
    /// Presents a modal dialog asking the user to confirm or abandon an action.
    ///
    /// Confirmation dialogs are the right tool for irreversible operations
    /// ("delete this placement", "reset this preset"). Give the confirming
    /// button the ``ConfirmationDialogAction/Role/destructive`` role and the
    /// abandoning button the ``ConfirmationDialogAction/Role/cancel`` role, and
    /// each backend will render them the way its platform expects — including
    /// making the cancelling button the dialog's keyboard escape route.
    ///
    /// ```swift
    /// content.confirmationDialog(
    ///     "Delete placement?",
    ///     isPresented: $isConfirmingDelete,
    ///     titleVisibility: .visible
    /// ) {
    ///     Button("Delete") { delete() }.role(.destructive)
    ///     Button("Cancel") {}.role(.cancel)
    /// } message: {
    ///     Text("This can't be undone.")
    /// }
    /// ```
    ///
    /// Backends that don't implement ``BackendFeatures/ConfirmationDialogs``
    /// fall back to a plain alert with unstyled buttons rather than failing.
    ///
    /// - Parameters:
    ///   - title: The dialog's title.
    ///   - isPresented: A binding controlling whether the dialog is presented.
    ///     It's set back to `false` once the user chooses an action.
    ///   - titleVisibility: Whether to display the title. Defaults to
    ///     ``Visibility/automatic``, which lets the backend decide.
    ///   - actions: The dialog's action buttons.
    ///   - message: An explanatory message shown below the title. Only
    ///     ``Text`` messages can be displayed; anything else is ignored.
    /// - Returns: A view that presents the described dialog while `isPresented`
    ///   is `true`.
    public func confirmationDialog<Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        @ConfirmationDialogActionsBuilder actions: () -> [ConfirmationDialogAction],
        @ViewBuilder message: () -> Message
    ) -> some View {
        ConfirmationDialogModifierView(
            child: self,
            title: title,
            titleVisibility: titleVisibility,
            message: ConfirmationDialogModifierView<Self>.string(ofMessage: message()),
            isPresented: isPresented,
            actions: actions()
        )
    }

    /// Presents a modal dialog asking the user to confirm or abandon an action.
    ///
    /// See ``View/confirmationDialog(_:isPresented:titleVisibility:actions:message:)``
    /// for details.
    ///
    /// - Parameters:
    ///   - title: The dialog's title.
    ///   - isPresented: A binding controlling whether the dialog is presented.
    ///   - titleVisibility: Whether to display the title.
    ///   - actions: The dialog's action buttons.
    /// - Returns: A view that presents the described dialog while `isPresented`
    ///   is `true`.
    public func confirmationDialog(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        @ConfirmationDialogActionsBuilder actions: () -> [ConfirmationDialogAction]
    ) -> some View {
        ConfirmationDialogModifierView(
            child: self,
            title: title,
            titleVisibility: titleVisibility,
            message: nil,
            isPresented: isPresented,
            actions: actions()
        )
    }
}

extension Button where Label == TupleView1<Text> {
    /// Gives a button a role for use inside a confirmation dialog.
    ///
    /// SwiftUI spells this `Button(_:role:action:)`. ``Button`` has no room for
    /// a role of its own yet, so confirmation dialogs take the role separately.
    ///
    /// - Parameter role: The role to give the button.
    /// - Returns: An action that a confirmation dialog can display.
    @MainActor
    public func role(_ role: ConfirmationDialogAction.Role) -> ConfirmationDialogAction {
        ConfirmationDialogAction(
            label: body.view0.view0.string,
            role: role,
            action: action
        )
    }
}

/// A result builder for `[ConfirmationDialogAction]`.
///
/// Accepts plain ``Button``s (which become role-less actions), and
/// ``ConfirmationDialogAction``s, which carry a role.
@resultBuilder
public struct ConfirmationDialogActionsBuilder {
    /// Called when no actions are provided.
    ///
    /// - Returns: A default "OK" action.
    public static func buildBlock() -> [ConfirmationDialogAction] {
        [.default]
    }

    /// Starts an action list with a role-less button.
    ///
    /// - Parameter first: The button.
    /// - Returns: The action list so far.
    @MainActor
    public static func buildPartialBlock(
        first: Button<TupleView1<Text>>
    ) -> [ConfirmationDialogAction] {
        [
            ConfirmationDialogAction(
                label: first.body.view0.view0.string,
                action: first.action
            )
        ]
    }

    /// Starts an action list with an action.
    ///
    /// - Parameter first: The action.
    /// - Returns: The action list so far.
    public static func buildPartialBlock(
        first: ConfirmationDialogAction
    ) -> [ConfirmationDialogAction] {
        [first]
    }

    /// Starts an action list with a conditionally-included block.
    ///
    /// - Parameter first: The block.
    /// - Returns: The action list so far.
    public static func buildPartialBlock(first: Block) -> [ConfirmationDialogAction] {
        first.actions
    }

    /// Appends a role-less button to an action list.
    ///
    /// - Parameters:
    ///   - accumulated: The action list so far.
    ///   - next: The button to append.
    /// - Returns: The extended action list.
    @MainActor
    public static func buildPartialBlock(
        accumulated: [ConfirmationDialogAction],
        next: Button<TupleView1<Text>>
    ) -> [ConfirmationDialogAction] {
        accumulated + [
            ConfirmationDialogAction(
                label: next.body.view0.view0.string,
                action: next.action
            )
        ]
    }

    /// Appends an action to an action list.
    ///
    /// - Parameters:
    ///   - accumulated: The action list so far.
    ///   - next: The action to append.
    /// - Returns: The extended action list.
    public static func buildPartialBlock(
        accumulated: [ConfirmationDialogAction],
        next: ConfirmationDialogAction
    ) -> [ConfirmationDialogAction] {
        accumulated + [next]
    }

    /// Appends a conditionally-included block to an action list.
    ///
    /// - Parameters:
    ///   - accumulated: The action list so far.
    ///   - next: The block to append.
    /// - Returns: The extended action list.
    public static func buildPartialBlock(
        accumulated: [ConfirmationDialogAction],
        next: Block
    ) -> [ConfirmationDialogAction] {
        accumulated + next.actions
    }

    /// Wraps the contents of an `if` statement without an `else`.
    ///
    /// - Parameter component: The actions, if the branch was taken.
    /// - Returns: A block of actions.
    public static func buildOptional(_ component: [ConfirmationDialogAction]?) -> Block {
        Block(actions: component ?? [])
    }

    /// Wraps the first branch of an `if`/`else` statement.
    ///
    /// - Parameter component: The actions from the branch.
    /// - Returns: A block of actions.
    public static func buildEither(first component: [ConfirmationDialogAction]) -> Block {
        Block(actions: component)
    }

    /// Wraps the second branch of an `if`/`else` statement.
    ///
    /// - Parameter component: The actions from the branch.
    /// - Returns: A block of actions.
    public static func buildEither(second component: [ConfirmationDialogAction]) -> Block {
        Block(actions: component)
    }

    /// A group of actions produced by a conditional statement.
    public struct Block {
        /// The actions in the block.
        var actions: [ConfirmationDialogAction]
    }
}

/// The implementation of
/// ``View/confirmationDialog(_:isPresented:titleVisibility:actions:message:)``.
struct ConfirmationDialogModifierView<Child: View>: TypeSafeView {
    typealias Children = ConfirmationDialogModifierViewChildren<Child>

    var body = EmptyView()

    var child: Child
    var title: String
    var titleVisibility: Visibility
    var message: String?
    var isPresented: Binding<Bool>
    var actions: [ConfirmationDialogAction]

    /// Extracts the string to display from a message view.
    ///
    /// Backends take the message as a string, so only text messages can be
    /// displayed. Anything else produces a warning and no message.
    ///
    /// - Parameter message: The message view.
    /// - Returns: The message's string, if it has one.
    static func string<Message: View>(ofMessage message: Message) -> String? {
        if let text = message as? Text {
            return text.string
        }
        if let wrapper = message as? TupleView1<Text> {
            return wrapper.view0.string
        }
        logger.warnOnce(
            """
            confirmationDialog messages must be 'Text' views; ignoring a \
            message of type '\(Message.self)'
            """
        )
        return nil
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        ConfirmationDialogModifierViewChildren(
            childNode: AnyViewGraphNode(
                ViewGraphNode(
                    for: child,
                    backend: backend,
                    environment: environment
                )
            )
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

        // A manual cast rather than @CastBackend, because a backend without
        // dialog support should degrade instead of trapping. Backends that
        // implement the richer protocol get roles and messages; backends that
        // only implement `Alerts` still get a working dialog.
        if let backend = backend as? any BaseAppBackend & BackendFeatures.ConfirmationDialogs {
            synchronizeDialog(children: children, environment: environment, backend: backend)
        } else if let backend = backend as? any BaseAppBackend & BackendFeatures.Alerts {
            synchronizeAlert(children: children, environment: environment, backend: backend)
        } else {
            logger.warnOnce(
                """
                confirmationDialog is unsupported by the current backend, \
                which implements neither 'ConfirmationDialogs' nor 'Alerts'
                """
            )
        }
    }

    /// Presents or dismisses the dialog using a backend that understands button
    /// roles.
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

        if isPresented.wrappedValue && children.dialog == nil {
            let dialog = backend.createConfirmationDialog()
            backend.updateConfirmationDialog(
                dialog,
                title: title,
                titleVisibility: titleVisibility,
                message: message,
                actions: actions,
                environment: environment
            )
            let actions = actions
            let isPresented = isPresented
            backend.showAlert(dialog, window: window) { response in
                children.dialog = nil
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
            children.dialog = dialog
        } else if !isPresented.wrappedValue, let dialog = children.dialog {
            backend.dismissAlert(dialog as! Backend.Alert, window: window)
            children.dialog = nil
        }
    }

    /// Presents or dismisses the dialog as a plain alert, for backends that
    /// don't implement ``BackendFeatures/ConfirmationDialogs``.
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

        if isPresented.wrappedValue && children.dialog == nil {
            let dialog = backend.createAlert()
            backend.updateAlert(
                dialog,
                title: ConfirmationDialogAction.headline(
                    title: title,
                    titleVisibility: titleVisibility,
                    message: message
                ),
                actionLabels: actions.map(\.label),
                environment: environment
            )
            let actions = actions
            let isPresented = isPresented
            backend.showAlert(dialog, window: window) { response in
                children.dialog = nil
                isPresented.wrappedValue = false

                guard actions.indices.contains(response) else {
                    return
                }
                actions[response].action()
            }
            children.dialog = dialog
        } else if !isPresented.wrappedValue, let dialog = children.dialog {
            backend.dismissAlert(dialog as! Backend.Alert, window: window)
            children.dialog = nil
        }
    }
}

/// The children of a ``ConfirmationDialogModifierView``.
class ConfirmationDialogModifierViewChildren<Child: View>: ViewGraphNodeChildren {
    /// The node of the view that the dialog is attached to.
    var childNode: AnyViewGraphNode<Child>
    /// The currently presented dialog, if any. Type-erased because its type
    /// depends on the backend.
    var dialog: Any?

    var widgets: [AnyWidget] {
        [childNode.widget]
    }

    var erasedNodes: [ErasedViewGraphNode] {
        [ErasedViewGraphNode(wrapping: childNode)]
    }

    /// Creates the children.
    ///
    /// - Parameter childNode: The node of the view the dialog is attached to.
    init(childNode: AnyViewGraphNode<Child>) {
        self.childNode = childNode
    }
}
