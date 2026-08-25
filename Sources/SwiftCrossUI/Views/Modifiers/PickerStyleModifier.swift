extension View {
    /// Sets the style of pickers within this view.
    ///
    /// A style the backend can't render degrades to the backend's default
    /// picker style, with a warning logged once per call site: SwiftUI's
    /// styles are hints, and a picker drawn differently is still a working
    /// picker whereas a trap is not.
    ///
    /// - Parameter style: The style to use.
    /// - Returns: A view whose pickers use `style` where the backend can.
    public func pickerStyle(_ style: any PickerStyle) -> some View {
        EnvironmentModifier(self) { environment in
            if !style.isSupported(backend: environment.backend) {
                logger.warnOnce(
                    """
                    Picker style \(style) isn't supported by \
                    \(type(of: environment.backend)); using the backend's \
                    default picker style instead
                    """
                )
                return environment.with(\.pickerStyle, .automatic)
            }
            return environment.with(\.pickerStyle, style)
        }
    }
}
