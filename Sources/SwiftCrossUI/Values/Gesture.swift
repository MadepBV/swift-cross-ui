/// An input gesture that a view can recognize.
///
/// Attach a gesture to a view with ``View/gesture(_:)`` or
/// ``View/simultaneousGesture(_:)``. SwiftCrossUI ships two gestures,
/// ``DragGesture`` and ``SpatialTapGesture``, both of which deliver their
/// events to handlers installed with `onChanged(_:)` and `onEnded(_:)`.
///
/// ```swift
/// Canvas { context, size in
///     draw(&context, size)
/// }
/// .gesture(
///     DragGesture(minimumDistance: 4)
///         .onEnded { value in
///             move(from: value.startLocation, to: value.location)
///         }
/// )
/// ```
///
/// ## Differences from SwiftUI
///
/// SwiftUI's `Gesture` additionally has a `Body` associated type and a `body`
/// property, which let a gesture be defined by composing others with
/// combinators such as `sequenced(before:)` and `simultaneously(with:)`.
/// SwiftCrossUI has no gesture combinators yet, so it omits that machinery:
/// this protocol exists so that gestures share a name and can be written as
/// `some Gesture`, and only SwiftCrossUI's own gestures conform to it.
///
/// - Important: How much of a gesture actually reaches your handlers depends
///   on the backend. See ``View/gesture(_:)`` for what today's backends can
///   and cannot recognize.
///
/// ## See Also
///
/// - ``DragGesture``
/// - ``SpatialTapGesture``
/// - ``View/gesture(_:)``
public protocol Gesture<Value> {
    /// The value handed to the gesture's handlers each time it updates.
    associatedtype Value
}
