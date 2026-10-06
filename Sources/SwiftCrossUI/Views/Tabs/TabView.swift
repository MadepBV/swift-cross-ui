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
/// - Note: Only the selected tab's content exists. Switching away discards the
///   view state (`@State`) of the tab left behind, so keep anything a tab must
///   remember, such as its navigation path, in a model above the tab view.
public struct TabView<SelectionValue: Hashable, Content: TabContent>: View
    where Content.TabValue == SelectionValue
{
    /// The width of the sidebar of ``SidebarAdaptableTabViewStyle``.
    static var sidebarWidth: CGFloat { 220 }
    /// The spacing between tabs in the tab bar.
    static var tabSpacing: Int { 4 }
    /// The tab bar's inset from the edges of the view.
    static var tabBarInset: CGFloat { 8 }

    /// The value of the selected tab.
    var selection: Binding<SelectionValue>

    /// The tabs.
    var content: Content

    @Environment(\.tabBarPlacement) private var placement

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
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: Self.tabSpacing) {
                        tabButtons(tabs, selected: selected?.value)
                        Spacer()
                    }
                    .padding(Self.tabBarInset)
                    .frame(width: Self.sidebarWidth)
                    selectedContent(selected)
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
            Button {
                selection.wrappedValue = tab.value
            } label: {
                if let systemImage = tab.systemImage {
                    Label(tab.title, systemImage: systemImage)
                } else {
                    Text(tab.title)
                }
            }
            .buttonStyle(
                isSelected
                    ? BorderedProminentButtonStyle() as any ButtonStyle
                    : BorderlessButtonStyle()
            )
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        }
    }

    /// The selected tab's content, identified by the tab's value so that
    /// switching tabs replaces the content's view state rather than handing it
    /// to the next tab.
    ///
    /// - Parameter tab: The selected tab.
    /// - Returns: The tab's content.
    @ViewBuilder
    private func selectedContent(_ tab: _TabItem<SelectionValue>?) -> some View {
        if let tab {
            tab.content()
                .id(tab.value)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
