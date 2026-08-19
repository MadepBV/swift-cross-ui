@_spi(Backends) import SwiftCrossUI
import UIKit

extension UIKitBackend: BackendFeatures.KeyboardShortcuts, BackendFeatures.Focus {}

// MARK: - Keyboard shortcuts

extension UIKitBackend {
    public func createKeyboardShortcutTarget(wrapping child: Widget) -> Widget {
        KeyboardShortcutWidget(child: child)
    }

    public func updateKeyboardShortcutTarget(
        _ target: Widget,
        shortcut: KeyboardShortcut?,
        environment: EnvironmentValues
    ) {
        guard let target = target as? KeyboardShortcutWidget else { return }
        target.isEnabled = environment.isEnabled
        target.shortcut = shortcut
    }
}

/// A widget that publishes a `UIKeyCommand` for its content.
///
/// - Important: UIKit collects key commands by walking *up* the responder
///   chain from the current first responder, so a shortcut declared here only
///   fires while focus is inside this widget (or nothing is focused and this
///   widget is on the path from the window to the first responder). That's
///   narrower than the window-wide scope SwiftUI gives shortcuts on macOS, and
///   is a limitation of `UIKeyCommand` rather than of this implementation.
final class KeyboardShortcutWidget: ContainerWidget {
    /// The shortcut currently attached, if any.
    var shortcut: KeyboardShortcut?

    /// Whether the shortcut is allowed to fire.
    var isEnabled = true

    override var keyCommands: [UIKeyCommand]? {
        guard
            let shortcut,
            isEnabled,
            let input = shortcut.key.keyCommandInput
        else {
            return nil
        }

        return [
            UIKeyCommand(
                input: input,
                modifierFlags: shortcut.modifiers.uiKeyModifierFlags,
                action: #selector(performKeyboardShortcut)
            )
        ]
    }

    @objc
    private func performKeyboardShortcut() {
        guard isEnabled else { return }
        activate(view)
    }

    /// Activates the first control in the subtree, as though it were tapped.
    private func activate(_ view: UIView) {
        var queue = [view]
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if let button = next as? UICustomButton {
                button.onTap?()
                return
            }
            if let control = next as? UIControl {
                control.sendActions(for: .touchUpInside)
                return
            }
            queue.append(contentsOf: next.subviews)
        }
    }
}

// MARK: - Focus

extension UIKitBackend {
    public func createFocusTarget(wrapping child: Widget) -> Widget {
        FocusWidget(child: child)
    }

    public func updateFocusTarget(
        _ target: Widget,
        isFocused: Bool,
        environment: EnvironmentValues,
        onFocusChange: @escaping (Bool) -> Void
    ) {
        guard let target = target as? FocusWidget else { return }
        target.onFocusChange = onFocusChange
        target.isEnabled = environment.isEnabled
        target.setDesiredFocus(isFocused)
    }
}

/// A widget that drives and observes its content's first responder status.
///
/// - Important: The state to focus direction is complete: writing to a
///   ``SwiftCrossUI/FocusState`` calls `becomeFirstResponder()` or
///   `resignFirstResponder()`. The focus to state direction is only
///   implemented for text input, because UIKit posts no general
///   first-responder-changed notification; `UITextField` and `UITextView`
///   editing notifications are observed instead. Focus moving onto a
///   non-text-input view will not write back to the focus state.
final class FocusWidget: ContainerWidget {
    /// Called when the platform changes the content's focus.
    var onFocusChange: ((Bool) -> Void)?

    /// Whether the content may take focus.
    var isEnabled = true

    /// The focus state most recently reported or applied.
    private var lastKnownFocus = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let center = NotificationCenter.default
        for name in [
            UITextField.textDidBeginEditingNotification,
            UITextView.textDidBeginEditingNotification,
        ] {
            center.addObserver(
                self,
                selector: #selector(editingDidBegin),
                name: name,
                object: nil
            )
        }
        for name in [
            UITextField.textDidEndEditingNotification,
            UITextView.textDidEndEditingNotification,
        ] {
            center.addObserver(
                self,
                selector: #selector(editingDidEnd),
                name: name,
                object: nil
            )
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Moves platform focus to match the bound focus state.
    func setDesiredFocus(_ shouldFocus: Bool) {
        guard let responder = firstFocusableResponder else { return }

        if shouldFocus {
            guard isEnabled, !responder.isFirstResponder else { return }
            if responder.becomeFirstResponder() {
                lastKnownFocus = true
            }
        } else if responder.isFirstResponder {
            if responder.resignFirstResponder() {
                lastKnownFocus = false
            }
        }
    }

    @objc
    private func editingDidBegin(_ notification: Notification) {
        guard contains(notification.object), !lastKnownFocus else { return }
        lastKnownFocus = true
        onFocusChange?(true)
    }

    @objc
    private func editingDidEnd(_ notification: Notification) {
        guard contains(notification.object), lastKnownFocus else { return }
        lastKnownFocus = false
        onFocusChange?(false)
    }

    /// Whether a notification's sender is inside this widget.
    private func contains(_ object: Any?) -> Bool {
        guard let sender = object as? UIView else { return false }
        return sender.isDescendant(of: view)
    }

    /// The nearest descendant that can become first responder.
    private var firstFocusableResponder: UIView? {
        // NB: `UIViewController.view` is implicitly unwrapped, so the queue's
        // element type has to be spelled out to keep it non-optional.
        guard let root: UIView = view else { return nil }
        var queue: [UIView] = [root]
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if next !== root, next.canBecomeFirstResponder {
                return next
            }
            queue.append(contentsOf: next.subviews)
        }
        return nil
    }
}

// MARK: - Platform mapping

extension EventModifiers {
    /// The UIKit modifier mask corresponding to these modifiers.
    var uiKeyModifierFlags: UIKeyModifierFlags {
        var flags: UIKeyModifierFlags = []
        if contains(.command) {
            flags.insert(.command)
        }
        if contains(.option) {
            flags.insert(.alternate)
        }
        if contains(.control) {
            flags.insert(.control)
        }
        if contains(.shift) {
            flags.insert(.shift)
        }
        if contains(.capsLock) {
            flags.insert(.alphaShift)
        }
        if contains(.numericPad) {
            flags.insert(.numericPad)
        }
        return flags
    }
}

extension KeyEquivalent {
    /// The `UIKeyCommand` input string for this key, if UIKit has one.
    ///
    /// UIKit exposes no input constants for home, end, clear or forward
    /// delete, so those return `nil` and the shortcut is simply not installed.
    var keyCommandInput: String? {
        switch self {
            case .upArrow: UIKeyCommand.inputUpArrow
            case .downArrow: UIKeyCommand.inputDownArrow
            case .leftArrow: UIKeyCommand.inputLeftArrow
            case .rightArrow: UIKeyCommand.inputRightArrow
            case .pageUp: UIKeyCommand.inputPageUp
            case .pageDown: UIKeyCommand.inputPageDown
            case .escape: UIKeyCommand.inputEscape
            case .return: "\r"
            case .tab: "\t"
            case .space: " "
            case .delete: "\u{8}"
            case .clear, .deleteForward, .end, .home: nil
            default: String(character)
        }
    }
}
