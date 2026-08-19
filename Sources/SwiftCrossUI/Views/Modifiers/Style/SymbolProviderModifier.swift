extension View {
    /// Sets the provider used to resolve ``Image/init(systemName:)`` names
    /// within this view.
    ///
    /// Apply it at the root of an app to change how every symbol in the app
    /// is drawn:
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
    ///
    /// - Note: ``Image`` caches what a symbol resolved to and re-resolves it
    ///   when the symbol's name, size, scale factor, or tint changes. Swapping
    ///   the provider itself out mid-run therefore won't redraw symbols that
    ///   are already on screen. Install the provider once, at the root.
    ///
    /// - Parameter provider: The provider to resolve symbol names with.
    /// - Returns: A view that resolves symbols using `provider`.
    public func symbolProvider(_ provider: any SymbolProvider) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.symbolProvider, provider)
        }
    }
}
