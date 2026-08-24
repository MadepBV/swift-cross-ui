/// A command menu.
public struct CommandMenu {
    /// The menu's name.
    var name: String

    /// Where the menu's items come from.
    ///
    /// A view is kept rather than collected in `init`, because collecting
    /// menu items reads view bodies, which may read `@Environment`; the
    /// items are collected when the application menu is set, with the root
    /// environment in force (see ``MenuItemCollection``).
    private enum Source {
        case view(any View)
        case items([MenuItem])
    }

    /// The menu's sources, in order; several when menus of the same name
    /// were merged by ``Commands/overlayed(with:)``.
    private var sources: [Source]

    /// The menu's contents, collected under the current menu collection
    /// environment.
    @MainActor
    var content: [MenuItem] {
        sources.flatMap { source in
            switch source {
                case .view(let view): view._asMenuItems
                case .items(let items): items
            }
        }
    }

    /// Creates a command menu.
    ///
    /// - Parameters:
    ///   - name: The menu's name.
    ///   - content: The menu's contents.
    @MainActor
    public init(_ name: String, @ViewBuilder content: () -> some View) {
        self.name = name
        self.sources = [.view(content())]
    }

    /// Creates a command menu.
    ///
    /// - Parameters:
    ///   - name: The menu's name.
    ///   - content: The menu's contents.
    init(name: String, content: [MenuItem]) {
        self.name = name
        self.sources = [.items(content)]
    }

    /// Creates a command menu holding the contents of several menus.
    ///
    /// - Parameters:
    ///   - name: The menu's name.
    ///   - menus: The menus whose contents to concatenate.
    init(name: String, merging menus: [CommandMenu]) {
        self.name = name
        self.sources = menus.flatMap(\.sources)
    }

    /// Resolves the menu to a representation used by backends.
    @MainActor
    func resolve() -> ResolvedMenu.Submenu {
        ResolvedMenu.Submenu(
            label: name,
            content: Menu.resolve(items: content)
        )
    }
}
