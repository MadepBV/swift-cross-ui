extension View {
    /// Hides this view while keeping its place in the layout.
    ///
    /// As in SwiftUI, the view is still measured and laid out, so it holds
    /// its space (a common use is measuring text that isn't shown); it's
    /// drawn fully transparent, ignores clicks and taps, and is left out of
    /// the accessibility tree. To remove a view and its space, leave it out
    /// with an `if` instead.
    ///
    /// - Returns: The view, invisible and inert.
    public func hidden() -> some View {
        opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
