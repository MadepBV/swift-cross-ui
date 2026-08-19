@_spi(Backends) import SwiftCrossUI
import WinUI

// swiftlint:disable force_try

extension WinUIBackend: BackendFeatures.Alerts {
    public class Alert: ContentDialog {
        var window: Window?
        var parentAlert: Alert?
        var handleResponse: ((Int) -> Void)?
        var ignoreNextDismissal = false

        /// Shows an alert that has already been attached to a window (via xamlRoot),
        /// and attached to the alert stack (via parentAlert and updating
        /// window.currentAlert)
        func showAttached() {
            let promise = try! showAsync()!
            promise.completed = { [weak self] operation, status in
                guard
                    let self,
                    status == .completed,
                    let operation,
                    let result = try? operation.getResults()
                else {
                    return
                }

                if !self.ignoreNextDismissal {
                    // If the alert was shown over the top of another alert, show
                    // the parent alert
                    self.window?.currentAlert = self.parentAlert
                    self.parentAlert?.showAttached()

                    let index =
                        switch result {
                            case .primary: 0
                            case .secondary: 1
                            case .none: 2
                            default:
                                fatalError("WinUIBackend: Invalid dialog response")
                        }
                    self.handleResponse?(index)
                } else {
                    self.ignoreNextDismissal = false
                }
            }
        }
    }

    public func createAlert() -> Alert {
        Alert()
    }

    public func updateAlert(
        _ alert: Alert,
        title: String,
        actionLabels: [String],
        environment: EnvironmentValues
    ) {
        alert.title = title
        if actionLabels.count >= 1 {
            alert.primaryButtonText = actionLabels[0]
        }
        if actionLabels.count >= 2 {
            alert.secondaryButtonText = actionLabels[1]
        }
        if actionLabels.count >= 3 {
            alert.closeButtonText = actionLabels[2]
        }

        switch environment.colorScheme {
            case .light:
                alert.requestedTheme = .light
            case .dark:
                alert.requestedTheme = .dark
        }
    }

    public func showAlert(
        _ alert: Alert,
        window: Window?,
        responseHandler handleResponse: @escaping (Int) -> Void
    ) {
        // WinUI only allows one dialog at a time so we limit ourselves using
        // a semaphore.
        guard let window = window ?? windows.first else {
            logger.warning("WinUI can't show alert without window")
            return
        }

        alert.xamlRoot = window.content.xamlRoot
        alert.window = window

        // WinUI only allows one dialog at a time (subsequent dialogs throw
        // exceptions), so we hide any existing alert before showing the new one
        if let currentAlert = window.currentAlert {
            currentAlert.ignoreNextDismissal = true
            try! currentAlert.hide()
            alert.parentAlert = currentAlert
        }

        window.currentAlert = alert
        alert.handleResponse = handleResponse
        alert.showAttached()
    }

    public func dismissAlert(_ alert: Alert, window: Window?) {
        try! alert.hide()
        alert.window?.currentAlert = alert.parentAlert
        alert.parentAlert?.showAttached()
    }
}

// MARK: Text entry

// NOTE: This backend can't be compiled on macOS, so everything below is written
// against the documented `ContentDialog` and `TextBox`/`PasswordBox` APIs but is
// unverified.
extension WinUIBackend {
    /// The gap between a text-entry alert's message and its field.
    private static let alertContentSpacing: Double = 8

    public func addTextField(_ textField: AlertTextField, to alert: Alert) -> Bool {
        // `ContentDialog` has a single content slot, which the message is
        // already using, so the field and the message share a stack.
        let panel = StackPanel()
        panel.orientation = .vertical
        panel.spacing = Self.alertContentSpacing

        if let message = alert.content as? String, !message.isEmpty {
            let label = TextBlock()
            label.text = message
            label.textWrapping = .wrap
            panel.children.append(label)
        }

        if textField.isSecure {
            let box = PasswordBox()
            box.placeholderText = textField.placeholder
            box.password = textField.initialValue
            panel.children.append(box)
        } else {
            let box = TextBox()
            box.placeholderText = textField.placeholder
            box.text = textField.initialValue
            panel.children.append(box)
        }

        alert.content = panel
        return true
    }

    public func textFieldContents(of alert: Alert) -> String? {
        guard let panel = alert.content as? StackPanel else {
            return nil
        }

        for index in 0..<panel.children.size {
            let child = panel.children.getAt(index)
            if let box = child as? TextBox {
                return box.text
            }
            if let box = child as? PasswordBox {
                return box.password
            }
        }
        return nil
    }
}
