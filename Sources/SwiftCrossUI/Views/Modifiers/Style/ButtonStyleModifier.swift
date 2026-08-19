extension View {
    /// Sets the style for buttons within this view to a button style with a
    /// custom appearance and standard interaction behavior.
    ///
    /// The style propagates through the environment, so it applies to every
    /// ``Button`` nested inside this view.
    ///
    /// ```swift
    /// HStack {
    ///     Button("Extrude") { extrude() }
    ///     Button("Revolve") { revolve() }
    /// }
    /// .buttonStyle(.bordered)
    /// ```
    ///
    /// - Parameter style: The button style to use.
    /// - Returns: A view whose descendant buttons use `style`.
    ///
    /// ## See Also
    ///
    /// - ``ButtonStyle``
    /// - ``Button``
    public func buttonStyle(_ style: any ButtonStyle) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.buttonStyle, style)
        }
    }
}
