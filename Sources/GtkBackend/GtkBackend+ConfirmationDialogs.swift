import CGtk
import Gtk
@_spi(Backends) import SwiftCrossUI

extension GtkBackend: BackendFeatures.ConfirmationDialogs {
    public func updateConfirmationDialog(
        _ dialog: Alert,
        title: String,
        titleVisibility: SwiftCrossUI.Visibility,
        message: String?,
        actions: [ConfirmationDialogAction],
        environment: EnvironmentValues
    ) {
        dialog.text = ConfirmationDialogAction.headline(
            title: title,
            titleVisibility: titleVisibility,
            message: message
        )
        if titleVisibility != .hidden, let message {
            dialog.setProperty(named: "secondary-text", newValue: message)
        }

        // Buttons are added in declaration order, so the response ids that
        // `showAlert` reports are already indices into `actions`.
        for (index, action) in actions.enumerated() {
            dialog.addButton(label: action.label, responseId: index)

            guard
                let button = gtk_dialog_get_widget_for_response(
                    Self.dialogPointer(of: dialog),
                    gint(index)
                )
            else {
                continue
            }

            // Adwaita and the stock GTK themes both style this class as a
            // red, dangerous-looking button.
            if action.role == .destructive {
                gtk_widget_add_css_class(button, "destructive-action")
            }
        }
    }

    /// Reinterprets a message dialog's widget pointer as a dialog pointer.
    ///
    /// - Parameter dialog: The dialog.
    /// - Returns: The dialog's `GtkDialog` pointer.
    private static func dialogPointer(
        of dialog: Alert
    ) -> UnsafeMutablePointer<GtkDialog> {
        UnsafeMutablePointer(
            mutating: UnsafeRawPointer(dialog.widgetPointer)
                .bindMemory(to: GtkDialog.self, capacity: 1)
        )
    }
}
