/// A button style for buttons that navigate somewhere, drawn like a link.
///
/// SwiftCrossUI currently renders this identically to
/// ``ButtonStyle/borderless``; no backend exposes native link chrome. Apply
/// ``View/foregroundColor(_:)`` to the label for an accent-coloured link.
///
/// ## See Also
///
/// - ``ButtonStyle``
/// - ``View/buttonStyle(_:)``
public struct LinkButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    /// Creates the style.
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind { .borderless }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == LinkButtonStyle {
    /// A button style for buttons that navigate somewhere, drawn like a link.
    public static nonisolated var link: Self { Self() }
}
