extension View {
    /// Sets the style for labels within this view.
    ///
    /// The style propagates through the environment, so it applies to every
    /// ``Label`` nested inside this view, including labels used as the content
    /// of controls such as ``Button``.
    ///
    /// ```swift
    /// Button {
    ///     duplicate()
    /// } label: {
    ///     Label("Duplicate", systemImage: "square.on.square")
    /// }
    /// .labelStyle(.iconOnly)
    /// ```
    ///
    /// - Parameter style: The label style to use.
    ///
    /// ## See Also
    ///
    /// - ``LabelStyle``
    /// - ``Label``
    public func labelStyle(_ style: any LabelStyle) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.labelStyle, style)
        }
    }
}
