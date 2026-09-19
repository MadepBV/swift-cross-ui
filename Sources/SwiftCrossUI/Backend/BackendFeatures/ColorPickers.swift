extension BackendFeatures {
    /// Backend methods for color pickers.
    ///
    /// Every desktop platform ships a color picker of its own (`NSColorWell`,
    /// WinUI's `ColorPicker`, `GtkColorButton`), and users expect the one they
    /// know, so this is modelled the same way as
    /// ``BackendFeatures/DatePickers``: the backend supplies the whole control
    /// and SwiftCrossUI just tells it what to display.
    ///
    /// These are used by ``ColorPicker``.
    @MainActor
    public protocol ColorPickers: Core {
        /// Create a color picker widget.
        ///
        /// Predominantly used by ``ColorPicker``.
        func createColorPicker() -> Widget

        /// Update a color picker.
        /// - Parameters:
        ///   - colorPicker: The color picker widget to update.
        ///   - supportsOpacity: If `false`, do not allow the user to change the alpha value of the
        ///     color. If the color provided to ``setValue(ofColorPicker:to:)`` has an alpha value
        ///     less than 1, leave it at that value.
        ///   - environment: The current environment.
        ///   - onChange: The action to perform when the selected color changes. This handler
        ///     replaces any existing change handlers and is called whenever a selection is made,
        ///     even if the same color is picked again.
        func updateColorPicker(
            _ colorPicker: Widget,
            supportsOpacity: Bool,
            environment: EnvironmentValues,
            onChange: @escaping (Color.Resolved) -> Void
        )

        /// Change the color shown by the picker's color swatch.
        func setValue(ofColorPicker colorPicker: Widget, to color: Color.Resolved)
    }
}
