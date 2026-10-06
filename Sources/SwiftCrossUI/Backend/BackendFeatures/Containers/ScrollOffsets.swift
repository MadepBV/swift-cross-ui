extension BackendFeatures {
    /// Backend methods for scrolling a scroll container programmatically.
    ///
    /// These are used by ``ScrollViewReader``, ``ScrollPosition`` and
    /// ``View/scrollPosition(id:anchor:)``. A backend that doesn't implement
    /// them leaves its scroll views where the user put them.
    ///
    /// Offsets and positions are measured in points from the top-leading
    /// corner of the scroll container's content, whatever the platform's own
    /// coordinate system is.
    @MainActor
    public protocol ScrollOffsets: ScrollContainers {
        /// Gets how far a scroll container is scrolled.
        ///
        /// - Parameter scrollContainer: A widget created by
        ///   ``ScrollContainers/createScrollContainer(for:)``.
        /// - Returns: The offset of the visible region's top-leading corner
        ///   from the content's.
        func scrollOffset(of scrollContainer: Widget) -> SIMD2<Double>

        /// Scrolls a scroll container.
        ///
        /// The backend clamps the offset to the scrollable range.
        ///
        /// - Parameters:
        ///   - scrollContainer: A widget created by
        ///     ``ScrollContainers/createScrollContainer(for:)``.
        ///   - offset: The offset of the visible region's top-leading corner
        ///     from the content's.
        ///   - animated: Whether to animate the change, where the platform
        ///     can.
        func setScrollOffset(
            of scrollContainer: Widget,
            to offset: SIMD2<Double>,
            animated: Bool
        )

        /// Gets where a widget inside a scroll container's content is.
        ///
        /// - Parameters:
        ///   - widget: A widget somewhere inside the scroll container's content.
        ///   - scrollContainer: A widget created by
        ///     ``ScrollContainers/createScrollContainer(for:)``.
        /// - Returns: The widget's top-leading corner, measured from the
        ///   content's, and its size; `nil` if the widget isn't inside the
        ///   container.
        func frame(
            of widget: Widget,
            inContentOf scrollContainer: Widget
        ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)?
    }
}
