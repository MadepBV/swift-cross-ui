import Foundation // for CGPoint and Date

/// One step of a pinch-to-zoom, reported by a backend implementing
/// ``BackendFeatures/PointerGestures``.
///
/// Delivered to the handler installed with ``View/onMagnify(perform:)``.
///
/// ``magnification`` is the scale factor accumulated since the pinch began,
/// exactly as SwiftUI's `MagnifyGesture.Value.magnification`: it starts at
/// `1.0` and a pinch that doubles the content reports `2.0`. To apply it
/// incrementally, divide by the previous event's magnification.
///
/// ## See Also
///
/// - ``PointerScrollEvent``
/// - ``PointerModifiers``
public struct PointerMagnifyEvent: Sendable {
    /// Where the pinch is centred, in the target's coordinate space.
    public var location: CGPoint

    /// The scale factor accumulated since the pinch began; `1.0` means
    /// unchanged.
    public var magnification: Double

    /// Where the pinch is in its lifetime.
    public var phase: PointerEventPhase

    /// The modifier keys held down.
    public var modifiers: PointerModifiers

    /// When the event happened.
    public var time: Date

    /// Describes a pinch step.
    ///
    /// - Parameters:
    ///   - location: Where the pinch is centred.
    ///   - magnification: The scale factor accumulated since the pinch began.
    ///   - phase: Where the pinch is in its lifetime.
    ///   - modifiers: The modifier keys held down.
    ///   - time: When the event happened.
    public init(
        location: CGPoint,
        magnification: Double,
        phase: PointerEventPhase = .changed,
        modifiers: PointerModifiers = [],
        time: Date = Date()
    ) {
        self.location = location
        self.magnification = magnification
        self.phase = phase
        self.modifiers = modifiers
        self.time = time
    }
}
