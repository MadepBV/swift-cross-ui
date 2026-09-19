/// A set of modifier keys that can be combined with a ``KeyEquivalent`` to
/// form a ``KeyboardShortcut``.
///
/// ```swift
/// Button("Redo") { redo() }
///     .keyboardShortcut("z", modifiers: [.command, .shift])
/// ```
///
/// The naming follows Apple's platform conventions: ``EventModifiers/option``
/// is the Alt key on Windows and Linux, and ``EventModifiers/command`` is the
/// Windows/Super key. Backends are responsible for mapping these onto their
/// platform's native modifier masks.
public struct EventModifiers: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    /// Creates a set of event modifiers from a raw value.
    ///
    /// - Parameter rawValue: The raw bit mask.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The Caps Lock key.
    public static let capsLock = EventModifiers(rawValue: 1 << 0)
    /// The Shift key.
    public static let shift = EventModifiers(rawValue: 1 << 1)
    /// The Control key.
    public static let control = EventModifiers(rawValue: 1 << 2)
    /// The Option key (called Alt on Windows and Linux).
    public static let option = EventModifiers(rawValue: 1 << 3)
    /// The Command key (called the Windows or Super key on Windows and Linux).
    public static let command = EventModifiers(rawValue: 1 << 4)
    /// The key on the numeric keypad, if the event originated there.
    public static let numericPad = EventModifiers(rawValue: 1 << 5)

    /// Every modifier key.
    public static let all: EventModifiers = [
        .capsLock,
        .shift,
        .control,
        .option,
        .command,
        .numericPad,
    ]

    /// The Function key.
    ///
    /// Included for source compatibility with SwiftUI, which deprecated it
    /// because no platform reliably reports it. SwiftCrossUI backends ignore
    /// it when matching shortcuts.
    @available(*, deprecated, message: "this modifier is not supported")
    public static let function = EventModifiers(rawValue: 1 << 6)
}

extension EventModifiers: CustomStringConvertible {
    public var description: String {
        var names: [String] = []
        if contains(.control) {
            names.append("control")
        }
        if contains(.option) {
            names.append("option")
        }
        if contains(.shift) {
            names.append("shift")
        }
        if contains(.command) {
            names.append("command")
        }
        if contains(.capsLock) {
            names.append("caps lock")
        }
        if contains(.numericPad) {
            names.append("numeric pad")
        }
        return names.isEmpty ? "none" : names.joined(separator: "+")
    }
}
