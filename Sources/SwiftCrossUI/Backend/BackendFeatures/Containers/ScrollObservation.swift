extension BackendFeatures {
    /// Backend methods for learning that the user scrolled a scroll container.
    ///
    /// Lazy containers use it to make their children appear (``View/onAppear(perform:)``,
    /// ``View/task(priority:_:)``) as they're scrolled into view. The feature is
    /// optional: without it, and without ``WidgetGeometry``, children appear as
    /// soon as they're created.
    @MainActor
    public protocol ScrollObservation: ScrollContainers {
        /// Sets the action to run whenever the container's visible region
        /// moves, replacing any previous action. The action may run often
        /// while a scroll is in flight; SwiftCrossUI coalesces the work it
        /// does in response.
        ///
        /// - Parameters:
        ///   - scrollContainer: A container made by `createScrollContainer(for:)`.
        ///   - action: The action.
        func setScrollChangeHandler(
            of scrollContainer: Widget,
            to action: @escaping @MainActor () -> Void
        )
    }
}
