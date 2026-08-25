import Foundation // for CGPoint

/// A gesture that recognizes a tap or click and reports where it happened.
///
/// Use this instead of ``View/onTapGesture(gesture:perform:)`` when the action
/// depends on *where* the view was tapped.
///
/// ```swift
/// Canvas { context, size in
///     draw(&context, size)
/// }
/// .gesture(
///     SpatialTapGesture()
///         .onEnded { value in
///             select(nearestNode(to: value.location))
///         }
/// )
/// ```
///
/// - Important: No backend reports the location of a tap yet, so the handlers
///   installed on a spatial tap gesture are never called. Use
///   ``View/onTapGesture(gesture:perform:)`` when the location isn't needed;
///   that is wired up on every backend. See ``View/gesture(_:)`` for the
///   details.
///
/// ## See Also
///
/// - ``Gesture``
/// - ``View/gesture(_:)``
/// - ``View/onTapGesture(gesture:perform:)``
public struct SpatialTapGesture: Gesture {
    /// The location of a recognized tap.
    ///
    /// Handed to the handlers installed with
    /// ``SpatialTapGesture/onEnded(_:)``.
    public struct Value: Equatable, Sendable {
        /// Where the tap happened, in the gesture's coordinate space.
        public var location: CGPoint

        /// The modifier keys held down when the tap happened.
        ///
        /// SwiftUI's value has no such field; SwiftCrossUI adds it so that
        /// additive selection (Shift or Command clicks) doesn't need a
        /// separate keyboard listener.
        public var modifiers: PointerModifiers

        /// How many clicks in quick succession this tap completed: the
        /// gesture's ``SpatialTapGesture/count``.
        ///
        /// SwiftUI's value has no such field; SwiftCrossUI adds it so that a
        /// handler shared between a single- and a double-click gesture can
        /// tell them apart without timing clicks itself.
        public var clickCount: Int

        /// Describes a tap at a location.
        ///
        /// - Parameters:
        ///   - location: Where the tap happened.
        ///   - modifiers: The modifier keys held down.
        ///   - clickCount: How many clicks in quick succession the tap
        ///     completed.
        package init(
            location: CGPoint,
            modifiers: PointerModifiers = [],
            clickCount: Int = 1
        ) {
            self.location = location
            self.modifiers = modifiers
            self.clickCount = clickCount
        }

        /// Compares two tap locations.
        ///
        /// Written out by hand because `CGPoint` only picks up its
        /// `Equatable` conformance from the Core Graphics overlay, which
        /// isn't available on every platform SwiftCrossUI targets.
        ///
        /// - Parameters:
        ///   - lhs: The first tap.
        ///   - rhs: The second tap.
        /// - Returns: Whether the two taps happened at the same place.
        public static func == (lhs: Value, rhs: Value) -> Bool {
            lhs.location.x == rhs.location.x
                && lhs.location.y == rhs.location.y
                && lhs.modifiers == rhs.modifiers
                && lhs.clickCount == rhs.clickCount
        }
    }

    /// The number of taps that must happen in quick succession.
    public var count: Int

    /// The coordinate space that the gesture's locations are measured in.
    public var coordinateSpace: CoordinateSpace

    /// The handlers to call each time the gesture updates.
    package var changeHandlers: [@MainActor (Value) -> Void] = []

    /// The handlers to call once the tap completes.
    package var endHandlers: [@MainActor (Value) -> Void] = []

    /// Creates a spatial tap gesture.
    ///
    /// - Parameters:
    ///   - count: The number of taps that must happen in quick succession.
    ///   - coordinateSpace: The coordinate space to report locations in.
    public init(count: Int = 1, coordinateSpace: CoordinateSpace = .local) {
        self.count = count
        self.coordinateSpace = coordinateSpace
    }

    /// Adds an action to perform each time the gesture updates.
    ///
    /// A tap is discrete, so this only ever runs at the moment the tap is
    /// recognized. Handlers are called in the order they were added.
    ///
    /// - Parameter action: The action to perform.
    /// - Returns: A tap gesture that also runs `action`.
    public func onChanged(
        _ action: @escaping @MainActor (Value) -> Void
    ) -> SpatialTapGesture {
        var gesture = self
        gesture.changeHandlers.append(action)
        return gesture
    }

    /// Adds an action to perform once the tap completes.
    ///
    /// Handlers are called in the order they were added, and adding one never
    /// replaces an existing one.
    ///
    /// - Parameter action: The action to perform.
    /// - Returns: A tap gesture that also runs `action`.
    public func onEnded(
        _ action: @escaping @MainActor (Value) -> Void
    ) -> SpatialTapGesture {
        var gesture = self
        gesture.endHandlers.append(action)
        return gesture
    }
}

extension SpatialTapGesture: _ResolvableGesture {
    package var _resolved: ResolvedGesture {
        .spatialTap(self)
    }
}
