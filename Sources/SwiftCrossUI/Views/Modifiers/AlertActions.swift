/// Turns the `actions` view builder of an alert into the action list that the
/// dialog backends consume.
///
/// SwiftUI's modern alert takes its buttons as a `@ViewBuilder` rather than as
/// a dedicated result builder, so that `if` statements, `ForEach`, and view
/// modifiers such as ``View/disabled(_:)`` all work inside it. This type turns
/// the resulting view back into the flat list of labelled actions that
/// ``BackendFeatures/Alerts`` and ``BackendFeatures/ConfirmationDialogs``
/// understand.
///
/// The traversal reuses ``MenuItem``, the framework's existing "view tree to
/// list of buttons" mechanism, rather than introducing a second one. That comes
/// with the same limitations menus have: only ``Button``s with text labels
/// become actions, and everything else in the block is ignored.
///
/// Actions are produced as ``ConfirmationDialogAction``s rather than
/// ``AlertAction``s because that type carries a ``ConfirmationDialogAction/Role``,
/// which alerts need in order to render `Button("Delete", role: .destructive)`
/// the way SwiftUI does.
@MainActor
enum AlertActions {
    /// Extracts an alert's actions from its `actions` view builder's result.
    ///
    /// An alert with no recognisable buttons gets a single "OK" button, which
    /// is both what SwiftUI does and what
    /// ``AlertActionsBuilder/buildBlock()`` already did for the result-builder
    /// spelling of this API.
    ///
    /// - Parameter view: The view produced by the `actions` block.
    /// - Returns: The alert's actions, never empty.
    static func actions<Actions: View>(from view: Actions) -> [ConfirmationDialogAction] {
        let actions = view._asMenuItems.flatMap(action(from:))
        guard !actions.isEmpty else {
            return [.default]
        }
        return actions
    }

    /// Turns a single menu item into an alert action, if it is one.
    ///
    /// - Parameter item: The menu item to convert.
    /// - Returns: The action the item describes, or an empty array if the item
    ///   isn't something an alert can display.
    private static func action(from item: MenuItem) -> [ConfirmationDialogAction] {
        switch item {
            case .button(let button):
                return [
                    ConfirmationDialogAction(
                        label: button.body.view0.view0.string,
                        role: role(of: button.role),
                        action: button.action
                    )
                ]
            case .modifiedEnvironment(let item, _):
                // A modifier such as `.disabled(_:)` wraps the button rather
                // than replacing it. The modification itself is dropped: the
                // backend action surface has no per-button enablement.
                return action(from: item())
            case .text, .toggle, .separator, .submenu:
                return []
        }
    }

    /// Translates a button's role into the equivalent dialog action role.
    ///
    /// - Parameter role: The button's role, if it has one.
    /// - Returns: The matching action role, if there is one.
    private static func role(of role: ButtonRole?) -> ConfirmationDialogAction.Role? {
        guard let role else {
            return nil
        }
        switch role.kind {
            case .destructive:
                return .destructive
            case .cancel:
                return .cancel
        }
    }

    /// Whether an actions block contains a text field.
    ///
    /// SwiftUI supports text-entry alerts, which put a ``TextField`` in the
    /// `actions` block. No backend feature protocol can express one, so such a
    /// field is silently dropped; this detects the case so that the dropped
    /// field can at least be reported.
    ///
    /// The scan works on the block's *static* type, which for a view builder
    /// result names every view in the block, so it costs nothing until an alert
    /// is actually presented.
    ///
    /// - Parameter actionsType: The type of the view produced by the `actions`
    ///   block.
    /// - Returns: Whether the block appears to contain a text entry field.
    static func containsTextEntry(_ actionsType: Any.Type) -> Bool {
        let description = String(reflecting: actionsType)
        return description.contains("SwiftCrossUI.TextField")
            || description.contains("SwiftCrossUI.SecureField")
    }
}
