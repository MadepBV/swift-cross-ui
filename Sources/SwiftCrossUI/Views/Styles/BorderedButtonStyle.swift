/// A button style that applies the standard border for the button's context.
///
/// This is the default on desktop backends.
///
/// ## See Also
///
/// - ``ButtonStyle``
/// - ``View/buttonStyle(_:)``
@available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, *)
public struct BorderedButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    /// Creates the style.
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind { .bordered }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == BorderedButtonStyle {
    /// A button style that applies the standard border for the button's
    /// context.
    @available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, *)
    public static nonisolated var bordered: Self { Self() }
}
