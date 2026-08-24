import Foundation // for CGPoint

/// Where the pointer is while it hovers over a view, as reported by
/// ``View/onContinuousHover(coordinateSpace:perform:)``.
///
/// This is SwiftUI's `HoverPhase`.
public enum HoverPhase: Sendable {
    /// The pointer is over the view, at the given location in the requested
    /// coordinate space.
    case active(CGPoint)

    /// The pointer left the view.
    case ended
}

extension HoverPhase: Equatable {
    /// Written out by hand because `CGPoint` only picks up its `Equatable`
    /// conformance from the Core Graphics overlay, which isn't available on
    /// every platform SwiftCrossUI targets.
    public static func == (lhs: HoverPhase, rhs: HoverPhase) -> Bool {
        switch (lhs, rhs) {
            case (.active(let a), .active(let b)):
                a.x == b.x && a.y == b.y
            case (.ended, .ended):
                true
            default:
                false
        }
    }
}
