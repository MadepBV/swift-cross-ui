extension View {
    /// Attaches a gesture to this view.
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
    /// ## Backend support
    ///
    /// Recognizing ``DragGesture`` or ``SpatialTapGesture`` needs the backend
    /// to report where the pointer is, and for a drag it needs a stream of
    /// press, move and release events. The gesture surface that backends
    /// implement today, ``BackendFeatures/TapGestures`` and
    /// ``BackendFeatures/HoverGestures``, carries neither: a tap arrives as a
    /// bare callback with no location, and there is no drag callback at all.
    ///
    /// So this modifier currently accepts a gesture, keeps the view's layout
    /// and hit testing exactly as they were, and never calls the gesture's
    /// handlers. It logs a warning the first time it is used. Making it work
    /// needs a new backend feature protocol carrying pointer positions; until
    /// then, reach for ``View/onTapGesture(gesture:perform:)`` and
    /// ``View/onHover(perform:)``, which every backend implements.
    ///
    /// - Parameter gesture: The gesture to recognize.
    /// - Returns: A view that would recognize `gesture`.
    ///
    /// ## See Also
    ///
    /// - ``Gesture``
    /// - ``View/simultaneousGesture(_:)``
    /// - ``View/onTapGesture(gesture:perform:)``
    public func gesture(_ gesture: some Gesture) -> some View {
        logger.warnOnce(
            """
            'View.gesture(_:)' is not wired up to any backend yet, so the \
            gesture's handlers will never run. Use \
            'View.onTapGesture(gesture:perform:)' for taps that don't need a \
            location.
            """
        )
        return self
    }

    /// Attaches a gesture to this view, letting the gestures already on it
    /// keep running alongside it.
    ///
    /// Carries the same backend limitation as ``View/gesture(_:)``: the
    /// gesture is accepted but its handlers never run, because no backend
    /// reports pointer positions yet.
    ///
    /// - Parameter gesture: The gesture to recognize.
    /// - Returns: A view that would recognize `gesture` simultaneously with
    ///   its existing gestures.
    ///
    /// ## See Also
    ///
    /// - ``Gesture``
    /// - ``View/gesture(_:)``
    public func simultaneousGesture(_ gesture: some Gesture) -> some View {
        logger.warnOnce(
            """
            'View.simultaneousGesture(_:)' is not wired up to any backend \
            yet, so the gesture's handlers will never run. Use \
            'View.onTapGesture(gesture:perform:)' for taps that don't need a \
            location.
            """
        )
        return self
    }
}
