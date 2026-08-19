/// Resolves SF Symbol names into something SwiftCrossUI can draw.
///
/// ``Image/init(systemName:)`` accepts Apple's SF Symbol names so that
/// SwiftUI source compiles unchanged everywhere, but SF Symbols themselves
/// are an Apple-only font. A symbol provider is the seam between the name and
/// the pixels, so that each platform can answer in the way that suits it:
///
/// - The default, ``LucideSymbolProvider``, returns bundled vector geometry
///   from the [Lucide](https://lucide.dev) icon set. It needs no platform
///   support beyond the backend's path drawing, so it works on Windows,
///   Linux, and anywhere else.
/// - A provider backed by a platform symbol library can return
///   ``SymbolResolution/image(_:)`` instead. On Apple platforms that means
///   real SF Symbols, resolved natively and rasterised at the requested size.
///
/// Install a provider with ``View/symbolProvider(_:)``:
///
/// ```swift
/// ContentView()
///     .symbolProvider(MyNativeSymbolProvider())
/// ```
///
/// A provider that only handles some names should return `nil` for the rest;
/// see ``FallbackSymbolProvider`` for chaining one provider behind another.
///
/// ## See Also
///
/// - ``SymbolResolution``
/// - ``SymbolGeometry``
/// - ``EnvironmentValues/symbolProvider``
public protocol SymbolProvider: Sendable {
    /// Resolves a symbol.
    ///
    /// - Parameter request: The symbol's name and the size and tint it will
    ///   be drawn at. Providers that return vector geometry can ignore
    ///   everything but ``SymbolRenderRequest/name``.
    /// - Returns: How to draw the symbol, or `nil` if this provider doesn't
    ///   know the name.
    func resolve(_ request: SymbolRenderRequest) -> SymbolResolution?
}

/// An environment key holding the symbol provider in effect.
struct SymbolProviderKey: EnvironmentKey {
    static var defaultValue: any SymbolProvider {
        LucideSymbolProvider.shared
    }
}

extension EnvironmentValues {
    /// The provider used to resolve ``Image/init(systemName:)`` names.
    ///
    /// Defaults to ``LucideSymbolProvider/shared``. Set it with
    /// ``View/symbolProvider(_:)`` rather than assigning to it directly.
    public var symbolProvider: any SymbolProvider {
        get { self[SymbolProviderKey.self] }
        set { self[SymbolProviderKey.self] = newValue }
    }
}
