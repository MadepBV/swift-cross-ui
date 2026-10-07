extension BackendFeatures {
    /// Backend methods for drawing a view through the opacity of another
    /// view, as ``View/mask(alignment:_:)`` does.
    ///
    /// The feature is optional: on a backend without it the modifier keeps
    /// its layout and draws the content unmasked.
    @MainActor
    public protocol Masks: Core {
        /// Creates a container that draws `content` only where `mask` is
        /// opaque, scaled by the mask's opacity. The mask itself is never drawn.
        ///
        /// - Parameters:
        ///   - content: The widget to draw.
        ///   - mask: The widget whose opacity masks `content`.
        /// - Returns: The container.
        func createMaskContainer(content: Widget, mask: Widget) -> Widget

        /// Sizes a mask container and places its mask, after its content and
        /// mask have committed.
        ///
        /// - Parameters:
        ///   - container: A container made by ``createMaskContainer(content:mask:)``.
        ///   - size: The content's size, which is the container's.
        ///   - maskOrigin: Where the mask's top-leading corner is in the
        ///     container.
        ///   - maskSize: The mask's size.
        func updateMaskContainer(
            _ container: Widget,
            size: SIMD2<Int>,
            maskOrigin: SIMD2<Int>,
            maskSize: SIMD2<Int>
        )
    }
}
