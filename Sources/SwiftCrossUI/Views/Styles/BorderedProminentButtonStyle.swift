/// A button style that applies a prominent version of the standard border.
///
/// SwiftCrossUI currently renders this identically to
/// ``ButtonStyle/bordered``; no backend exposes a prominent variant of its
/// native button chrome. Use ``View/foregroundColor(_:)`` on the label, or a
/// custom ``ButtonStyle``, if the emphasis has to be visible today.
///
/// ## See Also
///
/// - ``ButtonStyle``
/// - ``View/buttonStyle(_:)``
@available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, *)
public struct BorderedProminentButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    /// Creates the style.
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind { .bordered }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == BorderedProminentButtonStyle {
    /// A button style that applies a prominent version of the standard border.
    @available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, *)
    public static nonisolated var borderedProminent: Self { Self() }
}
