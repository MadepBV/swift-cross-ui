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
///
/// A ``TextField`` in the block doesn't become an action; it makes the alert a
/// text-entry alert. ``textEntry(in:)`` finds it.
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
                        role: ConfirmationDialogAction.Role(button.role),
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

    /// Whether an actions block contains a text field.
    ///
    /// SwiftUI supports text-entry alerts, which put a ``TextField`` in the
    /// `actions` block. This detects the case cheaply, so that a field which
    /// ``textEntry(in:)`` couldn't reach, or which the backend couldn't
    /// display, can be reported rather than silently dropped.
    ///
    /// The scan works on the block's *static* type, which for a view builder
    /// result names every view in the block, so it never has to walk the views
    /// themselves.
    ///
    /// - Parameter actionsType: The type of the view produced by the `actions`
    ///   block.
    /// - Returns: Whether the block appears to contain a text entry field.
    static func containsTextEntry(_ actionsType: Any.Type) -> Bool {
        let description = String(reflecting: actionsType)
        return description.contains("SwiftCrossUI.TextField")
            || description.contains("SwiftCrossUI.SecureField")
    }

    /// Extracts an alert's text entry field from its `actions` view builder's
    /// result.
    ///
    /// An alert can only have one field, so the first one found wins and the
    /// rest are dropped, exactly as SwiftUI does.
    ///
    /// The block's static type is checked first, so that the blocks which don't
    /// declare a field at all — almost all of them — never pay for the search.
    ///
    /// - Parameter view: The view produced by the `actions` block.
    /// - Returns: The alert's text entry field, if it has one.
    static func textEntry<Actions: View>(in view: Actions) -> TextEntry? {
        guard containsTextEntry(Actions.self) else {
            return nil
        }
        return textEntry(inside: view, depth: 0)
    }

    /// How far into an actions block to look for a text field.
    ///
    /// Deep enough for a field wrapped in the modifiers an author might
    /// reasonably apply to one, and shallow enough that a view holding a
    /// reference cycle can't make the search run forever.
    private static let maximumTextEntrySearchDepth = 8

    /// Finds the first text field within a value.
    ///
    /// - Parameters:
    ///   - value: The value to search. Usually a view.
    ///   - depth: How many levels have already been descended.
    /// - Returns: The first text field found, if any.
    private static func textEntry(inside value: Any, depth: Int) -> TextEntry? {
        if let field = value as? TextField {
            return TextEntry(reflecting: field, isSecure: false)
        }
        if let field = value as? SecureField {
            return TextEntry(reflecting: field, isSecure: true)
        }

        guard depth < maximumTextEntrySearchDepth else {
            return nil
        }

        for child in Mirror(reflecting: value).children {
            if let entry = textEntry(inside: child.value, depth: depth + 1) {
                return entry
            }
        }
        return nil
    }

    /// An alert's single line of text entry, as the author declared it.
    ///
    /// Unlike ``AlertTextField``, which is the flat snapshot the backend gets,
    /// this keeps the field's binding so that what the user types can be
    /// written back once the alert is dismissed.
    struct TextEntry {
        /// The text to show while the field is empty.
        var placeholder: String
        /// The field's content.
        var text: Binding<String>
        /// Whether the field hides what's typed into it.
        var isSecure: Bool

        /// The snapshot of this field to hand to the backend.
        var backendDescription: AlertTextField {
            AlertTextField(
                placeholder: placeholder,
                initialValue: text.wrappedValue,
                isSecure: isSecure
            )
        }

        /// Reads a field's placeholder and binding out of the field itself.
        ///
        /// ``TextField`` and ``SecureField`` keep both of them private, and
        /// neither has anywhere to put an accessor that only alerts would ever
        /// use, so they're read reflectively. A rename on either type makes
        /// this return `nil` rather than misbehaving, and the alert then
        /// reports the field it couldn't present.
        ///
        /// - Parameters:
        ///   - field: The ``TextField`` or ``SecureField`` to read.
        ///   - isSecure: Whether the field hides what's typed into it.
        init?(reflecting field: Any, isSecure: Bool) {
            var placeholder: String?
            var text: Binding<String>?
            for child in Mirror(reflecting: field).children {
                switch child.label {
                    case "placeholder":
                        placeholder = child.value as? String
                    case "_text":
                        text = child.value as? Binding<String>
                    default:
                        break
                }
            }

            guard let placeholder, let text else {
                return nil
            }

            self.placeholder = placeholder
            self.text = text
            self.isSecure = isSecure
        }
    }
}
