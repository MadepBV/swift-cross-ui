/// Where a continuous pointer interaction is in its lifetime.
///
/// Used by ``PointerScrollEvent`` and ``PointerMagnifyEvent``. A discrete
/// interaction with no lifetime, such as one notch of a mouse wheel, is
/// reported as ``changed``.
public enum PointerEventPhase: Hashable, Sendable {
    /// The interaction just started; this is the first event of it.
    case began

    /// The interaction is in progress (or is a discrete event).
    case changed

    /// The interaction finished normally; this is the last event of it.
    case ended

    /// The interaction was cut short by the system; this is the last event
    /// of it and any effect it had may be reverted.
    case cancelled
}
