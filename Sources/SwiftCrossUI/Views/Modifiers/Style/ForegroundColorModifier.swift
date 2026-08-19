extension View {
    /// Sets the color of the foreground elements displayed by this view.
    ///
    /// - Parameter color: The new foreground color. `nil` clears the color,
    ///   letting the view inherit again, exactly as in SwiftUI.
    ///
    /// - Note: The parameter is optional so that it matches SwiftUI's, and so
    ///   that ``Text/foregroundColor(_:)`` (which is also optional, and which
    ///   returns a ``Text`` rather than erasing to `some View`) is preferred
    ///   over this modifier when the receiver is a ``Text``.
    public func foregroundColor(_ color: Color?) -> some View {
        return EnvironmentModifier(self) { environment in
            return environment.with(\.foregroundColor, color)
        }
    }
}
