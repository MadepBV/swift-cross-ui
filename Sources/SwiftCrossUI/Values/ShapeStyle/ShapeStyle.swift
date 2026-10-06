/// A colour or pattern to use when rendering a shape or foreground content.
///
/// This is the type behind the arguments of ``View/foregroundStyle(_:)-(ShapeStyle)``,
/// ``Shape/fill(_:)-(ShapeStyle)``, ``View/background(_:in:fillStyle:)`` and
/// ``View/tint(_:)-(ShapeStyle?)``, so SwiftUI call sites such as
/// `.background(.thinMaterial, in: Capsule())` and `.fill(.fill.tertiary)`
/// compile unchanged.
///
/// ## How styles are drawn
///
/// Every style SwiftCrossUI paints with reduces to a ``Color``. That is not
/// as limiting as it sounds, because a ``Color`` already resolves late, in the
/// environment of the view drawing it: adaptive colours follow the colour
/// scheme, hierarchical levels such as ``Color/secondary`` follow the current
/// foreground style, and ``Color/tint`` follows ``View/tint(_:)-(Color?)``.
///
/// What a colour cannot express is drawn as the closest colour instead, and
/// each such style says so: materials are translucent neutrals without blur
/// (see ``Material``), and gradients are views (``LinearGradient``) rather than
/// styles.
///
/// ## Conforming types
///
/// A custom style supplies the colour it paints with:
///
/// ```swift
/// struct Warning: ShapeStyle {
///     var _color: Color { .orange.opacity(0.8) }
/// }
/// ```
public protocol ShapeStyle: Sendable {
    /// The colour this style paints with.
    ///
    /// The colour may itself refer to the environment (it may be adaptive,
    /// hierarchical or the tint); it is resolved where it is drawn.
    var _color: Color { get }
}

extension Color: ShapeStyle {
    public var _color: Color { self }
}

/// A type-erased shape style.
///
/// Use it to choose between styles of different types, exactly as in SwiftUI:
///
/// ```swift
/// var tint: AnyShapeStyle {
///     isWeak ? AnyShapeStyle(.secondary) : AnyShapeStyle(.green)
/// }
/// ```
public struct AnyShapeStyle: ShapeStyle, Hashable {
    public let _color: Color

    /// Creates a type-erased shape style.
    ///
    /// - Parameter style: The style to erase.
    public init<S: ShapeStyle>(_ style: S) {
        _color = style._color
    }
}

extension ShapeStyle {
    /// Returns this style at a lower opacity.
    ///
    /// - Parameter opacity: The opacity multiplier, from 0 to 1.
    /// - Returns: The style, multiplied by `opacity`.
    public func opacity(_ opacity: Double) -> AnyShapeStyle {
        AnyShapeStyle(_color.opacity(opacity))
    }
}

extension EnvironmentValues {
    /// The tint set by ``View/tint(_:)-(Color?)``.
    ///
    /// `nil` means the accent colour. Read through ``Color/tint``.
    @Entry public var tintColor: Color?
}
