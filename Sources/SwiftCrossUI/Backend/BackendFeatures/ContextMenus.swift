extension BackendFeatures {
    /// Backend methods for context menus (the menus shown when a view is
    /// secondary-clicked or long-pressed).
    ///
    /// This is deliberately separate from ``BackendFeatures/MenuButtons``.
    /// A menu button owns its own widget and decides when to show its menu,
    /// whereas a context menu is attached to a view that the backend already
    /// renders, and the *platform* decides when to show it. Backends are
    /// expected to reuse whatever machinery they already have for turning a
    /// ``ResolvedMenu`` into native menu items.
    ///
    /// These are used by ``View/contextMenu(menuItems:)``.
    @MainActor
    public protocol ContextMenus: Core {
        /// Wraps a view in a container that can present a context menu.
        ///
        /// Some backends may not have to wrap the child, in which case they may
        /// just return the child as-is.
        ///
        /// - Parameter child: The child to wrap.
        /// - Returns: A widget that can present a context menu.
        func createContextMenuTarget(wrapping child: Widget) -> Widget

        /// Updates the context menu presented by a widget.
        ///
        /// The new content replaces the old content.
        ///
        /// - Parameters:
        ///   - contextMenuTarget: The target to update. Will always have been
        ///     created by ``createContextMenuTarget(wrapping:)``.
        ///   - content: The menu to present, or `nil` to remove the widget's
        ///     context menu entirely.
        ///   - environment: The current environment.
        func updateContextMenuTarget(
            _ contextMenuTarget: Widget,
            content: ResolvedMenu?,
            environment: EnvironmentValues
        )
    }
}
