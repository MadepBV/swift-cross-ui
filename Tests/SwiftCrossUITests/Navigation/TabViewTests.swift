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
}
