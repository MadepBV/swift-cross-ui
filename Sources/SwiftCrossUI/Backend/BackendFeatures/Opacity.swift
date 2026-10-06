extension BackendFeatures {
    /// Backend methods for drawing a widget, and everything inside it,
    /// partially transparent.
    ///
    /// These are used by ``View/opacity(_:)``. The feature is optional: on a
    /// backend without it the modifier keeps its layout and draws the content
    /// fully opaque.
    @MainActor
    public protocol Opacity: Core {
        /// Sets the opacity of a widget and its descendants.
        ///
        /// SwiftCrossUI only calls this on a container it created for the
        /// modifier, so it never competes with opacity a backend sets on its
        /// own controls (a disabled button, for instance).
        ///
        /// - Parameters:
        ///   - widget: The widget to make transparent.
        ///   - opacity: The opacity, from 0 (invisible) to 1 (opaque).
        func setOpacity(of widget: Widget, to opacity: Double)
    }
}
