extension BackendFeatures {
    /// Backend methods for color pickers.
    ///
    /// Every desktop platform ships a colour picker of its own (`NSColorWell`,
    /// WinUI's `ColorPicker`, `GtkColorButton`), and users expect the one they
    /// know, so this is modelled the same way as
    /// ``BackendFeatures/DatePickers``: the backend supplies the whole control
    /// and SwiftCrossUI just tells it what to display.
    ///
    /// These are used by ``ColorPicker``.
    @MainActor
    public protocol ColorPickers: Core {
        /// Creates a color picker.
        ///
        /// - Returns: A color picker widget.
        func createColorPicker() -> Widget

        /// Updates a color picker's value and appearance.
        ///
        /// - Parameters:
        ///   - colorPicker: The color picker to update.
        ///   - color: The currently selected color.
        ///   - supportsOpacity: Whether the user should be able to choose a
        ///     color with an opacity below 1. Backends that can't hide their
        ///     opacity control should clamp the reported opacity to 1 instead.
        ///   - environment: The current environment.
        ///   - onChange: Called whenever the user picks a different color.
        func updateColorPicker(
            _ colorPicker: Widget,
            color: Color.Resolved,
            supportsOpacity: Bool,
            environment: EnvironmentValues,
            onChange: @escaping (Color.Resolved) -> Void
        )
    }
}
