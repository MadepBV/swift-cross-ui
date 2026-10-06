extension View {
    /// Sets the style of the foreground elements displayed by this view.
    ///
    /// This is the spelling SwiftUI uses, and behaves exactly like
    /// ``View/foregroundColor(_:)``.
    ///
    /// - Parameter color: The new foreground colour.
    /// - Returns: A view whose foreground elements use `color`.
    public func foregroundStyle(_ color: Color) -> some View {
        foregroundColor(color)
    }

    /// Sets the style of the foreground elements displayed by this view.
    ///
    /// Accepts any ``ShapeStyle``, such as an ``AnyShapeStyle`` chosen at run
    /// time or a ``Material``. A hierarchical style such as
    /// ``Color/secondary`` is a level of the foreground style *outside* this
    /// modifier, as in SwiftUI.
    ///
    /// - Parameter style: The new foreground style.
    /// - Returns: A view whose foreground elements use `style`.
    public func foregroundStyle<S: ShapeStyle>(_ style: S) -> some View {
        foregroundColor(style._color)
    }

    /// Sets the primary and secondary styles of the foreground elements in
    /// this view.
    ///
    /// The styles are for the layers of multi-layer symbols in
    /// ``SymbolRenderingMode/palette``. SwiftCrossUI's symbols have a single
    /// layer (see ``SymbolRenderingMode``), so they and all other content
    /// draw in the primary style.
    ///
    /// - Parameters:
    ///   - primary: The primary style.
    ///   - secondary: The secondary style.
    /// - Returns: A view whose foreground elements use `primary`.
    public func foregroundStyle<S1: ShapeStyle, S2: ShapeStyle>(
        _ primary: S1,
        _ secondary: S2
    ) -> some View {
        foregroundColor(primary._color)
    }

    /// Sets the primary, secondary and tertiary styles of the foreground
    /// elements in this view.
    ///
    /// Content draws in the primary style; see
    /// ``View/foregroundStyle(_:_:)``.
    ///
    /// - Parameters:
    ///   - primary: The primary style.
    ///   - secondary: The secondary style.
    ///   - tertiary: The tertiary style.
    /// - Returns: A view whose foreground elements use `primary`.
    public func foregroundStyle<S1: ShapeStyle, S2: ShapeStyle, S3: ShapeStyle>(
        _ primary: S1,
        _ secondary: S2,
        _ tertiary: S3
    ) -> some View {
        foregroundColor(primary._color)
    }
}
