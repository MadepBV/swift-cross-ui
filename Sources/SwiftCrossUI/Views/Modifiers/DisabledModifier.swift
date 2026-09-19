extension View {
    /// Disables user interaction in any subviews that support disabling
    /// interaction.
    ///
    /// A descendant cannot re-enable interaction disabled by an ancestor.
    /// Passing `false` removes only this modifier's own disabling condition.
    ///
    /// - Parameter disabled: Whether to disable user interaction.
    public func disabled(_ disabled: Bool = true) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.isEnabled, environment.isEnabled && !disabled)
        }
    }
}
