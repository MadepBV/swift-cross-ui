/// A button style that doesn't apply a border.
///
/// On desktop operating systems it behaves mostly the same as
/// ``ButtonStyle/plain``, matching SwiftUI's borderless behaviour on macOS.
/// The only difference is a default foreground colour of grey.
///
/// ## See Also
///
/// - ``ButtonStyle``
/// - ``View/buttonStyle(_:)``
public struct BorderlessButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    /// Creates the style.
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind { .borderless }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == BorderlessButtonStyle {
    /// A button style that doesn't apply a border.
    public static nonisolated var borderless: Self { Self() }
}
