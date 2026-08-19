/// A control for toggling between two values (usually representing on and off).
///
/// Depending on the value of ``EnvironmentValues/toggleStyle``, this control
/// can appear as a switch, a button, or a checkbox.
///
/// ```swift
/// Toggle("Show grid", isOn: $isShowingGrid)
///
/// Toggle(isOn: $isShowingGrid) {
///     HStack {
///         Image(systemName: "square.grid.2x2")
///         Text("Show grid")
///     }
/// }
/// ```
public struct Toggle: View {
    @Environment(\.backend) var backend
    @Environment(\.toggleStyle) var toggleStyle

    /// The label to be shown on or beside the toggle.
    ///
    /// This is the empty string when the toggle was created with a custom
    /// label view whose text content couldn't be determined.
    var label: String
    /// A custom label view shown in place of ``label``, if there is one.
    ///
    /// Only set when the custom label isn't simply text; a textual custom
    /// label gets reduced to ``label`` so that toggles created either way
    /// render identically.
    var customLabel: AnyView?
    /// Whether the toggle is active or not.
    var active: Binding<Bool>

    @available(*, deprecated, renamed: "init(_:isOn:)")
    public init(_ label: String, active: Binding<Bool>) {
        self.init(label, isOn: active)
    }

    /// Creates a toggle that displays a text label.
    ///
    /// - Parameters:
    ///   - label: The label to be shown on or beside the toggle.
    ///   - active: Whether the toggle is active or not.
    public init(_ label: String, isOn active: Binding<Bool>) {
        self.label = label
        self.customLabel = nil
        self.active = active
    }

    /// Creates a toggle that displays a custom label view.
    ///
    /// - Note: Under ``ToggleStyle/button`` the label is normally rendered by
    ///   the backend's native toggle button widget, which only accepts a
    ///   plain string. A custom label that isn't text therefore falls back to
    ///   an ordinary ``Button``, which can't show the toggle's state. The
    ///   same string-only limitation applies to toggles used as menu items.
    ///   Textual labels (the common case) are unaffected, and render exactly
    ///   as they would have via ``Toggle/init(_:isOn:)``.
    ///
    /// - Parameters:
    ///   - active: Whether the toggle is active or not.
    ///   - label: A view describing the purpose of the toggle.
    public init<Label: View>(
        isOn active: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        let labelView = label()
        if let string = Self.textContent(of: labelView) {
            self.label = string
            self.customLabel = nil
        } else {
            self.label = ""
            self.customLabel = AnyView(labelView)
        }
        self.active = active
    }

    /// Extracts the text content of a label view, if it's simply text.
    ///
    /// ``ViewBuilder`` wraps a lone view in a ``TupleView1``, hence the
    /// second case.
    ///
    /// - Parameter view: The label view to inspect.
    /// - Returns: The view's text content, or `nil` if it isn't just text.
    private static func textContent<Label: View>(of view: Label) -> String? {
        if let text = view as? Text {
            return text.string
        }
        if let wrapped = view as? TupleView1<Text> {
            return wrapped.view0.string
        }
        return nil
    }

    /// The custom label view if there is one, and the toggle's text otherwise.
    @ViewBuilder
    private var labelContent: some View {
        if let customLabel {
            customLabel
        } else {
            Text(label)
        }
    }

    public var body: some View {
        switch toggleStyle.style {
            case .switch:
                HStack {
                    labelContent

                    if backend.requiresToggleSwitchSpacer {
                        Spacer()
                    }

                    ToggleSwitch(isOn: active)
                }
            case .button:
                if let customLabel {
                    // The backends' toggle button widget takes a plain string
                    // label, so a custom label has to fall back to an ordinary
                    // button. That button can't show the toggle's state, which
                    // is why textual custom labels are reduced to `label` at
                    // initialization rather than taking this path.
                    Button(
                        action: { active.wrappedValue.toggle() },
                        label: { customLabel }
                    )
                } else {
                    ToggleButton(label, isOn: active)
                }
            case .checkbox:
                HStack {
                    labelContent

                    Checkbox(isOn: active)
                }
        }
    }

    public var _asMenuItems: [MenuItem] {
        [.toggle(self)]
    }
}

/// A style of toggle.
public struct ToggleStyle: Sendable {
    @_spi(Backends) public var style: Style

    /// A toggle switch.
    public static let `switch` = Self(style: .switch)
    /// A toggle button. Generally looks like a regular button when off and an
    /// accented button when on.
    public static let button = Self(style: .button)
    /// A checkbox.
    public static let checkbox = Self(style: .checkbox)

    @_spi(Backends) public enum Style: Sendable {
        case `switch`
        case button
        case checkbox
    }
}
