/// The default ``SymbolProvider``, which draws bundled Lucide icons.
///
/// SwiftCrossUI ships the vector geometry of every [Lucide](https://lucide.dev)
/// icon that an SF Symbol name in its table maps to, generated into Swift
/// source by `Scripts/generate-symbol-geometry.py`. Nothing is loaded from
/// disk and no SVG is parsed at runtime, so symbols cost nothing to start up
/// and stay sharp at any size.
///
/// Lucide is a stroke-only set with no filled counterparts, so SF Symbol
/// names ending in `.fill` resolve to the same outline icon as their unfilled
/// siblings.
///
/// ## Unknown names
///
/// A name the table doesn't cover resolves to a deliberately generic
/// placeholder (a dashed square) rather than to nothing and rather than to a
/// guess. A reader can tell an icon is missing; they can't tell that a
/// confidently-drawn wrong icon is wrong. Set
/// ``LucideSymbolProvider/drawsPlaceholderForUnknownNames`` to `false` to get
/// `nil` back instead, which makes ``Image`` render nothing at all.
public struct LucideSymbolProvider: SymbolProvider {
    /// The shared instance used when no other provider is installed.
    public static let shared = LucideSymbolProvider()

    /// Whether unknown symbol names resolve to a generic placeholder icon.
    ///
    /// `true` by default. When `false`, ``resolve(_:)`` returns `nil` for
    /// names outside the mapping table.
    public var drawsPlaceholderForUnknownNames: Bool

    /// Creates a Lucide-backed symbol provider.
    ///
    /// - Parameter drawsPlaceholderForUnknownNames: Whether unknown names
    ///   resolve to a generic placeholder icon instead of to `nil`.
    public init(drawsPlaceholderForUnknownNames: Bool = true) {
        self.drawsPlaceholderForUnknownNames = drawsPlaceholderForUnknownNames
    }

    /// Every SF Symbol name this provider can draw, sorted.
    public static var systemNames: [String] {
        SFSymbolLucideMapping.systemNames
    }

    /// The Lucide icon drawn in place of an SF Symbol.
    ///
    /// A name the table doesn't list is retried with any trailing `.fill`
    /// removed, since Lucide draws filled and unfilled symbols identically
    /// anyway.
    ///
    /// - Parameter name: An SF Symbol name.
    /// - Returns: A kebab-case Lucide icon name, or `nil` if the symbol isn't
    ///   in the mapping table.
    public static func lucideIcon(forSystemName name: String) -> String? {
        if let icon = SFSymbolLucideMapping.lucideIcon(forSystemName: name) {
            return icon
        }
        guard name.hasSuffix(Self.fillSuffix) else {
            return nil
        }
        let unfilled = String(name.dropLast(Self.fillSuffix.count))
        return SFSymbolLucideMapping.lucideIcon(forSystemName: unfilled)
    }

    /// The suffix Apple uses for a symbol's filled variant.
    private static let fillSuffix = ".fill"

    public func resolve(_ request: SymbolRenderRequest) -> SymbolResolution? {
        let icon =
            Self.lucideIcon(forSystemName: request.name)
            ?? (drawsPlaceholderForUnknownNames
                ? SFSymbolLucideMapping.placeholderIcon
                : nil)
        guard
            let icon,
            let geometry = LucideIconGeometry.geometry(forIcon: icon)
        else {
            return nil
        }
        return .geometry(geometry)
    }
}
