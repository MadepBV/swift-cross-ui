extension BackendFeatures {
    /// Backend methods for taking a widget, and everything inside it, out of
    /// sight without destroying it.
    ///
    /// Used for pages kept alive while they're not shown (a navigation
    /// stack's covered pages, a tab view's other tabs). A hidden widget is
    /// not drawn, not hit-tested and not reachable by keyboard focus. The
    /// feature is optional: without it such pages are made fully transparent
    /// through ``Opacity``.
    @MainActor
    public protocol WidgetVisibility: Core {
        /// Shows or hides a widget and its descendants.
        ///
        /// SwiftCrossUI only calls this on a container it created for the
        /// purpose, so it never competes with visibility a backend manages on
        /// its own controls.
        ///
        /// - Parameters:
        ///   - widget: The widget.
        ///   - visible: Whether it's shown.
        func setVisibility(of widget: Widget, visible: Bool)
    }
}
