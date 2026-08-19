@_spi(Backends) import SwiftCrossUI
import UIKit

extension UIKitBackend: BackendFeatures.ConfirmationDialogs {
    public func createConfirmationDialog() -> Alert {
        // An action sheet is what UIKit calls a confirmation dialog. On
        // regular-width devices UIKit insists on presenting action sheets in a
        // popover anchored to a source view, and traps if there isn't one, so
        // those fall back to a plain alert.
        let style: UIAlertController.Style =
            UIDevice.current.userInterfaceIdiom == .phone ? .actionSheet : .alert
        return Alert(title: nil, message: nil, preferredStyle: style)
    }

    public func updateConfirmationDialog(
        _ dialog: Alert,
        title: String,
        titleVisibility: SwiftCrossUI.Visibility,
        message: String?,
        actions: [ConfirmationDialogAction],
        environment: EnvironmentValues
    ) {
        dialog.title = titleVisibility == .hidden ? nil : title
        dialog.message = message

        // Actions are added in declaration order, and `UIAlertController`
        // preserves that order in its `actions` array even though it moves
        // cancelling actions to the bottom visually, so the response indices
        // reported by `showAlert` need no remapping.
        for action in actions {
            let style: UIAlertAction.Style =
                switch action.role {
                    case .destructive: .destructive
                    case .cancel: .cancel
                    case nil: .default
                }
            let uiAction = CustomAlertAction(title: action.label, style: style) { uiAction in
                (uiAction as! CustomAlertAction).handler?()
            }
            dialog.addAction(uiAction)
        }
    }
}
