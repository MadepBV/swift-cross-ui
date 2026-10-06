/// The shape of a rounded rectangle's corners.
public enum RoundedCornerStyle: Hashable, Sendable {
    /// Quarter-circle corners.
    case circular
    /// Continuous corners, whose curvature eases into the straight edges.
    case continuous
}
