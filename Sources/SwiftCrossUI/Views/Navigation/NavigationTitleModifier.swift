extension View {
    /// Sets the title that the enclosing navigation container's bar shows
    /// while this view is on screen.
    ///
    /// The innermost title wins. Outside a navigation container the title
    /// isn't drawn; name the window with its scene's title instead.
    ///
    /// - Parameter title: The title.
    /// - Returns: A view that contributes the title to the bar.
    public func navigationTitle(_ title: String) -> some View {
        NavigationChromeContributor(
            contribution: .title(title),
            hostsWhenAlone: false,
            content: self
        )
    }

    /// Sets the title that the enclosing navigation container's bar shows
    /// while this view is on screen, from a text view.
    ///
    /// Only the text's string is used; its styling is the bar's.
    ///
    /// - Parameter title: The title.
    /// - Returns: A view that contributes the title to the bar.
    public func navigationTitle(_ title: Text) -> some View {
        navigationTitle(title.string)
    }

    /// Sets the subtitle of the enclosing navigation container.
    ///
    /// SwiftCrossUI's bar has no subtitle line, so this only keeps SwiftUI
    /// source compiling.
    ///
    /// - Parameter subtitle: The subtitle.
    /// - Returns: This view, unchanged.
    public func navigationSubtitle(_ subtitle: String) -> some View {
        self
    }
}
