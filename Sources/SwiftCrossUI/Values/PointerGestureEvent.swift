import Foundation // for CGPoint, CGSize and Date

/// A single pointer position reported by a backend while a gesture is being
/// recognized.
///
/// Backends implementing ``BackendFeatures/PointerGestures`` build these and
/// hand them to the callbacks that protocol installs. SwiftCrossUI turns them
/// into ``DragGesture/Value`` and ``SpatialTapGesture/Value``.
///
/// ## See Also
///
/// - ``BackendFeatures/PointerGestures``
/// - ``DragGesture``
public struct PointerGestureEvent: Sendable {
    /// Where the interaction started, in the gesture's coordinate space.
    ///
    /// For a tap this is the same as ``PointerGestureEvent/location``.
    public var startLocation: CGPoint

    /// Where the pointer is now, in the gesture's coordinate space.
    public var location: CGPoint

    /// When the event happened.
    public var time: Date

    /// How fast the pointer is moving, in points per second.
    ///
    /// Backends that can't measure this report zero.
    public var velocity: CGSize

    /// The modifier keys held down when the event happened.
    public var modifiers: PointerModifiers

    /// The button that drove the event.
    public var button: PointerButton

    /// For a tap, how many clicks in quick succession this one is; `1` for
    /// a single click, `2` for the second click of a double click, and so
    /// on. Always `1` for a drag.
    public var clickCount: Int

    /// Describes a pointer position.
    ///
    /// - Parameters:
    ///   - startLocation: Where the interaction started.
    ///   - location: Where the pointer is now.
    ///   - time: When the event happened.
    ///   - velocity: How fast the pointer is moving, or zero if the backend
    ///     can't measure it.
    ///   - modifiers: The modifier keys held down.
    ///   - button: The button that drove the event.
    ///   - clickCount: For a tap, which click of a multi-click this is.
    public init(
        startLocation: CGPoint,
        location: CGPoint,
        time: Date = Date(),
        velocity: CGSize = CGSize(width: 0.0, height: 0.0),
        modifiers: PointerModifiers = [],
        button: PointerButton = .primary,
        clickCount: Int = 1
    ) {
        self.startLocation = startLocation
        self.location = location
        self.time = time
        self.velocity = velocity
        self.modifiers = modifiers
        self.button = button
        self.clickCount = clickCount
    }
}
