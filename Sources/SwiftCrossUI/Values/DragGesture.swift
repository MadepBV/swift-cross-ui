import Foundation // for CGPoint, CGSize and Date

/// A gesture that recognizes a pointer or finger being dragged across a view.
///
/// ```swift
/// Rectangle()
///     .frame(width: 44, height: 44)
///     .gesture(
///         DragGesture(minimumDistance: 0, coordinateSpace: .named("canvas"))
///             .onChanged { value in
///                 preview = value.location
///             }
///             .onEnded { value in
///                 commit(value.translation)
///             }
///     )
/// ```
///
/// - Important: No backend can deliver drag events yet, so the handlers
///   installed on a drag gesture are never called. See ``View/gesture(_:)``
///   for the details.
///
/// ## See Also
///
/// - ``Gesture``
/// - ``View/gesture(_:)``
public struct DragGesture: Gesture {
    /// A snapshot of a drag in progress.
    ///
    /// Handed to the handlers installed with ``DragGesture/onChanged(_:)``
    /// and ``DragGesture/onEnded(_:)``.
    public struct Value: Equatable, Sendable {
        /// The time at which this snapshot was taken.
        public var time: Date

        /// Where the drag started, in the gesture's coordinate space.
        public var startLocation: CGPoint

        /// Where the pointer is now, in the gesture's coordinate space.
        public var location: CGPoint

        /// How far the pointer has moved since the drag started.
        public var translation: CGSize

        /// How fast the pointer is currently moving, in points per second.
        ///
        /// SwiftCrossUI has no backend that measures pointer velocity, so
        /// this is currently always zero.
        public var velocity: CGSize

        /// Where the drag is expected to end once momentum runs out.
        ///
        /// SwiftCrossUI does not model drag momentum, so this is the same as
        /// ``DragGesture/Value/location``.
        public var predictedEndLocation: CGPoint

        /// The translation the drag is expected to end at once momentum runs
        /// out.
        ///
        /// SwiftCrossUI does not model drag momentum, so this is the same as
        /// ``DragGesture/Value/translation``.
        public var predictedEndTranslation: CGSize

        /// Describes a drag from its two endpoints.
        ///
        /// ``DragGesture/Value/translation`` is derived from the two
        /// locations, and the predicted values are left equal to the current
        /// ones because SwiftCrossUI does not model momentum.
        ///
        /// - Parameters:
        ///   - time: The time at which the snapshot was taken.
        ///   - startLocation: Where the drag started.
        ///   - location: Where the pointer is now.
        ///   - velocity: How fast the pointer is moving, if the backend
        ///     measures that.
        package init(
            time: Date,
            startLocation: CGPoint,
            location: CGPoint,
            velocity: CGSize = CGSize(width: 0.0, height: 0.0)
        ) {
            let translation = CGSize(
                width: location.x - startLocation.x,
                height: location.y - startLocation.y
            )
            self.time = time
            self.startLocation = startLocation
            self.location = location
            self.translation = translation
            self.velocity = velocity
            self.predictedEndLocation = location
            self.predictedEndTranslation = translation
        }

        /// Compares two snapshots field by field.
        ///
        /// Written out by hand because `CGPoint` and `CGSize` only pick up
        /// their `Equatable` conformances from the Core Graphics overlay,
        /// which isn't available on every platform SwiftCrossUI targets.
        ///
        /// - Parameters:
        ///   - lhs: The first snapshot.
        ///   - rhs: The second snapshot.
        /// - Returns: Whether the two snapshots describe the same drag.
        public static func == (lhs: Value, rhs: Value) -> Bool {
            lhs.time == rhs.time
                && lhs.startLocation.x == rhs.startLocation.x
                && lhs.startLocation.y == rhs.startLocation.y
                && lhs.location.x == rhs.location.x
                && lhs.location.y == rhs.location.y
                && lhs.translation.width == rhs.translation.width
                && lhs.translation.height == rhs.translation.height
                && lhs.velocity.width == rhs.velocity.width
                && lhs.velocity.height == rhs.velocity.height
                && lhs.predictedEndLocation.x == rhs.predictedEndLocation.x
                && lhs.predictedEndLocation.y == rhs.predictedEndLocation.y
                && lhs.predictedEndTranslation.width
                    == rhs.predictedEndTranslation.width
                && lhs.predictedEndTranslation.height
                    == rhs.predictedEndTranslation.height
        }
    }

    /// How far the pointer must move before the drag is recognized.
    public var minimumDistance: CGFloat

    /// The coordinate space that the gesture's locations are measured in.
    public var coordinateSpace: CoordinateSpace

    /// The handlers to call each time the drag updates.
    package var changeHandlers: [@MainActor (Value) -> Void] = []

    /// The handlers to call once the drag finishes.
    package var endHandlers: [@MainActor (Value) -> Void] = []

    /// Creates a drag gesture.
    ///
    /// - Parameters:
    ///   - minimumDistance: How far the pointer must move before the drag is
    ///     recognized.
    ///   - coordinateSpace: The coordinate space to report locations in.
    public init(
        minimumDistance: CGFloat = 10.0,
        coordinateSpace: CoordinateSpace = .local
    ) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
    }

    /// Adds an action to perform each time the drag updates.
    ///
    /// Handlers are called in the order they were added, and adding one never
    /// replaces an existing one.
    ///
    /// - Parameter action: The action to perform.
    /// - Returns: A drag gesture that also runs `action`.
    public func onChanged(
        _ action: @escaping @MainActor (Value) -> Void
    ) -> DragGesture {
        var gesture = self
        gesture.changeHandlers.append(action)
        return gesture
    }

    /// Adds an action to perform once the drag finishes.
    ///
    /// Handlers are called in the order they were added, and adding one never
    /// replaces an existing one.
    ///
    /// - Parameter action: The action to perform.
    /// - Returns: A drag gesture that also runs `action`.
    public func onEnded(
        _ action: @escaping @MainActor (Value) -> Void
    ) -> DragGesture {
        var gesture = self
        gesture.endHandlers.append(action)
        return gesture
    }
}
