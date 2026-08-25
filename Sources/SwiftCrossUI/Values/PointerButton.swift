/// A button on a pointing device.
///
/// ``PointerGestureEvent`` reports which button drove it, and
/// ``DragGesture/buttons`` selects which buttons a drag responds to.
public enum PointerButton: Hashable, Sendable {
    /// The left mouse button, a touch contact or a pen tip.
    case primary

    /// The right mouse button.
    case secondary

    /// The middle mouse button (or wheel click).
    case middle
}

/// A set of pointer buttons.
public struct PointerButtons: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Creates a set holding one button.
    ///
    /// - Parameter button: The button.
    public init(_ button: PointerButton) {
        switch button {
            case .primary: self = .primary
            case .secondary: self = .secondary
            case .middle: self = .middle
        }
    }

    /// The left mouse button, a touch contact or a pen tip.
    public static let primary = PointerButtons(rawValue: 1 << 0)

    /// The right mouse button.
    public static let secondary = PointerButtons(rawValue: 1 << 1)

    /// The middle mouse button.
    public static let middle = PointerButtons(rawValue: 1 << 2)

    /// Every button.
    public static let all: PointerButtons = [.primary, .secondary, .middle]

    /// Whether the set holds a button.
    ///
    /// - Parameter button: The button to look for.
    /// - Returns: Whether it's in the set.
    public func contains(_ button: PointerButton) -> Bool {
        contains(PointerButtons(button))
    }
}
