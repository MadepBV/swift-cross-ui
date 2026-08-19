/// A gesture reduced to the concrete kind that a backend can recognize.
///
/// ``View/gesture(_:)`` resolves whatever it is handed into one of these, and
/// ``BackendFeatures/PointerGestures`` is driven from the result.
package enum ResolvedGesture {
    /// A drag, recognized once the pointer has moved far enough.
    case drag(DragGesture)

    /// A tap, reported with the position it happened at.
    case spatialTap(SpatialTapGesture)

    /// The coordinate space the gesture wants its positions in.
    package var coordinateSpace: CoordinateSpace {
        switch self {
            case .drag(let gesture): gesture.coordinateSpace
            case .spatialTap(let gesture): gesture.coordinateSpace
        }
    }

    /// How far the pointer must move before this gesture is recognized.
    ///
    /// Zero for a tap, which isn't a drag at all.
    package var minimumDragDistance: Double {
        switch self {
            case .drag(let gesture): Double(gesture.minimumDistance)
            case .spatialTap: 0.0
        }
    }

    /// How many taps in quick succession this gesture needs.
    ///
    /// One for a drag, which isn't a tap at all.
    package var tapCount: Int {
        switch self {
            case .drag: 1
            case .spatialTap(let gesture): gesture.count
        }
    }

    /// Delivers a drag update to the gesture's handlers.
    ///
    /// Does nothing for a gesture that isn't a drag.
    ///
    /// - Parameters:
    ///   - event: The pointer position the backend reported.
    ///   - phase: Whether the drag is still going or has finished.
    @MainActor
    package func sendDrag(_ event: PointerGestureEvent, phase: DragPhase) {
        guard case .drag(let gesture) = self else {
            return
        }
        let value = DragGesture.Value(
            time: event.time,
            startLocation: event.startLocation,
            location: event.location,
            velocity: event.velocity
        )
        let handlers = switch phase {
            case .changed: gesture.changeHandlers
            case .ended: gesture.endHandlers
        }
        for handler in handlers {
            handler(value)
        }
    }

    /// Delivers a tap to the gesture's handlers.
    ///
    /// Does nothing for a gesture that isn't a tap. A tap is discrete, so both
    /// the change and end handlers run, in that order.
    ///
    /// - Parameter event: The pointer position the backend reported.
    @MainActor
    package func sendTap(_ event: PointerGestureEvent) {
        guard case .spatialTap(let gesture) = self else {
            return
        }
        let value = SpatialTapGesture.Value(location: event.location)
        for handler in gesture.changeHandlers {
            handler(value)
        }
        for handler in gesture.endHandlers {
            handler(value)
        }
    }

    /// Which part of a drag an event belongs to.
    package enum DragPhase {
        /// The drag is still in progress.
        case changed
        /// The drag has finished.
        case ended
    }
}
