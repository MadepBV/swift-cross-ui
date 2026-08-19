extension BackendFeatures {
    /// Backend methods for confirmation dialogs.
    ///
    /// A confirmation dialog is an alert that asks the user to confirm or
    /// abandon an action. Unlike a plain alert, its buttons carry semantic
    /// roles (see ``ConfirmationDialogAction/Role``) which the backend is
    /// expected to honour, and it can carry an explanatory message below its
    /// title.
    ///
    /// This protocol deliberately refines ``BackendFeatures/Alerts`` instead of
    /// duplicating it. Creating, showing, and dismissing a confirmation dialog
    /// all reuse the existing alert plumbing
    /// (``BackendFeatures/Alerts/showAlert(_:window:responseHandler:)`` and
    /// friends); only the *content* of the dialog needs richer information than
    /// ``BackendFeatures/Alerts/updateAlert(_:title:actionLabels:environment:)``
    /// can express.
    ///
    /// Backends that don't conform still get working confirmation dialogs, they
    /// just fall back to plain alerts with unstyled buttons.
    ///
    /// These are used by
    /// ``View/confirmationDialog(_:isPresented:titleVisibility:actions:message:)``.
    @MainActor
    public protocol ConfirmationDialogs<Alert>: Alerts {
        /// Creates a confirmation dialog object (without showing it).
        ///
        /// The returned object is passed to
        /// ``BackendFeatures/Alerts/showAlert(_:window:responseHandler:)`` and
        /// ``BackendFeatures/Alerts/dismissAlert(_:window:)``, so it must be
        /// usable anywhere a regular alert is.
        ///
        /// The default implementation simply calls
        /// ``BackendFeatures/Alerts/createAlert()``. Override it when the
        /// underlying UI framework distinguishes confirmation dialogs from
        /// alerts at creation time (UIKit's `UIAlertController`, for example,
        /// takes its presentation style as an initializer argument).
        ///
        /// - Returns: A confirmation dialog.
        func createConfirmationDialog() -> Alert

        /// Updates the content and appearance of a confirmation dialog.
        ///
        /// Can only be called once per dialog.
        ///
        /// Implementations must add the dialog's buttons in the same order as
        /// `actions` unless they also implement
        /// ``confirmationDialogActionIndex(forResponse:actions:)`` to describe
        /// the reordering.
        ///
        /// - Parameters:
        ///   - dialog: The dialog to update.
        ///   - title: The dialog's title.
        ///   - titleVisibility: Whether the title should be displayed. When
        ///     hidden, backends that can't hide the title should fall back to
        ///     showing `message` in its place.
        ///   - message: The dialog's explanatory message, if any.
        ///   - actions: The dialog's action buttons, in the order the author
        ///     declared them.
        ///   - environment: The current environment.
        func updateConfirmationDialog(
            _ dialog: Alert,
            title: String,
            titleVisibility: Visibility,
            message: String?,
            actions: [ConfirmationDialogAction],
            environment: EnvironmentValues
        )

        /// Maps a raw response index back to an index into the `actions` array
        /// that was passed to
        /// ``updateConfirmationDialog(_:title:titleVisibility:message:actions:environment:)``.
        ///
        /// ``BackendFeatures/Alerts/showAlert(_:window:responseHandler:)``
        /// reports which button was chosen as an index. Backends whose
        /// underlying dialog has fixed button slots (WinUI's `ContentDialog`,
        /// for example) may have to put the actions somewhere other than their
        /// declared positions in order to make roles behave correctly; this
        /// method lets them undo that reordering.
        ///
        /// The default implementation is the identity mapping.
        ///
        /// - Parameters:
        ///   - response: The index reported by `showAlert`.
        ///   - actions: The actions the dialog was updated with.
        /// - Returns: The index of the chosen action, or `nil` if the response
        ///   doesn't correspond to any action.
        func confirmationDialogActionIndex(
            forResponse response: Int,
            actions: [ConfirmationDialogAction]
        ) -> Int?
    }
}

// MARK: Default Implementations

extension BackendFeatures.ConfirmationDialogs {
    /// Creates the dialog using ``BackendFeatures/Alerts/createAlert()``.
    ///
    /// - Returns: A confirmation dialog.
    public func createConfirmationDialog() -> Alert {
        createAlert()
    }

    /// Falls back to a plain alert, dropping button roles.
    ///
    /// - Parameters:
    ///   - dialog: The dialog to update.
    ///   - title: The dialog's title.
    ///   - titleVisibility: Whether the title should be displayed.
    ///   - message: The dialog's explanatory message, if any.
    ///   - actions: The dialog's action buttons.
    ///   - environment: The current environment.
    public func updateConfirmationDialog(
        _ dialog: Alert,
        title: String,
        titleVisibility: Visibility,
        message: String?,
        actions: [ConfirmationDialogAction],
        environment: EnvironmentValues
    ) {
        updateAlert(
            dialog,
            title: ConfirmationDialogAction.headline(
                title: title,
                titleVisibility: titleVisibility,
                message: message
            ),
            actionLabels: actions.map(\.label),
            environment: environment
        )
    }

    /// Maps responses to actions one-to-one.
    ///
    /// - Parameters:
    ///   - response: The index reported by `showAlert`.
    ///   - actions: The actions the dialog was updated with.
    /// - Returns: The index of the chosen action, or `nil` if out of bounds.
    public func confirmationDialogActionIndex(
        forResponse response: Int,
        actions: [ConfirmationDialogAction]
    ) -> Int? {
        guard actions.indices.contains(response) else {
            return nil
        }
        return response
    }
}

/// A confirmation dialog action button.
///
/// Only backends and ``ConfirmationDialogActionsBuilder`` should interface with
/// this type directly. It exists for the same reason as ``AlertAction``: so
/// that dialogs don't have to expose the internals of ``Button``.
///
/// Unlike ``AlertAction``, actions carry a ``Role`` so that destructive and
/// cancelling buttons can be rendered the way each platform expects.
///
/// Like ``AlertAction``, the action isn't `@Sendable`. It's already confined to
/// the main actor and it comes from a ``Button``, whose action isn't
/// `@Sendable` either, so requiring it here would reject the plain
/// `@escaping () -> Void` callbacks applications hand to buttons without buying
/// any safety in return.
///
/// ## See Also
/// - ``View/confirmationDialog(_:isPresented:titleVisibility:actions:message:)``
public struct ConfirmationDialogAction {
    /// The semantic role of a confirmation dialog button.
    ///
    /// Roles change how a button looks and behaves. They don't change what it
    /// does; that's entirely up to ``ConfirmationDialogAction/action``.
    public enum Role: Sendable, Hashable {
        /// A button that performs an irreversible or otherwise dangerous
        /// action.
        ///
        /// Rendered with the platform's destructive styling (red text on Apple
        /// platforms, the `destructive-action` style class on Gtk).
        case destructive

        /// A button that abandons the action being confirmed.
        ///
        /// Backends should make this button the dialog's escape route, so that
        /// dismissing the dialog with the keyboard runs this action.
        case cancel

        /// Translates a ``Button``'s role into the equivalent dialog role.
        ///
        /// ``ButtonRole`` is the role that authors write, and it's a struct so
        /// that it can gain new roles without breaking the backends that
        /// switch over this enum exhaustively. This is the single place the
        /// two vocabularies meet, so a new ``ButtonRole`` has to be given a
        /// dialog meaning here rather than being quietly dropped.
        ///
        /// - Parameter role: The button's role, if it has one.
        /// - Returns: The matching dialog role, or `nil` if the button has no
        ///   role.
        public init?(_ role: ButtonRole?) {
            guard let role else {
                return nil
            }
            switch role.kind {
                case .destructive:
                    self = .destructive
                case .cancel:
                    self = .cancel
            }
        }
    }

    /// The default confirmation dialog action.
    ///
    /// Consists of a button labeled "OK" with no action (other than dismissing
    /// the dialog, which is implicit).
    public static var `default`: ConfirmationDialogAction {
        ConfirmationDialogAction(label: "OK")
    }

    /// The button's label.
    public var label: String
    /// The button's role, if it has one.
    public var role: Role?
    /// The button's action.
    public var action: @MainActor () -> Void

    /// Creates a confirmation dialog action.
    ///
    /// - Parameters:
    ///   - label: The button's label.
    ///   - role: The button's role. Defaults to `nil` (no particular role).
    ///   - action: The button's action.
    public init(
        label: String,
        role: Role? = nil,
        action: @escaping @MainActor () -> Void = {}
    ) {
        self.label = label
        self.role = role
        self.action = action
    }

    /// Creates an action that performs an irreversible or dangerous operation.
    ///
    /// - Parameters:
    ///   - label: The button's label.
    ///   - action: The button's action.
    /// - Returns: A destructive action.
    public static func destructive(
        _ label: String,
        action: @escaping @MainActor () -> Void = {}
    ) -> ConfirmationDialogAction {
        ConfirmationDialogAction(label: label, role: .destructive, action: action)
    }

    /// Creates an action that abandons the operation being confirmed.
    ///
    /// - Parameters:
    ///   - label: The button's label. Defaults to "Cancel".
    ///   - action: The button's action.
    /// - Returns: A cancelling action.
    public static func cancel(
        _ label: String = "Cancel",
        action: @escaping @MainActor () -> Void = {}
    ) -> ConfirmationDialogAction {
        ConfirmationDialogAction(label: label, role: .cancel, action: action)
    }

    /// Picks the single string to display when a backend can only show one line
    /// of text.
    ///
    /// - Parameters:
    ///   - title: The dialog's title.
    ///   - titleVisibility: Whether the title should be displayed.
    ///   - message: The dialog's message, if any.
    /// - Returns: The most informative string available.
    @_spi(Backends) public static func headline(
        title: String,
        titleVisibility: Visibility,
        message: String?
    ) -> String {
        guard titleVisibility == .hidden, let message else {
            return title
        }
        return message
    }
}
