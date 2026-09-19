import Foundation

/// Converts Windows wheel-distance units into fractional wheel notches.
@_spi(Backends)
public enum WindowsScrollWheel {
    /// Builds a wheel event without guessing its physical device from a delta.
    ///
    /// MouseWheelDelta uses 120 units per detent. Finer-resolution wheels and
    /// precision touchpads can send smaller packets in those same units; they
    /// are not point distances. Preserve fractional notches and report
    /// `isPrecise: false` so a consumer does not apply a point-based rate to
    /// values already divided by 120. No rounding or accumulation is needed.
    /// Positive input remains forward (vertical) or rightward (horizontal).
    ///
    /// Native point-based scroll and pinch/manipulation events are separate
    /// paths and must not be passed through this conversion.
    ///
    /// See Microsoft's PointerPointProperties.MouseWheelDelta documentation:
    /// https://learn.microsoft.com/uwp/api/windows.ui.input.pointerpointproperties.mousewheeldelta
    public static func event(
        rawDelta: Int32,
        isHorizontal: Bool,
        location: CGPoint,
        modifiers: PointerModifiers = [],
        time: Date = Date()
    ) -> PointerScrollEvent {
        let notches = Double(rawDelta) / 120.0
        return PointerScrollEvent(
            location: location,
            deltaX: isHorizontal ? notches : 0,
            deltaY: isHorizontal ? 0 : notches,
            isPrecise: false,
            phase: .changed,
            modifiers: modifiers,
            time: time)
    }
}
