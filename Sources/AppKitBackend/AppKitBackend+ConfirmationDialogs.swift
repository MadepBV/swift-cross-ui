import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.ConfirmationDialogs {
    /// The escape key, used to make cancelling buttons the dialog's escape
    /// route.
    private static let escapeKeyEquivalent = "\u{1b}"

    public func updateConfirmationDialog(
        _ dialog: Alert,
        title: String,
        titleVisibility: SwiftCrossUI.Visibility,
        message: String?,
        actions: [ConfirmationDialogAction],
        environment: EnvironmentValues
    ) {
        dialog.messageText = ConfirmationDialogAction.headline(
            title: title,
            titleVisibility: titleVisibility,
            message: message
        )
        if titleVisibility != .hidden, let message {
            dialog.informativeText = message
        }

        // AppKit reserves the 'critical' style for dialogs whose consequences
        // are severe, which is exactly what a destructive action is.
        let isDestructive = actions.contains { action in
            action.role == .destructive
        }
        dialog.alertStyle = isDestructive ? .critical : .warning

        // Buttons are added in declaration order. NSAlert lays them out
        // right-to-left, making the first one the default button, which matches
        // SwiftUI's ordering on macOS. Because the order is preserved, the
        // response indices reported by `showAlert` need no remapping.
        for action in actions {
            let button = dialog.addButton(withTitle: action.label)
            switch action.role {
                case .destructive:
                    if #available(macOS 11, *) {
                        button.hasDestructiveAction = true
                    }
                case .cancel:
                    button.keyEquivalent = Self.escapeKeyEquivalent
                case nil:
                    break
            }
        }
    }
}
