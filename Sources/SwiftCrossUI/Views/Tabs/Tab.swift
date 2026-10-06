/// The role a tab plays in a ``TabView``.
public struct TabRole: Hashable, Sendable {
    /// The role's identity.
    private let rawValue: Int

    /// The tab that searches the app. ``TabView`` puts it after every other
    /// tab, as the platforms do.
    public static let search = TabRole(rawValue: 0)
}

/// A tab of a ``TabView``: a title and symbol for the tab bar, the value that
/// selects it, and its content.
///
/// ```swift
/// TabView(selection: $selection) {
///     Tab("Library", systemImage: "books.vertical", value: Section.library) {
///         LibraryView()
///     }
///     Tab("Search", systemImage: "magnifyingglass", value: Section.search, role: .search) {
///         SearchView()
///     }
/// }
/// ```
public struct Tab<Value: Hashable, Content: View>: TabContent {
    public typealias TabValue = Value

    /// The tab, as its ``TabView`` sees it.
    private let item: _TabItem<Value>

    /// Creates a tab.
    ///
    /// - Parameters:
    ///   - title: The tab's title.
    ///   - systemImage: The name of the tab's symbol.
    ///   - value: The value that selects the tab.
    ///   - role: The tab's role, if it has one.
    ///   - content: The tab's content, built only while the tab is selected.
    public init(
        _ title: String,
        systemImage: String,
        value: Value,
        role: TabRole? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        item = _TabItem(
            title: title,
            systemImage: systemImage,
            value: value,
            role: role,
            content: { AnyView(content()) }
        )
    }

    /// Creates a tab without a symbol.
    ///
    /// - Parameters:
    ///   - title: The tab's title.
    ///   - value: The value that selects the tab.
    ///   - role: The tab's role, if it has one.
    ///   - content: The tab's content, built only while the tab is selected.
    public init(
        _ title: String,
        value: Value,
        role: TabRole? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        item = _TabItem(
            title: title,
            systemImage: nil,
            value: value,
            role: role,
            content: { AnyView(content()) }
        )
    }

    public var _tabs: [_TabItem<Value>] {
        [item]
    }
}
