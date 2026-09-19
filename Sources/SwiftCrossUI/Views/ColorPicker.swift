/// A control that lets the user pick a color.
///
/// The control itself comes from the backend, so users get the color picker
/// their platform ships (`NSColorWell` on macOS, WinUI's `ColorPicker` on
/// Windows, `GtkColorButton` on Gtk).
///
/// ```swift
/// ColorPicker("Layer colour", selection: $layerColor)
/// ```
///
/// Backends that don't implement ``BackendFeatures/ColorPickers`` render the
/// label alone.
public struct ColorPicker<Label: View> {
    /// The view shown next to the color input.
    private var label: Label
    /// The currently selected color.
    private var selection: Binding<Color>
    /// Whether the user can choose a partially transparent color.
    private var supportsOpacity: Bool
    @Environment(\.labelsHidden) private var labelsHidden

    /// Displays a color input with a custom label.
    ///
    /// - Parameters:
    ///   - selection: The currently selected color.
    ///   - supportsOpacity: Whether the user can adjust the color's opacity.
    ///     Backends that can't hide their opacity control clamp the chosen
    ///     opacity to 1 instead.
    ///   - label: The view to show next to the color input.
    public nonisolated init(
        selection: Binding<Color>,
        supportsOpacity: Bool = true,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.selection = selection
        self.supportsOpacity = supportsOpacity
    }

    /// Displays a color input with a textual label.
    ///
    /// - Parameters:
    ///   - label: The text to show next to the color input.
    ///   - selection: The currently selected color.
    ///   - supportsOpacity: Whether the user can adjust the color's opacity.
    public nonisolated init(
        _ label: String,
        selection: Binding<Color>,
        supportsOpacity: Bool = true
    ) where Label == Text {
        self.label = Text(label)
        self.selection = selection
        self.supportsOpacity = supportsOpacity
    }
}

extension ColorPicker: View {
    public var body: some View {
        HStack {
            if !labelsHidden {
                label
            }

            ColorPickerImplementation(
                selection: selection,
                supportsOpacity: supportsOpacity
            )
        }
        .retainingHiddenControlLabel(label, hidden: labelsHidden)
    }
}

/// The backend-provided part of a ``ColorPicker``.
internal struct ColorPickerImplementation: ElementaryView {
    /// The currently selected color.
    @Binding private var selection: Color
    /// Whether the user can choose a partially transparent color.
    private var supportsOpacity: Bool

    /// The size used for the picker when the backend doesn't provide one.
    private static let fallbackSize = ViewSize.zero

    /// Creates the implementation view.
    ///
    /// - Parameters:
    ///   - selection: The currently selected color.
    ///   - supportsOpacity: Whether the user can adjust the color's opacity.
    init(selection: Binding<Color>, supportsOpacity: Bool) {
        self._selection = selection
        self.supportsOpacity = supportsOpacity
    }

    let body = EmptyView()

    func asWidget<Backend: BaseAppBackend>(backend: Backend) -> Backend.Widget {
        // A manual cast rather than @CastBackend, so that backends without
        // color picker support degrade to an empty widget instead of trapping.
        guard
            let pickerBackend = backend as? any BaseAppBackend & BackendFeatures.ColorPickers
        else {
            logger.warnOnce(
                "ColorPicker is unsupported by the current backend; showing its label only"
            )
            return backend.createContainer()
        }

        return Self.createPicker(backend: pickerBackend) as! Backend.Widget
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        guard
            let pickerBackend = backend as? any BaseAppBackend & BackendFeatures.ColorPickers
        else {
            return ViewLayoutResult.leafView(size: Self.fallbackSize)
        }

        Self.updatePicker(
            widget,
            color: selection.resolve(in: environment),
            supportsOpacity: supportsOpacity,
            environment: environment,
            onChange: { newColor in
                selection = Color(newColor)
            },
            backend: pickerBackend
        )

        // Like DatePicker, a color picker's size is dictated by the platform
        // control rather than by the proposal.
        let naturalSize = backend.naturalSize(of: widget)
        return ViewLayoutResult.leafView(size: ViewSize(naturalSize))
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.setSize(of: widget, to: layout.size.vector)
    }

    /// Creates the backend's color picker widget.
    ///
    /// Type-erased at the boundary so that the backend's associated widget type
    /// can be recovered by the generic parameter.
    ///
    /// - Parameter backend: The app's backend.
    /// - Returns: The color picker widget.
    private static func createPicker<
        Backend: BaseAppBackend & BackendFeatures.ColorPickers
    >(
        backend: Backend
    ) -> Any {
        backend.createColorPicker()
    }

    /// Updates the backend's color picker widget.
    ///
    /// - Parameters:
    ///   - widget: The color picker widget.
    ///   - color: The currently selected color.
    ///   - supportsOpacity: Whether the user can adjust the color's opacity.
    ///   - environment: The current environment.
    ///   - onChange: Called whenever the user picks a different color.
    ///   - backend: The app's backend.
    private static func updatePicker<
        Backend: BaseAppBackend & BackendFeatures.ColorPickers
    >(
        _ widget: Any,
        color: Color.Resolved,
        supportsOpacity: Bool,
        environment: EnvironmentValues,
        onChange: @escaping (Color.Resolved) -> Void,
        backend: Backend
    ) {
        backend.updateColorPicker(
            widget as! Backend.Widget,
            color: color,
            supportsOpacity: supportsOpacity,
            environment: environment,
            onChange: onChange
        )
    }
}
