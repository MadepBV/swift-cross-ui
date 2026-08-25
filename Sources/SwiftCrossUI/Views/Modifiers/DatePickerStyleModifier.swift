extension View {
    /// Sets the style of date pickers within this view.
    ///
    /// A style the backend can't render degrades to the backend's default
    /// date picker style, with a warning logged once per call site.
    ///
    /// - Parameter style: The style to use.
    /// - Returns: A view whose date pickers use `style` where the backend can.
    public func datePickerStyle(_ style: DatePickerStyle) -> some View {
        EnvironmentModifier(self) { environment in
            guard environment.supportedDatePickerStyles.contains(style) else {
                logger.warnOnce(
                    """
                    Date picker style \(style) isn't supported by \
                    \(type(of: environment.backend)); using the backend's \
                    default date picker style instead
                    """
                )
                return environment.with(\.datePickerStyle, .automatic)
            }
            return environment.with(\.datePickerStyle, style)
        }
    }
}
