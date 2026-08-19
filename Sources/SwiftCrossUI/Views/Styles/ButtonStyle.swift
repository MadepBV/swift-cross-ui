/// A type that applies standard interaction behavior and a custom appearance
/// to all buttons within a view hierarchy.
///
/// Apply a button style with ``View/buttonStyle(_:)``. The style propagates
/// through the environment, so it affects every ``Button`` nested inside the
/// modified view.
///
/// ```swift
/// Button("Extrude") {
///     extrude()
/// }
/// .buttonStyle(.borderedProminent)
/// ```
///
/// ## Custom styles
///
/// Conform to this protocol to define your own style. The button hands its
/// label to ``ButtonStyle/makeBody(configuration:)`` as a
/// ``ButtonStyleConfiguration``, leaving the style free to decorate it however
/// it likes.
///
/// ```swift
/// struct RowButtonStyle: ButtonStyle {
///     var isSelected: Bool
///
///     func makeBody(configuration: Configuration) -> some View {
///         configuration.label
///             .padding(.vertical, 4)
///             .padding(.horizontal, 6)
///             .background(
///                 isSelected ? Color.accentColor.opacity(0.16) : .clear,
///                 in: RoundedRectangle(cornerRadius: 6)
///             )
///     }
/// }
/// ```
///
/// A button under a custom style is drawn without any of the backend's own
/// chrome, exactly as SwiftUI does it, so the style's body is the whole
/// appearance of the button.
///
/// ## See Also
///
/// - ``Button``
/// - ``View/buttonStyle(_:)``
/// - ``ButtonStyleConfiguration``
@MainActor
public protocol ButtonStyle: Sendable {
    /// A view that represents the body of a button.
    associatedtype Body: View

    /// Creates a view that represents the body of a button.
    ///
    /// Called for every ``Button`` in the hierarchy that the style applies to.
    ///
    /// - Parameter configuration: The label and role of the button being
    ///   styled.
    /// - Returns: The button's rendered form.
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body

    /// The properties of the button being styled.
    typealias Configuration = ButtonStyleConfiguration
}

extension ButtonStyle {
    /// The chrome that a backend draws for a button style.
    ///
    /// Spelled as a member of ``ButtonStyle`` so that backends can keep
    /// writing `ButtonStyle.Kind`.
    package typealias Kind = ButtonStyleKind

    /// The chrome that backends should draw behind a button using this style.
    ///
    /// A style defined outside of SwiftCrossUI draws its entire appearance
    /// from ``ButtonStyle/makeBody(configuration:)``, so backends are asked
    /// for ``ButtonStyleKind/plain`` — no chrome at all — and the style
    /// supplies everything the user sees.
    package var kind: ButtonStyleKind {
        guard let builtin = self as? any _BuiltinButtonStyle else {
            return .plain
        }
        return builtin.builtinKind
    }
}
