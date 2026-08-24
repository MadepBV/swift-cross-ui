extension BackendFeatures {
    /// Backend methods for gestures that need to know where the pointer is.
    ///
    /// These are used by ``View/gesture(_:)`` to recognize ``DragGesture``
    /// and ``SpatialTapGesture``, neither of which
    /// ``BackendFeatures/TapGestures`` can express: a tap arrives there as a
    /// bare callback with no location, and there is no drag callback at all.
    ///
    /// The same target also delivers scroll wheel/trackpad scrolling and
    /// pinch-to-zoom, which back ``View/onScrollWheel(perform:)`` and
    /// ``View/onMagnify(perform:)``, and every event carries the modifier
    /// keys held down (``PointerModifiers``).
    ///
    /// This is deliberately **not** part of ``BackendFeatures/Gestures`` or
    /// ``FullAppBackend``. ``View/gesture(_:)`` casts the backend to it at
    /// runtime, so a backend that doesn't implement it keeps compiling and
    /// simply never delivers these gestures. That makes the protocol additive:
    /// adopting it is how a backend opts into drag support, and not adopting
    /// it costs nothing.
    ///
    /// ## Coordinate spaces
    ///
    /// A backend only ever receives ``CoordinateSpace/local`` or
    /// ``CoordinateSpace/global``, because ``View/gesture(_:)`` refuses a
    /// gesture asking for ``CoordinateSpace/named(_:)`` rather than reporting
    /// positions from the wrong origin. ``CoordinateSpace/local`` means the
    /// gesture target's own top-leading corner; ``CoordinateSpace/global``
    /// means the window's.
    @MainActor
    public protocol PointerGestures: Core {
        /// Wraps a view in a container that can receive pointer events.
        ///
        /// Some backends may not have to wrap the child, in which case they
        /// may just return the child as is.
        ///
        /// - Parameter child: The child to wrap.
        /// - Returns: A widget that can receive pointer events.
        func createPointerGestureTarget(wrapping child: Widget) -> Widget

        /// Updates a pointer gesture target with new actions.
        ///
        /// The new actions replace any existing ones. A `nil` action means
        /// that no gesture of that kind is attached, and the backend should
        /// tear down whatever machinery it was using to recognize it.
        ///
        /// A target with no actions at all must not intercept pointer events
        /// that would otherwise reach the widgets beneath it.
        ///
        /// - Parameters:
        ///   - target: The pointer gesture target to update.
        ///   - minimumDragDistance: How far the pointer must move before a
        ///     drag is recognized.
        ///   - tapCount: How many taps in quick succession are needed before
        ///     `onTap` runs.
        ///   - coordinateSpace: The space to report positions in. Only
        ///     ``CoordinateSpace/local`` and ``CoordinateSpace/global`` are
        ///     ever passed.
        ///   - environment: The current environment.
        ///   - onDragChanged: The action to perform each time a drag updates.
        ///   - onDragEnded: The action to perform when a drag finishes.
        ///   - onTap: The action to perform when a tap is recognized.
        ///   - onScroll: The action to perform for each step of a scroll
        ///     wheel or trackpad scroll over the target. While this is `nil`
        ///     the backend must let scrolling reach whatever it would have
        ///     reached without the target (an enclosing scroll view, say).
        ///   - onMagnify: The action to perform for each step of a pinch
        ///     over the target. Backends whose platform has no pinch
        ///     gesture for the pointer in use never call it.
        func updatePointerGestureTarget(
            _ target: Widget,
            minimumDragDistance: Double,
            tapCount: Int,
            coordinateSpace: CoordinateSpace,
            environment: EnvironmentValues,
            onDragChanged: (@MainActor (PointerGestureEvent) -> Void)?,
            onDragEnded: (@MainActor (PointerGestureEvent) -> Void)?,
            onTap: (@MainActor (PointerGestureEvent) -> Void)?,
            onScroll: (@MainActor (PointerScrollEvent) -> Void)?,
            onMagnify: (@MainActor (PointerMagnifyEvent) -> Void)?
        )
    }
}
