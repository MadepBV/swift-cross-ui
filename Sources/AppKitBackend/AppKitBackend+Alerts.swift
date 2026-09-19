import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend {
    /// The size of a text-entry alert's field.
    ///
    /// `NSAlert` sizes itself to its accessory view, and an accessory view
    /// with no intrinsic width collapses, so the field is given the width of
    /// the alert's own text column.
    private static let alertTextFieldSize = NSSize(width: 250, height: 24)

    public func addTextField(_ textField: AlertTextField, to alert: Alert) -> Bool {
        let field =
            textField.isSecure
                ? NSSecureTextField(frame: .zero)
                : NSTextField(frame: .zero)
        field.setFrameSize(Self.alertTextFieldSize)
        field.placeholderString = textField.placeholder
        field.stringValue = textField.initialValue
        field.usesSingleLineMode = true
        field.cell?.wraps = false
        field.cell?.isScrollable = true

        alert.accessoryView = field

        // Without this the alert's default button takes focus, and the user has
        // to click into the field before they can type.
        alert.window.initialFirstResponder = field

        return true
    }

    public func textFieldContents(of alert: Alert) -> String? {
        guard let field = alert.accessoryView as? NSTextField else {
            return nil
        }
        return field.stringValue
    }
}
