extension View {
    /// Populates the toolbar of the enclosing navigation container.
    ///
    /// The items are drawn by the bar of the innermost ``NavigationStack``
    /// (see ``ToolbarItemPlacement`` for where each placement goes), for as
    /// long as this view is on screen. Outside any navigation container the
    /// view draws a bar of its own above itself, so a sheet's Cancel and Done
    /// buttons are never lost.
    ///
    /// ```swift
    /// Form { ... }
    ///     .toolbar {
    ///         ToolbarItem(placement: .cancellationAction) {
    ///             Button("Cancel") { dismiss() }
    ///         }
    ///         ToolbarItem(placement: .confirmationAction) {
    ///             Button("Save") { save() }
    ///         }
    ///     }
    /// ```
    ///
    /// - Note: The items take the environment of the bar that draws them,
    ///   not of the view that declares them; environment values set between
    ///   the container and this view don't reach them.
    ///
    /// - Parameter content: The toolbar's items.
    /// - Returns: A view that contributes `content` to the toolbar.
    public func toolbar<Content: ToolbarContent>(
        @ToolbarContentBuilder content: () -> Content
    ) -> some View {
        NavigationChromeContributor(
            contribution: .toolbar(content()._toolbarEntries),
            hostsWhenAlone: true,
            content: self
        )
    }

    /// Shows or hides the bar of the enclosing navigation container.
    ///
    /// - Parameter visibility: Whether the bar is visible. ``Visibility/hidden``
    ///   hides it, back button and all.
    /// - Returns: A view that sets the bar's visibility.
    public func toolbar(_ visibility: Visibility) -> some View {
        NavigationChromeContributor(
            contribution: .visibility(visibility),
            hostsWhenAlone: false,
            content: self
        )
    }

    /// Shows or hides one of the bars around this view.
    ///
    /// Only the navigation bar (``ToolbarPlacement/navigationBar``,
    /// ``ToolbarPlacement/windowToolbar`` and ``ToolbarPlacement/automatic``)
    /// is drawn by SwiftCrossUI; asking to hide another bar does nothing.
    ///
    /// - Parameters:
    ///   - visibility: Whether the bar is visible.
    ///   - bars: The bars to show or hide.
    /// - Returns: A view that sets the bars' visibility.
    public func toolbar(
        _ visibility: Visibility,
        for bars: ToolbarPlacement...
    ) -> some View {
        NavigationChromeContributor(
            contribution: .visibility(
                bars.contains(where: \.isNavigationBar) ? visibility : .automatic
            ),
            hostsWhenAlone: false,
            content: self
        )
    }

    /// Takes one of the bar's default items away.
    ///
    /// Removing ``ToolbarDefaultItemKind/title`` keeps the navigation title
    /// out of the bar (it's still the container's title);
    /// ``ToolbarDefaultItemKind/sidebarToggle`` is never drawn anyway.
    ///
    /// - Parameter defaultItemKind: The item to remove, or `nil` to remove
    ///   nothing.
    /// - Returns: A view whose bar lacks the item.
    public func toolbar(removing defaultItemKind: ToolbarDefaultItemKind?) -> some View {
        NavigationChromeContributor(
            contribution: .removesTitle(defaultItemKind == .title),
            hostsWhenAlone: false,
            content: self
        )
    }
}
