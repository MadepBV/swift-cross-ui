extension BackendFeatures {
    /// Backend methods for attaching keyboard shortcuts to controls.
    ///
    /// These are used by ``View/keyboardShortcut(_:)`` and
    /// ``View/keyboardShortcut(_:modifiers:)``.
    ///
    /// ## Activation model
    ///
    /// SwiftCrossUI deliberately does *not* hand the backend an action to run.
    /// A keyboard shortcut in SwiftUI activates whatever control it is applied
    /// to, exactly as if the user had clicked it, and every platform that
    /// SwiftCrossUI targets already has a native mechanism for that:
    ///
    /// | Platform | Mechanism |
    /// | --- | --- |
    /// | AppKit | `NSButton.keyEquivalent`, or an `NSEvent` local monitor |
    /// | WinUI | `UIElement.keyboardAccelerators` |
    /// | UIKit | `UIKeyCommand` on the responder chain |
    /// | Gtk | `GtkShortcutController` with a `GtkCallbackAction` |
    ///
    /// So a conforming backend must, when the shortcut matches, perform the
    /// wrapped widget's primary activation. For widgets with no primary
    /// activation the backend should simply do nothing rather than trapping.
    ///
    /// ## Scoping
    ///
    /// A shortcut must only fire while the window containing the target is the
    /// active/key window, and must not fire while the target's environment is
    /// disabled (see ``EnvironmentValues/isEnabled``).
    ///
    /// Backends that do not conform to this protocol degrade silently:
    /// ``View/keyboardShortcut(_:modifiers:)`` becomes a no-op rather than
    /// crashing.
    @MainActor
    public protocol KeyboardShortcuts: Core {
        /// Wraps a widget in a container that can hold a keyboard shortcut.
        ///
        /// Backends that can attach a shortcut directly to the child may
        /// return the child as-is.
        ///
        /// - Parameter child: The widget to wrap.
        /// - Returns: A widget that a keyboard shortcut can be attached to.
        func createKeyboardShortcutTarget(wrapping child: Widget) -> Widget

        /// Sets (or clears) the keyboard shortcut attached to a target.
        ///
        /// The new shortcut replaces any previously attached shortcut. When
        /// the shortcut fires, the backend must activate the wrapped child as
        /// though the user had clicked it.
        ///
        /// - Parameters:
        ///   - target: The target returned by
        ///     ``createKeyboardShortcutTarget(wrapping:)``.
        ///   - shortcut: The shortcut to listen for, or `nil` to remove any
        ///     existing shortcut.
        ///   - environment: The current environment. Backends must not fire
        ///     the shortcut when ``EnvironmentValues/isEnabled`` is `false`.
        func updateKeyboardShortcutTarget(
            _ target: Widget,
            shortcut: KeyboardShortcut?,
            environment: EnvironmentValues
        )
    }
}
