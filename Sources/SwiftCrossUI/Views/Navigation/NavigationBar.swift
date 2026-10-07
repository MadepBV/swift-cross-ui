import Foundation

/// The bar a navigation container draws above its content: the back button,
/// the navigation title, the toolbar's items and the search field.
///
/// SwiftUI leaves this bar to the platform; SwiftCrossUI composes it from
/// ordinary controls so that every backend gets one. Its layout follows
/// ``ToolbarItemPlacement``'s regions:
///
/// ```
/// [Back] [leading items] Title / principal item       [trailing items] [search]
/// [search field, when it isn't placed in the bar's row]
/// ```
///
/// The bar takes no room at all when it has nothing to show, so a container
/// whose pages declare no title, toolbar or search looks exactly as it did
/// before toolbars existed.
struct NavigationBar: View {
    /// The spacing between the bar's items.
    static let itemSpacing = 8
    /// The bar's inset from the container's edges: Fluent's page margin for
    /// medium and wide windows, so that the title and back button line up
    /// with page content laid out on the same margin instead of sitting 12
    /// points left of it.
    static let horizontalInset: CGFloat = 24
    /// The bar's vertical inset.
    static let verticalInset: CGFloat = 6
    /// The width of a search field drawn in the bar's row.
    static let inlineSearchFieldWidth: CGFloat = 240
    /// The label of the back button.
    static let backButtonLabel = "Back"

    /// What the bar's contents come from.
    var chrome: NavigationChrome

    /// Returns to the previous page, or `nil` when there's nothing to return
    /// to.
    var back: (@MainActor () -> Void)?

    /// Redraws the bar whenever a contribution changes.
    private let subscription: NavigationChromeSubscription

    /// The button that shows a hidden tab view sidebar; see `SidebarToggle`.
    @Environment(\.sidebarToggle) private var sidebarToggle

    /// Creates a bar.
    ///
    /// - Parameters:
    ///   - chrome: What the bar's contents come from.
    ///   - back: Returns to the previous page, if there is one.
    init(chrome: NavigationChrome, back: (@MainActor () -> Void)?) {
        self.chrome = chrome
        self.back = back
        subscription = NavigationChromeSubscription(chrome)
    }

    var body: some View {
        let state = chrome.state
        let title = state.removesTitle ? nil : state.title
        let leading = state.entries(in: .leading)
        let principal = state.entries(in: .principal)
        let trailing = state.entries(in: .trailing)
        let inlineSearch = state.search.flatMap { $0.placement.isInBarRow ? $0 : nil }
        let drawerSearch = state.search.flatMap { $0.placement.isInBarRow ? nil : $0 }
        let hasRow = sidebarToggle != nil || back != nil || title != nil || !leading.isEmpty
            || !principal.isEmpty || !trailing.isEmpty || inlineSearch != nil

        if state.visibility != .hidden && (hasRow || drawerSearch != nil) {
            VStack(alignment: .leading, spacing: Self.itemSpacing) {
                if hasRow {
                    HStack(spacing: Self.itemSpacing) {
                        if let sidebarToggle {
                            SidebarToggleButton(toggle: sidebarToggle)
                        }
                        if let back {
                            Button(Self.backButtonLabel) { back() }
                        }
                        Self.items(leading)
                        if !principal.isEmpty {
                            Spacer()
                            Self.items(principal)
                            Spacer()
                        } else {
                            if let title {
                                Text(title)
                                    .font(.headline)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        Self.items(trailing)
                        if let inlineSearch {
                            Self.searchField(inlineSearch)
                                .frame(width: Self.inlineSearchFieldWidth)
                        }
                    }
                }
                if let drawerSearch {
                    Self.searchField(drawerSearch)
                }
            }
            .padding(.horizontal, Self.horizontalInset)
            .padding(.vertical, Self.verticalInset)
        }
    }

    /// Draws a run of toolbar entries.
    ///
    /// - Parameter entries: The entries.
    /// - Returns: The entries' views, side by side.
    private static func items(_ entries: [_ToolbarEntry]) -> some View {
        ForEach(Array(entries.indices), id: \.self) { index in
            switch entries[index].kind {
                case .view(let view):
                    view
                case .spacer(let width?):
                    Spacer().frame(width: CGFloat(width))
                case .spacer(nil):
                    Spacer()
            }
        }
    }

    /// Draws a search field.
    ///
    /// - Parameter search: The field's contribution.
    /// - Returns: The field.
    private static func searchField(_ search: SearchFieldContribution) -> some View {
        TextField(search.prompt, text: search.text)
            .onSubmit {
                search.onSubmit?()
            }
    }
}

/// Draws a ``NavigationBar`` above some content and gives the content the
/// bar's chrome to contribute to.
///
/// ``NavigationStack`` is one; so is a ``View/toolbar(content:)`` or
/// ``View/searchable(text:placement:prompt:)-(_,_,String)`` that finds no
/// container around it.
struct NavigationChromeHost<Content: View>: View {
    /// The chrome the bar draws and the content contributes to.
    var chrome: NavigationChrome

    /// Returns to the previous page, if there is one.
    var back: (@MainActor () -> Void)?

    /// The content below the bar.
    var content: Content

    var body: some View {
        VStack(spacing: 0) {
            NavigationBar(chrome: chrome, back: back)
            content
                .environment(\.navigationChrome, chrome)
        }
    }
}

/// The objects a contributing modifier keeps for as long as it's on screen.
///
/// A struct rather than a class so that it can live in `@State` (which only
/// fully supports observable classes) while the objects inside keep their
/// identity.
@MainActor
struct NavigationChromeStorage {
    /// The modifier's place in the enclosing chrome.
    let slot = NavigationChromeSlot()
    /// The chrome the modifier hosts itself when there's no container.
    let ownChrome = NavigationChrome()
}

/// Contributes to the innermost navigation container's bar.
///
/// The shared implementation of `navigationTitle`, `toolbar` and
/// `searchable`. Outside any container, a contribution that can't be dropped
/// (`hostsWhenAlone`) draws a bar of its own above the modified view.
struct NavigationChromeContributor<Content: View>: View {
    /// What to contribute.
    var contribution: NavigationChrome.Contribution

    /// Whether to draw a bar of its own when there's no container.
    var hostsWhenAlone: Bool

    /// The modified view.
    var content: Content

    @Environment(\.navigationChrome) private var chrome
    @Environment(\.dormancyScope) private var dormancyScope
    @State private var storage = NavigationChromeStorage()

    var body: some View {
        let _ = dormancyScope?.register(storage.slot)
        if let chrome {
            // A page out of sight that updates on its own doesn't take the bar.
            let _ = (dormancyScope?.isDormant ?? false)
                ? () : storage.slot.contribute(contribution, to: chrome)
            content
        } else if hostsWhenAlone {
            let _ = storage.slot.contribute(contribution, to: storage.ownChrome)
            NavigationChromeHost(chrome: storage.ownChrome, back: nil, content: content)
        } else {
            let _ = storage.slot.contribute(contribution, to: nil)
            content
        }
    }
}
