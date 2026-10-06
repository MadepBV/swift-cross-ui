import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Menu tests")
struct MenuTests {
    @MainActor
    @Test(
        "Ensure buttons encode to menu items correctly",
        .bug("https://github.com/moreSwift/swift-cross-ui/issues/747")
    )
    func buttonMenuItemEncoding() throws {
        let labels = [
            "Button1",
            "Button2"
        ]
        let view = Menu("Menu") {
            Button(labels[0]) {}
            Button(action: {}) {
                Text(labels[1])
            }
        }

        let node = ViewGraphHelpers.committedNode(for: view)

        let button = try #require(node.widget as? DummyBackend.SimpleButton)
        let menu = try #require(button.menu)
        for (i, item) in menu.content.items.enumerated() {
            switch item {
                case .button(let label, let action):
                    #expect(label == labels[i])
                    #expect(action != nil)
                default:
                    Issue.record("Expected button, got \(item)")
            }
        }
    }

    @MainActor
    @Test("A menu with a label view draws the view on a button that shows the menu")
    func labelViewMenuDrawsItsLabel() throws {
        let view = Menu {
            Button("Mark as Watched") {}
        } label: {
            Label("Watched", systemImage: "checkmark.circle").labelStyle(.iconOnly)
        }

        let node = ViewGraphHelpers.committedNode(for: view)

        let button = try #require(node.widget as? DummyBackend.Button)
        #expect(button.label != nil)
        let menu = try #require(button.menu)
        guard case .button(let title, _) = menu.content.items.first else {
            Issue.record("Expected the menu's button, got \(menu.content.items)")
            return
        }
        #expect(title == "Mark as Watched")
    }
}
