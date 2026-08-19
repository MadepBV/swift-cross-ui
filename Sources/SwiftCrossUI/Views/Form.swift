/// A container view that groups controls used for data entry.
///
/// A form stacks its rows vertically with consistent spacing and, depending on
/// the ``EnvironmentValues/formStyle`` in effect, insets and groups them. Rows
/// are usually ``Section``s, ``LabeledContent``s, or plain controls.
///
/// ```swift
/// Form {
///     Section("Drafting parameters") {
///         LabeledContent("Diameter", value: diameter)
///     }
///     Section("Annotations") {
///         LabeledContent("Text height", value: textHeight)
///     }
/// }
/// .formStyle(.grouped)
/// ```
///
/// ## Scrolling
///
/// Like SwiftUI's form, a form scrolls vertically when its content is taller
/// than the space it's given, so rows below the fold stay reachable. This also
/// means that a form is greedy along the vertical axis, just like a
/// ``ScrollView``; constrain it with a `frame` modifier if you need it to take
/// up less than the full height of its container.
///
/// A form nested within a ``ScrollView`` that scrolls along the same axis
/// doesn't scroll independently. The outer scroll view proposes an unspecified
/// height to its content, which makes the form's own scroll view transparent
/// and lets it report its full intrinsic height to the outer scroll view. That
/// falls out of the layout system rather than being special cased, so it also
/// holds for any other container that proposes an unspecified height (such as
/// ``View/fixedSize()``).
public struct Form<Content: View>: View {
    /// The form's rows.
    private var content: Content

    /// The style to lay the form out with.
    @Environment(\.formStyle) private var formStyle

    /// Creates a form.
    ///
    /// - Parameter content: The form's rows.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: formStyle.formRowSpacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(formStyle.formPadding)
        }
        .environment(\.isInsideForm, true)
    }
}

extension EnvironmentValues {
    /// Whether the current view is a descendant of a ``Form``.
    ///
    /// ``Section`` uses this to decide whether to expand to the full width of
    /// its container, matching the way SwiftUI's form rows fill their row.
    @Entry var isInsideForm: Bool = false
}
