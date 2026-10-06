extension ToolbarContent {
    /// Shows or hides the shared glass background that groups toolbar items
    /// on Apple platforms.
    ///
    /// Purely cosmetic: SwiftCrossUI's bar draws its items as ordinary
    /// controls with no shared background, so there is nothing to hide.
    ///
    /// - Parameter visibility: Whether the background is visible.
    /// - Returns: This content, unchanged.
    public func sharedBackgroundVisibility(_ visibility: Visibility) -> Self {
        self
    }
}

/// How large a navigation title is drawn.
public struct NavigationBarItem {
    /// The title display modes of a navigation bar.
    public enum TitleDisplayMode: Hashable, Sendable {
        /// The platform's choice.
        case automatic
        /// A large title, which shrinks into the bar as the content scrolls.
        case large
        /// A title inside the bar.
        case inline
    }
}

/// How a toolbar draws its title.
public struct ToolbarTitleDisplayMode: Hashable, Sendable {
    /// The mode's identity.
    private let rawValue: Int

    /// The platform's choice.
    public static let automatic = ToolbarTitleDisplayMode(rawValue: 0)
    /// A large title.
    public static let large = ToolbarTitleDisplayMode(rawValue: 1)
    /// A title inside the bar.
    public static let inline = ToolbarTitleDisplayMode(rawValue: 2)
    /// A large title on iPad and Mac, inside the bar elsewhere.
    public static let inlineLarge = ToolbarTitleDisplayMode(rawValue: 3)
}

extension View {
    /// Sets how large the navigation title is drawn.
    ///
    /// Purely cosmetic, and without effect: SwiftCrossUI's bar draws one
    /// title size, the platform's headline, in every mode.
    ///
    /// - Parameter displayMode: The display mode.
    /// - Returns: This view, unchanged.
    public func navigationBarTitleDisplayMode(
        _ displayMode: NavigationBarItem.TitleDisplayMode
    ) -> some View {
        self
    }

    /// Sets how the toolbar draws its title.
    ///
    /// Purely cosmetic, and without effect, for the reason
    /// ``View/navigationBarTitleDisplayMode(_:)`` gives.
    ///
    /// - Parameter mode: The display mode.
    /// - Returns: This view, unchanged.
    public func toolbarTitleDisplayMode(_ mode: ToolbarTitleDisplayMode) -> some View {
        self
    }
}
