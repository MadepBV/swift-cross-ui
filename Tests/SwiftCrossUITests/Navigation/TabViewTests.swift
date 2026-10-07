import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

private enum Section: Hashable {
    case home
    case library
    case search
}

@Suite("Testing TabView and Tab")
@MainActor
struct TabViewTests {
    @Test("Activating a tab writes its value and shows its content")
    func activatingATabSelectsIt() {
        let selection = StateBox(Section.home)
        let harness = GraphHarness {
            TabView(selection: selection.binding) {
                Tab("Home", value: Section.home) { Text("Home page") }
                Tab("Library", value: Section.library) { Text("Library page") }
            }
        }
        harness.render(passes: 1)
        #expect(harness.texts == ["Home", "Library", "Home page"])

        harness.click("Library")
        #expect(selection.value == .library)
        harness.render(passes: 1)
        #expect(harness.texts == ["Home", "Library", "Library page"])
    }

    @Test("Search tabs come last, conditional tabs come and go, and an unknown selection shows the first tab")
    func tabOrderAndConditions() {
        let showsLibrary = StateBox(false)
        let selection = StateBox(Section.library)
        let harness = GraphHarness {
            TabView(selection: selection.binding) {
                Tab("Search", value: Section.search, role: .search) { Text("Search page") }
                Tab("Home", value: Section.home) { Text("Home page") }
                if showsLibrary.value {
                    Tab("Library", value: Section.library) { Text("Library page") }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
        }
        harness.render(passes: 1)
        #expect(harness.texts == ["Home", "Search", "Search page"])

        showsLibrary.value = true
        harness.render(passes: 1)
        #expect(harness.texts == ["Home", "Library", "Search", "Library page"])
    }

    @Test("Switching tabs gives the new tab fresh view state")
    func switchingTabsResetsState() {
        struct Counter: View {
            @State private var count = 0
            var body: some View {
                Button("Count \(count)") { count += 1 }
            }
        }
        let selection = StateBox(Section.home)
        let harness = GraphHarness {
            TabView(selection: selection.binding) {
                Tab("Home", value: Section.home) { Counter() }
                Tab("Library", value: Section.library) { Counter() }
            }
        }
        harness.render(passes: 1)
        harness.click("Count 0")
        harness.render(passes: 1)
        #expect(harness.texts.contains("Count 1"))

        selection.value = .library
        harness.render(passes: 1)
        #expect(harness.texts.contains("Count 0"))
    }

    @Test("The sidebar hides and shows, its button moving into the selected tab's navigation bar while it's hidden")
    func sidebarHidesAndShows() throws {
        let selection = StateBox(Section.home)
        let harness = GraphHarness {
            TabView(selection: selection.binding) {
                Tab("Home", value: Section.home) {
                    NavigationStack { Text("Home page").navigationTitle("Home title") }
                }
                Tab("Library", value: Section.library) { Text("Library page") }
            }
            .tabViewStyle(.sidebarAdaptable)
        }
        harness.render()
        #expect(harness.texts.contains("Library"))
        let toggles = harness.widgets.compactMap { $0 as? DummyBackend.Button }
        // The sidebar's button comes first; a showing sidebar puts none in the bar.
        try #require(toggles.first).action?()

        harness.render()
        #expect(!harness.texts.contains("Library"))
        #expect(harness.texts.contains("Home page"))
        let barToggle = try #require(harness.widgets.compactMap { $0 as? DummyBackend.Button }.first)
        barToggle.action?()

        harness.render()
        #expect(harness.texts.contains("Library"))
        #expect(harness.texts.contains("Home page"))
    }

    @Test("Sidebar rows are one height and as wide as each other, whichever is selected")
    func sidebarRowsAreUniform() {
        let selection = StateBox(Section.library)
        let harness = GraphHarness {
            TabView(selection: selection.binding) {
                Tab("Home", systemImage: "house", value: Section.home) { Text("Home page") }
                Tab("Library", systemImage: "books.vertical", value: Section.library) { Text("Library page") }
                Tab("Search", systemImage: "magnifyingglass", value: Section.search) { Text("Search page") }
            }
            .tabViewStyle(.sidebarAdaptable)
        }
        harness.render()
        // The first button is the sidebar's own toggle; the rest are the rows.
        let rows = Array(harness.widgets.compactMap { $0 as? DummyBackend.Button }.dropFirst())
        #expect(rows.count == 3)
        #expect(Set(rows.map(\.size)).count == 1)
    }
}
