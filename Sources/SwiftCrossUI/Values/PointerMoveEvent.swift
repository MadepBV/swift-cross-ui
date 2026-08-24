import Foundation // for Date

/// A pointer moving over a view with no button held, or leaving it, reported
/// by a backend implementing ``BackendFeatures/PointerGestures``.
///
/// Delivered to the handler installed with ``View/onPointerMove(perform:)``,
/// and reduced to its ``phase`` for
/// ``View/onContinuousHover(coordinateSpace:perform:)``.
///
/// Moves with a button held are drags and are reported through
/// ``DragGesture`` instead, so a snap echo or draft preview driven by this
/// event never fights a drag on the same view.
///
/// ## See Also
///
/// - ``HoverPhase``
/// - ``PointerModifiers``
public struct PointerMoveEvent: Sendable {
    /// Where the pointer is, or ``HoverPhase/ended`` once it left the view.
    public var phase: HoverPhase

    /// The modifier keys held down.
    public var modifiers: PointerModifiers

    /// When the event happened.
    public var time: Date

    /// Describes a pointer move.
    ///
    /// - Parameters:
    ///   - phase: Where the pointer is, or that it left.
    ///   - modifiers: The modifier keys held down.
    ///   - time: When the event happened.
    public init(
        phase: HoverPhase,
        modifiers: PointerModifiers = [],
        time: Date = Date()
    ) {
        self.phase = phase
        self.modifiers = modifiers
        self.time = time
    }
}
