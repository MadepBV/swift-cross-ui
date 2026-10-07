import Foundation


/// A view that switches between several child views with a tab bar.
///
/// ```swift
/// TabView(selection: $selection) {
///     Tab("Watch Now", systemImage: "play.rectangle", value: Section.home) {
///         HomeView()
///     }
///     Tab("Settings", systemImage: "gearshape", value: Section.settings) {
///         SettingsView()
///     }
/// }
/// .tabViewStyle(.sidebarAdaptable)
/// ```
///
/// Activating a tab writes its value to `selection`, and the view shows that
/// tab's content; a selection no tab has shows the first tab. Tabs with the
/// ``TabRole/search`` role come after every other tab. The tab bar is drawn
/// from buttons, as a row above the content or a sidebar beside it (see
/// ``TabViewStyle``).
///
/// - Note: As in SwiftUI, a tab keeps its view state (`@State`, its navigation
///   stack, where it's scrolled to) while another tab is selected; its views
///   disappear and appear again as it's left and selected.
public struct TabView<SelectionValue: Hashable, Content: TabContent>: View
    where Content.TabValue == SelectionValue
{
    /// The width of the sidebar of ``SidebarAdaptableTabViewStyle``.
    static var sidebarWidth: CGFloat { 220 }
    /// The spacing between tabs in the tab bar.
    static var tabSpacing: Int { 4 }
    /// The tab bar's inset from the edges of the view.
    static var tabBarInset: CGFloat { 8 }
    /// A sidebar row's horizontal inset inside its selection platter.
    static var sidebarRowInset: CGFloat { 8 }
    /// A sidebar row's vertical inset, which makes it the 28 points of a Mac
    /// sidebar row with a body-sized title.
    static var sidebarRowVerticalInset: CGFloat { 6 }
    /// The corner radius of a sidebar row's selection platter.
    static var sidebarRowCornerRadius: CGFloat { 6 }

    /// The value of the selected tab.
    var selection: Binding<SelectionValue>

    /// The tabs.
    var content: Content

    @Environment(\.tabBarPlacement) private var placement

    /// Whether the sidebar of ``SidebarAdaptableTabViewStyle`` is showing.
    @State private var sidebarIsVisible = true
    @State private var visitedTabs = VisitedTabs<SelectionValue>()

    /// Creates a tab view whose selection you control.
    ///
    /// - Parameters:
    ///   - selection: The value of the selected tab.
    ///   - content: The tabs.
    public init(
        selection: Binding<SelectionValue>,
        @TabContentBuilder<SelectionValue> content: () -> Content
    ) {
        self.selection = selection
        self.content = content()
    }

    /// The tabs in tab bar order: search tabs last.
    var orderedTabs: [_TabItem<SelectionValue>] {
        let tabs = content._tabs
        return tabs.filter { $0.role != .search } + tabs.filter { $0.role == .search }
    }

    /// The tab whose content is shown.
    var selectedTab: _TabItem<SelectionValue>? {
        let tabs = content._tabs
        return tabs.first { $0.value == selection.wrappedValue } ?? tabs.first
    }

    public var body: some View {
        let tabs = orderedTabs
        let selected = selectedTab
        switch placement {
            case .top:
                VStack(spacing: 0) {
                    HStack(spacing: Self.tabSpacing) {
                        tabButtons(tabs, selected: selected?.value)
                    }
                    .padding(Self.tabBarInset)
                    selectedContent(selected)
                }
            case .sidebar:
                let toggle = SidebarToggle(isVisible: sidebarIsVisible) {
                    sidebarIsVisible.toggle()
                }
                HStack(spacing: 0) {
                    if sidebarIsVisible {
                        VStack(alignment: .leading, spacing: Self.tabSpacing) {
                            // Level with the navigation bar's row beside it, as
                            // a Mac window's toolbar runs across its sidebar.
                            SidebarToggleButton(toggle: toggle)
                                .padding(.leading, Self.sidebarRowInset)
                                .padding(.bottom, Self.tabBarInset)
                            tabButtons(tabs, selected: selected?.value)
                            Spacer()
                        }
                        .padding(.horizontal, Self.tabBarInset)
                        .padding(.top, NavigationBar.verticalInset)
                        .padding(.bottom, Self.tabBarInset)
                        .frame(width: Self.sidebarWidth)
                    }
                    selectedContent(selected)
                        .environment(\.sidebarToggle, sidebarIsVisible ? nil : toggle)
                }
        }
    }

    /// The buttons that select each tab.
    ///
    /// - Parameters:
    ///   - tabs: The tabs, in tab bar order.
    ///   - selected: The value of the selected tab.
    /// - Returns: One button per tab.
    private func tabButtons(
        _ tabs: [_TabItem<SelectionValue>],
        selected: SelectionValue?
    ) -> some View {
        let selection = selection
        return ForEach(Array(tabs.indices), id: \.self) { index in
            let tab = tabs[index]
            let isSelected = tab.value == selected
            if placement == .sidebar {
                // Every sidebar row is drawn alike, with the selection as a
                // platter behind it, so the rows are one height and their
                // icons and titles share one leading edge, as in a Mac
                // sidebar. A bordered selected row moved its title 12 points
                // in and stood twice as tall as the rows around it.
                Button {
                    selection.wrappedValue = tab.value
                } label: {
                    tabLabel(tab)
                        .padding(.horizontal, Self.sidebarRowInset)
                        .padding(.vertical, Self.sidebarRowVerticalInset)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: Self.sidebarRowCornerRadius)
                                .fill(isSelected ? Color.gray.opacity(0.25) : Color.clear)
                        }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            } else {
                // A tab bar's selected tab is prominent.
                Button {
                    selection.wrappedValue = tab.value
                } label: {
                    tabLabel(tab)
                }
                .buttonStyle(
                    isSelected
                        ? BorderedProminentButtonStyle() as any ButtonStyle
                        : BorderlessButtonStyle()
                )
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    /// A tab's title, with its symbol when it has one.
    @ViewBuilder
    private func tabLabel(_ tab: _TabItem<SelectionValue>) -> some View {
        if let systemImage = tab.systemImage {
            Label(tab.title, systemImage: systemImage)
        } else {
            Text(tab.title)
        }
    }

    /// The content of every tab visited so far, the selected one showing and
    /// the others dormant (see ``DormantContent``), as SwiftUI keeps a tab's
    /// state while another is selected. Switching back to a tab shows what's
    /// already there instead of building the tab again.
    ///
    /// - Parameter tab: The selected tab.
    /// - Returns: The tabs' content.
    @ViewBuilder
    private func selectedContent(_ tab: _TabItem<SelectionValue>?) -> some View {
        if let tab {
            let tabs = content._tabs
            let visited = visitedTabs.including(tab.value, among: tabs.map(\.value))
            ZStack {
                ForEach(visited, id: \.self) { value in
                    if let item = tabs.first(where: { $0.value == value }) {
                        DormantContent(
                            isActive: value == tab.value,
                            content: item.content()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// The tabs a tab view has shown, in the order they were first selected.
///
/// A reference so that recording a tab during `body` doesn't count as a state
/// change; the selection that adds a tab has already updated the view.
final class VisitedTabs<Value: Hashable> {
    private var values: [Value] = []

    /// The visited tabs that still exist, `selected` among them.
    func including(_ selected: Value, among existing: [Value]) -> [Value] {
        if !values.contains(selected) {
            values.append(selected)
        }
        values.removeAll { !existing.contains($0) }
        return values
    }
}
