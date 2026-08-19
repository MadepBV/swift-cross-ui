/// A type that applies a custom appearance to all ``Label``s within a view
/// hierarchy.
///
/// Apply a label style with ``View/labelStyle(_:)``. The style propagates
/// through the environment, so it affects every ``Label`` nested inside the
/// modified view, including labels used as the content of controls such as
/// ``Button``.
///
/// ```swift
/// HStack {
///     Label("Duplicate", systemImage: "square.on.square")
///     Label("Delete", systemImage: "trash")
/// }
/// .labelStyle(.iconOnly)
/// ```
///
/// ## Custom styles
///
/// Conform to this protocol to define your own style. The label hands its
/// title and icon to ``LabelStyle/makeBody(configuration:)`` as a
/// ``LabelStyleConfiguration``, leaving the style free to arrange them however
/// it likes.
///
/// ```swift
/// struct VerticalLabelStyle: LabelStyle {
///     func makeBody(configuration: Configuration) -> some View {
///         VStack(spacing: 4) {
///             configuration.icon
///             configuration.title
///         }
///     }
/// }
///
/// extension LabelStyle where Self == VerticalLabelStyle {
///     static var vertical: Self { Self() }
/// }
/// ```
///
/// ## See Also
///
/// - ``Label``
/// - ``View/labelStyle(_:)``
/// - ``LabelStyleConfiguration``
@MainActor
public protocol LabelStyle: Sendable {
    /// A view that represents the body of a label.
    associatedtype Body: View

    /// Creates a view that represents the body of a label.
    ///
    /// Called for every ``Label`` in the hierarchy that the style applies to.
    ///
    /// - Parameter configuration: The title and icon of the label being
    ///   styled.
    /// - Returns: The label's rendered form.
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body

    /// The properties of the label being styled.
    typealias Configuration = LabelStyleConfiguration
}

extension EnvironmentValues {
    /// The display style used by ``Label``.
    ///
    /// Set this with ``View/labelStyle(_:)`` rather than mutating the
    /// environment directly.
    @Entry public var labelStyle: any LabelStyle = .automatic
}
