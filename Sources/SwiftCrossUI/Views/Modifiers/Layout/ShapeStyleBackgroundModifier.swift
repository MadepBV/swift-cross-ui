extension View {
    /// Fills the area behind this view with a shape style.
    ///
    /// The style fills the view's whole frame, so `.background(.black)` and
    /// `.background(.thinMaterial)` read as they do in SwiftUI.
    ///
    /// - Note: `ignoresSafeAreaEdges` is accepted for source compatibility.
    ///   SwiftCrossUI's desktop windows have no safe area to extend into.
    ///
    /// - Parameters:
    ///   - style: The style to fill with.
    ///   - ignoresSafeAreaEdges: Ignored; see above.
    /// - Returns: A view with `style` behind it.
    @_disfavoredOverload
    public func background<S: ShapeStyle>(
        _ style: S,
        ignoresSafeAreaEdges: Edge.Set = .all
    ) -> some View {
        background(style._color)
    }

    /// Fills a shape behind this view with a shape style.
    ///
    /// ```swift
    /// Text("New")
    ///     .padding(6)
    ///     .background(.black.opacity(0.3), in: Capsule())
    /// ```
    ///
    /// The shape takes the view's frame, exactly as in SwiftUI.
    ///
    /// - Parameters:
    ///   - style: The style to fill the shape with.
    ///   - shape: The shape to fill.
    ///   - fillStyle: How to rasterise the shape. Accepted for source
    ///     compatibility; shapes are filled with the non-zero rule.
    /// - Returns: A view with the filled shape behind it.
    public func background<S: ShapeStyle, Fill: Shape>(
        _ style: S,
        in shape: Fill,
        fillStyle: FillStyle = FillStyle()
    ) -> some View {
        background(shape.fill(style))
    }

    /// Fills a shape behind this view with the current background style.
    ///
    /// - Parameters:
    ///   - shape: The shape to fill.
    ///   - fillStyle: Accepted for source compatibility.
    /// - Returns: A view with the filled shape behind it.
    public func background<Fill: Shape>(
        in shape: Fill,
        fillStyle: FillStyle = FillStyle()
    ) -> some View {
        background(shape.fill(Color.background))
    }
}
