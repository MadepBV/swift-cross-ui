/// A ``SymbolProvider`` that tries one provider and falls back to another.
///
/// This is how a platform with native symbols keeps full coverage: ask the
/// native library first, and let the bundled Lucide geometry answer whatever
/// it doesn't recognise.
///
/// ```swift
/// ContentView()
///     .symbolProvider(
///         FallbackSymbolProvider(
///             MyNativeSymbolProvider(),
///             fallingBackTo: LucideSymbolProvider.shared
///         )
///     )
/// ```
public struct FallbackSymbolProvider: SymbolProvider {
    /// The provider consulted first.
    public var primary: any SymbolProvider
    /// The provider consulted when ``primary`` returns `nil`.
    public var fallback: any SymbolProvider

    /// Creates a provider that chains two providers together.
    ///
    /// - Parameters:
    ///   - primary: The provider consulted first.
    ///   - fallback: The provider consulted when `primary` returns `nil`.
    public init(
        _ primary: any SymbolProvider,
        fallingBackTo fallback: any SymbolProvider
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    public func resolve(_ request: SymbolRenderRequest) -> SymbolResolution? {
        primary.resolve(request) ?? fallback.resolve(request)
    }
}
