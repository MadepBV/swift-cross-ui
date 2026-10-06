/// A button style that draws the button on Liquid Glass.
///
/// Spelled `.glass`, as in SwiftUI:
///
/// ```swift
/// Button("Sign in") { signIn() }
///     .buttonStyle(.glass)
/// ```
///
/// ## Appearance
///
/// Liquid Glass is Apple's refracting material and exists only on Apple
/// platforms. Elsewhere the style draws the platform's standard bordered
/// button, which is the closest native counterpart: on Windows that is the
/// WinUI button, whose translucent fill and hairline border are Fluent's
/// equivalent of a glass control.
public struct GlassButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind { .bordered }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// A button style that draws the button on prominent, tinted Liquid Glass.
///
/// Spelled `.glassProminent`. Drawn like ``BorderedProminentButtonStyle``;
/// see ``GlassButtonStyle`` for how glass maps to each platform.
public struct GlassProminentButtonStyle: ButtonStyle, _BuiltinButtonStyle {
    public nonisolated init() {}

    package nonisolated var builtinKind: ButtonStyleKind {
        BorderedProminentButtonStyle().builtinKind
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    /// A button style that draws the button on Liquid Glass. See
    /// ``GlassButtonStyle``.
    public static nonisolated var glass: Self { Self() }
}

extension ButtonStyle where Self == GlassProminentButtonStyle {
    /// A button style that draws the button on prominent Liquid Glass. See
    /// ``GlassProminentButtonStyle``.
    public static nonisolated var glassProminent: Self { Self() }
}
