extension View {
    /// Places a bar of controls along an edge of this view, outside its safe
    /// area, so that the view's content makes room for it.
    ///
    /// SwiftUI draws the bar over a scroll edge effect that the content
    /// scrolls beneath; SwiftCrossUI has no scroll edge effects, so this lays
    /// the bar out exactly as ``View/safeAreaInset(edge:alignment:spacing:content:)-(VerticalEdge,_,_,_)``
    /// does, with the content beside it rather than beneath it.
    ///
    /// - Parameters:
    ///   - edge: The edge to place the bar along.
    ///   - alignment: How to align the bar along the edge.
    ///   - spacing: The distance between the bar and the content, or `nil`
    ///     for none.
    ///   - content: The bar.
    /// - Returns: A view with the bar along `edge`.
    public func safeAreaBar<Bar: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Bar
    ) -> some View {
        safeAreaInset(edge: edge, alignment: alignment, spacing: spacing, content: content)
    }

    /// Places a bar of controls along a side of this view, outside its safe
    /// area; see ``View/safeAreaBar(edge:alignment:spacing:content:)-(VerticalEdge,_,_,_)``.
    ///
    /// - Parameters:
    ///   - edge: The side to place the bar along.
    ///   - alignment: How to align the bar along the side.
    ///   - spacing: The distance between the bar and the content, or `nil`
    ///     for none.
    ///   - content: The bar.
    /// - Returns: A view with the bar along `edge`.
    public func safeAreaBar<Bar: View>(
        edge: HorizontalEdge,
        alignment: VerticalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Bar
    ) -> some View {
        safeAreaInset(edge: edge, alignment: alignment, spacing: spacing, content: content)
    }
}
