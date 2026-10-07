extension BackendFeatures {
    /// Backend methods for finding where a committed widget is drawn relative
    /// to one of its ancestors.
    ///
    /// These resolve ``GeometryProxy/frame(in:)`` for a named coordinate space
    /// (``View/coordinateSpace(name:)``) and for ``CoordinateSpace/scrollView``.
    /// The feature is optional: on a backend without it those frames are the
    /// view's local bounds, as they were before.
    @MainActor
    public protocol WidgetGeometry: Core {
        /// The frame of `widget` in the coordinate space of `ancestor`, with
        /// the origin at the ancestor's top-leading corner and y growing
        /// downwards.
        ///
        /// Called after a commit has positioned every widget, so it reflects
        /// that commit. When `ancestor` is a scroll container, the frame is
        /// relative to its visible region, so it moves as the content scrolls.
        ///
        /// - Parameters:
        ///   - widget: The widget to locate.
        ///   - ancestor: The widget whose coordinate space to use.
        /// - Returns: The frame, or `nil` if `widget` isn't below `ancestor`.
        func frame(
            of widget: Widget,
            in ancestor: Widget
        ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)?
    }
}
