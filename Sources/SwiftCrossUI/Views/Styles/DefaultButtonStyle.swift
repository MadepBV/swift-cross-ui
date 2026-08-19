/// The button style that reflects the platform's default.
///
/// Buttons under this style look however the current backend draws an
/// undecorated button, which is what a button with no style modifier at all
/// looks like.
///
/// ## See Also
///
/// - ``ButtonStyle``
/// - ``View/buttonStyle(_:)``
public struct DefaultButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    /// Creates the style.
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind { .bordered }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == DefaultButtonStyle {
    /// The button style that reflects the platform's default.
    public static nonisolated var automatic: Self { Self() }
}
