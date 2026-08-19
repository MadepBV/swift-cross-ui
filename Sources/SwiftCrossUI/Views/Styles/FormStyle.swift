/// A type that specifies the appearance of all forms within a view hierarchy.
///
/// Apply a form style with ``View/formStyle(_:)``. The style propagates
/// through the environment, so every ``Form`` and ``Section`` beneath the
/// modified view picks it up.
///
/// ```swift
/// Form {
///     Section("Drafting parameters") {
///         Toggle("Snap to grid", active: $snapToGrid)
///     }
/// }
/// .formStyle(.grouped)
/// ```
///
/// ## Custom styles
///
/// Conform to this protocol to define your own style. The form hands its rows
/// to ``FormStyle/makeBody(configuration:)`` as a ``FormStyleConfiguration``,
/// leaving the style in charge of laying them out.
///
/// ```swift
/// struct BorderedFormStyle: FormStyle {
///     func makeBody(configuration: Configuration) -> some View {
///         VStack(alignment: .leading, spacing: 12) {
///             configuration.content
///         }
///         .padding(8)
///     }
/// }
///
/// extension FormStyle where Self == BorderedFormStyle {
///     static var bordered: Self { Self() }
/// }
/// ```
///
/// ## See Also
///
/// - ``Form``
/// - ``View/formStyle(_:)``
/// - ``FormStyleConfiguration``
@MainActor
public protocol FormStyle: Sendable {
    /// A view that represents the body of a form.
    associatedtype Body: View

    /// Creates a view that represents the body of a form.
    ///
    /// - Parameter configuration: The rows of the form being styled.
    /// - Returns: The form's rendered form.
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body

    /// The properties of the form being styled.
    typealias Configuration = FormStyleConfiguration
}
