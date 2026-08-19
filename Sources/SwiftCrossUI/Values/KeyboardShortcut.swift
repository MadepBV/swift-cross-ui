/// A combination of a ``KeyEquivalent`` and a set of ``EventModifiers`` that
/// activates a control from the keyboard.
///
/// Apply one to a control with ``View/keyboardShortcut(_:)`` or
/// ``View/keyboardShortcut(_:modifiers:)``:
///
/// ```swift
/// Button("Save") { save() }
///     .keyboardShortcut("s", modifiers: [.command])
///
/// Button("OK") { confirm() }
///     .keyboardShortcut(.defaultAction)
/// ```
public struct KeyboardShortcut: Hashable, Sendable {
    /// The key that triggers the shortcut.
    public var key: KeyEquivalent
    /// The modifier keys that must be held for the shortcut to trigger.
    public var modifiers: EventModifiers
    /// How the shortcut is adapted for the user's locale.
    public var localization: Localization

    /// The standard shortcut for the primary action of a scene or dialog:
    /// the Return key with no modifiers.
    ///
    /// Backends that distinguish default controls (such as AppKit) also give
    /// the control its platform's default-button appearance.
    public static let defaultAction = KeyboardShortcut(.return, modifiers: [])

    /// The standard shortcut for cancelling out of a scene or dialog: the
    /// Escape key with no modifiers.
    public static let cancelAction = KeyboardShortcut(.escape, modifiers: [])

    /// Creates a keyboard shortcut.
    ///
    /// - Parameters:
    ///   - key: The key that triggers the shortcut.
    ///   - modifiers: The modifier keys that must be held. Defaults to
    ///     ``EventModifiers/command`` to match SwiftUI.
    ///   - localization: How the shortcut is adapted for the user's locale.
    public init(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = .command,
        localization: Localization = .automatic
    ) {
        self.key = key
        self.modifiers = modifiers
        self.localization = localization
    }

    /// A strategy for adapting a keyboard shortcut to the user's locale.
    ///
    /// - Note: SwiftCrossUI currently treats every case identically; no
    ///   backend mirrors shortcuts for right-to-left layouts yet. The type
    ///   exists so that shortcut declarations can be shared verbatim with
    ///   SwiftUI code.
    public struct Localization: Hashable, Sendable {
        private enum Strategy: Hashable, Sendable {
            case automatic
            case withoutMirroring
            case custom
        }

        private var strategy: Strategy

        /// Adapt the shortcut for the user's locale where it makes sense.
        public static let automatic = Self(strategy: .automatic)
        /// Never mirror the shortcut, even in right-to-left locales.
        public static let withoutMirroring = Self(strategy: .withoutMirroring)
        /// The shortcut is localized by the developer, not the framework.
        public static let custom = Self(strategy: .custom)
    }
}

extension KeyboardShortcut: CustomStringConvertible {
    public var description: String {
        modifiers.isEmpty ? key.description : "\(modifiers)+\(key)"
    }
}
