/// A button that shows a popover menu when clicked.
///
/// Due to technical limitations, the minimum supported OS's for menu buttons in
/// UIKitBackend are iOS 14 and tvOS 17.
public struct Menu {
    /// The menu's label.
    public var label: String

    /// Where the menu's items come from.
    ///
    /// A view is kept rather than collected in `init`, because collecting
    /// menu items reads view bodies, and a body may read `@Environment`
    /// (``Section``, ``Picker``): the items are collected when the menu is
    /// laid out or shown, with the environment in force (see
    /// ``MenuItemCollection``).
    private enum Source {
        case view(any View)
        case items([MenuItem])
    }

    private var source: Source

    /// The menu's items.
    ///
    /// Collected on demand under whatever environment the current menu
    /// collection installed.
    @MainActor
    public var items: [MenuItem] {
        switch source {
            case .view(let view): view._asMenuItems
            case .items(let items): items
        }
    }

    var buttonWidth: Int?

    /// Creates a menu.
    ///
    /// - Parameters:
    ///   - label: The menu's label.
    ///   - items: The menu's items.
    @MainActor
    public init(_ label: String, @ViewBuilder items: () -> some View) {
        self.label = label
        self.source = .view(items())
    }

    /// Creates a menu from items that have already been collected.
    ///
    /// - Parameters:
    ///   - label: The menu's label.
    ///   - items: The menu's items.
    init(label: String, items: [MenuItem]) {
        self.label = label
        self.source = .items(items)
    }

    /// Resolves the menu to a representation used by backends.
    @MainActor
    func resolve() -> ResolvedMenu.Submenu {
        ResolvedMenu.Submenu(
            label: label,
            content: Self.resolve(items: items)
        )
    }

    @MainActor
    static func resolve(item: MenuItem) -> ResolvedMenu.Item {
        switch item {
            case .button(let button):
                .button(button.title, button.action)
            case .text(let text):
                .button(text.string, nil)
            case .toggle(let toggle):
                .toggle(
                    toggle.label,
                    toggle.active.wrappedValue,
                    onChange: { toggle.active.wrappedValue = $0 }
                )
            case .separator:
                .separator
            case .submenu(let submenu):
                .submenu(submenu.resolve())
            case .modifiedEnvironment(let item, let modification):
                .modifiedEnvironment(resolve(item: item()), modification())
        }
    }

    /// Resolves the menu's items to a representation used by backends.
    @MainActor
    static func resolve(items: [MenuItem]) -> ResolvedMenu {
        ResolvedMenu(items: Self.tidyingSeparators(items.map(resolve(item:))))
    }

    /// Drops separators that would draw as a bare line: at either end of a
    /// menu, or two in a row.
    ///
    /// ``Section`` brackets its content with separators so that adjacent
    /// sections divide correctly, which leaves stray ones at the edges.
    ///
    /// - Parameter items: The resolved items.
    /// - Returns: The items with redundant separators removed.
    private static func tidyingSeparators(_ items: [ResolvedMenu.Item]) -> [ResolvedMenu.Item] {
        var result: [ResolvedMenu.Item] = []
        for item in items {
            if case .separator = item {
                guard let last = result.last else {
                    continue
                }
                if case .separator = last {
                    continue
                }
            }
            result.append(item)
        }
        if let last = result.last, case .separator = last {
            result.removeLast()
        }
        return result
    }
}

@available(iOS 14, macCatalyst 14, tvOS 17, *)
extension Menu: TypeSafeView {
    public var body: EmptyView { return EmptyView() }

    public var _asMenuItems: [MenuItem] { [.submenu(self)] }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        MenuStorage()
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: MenuStorage,
        backend: Backend
    ) -> Backend.Widget {
        return backend.createSimpleButton()
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: MenuStorage
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    @CastBackend<BackendFeatures.MenuButtons>(backendGenericName: "NewBackend")
    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: MenuStorage,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // TODO: Look into ways to predict a button's natural size without
        //   updating its content so that computeLayout can be a bit more of
        //   a pure function.

        // Update the button before measuring its natural size
        switch backend.menuImplementationStyle {
            case .dynamicPopover(let backend):
                // Our menu button action implementation needs to know the size
                // of the button, but we don't have that yet, so just update it
                // with an empty action and fix it in commit.
                backend.updateSimpleButton(
                    widget,
                    label: label,
                    environment: environment,
                    action: {}
                )
            case .menuButton(let backend):
                let menu =
                    children.menu.flatMap { $0 as? NewBackend.Menu }
                        ?? backend.createPopoverMenu()
                children.menu = menu
                backend.updateButton(
                    widget,
                    label: label,
                    menu: menu,
                    environment: environment
                )
        }

        var size = ViewSize(backend.naturalSize(of: widget))
        if let buttonWidth {
            size.width = Double(buttonWidth)
        } else if let width = proposedSize.width, width.isFinite {
            // Inspector menus often display a user-authored name. Keep the
            // closed button inside its proposed row while the popover keeps
            // the complete menu titles.
            size.width = min(size.width, max(0, width))
        }
        return ViewLayoutResult.leafView(size: size)
    }

    @CastBackend<BackendFeatures.MenuButtons>(backendGenericName: "NewBackend")
    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: MenuStorage,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = layout.size
        backend.setSize(of: widget, to: size.vector)

        switch backend.menuImplementationStyle {
            case .dynamicPopover(let backend):
                backend.updateSimpleButton(
                    widget,
                    label: label,
                    environment: environment,
                    action: {
                        let content = MenuItemCollection.withEnvironment(environment) {
                            resolve().content
                        }
                        let menu = backend.createPopoverMenu()
                        children.menu = menu
                        backend.updatePopoverMenu(
                            menu,
                            content: content,
                            environment: environment
                        )
                        backend.showPopoverMenu(
                            menu,
                            at: SIMD2(0, LayoutSystem.roundSize(size.height) + 2),
                            relativeTo: widget
                        ) {
                            children.menu = nil
                        }
                    }
                )

                if let menu = children.menu {
                    let content = MenuItemCollection.withEnvironment(environment) {
                        resolve().content
                    }
                    backend.updatePopoverMenu(
                        menu as! NewBackend.Menu,
                        content: content,
                        environment: environment
                    )
                }
            case .menuButton(let backend):
                // We can assume that computeLayout has already run, so children.menu
                // will already be correctly initialized.
                let content = MenuItemCollection.withEnvironment(environment) {
                    resolve().content
                }
                let menu = children.menu! as! NewBackend.Menu
                backend.updatePopoverMenu(
                    menu,
                    content: content,
                    environment: environment
                )

                // Even though we update the button in computeLayout (in order
                // for naturalSize to work), we appear to have to update it again
                // in commit; otherwise UIKitBackend users get menu buttons that
                // aren't poppable until the second time that the view gets updated.
                // They also get menu button menus with toggles that only toggle every
                // second time. I'm not sure why any of that happens.
                // TODO: Investigate why the following is needed. It may point us to
                //   some layout system/state management issues.
                backend.updateButton(
                    widget,
                    label: label,
                    menu: menu,
                    environment: environment
                )
        }
    }

    /// A temporary button width solution until arbitrary labels are supported.
    public func _buttonWidth(_ width: Int?) -> Menu {
        var menu = self
        menu.buttonWidth = width
        return menu
    }
}

class MenuStorage: ViewGraphNodeChildren {
    var menu: Any?

    var widgets: [AnyWidget] = []
    var erasedNodes: [ErasedViewGraphNode] = []

    init() {}
}
