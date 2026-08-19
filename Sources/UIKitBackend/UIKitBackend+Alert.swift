@_spi(Backends) import SwiftCrossUI
import UIKit

extension UIKitBackend {
    public typealias Alert = UIAlertController

    final class CustomAlertAction: UIAlertAction {
        var handler: (() -> Void)?
    }

    public func createAlert() -> Alert {
        Alert(title: nil, message: nil, preferredStyle: .alert)
    }

    public func updateAlert(
        _ alert: Alert,
        title: String,
        actionLabels: [String],
        environment _: EnvironmentValues
    ) {
        alert.title = title

        for actionLabel in actionLabels {
            let action = CustomAlertAction(title: actionLabel, style: .default) { action in
                (action as! CustomAlertAction).handler?()
            }
            alert.addAction(action)
        }
    }

    public func showAlert(
        _ alert: Alert,
        window: Window?,
        responseHandler handleResponse: @escaping (Int) -> Void
    ) {
        guard let window = window ?? Self.mainWindow else {
            assertionFailure("Could not find window in which to display alert")
            return
        }

        for (index, action) in alert.actions.enumerated() {
            (action as! CustomAlertAction).handler = { handleResponse(index) }
        }
        window.rootViewController!.present(alert, animated: true)
    }

    public func dismissAlert(_ alert: Alert, window: Window?) {
        alert.dismiss(animated: true)
    }
}

// MARK: Text entry

// NOTE: This backend can't be compiled on macOS, so everything below is written
// against the documented `UIAlertController` API but is unverified.
extension UIKitBackend {
    public func addTextField(_ textField: AlertTextField, to alert: Alert) -> Bool {
        // `addTextField(configurationHandler:)` traps on an action sheet, so a
        // dialog that ended up as one has to refuse the field rather than take
        // the app down with it.
        guard alert.preferredStyle == .alert else {
            return false
        }

        alert.addTextField { field in
            field.placeholder = textField.placeholder
            field.text = textField.initialValue
            field.isSecureTextEntry = textField.isSecure
        }
        return true
    }

    public func textFieldContents(of alert: Alert) -> String? {
        alert.textFields?.first?.text
    }
}
