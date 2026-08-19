/// The coordinate system that a gesture reports its locations in.
///
/// Pass one to ``DragGesture/init(minimumDistance:coordinateSpace:)`` or
/// ``SpatialTapGesture/init(count:coordinateSpace:)`` to choose which origin
/// the gesture's `location` and `startLocation` are measured from.
///
/// ```swift
/// DragGesture(coordinateSpace: .named("canvas"))
/// ```
///
/// ## See Also
///
/// - ``DragGesture``
/// - ``SpatialTapGesture``
public enum CoordinateSpace: Hashable {
    /// The coordinate space of the window the view is displayed in.
    case global

    /// The coordinate space of the view the gesture is attached to.
    case local

    /// The coordinate space of an ancestor view that has been given a name.
    ///
    /// - Parameter name: The name the ancestor was tagged with.
    case named(AnyHashable)
}
