/// Tracks selection state acknowledged by a native control bridge.
///
/// Native controls can report a programmatic selection after their setter has
/// returned, for example when initially realizing their items. Suppressing only
/// events delivered inside the setter does not cover those notifications.
///
/// Record model selections before writing native properties, including when
/// skipping an equal property write. For native notifications, pass the current
/// selection property and forward only when `shouldForwardNativeSelection`
/// returns true. Update scopes must separately suppress intermediate native
/// states produced while rebuilding items or applying a model selection.
///
/// The tracker retains a value, not a pending-event count or timeout. A different
/// native selection is forwarded immediately and becomes the new baseline, so
/// selecting the former model value again remains a real change. Use it on the
/// control's owning thread; it does not synchronize native widget access.
@_spi(Backends)
public struct NativeSelectionTracker<Selection: Equatable> {
    private var acknowledgedSelection: Selection

    public init(initialSelection: Selection) {
        acknowledgedSelection = initialSelection
    }

    public mutating func recordProgrammaticSelection(_ selection: Selection) {
        acknowledgedSelection = selection
    }

    /// Acknowledges a new native value before application callbacks can reenter
    /// the backend with another model write.
    public mutating func shouldForwardNativeSelection(_ selection: Selection) -> Bool {
        guard selection != acknowledgedSelection else { return false }
        acknowledgedSelection = selection
        return true
    }
}
