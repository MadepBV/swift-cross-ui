// Leading-dot syntax at a `some ShapeStyle` parameter looks for static members
// of `ShapeStyle` itself, not of `Color`. SwiftUI declares its palette with
// `extension ShapeStyle where Self == Color`, and so does SwiftCrossUI; without
// these, `.fill(.white)` and `.background(.black.opacity(0.3), in: Capsule())`
// would not compile even though `Color.white` exists.

extension ShapeStyle where Self == Color {
    /// The current foreground style. See ``Color/primary``.
    public static var primary: Color { Color.primary }
    /// The current foreground style at secondary emphasis.
    public static var secondary: Color { Color.secondary }
    /// The current foreground style at tertiary emphasis.
    public static var tertiary: Color { Color.tertiary }
    /// The current foreground style at quaternary emphasis.
    public static var quaternary: Color { Color.quaternary }
    /// The current foreground style at quinary emphasis.
    public static var quinary: Color { Color.quinary }

    /// The current foreground style.
    ///
    /// SwiftUI spells this `ForegroundStyle`; it is the same colour as
    /// ``Color/primary``.
    public static var foreground: Color { Color.primary }

    /// The current tint. See ``Color/tint``.
    public static var tint: Color { Color.tint }
    /// The app's accent colour. See ``Color/accentColor``.
    public static var accentColor: Color { Color.accentColor }

    /// The colour a window or document draws behind its content.
    ///
    /// - Note: A flat adaptive colour. SwiftUI's `BackgroundStyle` resolves
    ///   against the surrounding container (a sheet, a sidebar and a window
    ///   each give it a different value), which SwiftCrossUI's backends don't
    ///   report.
    public static var background: Color {
        Color.adaptive(light: Color(white: 1.0), dark: Color(white: 0.12))
    }

    /// The colour of separators between content.
    public static var separator: Color {
        Color.adaptive(
            light: Color(white: 0.0, opacity: 0.14),
            dark: Color(white: 1.0, opacity: 0.16)
        )
    }

    public static var black: Color { Color.black }
    public static var white: Color { Color.white }
    public static var clear: Color { Color.clear }
    public static var blue: Color { Color.blue }
    public static var brown: Color { Color.brown }
    public static var cyan: Color { Color.cyan }
    public static var gray: Color { Color.gray }
    public static var green: Color { Color.green }
    public static var indigo: Color { Color.indigo }
    public static var mint: Color { Color.mint }
    public static var orange: Color { Color.orange }
    public static var pink: Color { Color.pink }
    public static var purple: Color { Color.purple }
    public static var red: Color { Color.red }
    public static var teal: Color { Color.teal }
    public static var yellow: Color { Color.yellow }

    /// An adaptive colour tailored to each platform's design guidelines.
    public static func system(_ color: Color.SystemAdaptive) -> Color {
        Color.system(color)
    }

    /// An adaptive colour that changes with the colour scheme.
    public static func adaptive(light: Color, dark: Color) -> Color {
        Color.adaptive(light: light, dark: dark)
    }
}
