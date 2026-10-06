/// The neutral fill of a shape that sits on content, such as a placeholder
/// or the track of a control.
///
/// Reached as `.fill`, with lighter levels at `.fill.secondary`,
/// `.fill.tertiary` and `.fill.quaternary`:
///
/// ```swift
/// RoundedRectangle(cornerRadius: 8)
///     .fill(.fill.tertiary)
/// ```
///
/// The colours are Apple's `systemFill` family: a cool grey whose opacity
/// steps down with each level, and which is stronger in dark mode so it stays
/// visible against a dark background.
public struct FillShapeStyle: ShapeStyle, Hashable {
    private let level: Color.HierarchicalLevel

    private init(level: Color.HierarchicalLevel) {
        self.level = level
    }

    /// The primary fill.
    public static let primary = FillShapeStyle(level: .primary)

    /// The secondary fill level.
    public var secondary: FillShapeStyle { FillShapeStyle(level: .secondary) }
    /// The tertiary fill level.
    public var tertiary: FillShapeStyle { FillShapeStyle(level: .tertiary) }
    /// The quaternary fill level.
    public var quaternary: FillShapeStyle { FillShapeStyle(level: .quaternary) }
    /// The quinary fill level.
    public var quinary: FillShapeStyle { FillShapeStyle(level: .quinary) }

    public var _color: Color {
        let (light, dark): (Double, Double) =
            switch level {
                case .primary: (0.2, 0.36)
                case .secondary: (0.16, 0.32)
                case .tertiary: (0.12, 0.24)
                case .quaternary: (0.08, 0.18)
                case .quinary: (0.05, 0.1)
            }
        return Color.adaptive(
            light: Color(red: 0.471, green: 0.471, blue: 0.502, opacity: light),
            dark: Color(red: 0.471, green: 0.471, blue: 0.502, opacity: dark)
        )
    }
}

extension ShapeStyle where Self == FillShapeStyle {
    /// The neutral fill for shapes on content. See ``FillShapeStyle``.
    public static var fill: FillShapeStyle { .primary }
}
