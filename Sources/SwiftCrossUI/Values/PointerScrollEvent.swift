import Foundation // for CGPoint and Date

/// One step of a scroll wheel or trackpad scroll, reported by a backend
/// implementing ``BackendFeatures/PointerGestures``.
///
/// Delivered to the handler installed with ``View/onScrollWheel(perform:)``.
///
/// ## Deltas
///
/// ``deltaX`` and ``deltaY`` follow the platform's reporting convention:
///
/// - When ``isPrecise`` is `true` (a trackpad or other precise device) they
///   are in points, and the interaction has a lifetime that ``phase``
///   describes.
/// - When ``isPrecise`` is `false` they are in wheel notches (including
///   fractional notches), or in lines on platforms that accelerate wheel
///   scrolling, and ``phase`` is always ``PointerEventPhase/changed``.
///   Windows wheel messages retain these units even when a high-resolution
///   wheel or precision touchpad sends small deltas; finer packet resolution
///   alone does not make the values point distances.
///
/// A positive ``deltaY`` means the wheel rolled away from the user, or the
/// fingers moved up the trackpad with natural scrolling off. Zooming at the
/// cursor and panning should therefore use the sign, and treat the magnitude
/// as a speed hint rather than a distance when ``isPrecise`` is `false`.
///
/// ## See Also
///
/// - ``PointerMagnifyEvent``
/// - ``PointerModifiers``
public struct PointerScrollEvent: Sendable {
    /// Where the pointer was, in the target's coordinate space.
    public var location: CGPoint

    /// The horizontal scroll amount. See the type's discussion for units.
    public var deltaX: Double

    /// The vertical scroll amount. See the type's discussion for units.
    public var deltaY: Double

    /// Whether the deltas are point distances, rather than wheel/line units.
    /// A high-resolution device can still report fractional wheel units.
    public var isPrecise: Bool

    /// Where a precise scroll is in its lifetime.
    public var phase: PointerEventPhase

    /// The modifier keys held down.
    public var modifiers: PointerModifiers

    /// When the event happened.
    public var time: Date

    /// Describes a scroll step.
    ///
    /// - Parameters:
    ///   - location: Where the pointer was.
    ///   - deltaX: The horizontal scroll amount.
    ///   - deltaY: The vertical scroll amount.
    ///   - isPrecise: Whether the deltas are point distances.
    ///   - phase: Where a precise scroll is in its lifetime.
    ///   - modifiers: The modifier keys held down.
    ///   - time: When the event happened.
    public init(
        location: CGPoint,
        deltaX: Double,
        deltaY: Double,
        isPrecise: Bool = false,
        phase: PointerEventPhase = .changed,
        modifiers: PointerModifiers = [],
        time: Date = Date()
    ) {
        self.location = location
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.isPrecise = isPrecise
        self.phase = phase
        self.modifiers = modifiers
        self.time = time
    }
}
