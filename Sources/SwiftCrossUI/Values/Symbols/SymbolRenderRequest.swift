/// Everything a ``SymbolProvider`` needs to know to resolve a symbol.
///
/// A provider that returns vector geometry can ignore everything but
/// ``name``. The size and tint are supplied for providers that rasterise --
/// a future Apple backend resolving real SF Symbols, for example -- so that
/// they can render at the right size and colour without a second round trip.
public struct SymbolRenderRequest: Equatable, Sendable {
    /// The requested symbol's name, in Apple's SF Symbols spelling.
    ///
    /// For example `"square.and.arrow.up"`.
    public var name: String
    /// The symbol's intended side length in points, before accounting for
    /// ``scaleFactor``.
    public var pointSize: Double
    /// The scale factor of the window the symbol will be shown in.
    ///
    /// A provider that produces pixels should render at
    /// `pointSize * scaleFactor` pixels per side.
    public var scaleFactor: Double
    /// The colour the symbol should be tinted with.
    public var color: Color

    /// Creates a symbol render request.
    ///
    /// - Parameters:
    ///   - name: The symbol's name, in Apple's SF Symbols spelling.
    ///   - pointSize: The symbol's intended side length in points.
    ///   - scaleFactor: The scale factor of the destination window.
    ///   - color: The colour the symbol should be tinted with.
    public init(
        name: String,
        pointSize: Double,
        scaleFactor: Double = 1,
        color: Color = .black
    ) {
        self.name = name
        self.pointSize = pointSize
        self.scaleFactor = scaleFactor
        self.color = color
    }
}
