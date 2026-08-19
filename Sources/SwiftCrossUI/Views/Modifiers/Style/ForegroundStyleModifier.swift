extension View {
    /// Sets the style of the foreground elements displayed by this view.
    ///
    /// This is the spelling SwiftUI uses, and behaves exactly like
    /// ``View/foregroundColor(_:)``. SwiftUI accepts any `ShapeStyle` here;
    /// SwiftCrossUI has no `ShapeStyle` yet, so only colours are accepted.
    ///
    /// - Parameter color: The new foreground colour.
    /// - Returns: A view whose foreground elements use `color`.
    public func foregroundStyle(_ color: Color) -> some View {
        foregroundColor(color)
    }
}
