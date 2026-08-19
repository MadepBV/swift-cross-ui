/// A form style that ships with SwiftCrossUI, and therefore has layout
/// metrics that ``Section`` can match.
///
/// Mirrors the way ``_BuiltinPickerStyle`` lets ``Picker`` recognise the
/// styles it knows how to render natively. A style defined outside of
/// SwiftCrossUI doesn't conform, so sections fall back to
/// ``FormMetrics/automatic`` beneath it.
package protocol _BuiltinFormStyle {
    /// The metrics that this style lays forms and sections out with.
    var formMetrics: FormMetrics { get }
}

extension _BuiltinFormStyle {
    /// The layout shared by every built-in form style.
    ///
    /// The rows are stacked vertically, inset by the style's padding, and
    /// wrapped in a vertical ``ScrollView`` so that rows below the fold stay
    /// reachable. That also makes the form greedy along the vertical axis,
    /// just like any other scroll view.
    ///
    /// - Parameter configuration: The form being laid out.
    /// - Returns: The form's rendered form.
    @MainActor
    package func makeBuiltinBody(
        configuration: FormStyleConfiguration
    ) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: formMetrics.formRowSpacing) {
                configuration.content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(formMetrics.formPadding)
        }
    }
}
