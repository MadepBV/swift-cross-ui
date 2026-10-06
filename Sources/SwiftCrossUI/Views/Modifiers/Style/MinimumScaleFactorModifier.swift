extension EnvironmentValues {
    /// The smallest fraction of its size that text may shrink to in order to
    /// fit. Set with ``View/minimumScaleFactor(_:)``.
    @Entry public var minimumScaleFactor: Double = 1
}

extension View {
    /// Lets the text inside this view shrink to fit its space, down to a
    /// fraction of its size.
    ///
    /// ```swift
    /// Text(title)
    ///     .lineLimit(1)
    ///     .minimumScaleFactor(0.8)
    /// ```
    ///
    /// - Note: Applies to single-line text (`lineLimit(1)`), which is where
    ///   SwiftUI apps use it to keep a label on one line. Wrapping text keeps
    ///   its size; see ``Text``.
    ///
    /// - Parameter factor: The smallest scale, from 0 to 1.
    /// - Returns: A view whose text may shrink to `factor`.
    public func minimumScaleFactor(_ factor: Double) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.minimumScaleFactor, min(max(factor, 0.01), 1))
        }
    }
}
