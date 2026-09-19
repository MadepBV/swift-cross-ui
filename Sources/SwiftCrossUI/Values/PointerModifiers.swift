/// The modifier keys held down while a pointer event happened.
///
/// Every pointer event a backend reports through
/// ``BackendFeatures/PointerGestures`` carries these, so that snapping,
/// constrained drags and additive selection can key off them without a
/// separate keyboard listener.
///
/// The names follow the Mac keyboard, as SwiftUI's `EventModifiers` do; on
/// Windows ``option`` is the Alt key and ``command`` is the Windows key.
///
/// ## See Also
///
/// - ``PointerGestureEvent``
/// - ``PointerScrollEvent``
/// - ``PointerMagnifyEvent``
public struct PointerModifiers: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The Shift key.
    public static let shift = PointerModifiers(rawValue: 1 << 0)

    /// The Control key.
    public static let control = PointerModifiers(rawValue: 1 << 1)

    /// The Option key on a Mac, the Alt key on Windows.
    public static let option = PointerModifiers(rawValue: 1 << 2)

    /// The Command key on a Mac, the Windows key on Windows.
    public static let command = PointerModifiers(rawValue: 1 << 3)

    /// Caps Lock, when the backend can report it.
    public static let capsLock = PointerModifiers(rawValue: 1 << 4)

    /// Every modifier.
    public static let all: PointerModifiers = [
        .shift,
        .control,
        .option,
        .command,
        .capsLock,
    ]
}

extension PointerModifiers: CustomStringConvertible {
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
        return names.isEmpty ? "none" : names.joined(separator: "+")
    }
}
