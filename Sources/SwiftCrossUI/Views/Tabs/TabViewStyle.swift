/// How a ``TabView`` lays out its tabs.
///
/// SwiftCrossUI draws the tab bar itself, from ordinary buttons:
///
/// - ``DefaultTabViewStyle`` and ``TabBarOnlyTabViewStyle`` put the tabs in a
///   row above the selected tab's content, like WinUI's top navigation pane
///   and macOS's tab bar.
/// - ``SidebarAdaptableTabViewStyle`` puts them in a column on the leading
///   side, like WinUI's left navigation pane and the iPad and Mac sidebar.
public protocol TabViewStyle: Sendable {
    /// Where the style puts the tabs.
    var _tabBarPlacement: _TabBarPlacement { get }
}

/// Where a ``TabViewStyle`` puts a ``TabView``'s tabs.
public enum _TabBarPlacement: Hashable, Sendable {
    /// In a row above the content.
    case top
    /// In a column on the leading side of the content.
    case sidebar
}

/// The platform's default tab view style: a row of tabs above the content.
public struct DefaultTabViewStyle: TabViewStyle {
    public var _tabBarPlacement: _TabBarPlacement { .top }

    public init() {}
}

/// A row of tabs above the content, which never becomes a sidebar.
public struct TabBarOnlyTabViewStyle: TabViewStyle {
    public var _tabBarPlacement: _TabBarPlacement { .top }

    public init() {}
}

/// A sidebar of tabs on the leading side of the content.
public struct SidebarAdaptableTabViewStyle: TabViewStyle {
    public var _tabBarPlacement: _TabBarPlacement { .sidebar }

    public init() {}
}

extension TabViewStyle where Self == DefaultTabViewStyle {
    /// The platform's default tab view style.
    public static var automatic: DefaultTabViewStyle { DefaultTabViewStyle() }
}

extension TabViewStyle where Self == TabBarOnlyTabViewStyle {
    /// A row of tabs above the content.
    public static var tabBarOnly: TabBarOnlyTabViewStyle { TabBarOnlyTabViewStyle() }
}

extension TabViewStyle where Self == SidebarAdaptableTabViewStyle {
    /// A sidebar of tabs on the leading side of the content.
    public static var sidebarAdaptable: SidebarAdaptableTabViewStyle {
        SidebarAdaptableTabViewStyle()
    }
}

extension EnvironmentValues {
    /// Where ``TabView``s put their tabs, set by ``View/tabViewStyle(_:)``.
    @Entry var tabBarPlacement: _TabBarPlacement = .top
}

extension View {
    /// Sets the style of the tab views within this view.
    ///
    /// - Parameter style: The style.
    /// - Returns: A view whose tab views use `style`.
    public func tabViewStyle(_ style: some TabViewStyle) -> some View {
        environment(\.tabBarPlacement, style._tabBarPlacement)
    }
}
