/// A button style that doesn't decorate its content while idle.
///
/// The backend may still apply a visual effect to indicate the button's
/// pressed, focused, or disabled state.
///
/// ## See Also
///
/// - ``ButtonStyle``
/// - ``View/buttonStyle(_:)``
public struct PlainButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    /// Creates the style.
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind { .plain }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == PlainButtonStyle {
    /// A button style that doesn't decorate its content while idle.
    public static nonisolated var plain: Self { Self() }
}
