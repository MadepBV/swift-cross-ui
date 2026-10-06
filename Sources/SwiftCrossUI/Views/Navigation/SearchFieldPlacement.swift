/// Where ``View/searchable(text:placement:prompt:)-(_,_,String)`` puts its
/// search field.
///
/// SwiftCrossUI's navigation bar (see ``NavigationBar``) draws the field in its
/// own row for ``toolbar`` and ``toolbarPrincipal``, and full width under that
/// row for every other placement.
public struct SearchFieldPlacement: Hashable, Sendable {
    /// How a search field placed in a navigation bar drawer is shown.
    public struct NavigationBarDrawerDisplayMode: Hashable, Sendable {
        /// The mode's identity.
        private let rawValue: Int

        /// The drawer hides as the content scrolls. SwiftCrossUI always shows
        /// it.
        public static let automatic = NavigationBarDrawerDisplayMode(rawValue: 0)
        /// The drawer is always shown.
        public static let always = NavigationBarDrawerDisplayMode(rawValue: 1)
    }

    /// The placement's identity.
    private let rawValue: Int

    /// The platform's usual place: under the bar's row.
    public static let automatic = SearchFieldPlacement(rawValue: 0)
    /// In the bar's row, at its trailing end.
    public static let toolbar = SearchFieldPlacement(rawValue: 1)
    /// In the bar's row, at its trailing end; SwiftUI centres it.
    public static let toolbarPrincipal = SearchFieldPlacement(rawValue: 2)
    /// At the top of a sidebar; SwiftCrossUI draws it under the bar's row.
    public static let sidebar = SearchFieldPlacement(rawValue: 3)
    /// In a drawer under the navigation bar.
    public static let navigationBarDrawer = SearchFieldPlacement(rawValue: 4)

    /// In a drawer under the navigation bar, shown according to a display
    /// mode.
    ///
    /// - Parameter displayMode: When the drawer shows.
    /// - Returns: The placement.
    public static func navigationBarDrawer(
        displayMode: NavigationBarDrawerDisplayMode
    ) -> SearchFieldPlacement {
        .navigationBarDrawer
    }

    /// Whether the field goes in the bar's row rather than under it.
    var isInBarRow: Bool {
        self == .toolbar || self == .toolbarPrincipal
    }
}
