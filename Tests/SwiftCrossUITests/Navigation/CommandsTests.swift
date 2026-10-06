import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing Commands, CommandGroup and focused-value commands")
@MainActor
struct CommandsTests {
    struct Document {
        var name: String
    }

    struct DocumentKey: FocusedValueKey {
        typealias Value = Document
    }

    struct EditorCommands: Commands {
        var title: String

        var body: some Commands {
            CommandMenu("Shape") {
                Button(title) {}
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {}
            }
            CommandGroup(after: .sidebar) {
                Button("Show Inspector") {}
            }
            SidebarCommands()
        }
    }

    /// The labels of a resolved menu's items.
    func labels(_ menu: ResolvedMenu.Submenu) -> [String] {
        menu.content.items.compactMap { item in
            if case .button(let label, _) = item { label } else { nil }
        }
    }

    @Test("A Commands type's body resolves into menus, and groups join the standard menus")
    func commandsResolveIntoMenus() {
        let commands = ResolvedCommands(EditorCommands(title: "Mirror"))
        let menus = commands.resolve()

        #expect(menus.map(\.label) == ["Shape", "File", "View"])
        #expect(labels(menus[0]) == ["Mirror"])
        #expect(labels(menus[1]) == ["Settings…"])
        #expect(labels(menus[2]) == ["Show Inspector"])
    }

    @Test("Overlaid commands merge menus of the same name in order")
    func overlaidCommandsMerge() {
        let first = ResolvedCommands(CommandMenu("Go") { Button("Back") {} })
        let second = ResolvedCommands(CommandMenu("Go") { Button("Forward") {} })
        let menus = first.overlayed(with: second).resolve()

        #expect(menus.map(\.label) == ["Go"])
        #expect(labels(menus[0]) == ["Back", "Forward"])
    }

    @Test("A command's body is read each time the menus resolve")
    func commandBodiesAreReadOnDemand() {
        let title = StateBox("First")
        struct DynamicCommands: Commands {
            let title: StateBox<String>
            var body: some Commands {
                CommandMenu("Edit") { Button(title.value) {} }
            }
        }
        let commands = ResolvedCommands(DynamicCommands(title: title))
        #expect(labels(commands.resolve()[0]) == ["First"])

        title.value = "Second"
        #expect(labels(commands.resolve()[0]) == ["Second"])
    }
}
