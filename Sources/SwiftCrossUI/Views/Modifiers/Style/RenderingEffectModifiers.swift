extension View {
    /// Blurs this view.
    ///
    /// - Note: Not drawn yet: a blur needs the backend to filter the view's
    ///   rendered pixels, which no backend exposes to SwiftCrossUI. The view
    ///   keeps its layout, which a blur never affects. Where a blur is
    ///   decorative (a softened backdrop), lower its opacity or cover it with
    ///   a material to keep content legible.
    ///
    /// - Parameters:
    ///   - radius: The blur radius.
    ///   - opaque: Whether the blur keeps the view's edges opaque.
    /// - Returns: The view.
    public func blur(radius: Double, opaque: Bool = false) -> some View {
        self
    }

    /// Masks this view with the opacity of another view.
    ///
    /// - Note: Not drawn yet: an alpha mask needs the backend to composite
    ///   the two views, which no backend exposes to SwiftCrossUI, so the view
    ///   draws unmasked. Use ``View/clipShape(_:style:)`` to cut a view to a
    ///   rounded rectangle, capsule or circle, which is drawn.
    ///
    /// - Parameters:
    ///   - alignment: How the mask is aligned in the view's frame.
    ///   - mask: The view whose opacity masks this one.
    /// - Returns: The view.
    public func mask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self
    }

    /// Brightens or darkens this view.
    ///
    /// - Note: Not drawn yet, for the reason given for
    ///   ``View/blur(radius:opaque:)``: a brightness filter needs the backend
    ///   to filter the view's rendered pixels. The view keeps its layout and
    ///   draws at its own brightness. Where the change signals state (a
    ///   hovered card), pair it with a change that is drawn, such as
    ///   ``View/opacity(_:)`` or a shadow.
    ///
    /// - Parameter amount: The amount to add to each color channel, from -1
    ///   (black) to 1 (white).
    /// - Returns: The view.
    public func brightness(_ amount: Double) -> some View {
        self
    }
}

