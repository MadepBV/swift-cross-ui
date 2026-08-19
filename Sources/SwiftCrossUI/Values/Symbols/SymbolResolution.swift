import ImageFormats

/// The outcome of asking a ``SymbolProvider`` to resolve a symbol.
///
/// The two cases exist so that platforms with a native symbol library can
/// bypass the bundled geometry entirely. SwiftCrossUI draws
/// ``SymbolResolution/geometry(_:)`` itself using the backend's path support,
/// and hands ``SymbolResolution/image(_:)`` straight to the backend's image
/// view -- the same route ``Image/init(_:useFileExtension:)`` already takes.
public enum SymbolResolution: Sendable {
    /// Vector geometry for SwiftCrossUI to draw.
    ///
    /// The geometry is tinted with the environment's foreground colour and
    /// scaled to whatever size the view ends up with.
    case geometry(SymbolGeometry)
    /// Pixel data the provider rendered for the request.
    ///
    /// Providers backed by a platform symbol library (such as AppKit's real
    /// SF Symbols) can rasterise at
    /// ``SymbolRenderRequest/pointSize`` times
    /// ``SymbolRenderRequest/scaleFactor`` and return the result here.
    case image(ImageFormats.Image<RGBA>)
}
