/// How a view's content changes when its value changes (the digits of a
/// counter rolling, a symbol morphing into another).
///
/// Set with ``View/contentTransition(_:)``. Like every animation in
/// SwiftCrossUI the change is instant; see ``Animation``.
public struct ContentTransition: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case identity
        case opacity
        case interpolate
        case numericText(countsDown: Bool)
        case symbolEffect(ReplaceSymbolEffect)
    }

    let kind: Kind

    /// No transition.
    public static let identity = ContentTransition(kind: .identity)
    /// A cross-fade.
    public static let opacity = ContentTransition(kind: .opacity)
    /// An interpolation between the two contents where possible.
    public static let interpolate = ContentTransition(kind: .interpolate)

    /// Digits that roll to their new value.
    ///
    /// - Parameter countsDown: Whether the digits roll downwards.
    public static func numericText(countsDown: Bool = false) -> ContentTransition {
        ContentTransition(kind: .numericText(countsDown: countsDown))
    }

    /// Digits that roll in the direction of the change in `value`.
    ///
    /// - Parameter value: The value the text shows.
    public static func numericText(value: Double) -> ContentTransition {
        ContentTransition(kind: .numericText(countsDown: false))
    }

    /// A symbol that animates into its replacement.
    ///
    /// - Parameter effect: The replacement effect.
    public static func symbolEffect(
        _ effect: ReplaceSymbolEffect = .replace
    ) -> ContentTransition {
        ContentTransition(kind: .symbolEffect(effect))
    }
}

/// A symbol effect that replaces one symbol with another.
///
/// Used as `.contentTransition(.symbolEffect(.replace))`.
public struct ReplaceSymbolEffect: Hashable, Sendable {
    enum Direction: Hashable, Sendable {
        case automatic
        case downUp
        case upUp
        case offUp
    }

    let direction: Direction

    /// The default replacement.
    public static let replace = ReplaceSymbolEffect(direction: .automatic)

    /// The old symbol scales down while the new one scales up.
    public var downUp: ReplaceSymbolEffect { ReplaceSymbolEffect(direction: .downUp) }
    /// Both symbols scale up.
    public var upUp: ReplaceSymbolEffect { ReplaceSymbolEffect(direction: .upUp) }
    /// The old symbol disappears while the new one scales up.
    public var offUp: ReplaceSymbolEffect { ReplaceSymbolEffect(direction: .offUp) }
}

extension View {
    /// Sets how this view's content changes when its value changes.
    ///
    /// The content changes instantly; see ``ContentTransition``.
    ///
    /// - Parameter transition: The transition.
    /// - Returns: The view.
    public func contentTransition(_ transition: ContentTransition) -> some View {
        self
    }
}
