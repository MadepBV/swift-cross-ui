/// A variant of a symbol: filled, enclosed in a shape, or slashed.
///
/// Set with ``View/symbolVariant(_:)``; every ``Image/init(systemName:)``
/// inside draws the variant's name, so `Image(systemName: "heart")` under
/// `.symbolVariant(.fill)` draws `heart.fill`, as in SwiftUI.
///
/// A provider with no drawing for the variant's name treats it like any
/// other unknown name. The bundled ``LucideSymbolProvider`` falls back from a
/// missing `.fill` variant to the outline, so ``SymbolVariants/fill`` is
/// always safe to apply.
public struct SymbolVariants: Hashable, Sendable {
    /// The enclosing shape, if any (`circle`, `square` or `rectangle`).
    private var shape: String?
    /// Whether the symbol is slashed.
    private var isSlashed = false
    /// Whether the symbol is filled.
    private var isFilled = false

    /// No variant: the symbol as named.
    public static let none = SymbolVariants()
    /// The filled variant.
    public static let fill = SymbolVariants(isFilled: true)
    /// The variant enclosed in a circle.
    public static let circle = SymbolVariants(shape: "circle")
    /// The variant enclosed in a square.
    public static let square = SymbolVariants(shape: "square")
    /// The variant enclosed in a rectangle.
    public static let rectangle = SymbolVariants(shape: "rectangle")
    /// The slashed variant.
    public static let slash = SymbolVariants(isSlashed: true)

    /// This variant, filled.
    public var fill: SymbolVariants {
        var variants = self
        variants.isFilled = true
        return variants
    }

    /// This variant, enclosed in a circle.
    public var circle: SymbolVariants { enclosed(in: "circle") }
    /// This variant, enclosed in a square.
    public var square: SymbolVariants { enclosed(in: "square") }
    /// This variant, enclosed in a rectangle.
    public var rectangle: SymbolVariants { enclosed(in: "rectangle") }

    /// This variant, slashed.
    public var slash: SymbolVariants {
        var variants = self
        variants.isSlashed = true
        return variants
    }

    /// Whether this set includes every variant in `other`.
    ///
    /// - Parameter other: The variants to look for.
    /// - Returns: `true` if every variant of `other` is part of this set.
    public func contains(_ other: SymbolVariants) -> Bool {
        (other.shape == nil || other.shape == shape)
            && (!other.isSlashed || isSlashed)
            && (!other.isFilled || isFilled)
    }

    private func enclosed(in shape: String) -> SymbolVariants {
        var variants = self
        variants.shape = shape
        return variants
    }

    /// The name of `name`'s symbol in this variant, in Apple's order
    /// (`heart.slash.circle.fill`, for example).
    ///
    /// Components the name already carries aren't repeated, so
    /// `"heart.fill"` stays `"heart.fill"` under ``SymbolVariants/fill``.
    ///
    /// - Parameter name: The symbol name the image was created with.
    /// - Returns: The variant's symbol name.
    func applied(to name: String) -> String {
        var components = name.split(separator: ".").map(String.init)
        func append(_ component: String) {
            if !components.contains(component) {
                components.append(component)
            }
        }
        if isSlashed {
            append("slash")
        }
        if let shape {
            append(shape)
        }
        if isFilled {
            // `fill` is always last in an SF Symbol name.
            components.removeAll { $0 == "fill" }
            components.append("fill")
        }
        return components.joined(separator: ".")
    }
}

/// How a symbol's layers are coloured.
///
/// - Note: SwiftCrossUI's symbols are single-layer outlines (see
///   ``LucideSymbolProvider``), so every mode draws as ``monochrome``, in the
///   foreground colour. The value is kept in the environment so a custom
///   ``SymbolProvider`` can read it.
public struct SymbolRenderingMode: Hashable, Sendable {
    private let name: String

    /// One colour for every layer.
    public static let monochrome = SymbolRenderingMode(name: "monochrome")
    /// The symbol's own colours.
    public static let multicolor = SymbolRenderingMode(name: "multicolor")
    /// Layers at decreasing opacities of one colour.
    public static let hierarchical = SymbolRenderingMode(name: "hierarchical")
    /// A colour per layer, from the foreground styles.
    public static let palette = SymbolRenderingMode(name: "palette")
}

extension EnvironmentValues {
    /// The symbol variants set by ``View/symbolVariant(_:)``.
    @Entry public var symbolVariants: SymbolVariants = .none

    /// The symbol rendering mode set by ``View/symbolRenderingMode(_:)``.
    @Entry public var symbolRenderingMode: SymbolRenderingMode?
}

extension View {
    /// Draws the symbols inside this view in the given variant.
    ///
    /// ```swift
    /// Image(systemName: "heart")
    ///     .symbolVariant(isLiked ? .fill : .none)
    /// ```
    ///
    /// - Parameter variant: The variant to draw.
    /// - Returns: A view whose symbols use `variant`.
    public func symbolVariant(_ variant: SymbolVariants) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.symbolVariants, variant)
        }
    }

    /// Sets how the symbols inside this view colour their layers.
    ///
    /// - Note: Recorded but drawn as monochrome; see ``SymbolRenderingMode``.
    ///
    /// - Parameter mode: The rendering mode. `nil` restores the default.
    /// - Returns: A view whose symbols use `mode`.
    public func symbolRenderingMode(_ mode: SymbolRenderingMode?) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.symbolRenderingMode, mode)
        }
    }
}

extension Image {
    /// Sets how this symbol colours its layers.
    ///
    /// Returns an ``Image`` so that image modifiers such as ``resizable()``
    /// can follow. See ``View/symbolRenderingMode(_:)``.
    ///
    /// - Note: Recorded on SwiftUI's terms only: SwiftCrossUI draws every
    ///   symbol as monochrome; see ``SymbolRenderingMode``.
    ///
    /// - Parameter mode: The rendering mode.
    /// - Returns: The image.
    public func symbolRenderingMode(_ mode: SymbolRenderingMode?) -> Image {
        self
    }
}
