extension BackendFeatures {
    /// Optional control over native pointer hit testing for a whole view subtree.
    @MainActor
    public protocol HitTesting: Core {
        /// Wraps a child without adding any hit-testable empty area of its own.
        /// Must return a distinct container so a nested `true` cannot override
        /// an ancestor's `false`. Keep the child at the container's origin.
        func createHitTestingContainer(wrapping child: Widget) -> Widget

        /// Changes only native hit testing, preserving layout, appearance,
        /// enabled state and the existing child/handler identity.
        func setAllowsHitTesting(_ allowsHitTesting: Bool, of container: Widget)
    }
}
