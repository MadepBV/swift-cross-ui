extension View {
    /// Scales this view to fill its parent, keeping its aspect ratio.
    ///
    /// The same as `aspectRatio(contentMode: .fill)`.
    ///
    /// - Returns: The scaled view.
    public func scaledToFill() -> some View {
        aspectRatio(contentMode: .fill)
    }

    /// Scales this view to fit its parent, keeping its aspect ratio.
    ///
    /// The same as `aspectRatio(contentMode: .fit)`.
    ///
    /// - Returns: The scaled view.
    public func scaledToFit() -> some View {
        aspectRatio(contentMode: .fit)
    }
}
