extension View {
    /// Sets a limit for the number of lines text can occupy in this view.
    public func lineLimit(_ limit: Int?, reservesSpace: Bool = false) -> some View {
        EnvironmentModifier(self) { environment in
            if let limit {
                environment
                    .with(
                        \.lineLimitSettings,
                        LineLimit(limit: limit, reservesSpace: reservesSpace)
                    )
            } else {
                environment.with(\.lineLimitSettings, nil)
            }
        }
    }

    /// Sets a range for the number of lines text can occupy in this view.
    ///
    /// ```swift
    /// TextField("Description", text: $description, axis: .vertical)
    ///     .lineLimit(2...4)
    /// ```
    ///
    /// - Note: Only the upper bound is currently honoured — the view is capped
    ///   at `limit.upperBound` lines but is free to be shorter than
    ///   `limit.lowerBound`. ``LineLimit``, the environment value that carries
    ///   the setting to the views that read it, holds a single maximum, so
    ///   there's nowhere to put the lower bound yet.
    ///
    /// - Parameter limit: The range of lines the text may occupy.
    /// - Returns: A view whose text is capped at the range's upper bound.
    public func lineLimit(_ limit: ClosedRange<Int>) -> some View {
        lineLimit(limit.upperBound, reservesSpace: false)
    }
}
