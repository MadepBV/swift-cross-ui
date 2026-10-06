/// A place in the standard menus that a ``CommandGroup`` adds to.
///
/// SwiftCrossUI's backends build their standard menus themselves, so a
/// placement names the standard menu its group joins — File, Edit, View,
/// Window or Help — rather than a position inside it. Backends merge an app's
/// menus with their standard menus of the same name (`AppKitBackend` does),
/// or show them as menus of their own. The application menu's groups
/// (``appInfo``, ``appSettings``, ``appTermination``, ...) join the File menu,
/// where Windows and Linux apps keep those items.
public struct CommandGroupPlacement: Hashable, Sendable {
    /// The standard menu that groups with this placement join.
    let menuName: String

    /// About the app.
    public static let appInfo = CommandGroupPlacement(menuName: "File")
    /// The app's settings.
    public static let appSettings = CommandGroupPlacement(menuName: "File")
    /// The system's services.
    public static let systemServices = CommandGroupPlacement(menuName: "File")
    /// Hiding and showing the app.
    public static let appVisibility = CommandGroupPlacement(menuName: "File")
    /// Quitting the app.
    public static let appTermination = CommandGroupPlacement(menuName: "File")
    /// Creating documents and windows.
    public static let newItem = CommandGroupPlacement(menuName: "File")
    /// Saving and closing.
    public static let saveItem = CommandGroupPlacement(menuName: "File")
    /// Importing and exporting.
    public static let importExport = CommandGroupPlacement(menuName: "File")
    /// Printing.
    public static let printItem = CommandGroupPlacement(menuName: "File")
    /// Undo and redo.
    public static let undoRedo = CommandGroupPlacement(menuName: "Edit")
    /// Cut, copy and paste.
    public static let pasteboard = CommandGroupPlacement(menuName: "Edit")
    /// Finding and spelling.
    public static let textEditing = CommandGroupPlacement(menuName: "Edit")
    /// Text formatting.
    public static let textFormatting = CommandGroupPlacement(menuName: "Edit")
    /// Showing and customizing toolbars.
    public static let toolbar = CommandGroupPlacement(menuName: "View")
    /// Showing and hiding sidebars.
    public static let sidebar = CommandGroupPlacement(menuName: "View")
    /// Sizing windows.
    public static let windowSize = CommandGroupPlacement(menuName: "Window")
    /// The list of windows.
    public static let windowList = CommandGroupPlacement(menuName: "Window")
    /// The list of single windows.
    public static let singleWindowList = CommandGroupPlacement(menuName: "Window")
    /// Arranging windows.
    public static let windowArrangement = CommandGroupPlacement(menuName: "Window")
    /// The app's help.
    public static let help = CommandGroupPlacement(menuName: "Help")
}

/// Commands added to one of the standard menus.
///
/// ```swift
/// .commands {
///     CommandGroup(replacing: .appSettings) {
///         Button("Settings…") { showSettings() }
///     }
/// }
/// ```
///
/// - Note: SwiftCrossUI can't take the backends' own standard items out of
///   their menus, so `replacing:` adds the group's items like `after:` does,
///   and `before:` adds them at the end of the menu too. See
///   ``CommandGroupPlacement`` for which menu each placement joins.
public struct CommandGroup<Content: View>: Commands {
    public typealias Body = Never

    /// The standard menu the group joins.
    private let placement: CommandGroupPlacement

    /// The group's items.
    private let content: Content

    /// Creates a group that stands in for a group of standard items.
    ///
    /// - Parameters:
    ///   - group: The standard items.
    ///   - addition: The group's items.
    public init(
        replacing group: CommandGroupPlacement,
        @ViewBuilder addition: () -> Content
    ) {
        placement = group
        content = addition()
    }

    /// Creates a group that goes before a group of standard items.
    ///
    /// - Parameters:
    ///   - group: The standard items.
    ///   - addition: The group's items.
    public init(
        before group: CommandGroupPlacement,
        @ViewBuilder addition: () -> Content
    ) {
        placement = group
        content = addition()
    }

    /// Creates a group that goes after a group of standard items.
    ///
    /// - Parameters:
    ///   - group: The standard items.
    ///   - addition: The group's items.
    public init(
        after group: CommandGroupPlacement,
        @ViewBuilder addition: () -> Content
    ) {
        placement = group
        content = addition()
    }

    public var _commandMenus: [CommandMenu] {
        let content = content
        return [CommandMenu(placement.menuName) { content }]
    }
}

/// The standard commands for showing and hiding a sidebar.
///
/// SwiftCrossUI's sidebars (``NavigationSplitView``) aren't collapsible from
/// a menu, so these add nothing; they exist so that SwiftUI commands compile
/// unchanged.
public struct SidebarCommands: Commands {
    public typealias Body = Never

    /// Creates the sidebar commands.
    public init() {}

    public var _commandMenus: [CommandMenu] {
        []
    }
}

/// The standard commands for showing and customizing a window's toolbar.
///
/// SwiftCrossUI's toolbars aren't customizable, so these add nothing; they
/// exist so that SwiftUI commands compile unchanged.
public struct ToolbarCommands: Commands {
    public typealias Body = Never

    /// Creates the toolbar commands.
    public init() {}

    public var _commandMenus: [CommandMenu] {
        []
    }
}
