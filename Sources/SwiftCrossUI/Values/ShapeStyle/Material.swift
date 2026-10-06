/// A background material: a translucent layer that lets content behind it
/// show through.
///
/// ```swift
/// Image(systemName: "play.fill")
///     .padding()
///     .background(.thinMaterial, in: Circle())
/// ```
///
/// ## Fidelity
///
/// On Apple platforms a material blurs and vibrancy-adjusts what lies behind
/// it. SwiftCrossUI's backends expose no backdrop blur (WinUI's acrylic brush
/// and AppKit's visual effect view are both window-compositor features that a
/// colour cannot reach), so each material draws as a translucent neutral of
/// the matching weight in the current colour scheme. Thicker materials are
/// more opaque, so the relative legibility of content placed on them holds.
public struct Material: ShapeStyle, Hashable {
    /// How much of the content behind shows through, from 0 to 1.
    private let opacity: Double

    private init(opacity: Double) {
        self.opacity = opacity
    }

    /// A mostly translucent material.
    public static let ultraThin = Material(opacity: 0.45)
    /// A more translucent than opaque material.
    public static let thin = Material(opacity: 0.6)
    /// A material that is somewhat translucent.
    public static let regular = Material(opacity: 0.75)
    /// A mostly opaque material.
    public static let thick = Material(opacity: 0.85)
    /// A material that is almost opaque.
    public static let ultraThick = Material(opacity: 0.93)
    /// The material of a toolbar or tab bar.
    public static let bar = Material(opacity: 0.85)

    public var _color: Color {
        Color.adaptive(
            light: Color(white: 0.97, opacity: opacity),
            dark: Color(white: 0.14, opacity: opacity)
        )
    }
}

extension ShapeStyle where Self == Material {
    /// A mostly translucent material. See ``Material``.
    public static var ultraThinMaterial: Material { .ultraThin }
    /// A more translucent than opaque material. See ``Material``.
    public static var thinMaterial: Material { .thin }
    /// A material that is somewhat translucent. See ``Material``.
    public static var regularMaterial: Material { .regular }
    /// A mostly opaque material. See ``Material``.
    public static var thickMaterial: Material { .thick }
    /// A material that is almost opaque. See ``Material``.
    public static var ultraThickMaterial: Material { .ultraThick }
    /// The material of a toolbar or tab bar. See ``Material``.
    public static var bar: Material { .bar }
}
