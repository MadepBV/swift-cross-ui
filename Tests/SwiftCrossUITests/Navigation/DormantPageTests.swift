import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

private enum Section: Hashable {
    case home
    case library
}

private enum Page: Hashable {
    case detail
}

/// A tab left, or a page pushed over, stays alive but out of sight, as in
/// SwiftUI: coming back shows the same views with their state, without
/// building them again, and the views disappear and appear as they're left
/// and shown.
extension GraphHarness {
    func texts(in widget: DummyBackend.Widget) -> [String] {
        ((widget as? DummyBackend.TextView).map { [$0.content] } ?? [])
            + widget.getChildren().flatMap { texts(in: $0) }
    }
}

@Suite("Dormant tabs and covered pages")
@MainActor
struct DormantPageTests {
    struct Counter: View {
        var name: String
        var log: StateBox<[String]>
        @State private var count = 0

        var body: some View {
            Button("\(name) \(count)") { count += 1 }
                .onAppear { log.value.append("appear \(name)") }
                .onDisappear { log.value.append("disappear \(name)") }
        }
    }

    @Test("A tab keeps its state while another is selected, and isn't built again")
    func tabKeepsState() {
        let selection = StateBox(Section.home)
        let log = StateBox<[String]>([])
        let harness = GraphHarness {
            TabView(selection: selection.binding) {
                Tab("Home", value: Section.home) { Counter(name: "Home", log: log) }
                Tab("Library", value: Section.library) { Counter(name: "Library", log: log) }
            }
        }
        harness.render(passes: 1)
        let homeButton = harness.widgets.first { widget in
            (widget as? DummyBackend.Button)?.label.map { harness.texts(in: $0) == ["Home 0"] } ?? false
        }
        #expect(homeButton != nil)
        harness.click("Home 0")
        harness.render(passes: 1)
        #expect(harness.texts.contains("Home 1"))

        selection.value = .library
        harness.render(passes: 1)
        #expect(harness.texts.contains("Library 0"))
        #expect(!harness.texts.contains("Home 1"))

        harness.backend.resetCallCounts()
        selection.value = .home
        harness.render(passes: 1)
        #expect(harness.texts.contains("Home 1"))
        #expect(!harness.texts.contains("Library 0"))
        // Shown again, not rebuilt: the same button.
        #expect(harness.widgets.contains { $0 === homeButton! })
        // Each tab disappeared as it was left and appeared as it was shown.
        #expect(log.value.filter { $0.hasSuffix("Home") } == ["appear Home", "disappear Home", "appear Home"])
        #expect(log.value.filter { $0.hasSuffix("Library") } == ["appear Library", "disappear Library"])
    }

    @Test("Back shows the page that was covered, with its state and its title")
    func backKeepsCoveredPage() {
        let path = StateBox<[Page]>([])
        let log = StateBox<[String]>([])
        let harness = GraphHarness {
            NavigationStack(path: path.binding) {
                VStack {
                    Counter(name: "Root", log: log)
                    NavigationLink(value: Page.detail) { Text("Open") }
                }
                .navigationTitle("Root title")
                .navigationDestination(for: Page.self) { _ in
                    Text("Detail page").navigationTitle("Detail title")
                }
            }
        }
        harness.render()
        harness.click("Root 0")
        harness.render()
        #expect(harness.texts.contains("Root title"))

        harness.click("Open")
        harness.render()
        #expect(harness.texts.contains("Detail page"))
        #expect(harness.texts.contains("Detail title"))
        #expect(!harness.texts.contains("Root title"))
        #expect(!harness.texts.contains("Root 1"))

        harness.click("Back")
        harness.render()
        #expect(harness.texts.contains("Root 1"))
        #expect(harness.texts.contains("Root title"))
        #expect(!harness.texts.contains("Detail title"))
        #expect(log.value == ["appear Root", "disappear Root", "appear Root"])
    }
}
