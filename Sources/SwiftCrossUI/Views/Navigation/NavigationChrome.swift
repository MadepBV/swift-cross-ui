import Foundation

/// What the views inside a navigation container ask its bar to show.
///
/// SwiftUI's `navigationTitle`, `toolbar` and `searchable` are declared deep
/// inside a page but drawn by the container around it. SwiftCrossUI's
/// preferences only flow up as far as layout, so the container instead hands
/// its descendants this object through the environment
/// (``EnvironmentValues/navigationChrome``); each modifier keeps its
/// contribution here for as long as its view is on screen
/// (``NavigationChromeSlot``), and the container's ``NavigationBar`` redraws
/// whenever the contributions change.
///
/// Only the bar observes the chrome, never the page that wrote to it, so a
/// contribution can't make the page that made it evaluate again.
@MainActor
final class NavigationChrome {
    /// One modifier's contribution to the bar.
    enum Contribution {
        /// A navigation title.
        case title(String)
        /// Toolbar items.
        case toolbar([_ToolbarEntry])
        /// A search field.
        case search(SearchFieldContribution)
        /// Whether the bar is visible.
        case visibility(Visibility)
        /// Whether the title is taken out of the bar.
        case removesTitle(Bool)
    }

    /// A contribution together with when its slot first contributed.
    private struct Entry {
        /// The position of the slot's first contribution; earlier slots are
        /// outer views, because bodies are evaluated from the top down.
        var order: Int
        /// The contribution.
        var contribution: Contribution
    }

    /// Published whenever a contribution changes.
    ///
    /// Read by ``NavigationChromeSubscription`` from outside the main actor,
    /// as every ``ObservableProperty``'s publisher is; the publisher is only
    /// ever sent from the main actor.
    nonisolated(unsafe) let didChange = Publisher()

    /// The contributions, keyed by the slot that made them.
    private var entries: [ObjectIdentifier: Entry] = [:]

    /// The order the next new slot's contribution gets.
    private var nextOrder = 0

    /// Creates an empty chrome.
    init() {}

    /// Records a slot's contribution, replacing the slot's previous one.
    ///
    /// - Parameters:
    ///   - contribution: The contribution.
    ///   - slot: The slot making it.
    func contribute(_ contribution: Contribution, from slot: ObjectIdentifier) {
        if entries[slot] != nil {
            entries[slot]?.contribution = contribution
        } else {
            entries[slot] = Entry(order: nextOrder, contribution: contribution)
            nextOrder += 1
        }
        didChange.send()
    }

    /// Removes a slot's contribution.
    ///
    /// - Parameter slot: The slot whose contribution to remove.
    func withdraw(_ slot: ObjectIdentifier) {
        guard entries.removeValue(forKey: slot) != nil else {
            return
        }
        didChange.send()
    }

    /// The contributions, outermost first.
    private var contributions: [Contribution] {
        entries.values.sorted { $0.order < $1.order }.map(\.contribution)
    }

    /// What the bar draws, resolved from every current contribution.
    var state: NavigationBarState {
        var state = NavigationBarState()
        for contribution in contributions {
            switch contribution {
                case .title(let title):
                    // The innermost title wins, as in SwiftUI.
                    state.title = title
                case .toolbar(let toolbarEntries):
                    state.entries += toolbarEntries
                case .search(let search):
                    state.search = search
                case .visibility(let visibility):
                    state.visibility = visibility
                case .removesTitle(let removesTitle):
                    state.removesTitle = removesTitle
            }
        }
        return state
    }
}

/// What a ``NavigationBar`` draws.
struct NavigationBarState {
    /// The innermost navigation title, if any.
    var title: String?
    /// The toolbar items, outermost declaration first.
    var entries: [_ToolbarEntry] = []
    /// The search field, if a view is searchable.
    var search: SearchFieldContribution?
    /// Whether the bar is visible.
    var visibility: Visibility = .automatic
    /// Whether the title is taken out of the bar.
    var removesTitle = false

    /// The items in one region of the bar, in declaration order.
    ///
    /// - Parameter region: The region.
    /// - Returns: The region's items.
    func entries(in region: ToolbarItemPlacement.Region) -> [_ToolbarEntry] {
        entries.filter { $0.placement.region == region }
    }
}

/// A search field that ``View/searchable(text:placement:prompt:)-(_,_,String)``
/// asks the bar to draw.
struct SearchFieldContribution {
    /// The search text.
    var text: Binding<String>
    /// Where the field goes.
    var placement: SearchFieldPlacement
    /// The field's placeholder.
    var prompt: String
    /// What to do when the user submits a search.
    var onSubmit: (@MainActor @Sendable () -> Void)?
}

extension EnvironmentValues {
    /// The bar of the innermost navigation container, which `navigationTitle`,
    /// `toolbar` and `searchable` contribute to.
    ///
    /// `nil` outside any container; ``View/toolbar(content:)`` and
    /// ``View/searchable(text:placement:prompt:)-(_,_,String)`` then draw a
    /// bar of their own.
    @Entry var navigationChrome: NavigationChrome? = nil
}

/// Subscribes a view to a ``NavigationChrome``'s changes.
///
/// A view graph node observes the publishers of its view's
/// ``ObservableProperty`` fields, so a ``NavigationBar`` holding one of
/// these updates whenever a contribution changes.
struct NavigationChromeSubscription: ObservableProperty {
    let didChange: Publisher

    /// Subscribes to a chrome.
    ///
    /// - Parameter chrome: The chrome to observe.
    @MainActor
    init(_ chrome: NavigationChrome) {
        didChange = chrome.didChange
    }

    func update(with environment: EnvironmentValues, previousValue: Self?) {}
}
