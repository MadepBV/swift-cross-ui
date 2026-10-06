extension Image {
    /// The size of symbols relative to the text around them.
    ///
    /// Set with ``View/imageScale(_:)``.
    public enum Scale: Hashable, Sendable, CaseIterable {
        /// Smaller than the text.
        case small
        /// The size of the text (the default).
        case medium
        /// Larger than the text.
        case large

        /// How much larger a symbol at this scale is than a medium one,
        /// following the ratio of SF Symbols' scales.
        var symbolSizeMultiplier: Double {
            switch self {
                case .small: 0.78
                case .medium: 1
                case .large: 1.29
            }
        }
    }
}

extension EnvironmentValues {
    /// The scale of symbol images, set with ``View/imageScale(_:)``.
    @Entry public var imageScale: Image.Scale = .medium
}

extension View {
    /// Sets the size of the symbols inside this view relative to their text.
    ///
    /// - Parameter scale: The scale.
    /// - Returns: A view whose symbols use `scale`.
    public func imageScale(_ scale: Image.Scale) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.imageScale, scale)
        }
    }
}
