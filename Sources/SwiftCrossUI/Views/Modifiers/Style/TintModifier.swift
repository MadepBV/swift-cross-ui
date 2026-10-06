extension View {
    /// Sets the tint of this view hierarchy.
    ///
    /// The tint is what ``Color/tint`` (and the leading-dot `.tint` at any
    /// ``ShapeStyle`` parameter) draws with inside this view. `nil` restores
    /// the accent colour.
    ///
    /// - Note: Native controls drawn by a backend (progress bars, prominent
    ///   buttons, switches) keep the platform's own accent colour: no backend
    ///   exposes a per-control accent yet. Content styled with `.tint` follows
    ///   it.
    ///
    /// - Parameter tint: The tint colour.
    /// - Returns: A view tinted with `tint`.
    public func tint(_ tint: Color?) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.tintColor, tint?.bindingStyle(in: environment))
        }
    }

    /// Sets the tint of this view hierarchy to a shape style.
    ///
    /// See ``View/tint(_:)-(Color?)``.
    ///
    /// - Parameter tint: The tint style.
    /// - Returns: A view tinted with `tint`.
    public func tint<S: ShapeStyle>(_ tint: S?) -> some View {
        self.tint(tint?._color)
    }
}
