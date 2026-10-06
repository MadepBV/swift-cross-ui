/// Where a toolbar item goes in the bar that its navigation container draws.
///
/// SwiftCrossUI draws a navigation container's toolbar itself (see
/// ``View/toolbar(content:)``), so a placement chooses one of the bar's three
/// regions rather than a platform-specific slot:
///
/// - **Leading**, after the back button: ``navigation``,
///   ``cancellationAction``, ``topBarLeading`` and ``navigationBarLeading``.
/// - **Centre**, in place of the title: ``principal``.
/// - **Trailing**: every other placement, in the order the items were
///   declared.
///
/// ``keyboard`` items are dropped: no backend has an input accessory bar.
public struct ToolbarItemPlacement: Hashable, Sendable {
    /// The bar regions a placement can resolve to.
    enum Region: Hashable, Sendable {
        case leading
        case principal
        case trailing
        case none
    }

    /// The region of the bar that items with this placement go in.
    let region: Region

    /// The automatic placement: the trailing end of the bar.
    public static let automatic = ToolbarItemPlacement(region: .trailing)
    /// The centre of the bar, replacing the navigation title.
    public static let principal = ToolbarItemPlacement(region: .principal)
    /// Navigation controls, at the leading end of the bar.
    public static let navigation = ToolbarItemPlacement(region: .leading)
    /// The bar's primary actions, at its trailing end.
    public static let primaryAction = ToolbarItemPlacement(region: .trailing)
    /// Secondary actions, at the trailing end of the bar.
    public static let secondaryAction = ToolbarItemPlacement(region: .trailing)
    /// A status item, at the trailing end of the bar.
    public static let status = ToolbarItemPlacement(region: .trailing)
    /// A modal's confirming action (Done, Save), at the trailing end.
    public static let confirmationAction = ToolbarItemPlacement(region: .trailing)
    /// A modal's cancelling action (Cancel, Close), at the leading end.
    public static let cancellationAction = ToolbarItemPlacement(region: .leading)
    /// A modal's destructive action, at the trailing end.
    public static let destructiveAction = ToolbarItemPlacement(region: .trailing)
    /// The keyboard's input accessory bar, which no backend has; items with
    /// this placement aren't drawn.
    public static let keyboard = ToolbarItemPlacement(region: .none)
    /// The leading end of the top bar.
    public static let topBarLeading = ToolbarItemPlacement(region: .leading)
    /// The trailing end of the top bar.
    public static let topBarTrailing = ToolbarItemPlacement(region: .trailing)
    /// The leading end of the navigation bar.
    public static let navigationBarLeading = ToolbarItemPlacement(region: .leading)
    /// The trailing end of the navigation bar.
    public static let navigationBarTrailing = ToolbarItemPlacement(region: .trailing)
    /// The bottom bar, which SwiftCrossUI folds into the trailing end of the
    /// top bar.
    public static let bottomBar = ToolbarItemPlacement(region: .trailing)
}

/// A bar that ``View/toolbar(_:for:)`` can show or hide.
public struct ToolbarPlacement: Hashable, Sendable {
    /// The bar's identity.
    private let rawValue: Int

    /// The bar the platform picks: the navigation bar.
    public static let automatic = ToolbarPlacement(rawValue: 0)
    /// The bar a navigation container draws.
    public static let navigationBar = ToolbarPlacement(rawValue: 1)
    /// The tab bar of a ``TabView``.
    public static let tabBar = ToolbarPlacement(rawValue: 2)
    /// A window's toolbar, which SwiftCrossUI draws as the navigation bar.
    public static let windowToolbar = ToolbarPlacement(rawValue: 3)
    /// The bottom bar.
    public static let bottomBar = ToolbarPlacement(rawValue: 4)

    /// Whether this placement names the bar SwiftCrossUI draws for toolbars.
    var isNavigationBar: Bool {
        self != .tabBar && self != .bottomBar
    }
}

/// An item the system puts in a toolbar by default, which
/// ``View/toolbar(removing:)`` can take away.
public struct ToolbarDefaultItemKind: Hashable, Sendable {
    /// The item's identity.
    private let rawValue: Int

    /// The navigation title.
    public static let title = ToolbarDefaultItemKind(rawValue: 0)
    /// The button that shows and hides a sidebar, which SwiftCrossUI doesn't
    /// draw.
    public static let sidebarToggle = ToolbarDefaultItemKind(rawValue: 1)
}
