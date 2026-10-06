import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A destination that isn't `Codable`, as SwiftUI paths allow.
private enum Page: Hashable {
    case detail(String)
}

@Suite("Testing navigation bars: titles, toolbars, search and back navigation")
@MainActor
struct NavigationBarTests {
    @Test("A page's title and toolbar items are drawn in its stack's bar, in placement order")
    func titleAndToolbarItemsAreDrawnInTheBar() {
        let harness = GraphHarness {
            NavigationStack {
                Text("Content")
                    .navigationTitle("Library")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Done") {} }
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") {} }
                    }
            }
        }
        harness.render()

        #expect(harness.texts == ["Cancel", "Library", "Done", "Content"])
    }

    @Test("Toolbar content composes with conditions and custom ToolbarContent")
    func toolbarContentComposes() {
        struct ShareItem: ToolbarContent {
            var body: some ToolbarContent {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Share") {}
                    Button("Delete") {}
                }
            }
        }
        let showsShare = StateBox(false)
        let harness = GraphHarness {
            NavigationStack {
                Text("Content")
                    .toolbar {
                        if showsShare.value { ShareItem() }
                        ToolbarSpacer(.flexible)
                        ToolbarItem(placement: .principal) { Text("Centre") }
                    }
            }
        }
        harness.render()
        #expect(harness.texts == ["Centre", "Content"])

        showsShare.value = true
        harness.render()
        #expect(harness.texts == ["Centre", "Share", "Delete", "Content"])
    }

    @Test("A toolbar outside any navigation container draws a bar of its own")
    func toolbarWithoutAContainerDrawsItsOwnBar() {
        let harness = GraphHarness {
            Text("Sheet")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") {} }
                }
        }
        harness.render()

        #expect(harness.texts == ["Cancel", "Sheet"])
    }

    @Test("A title outside any navigation container is not drawn")
    func titleWithoutAContainerIsDropped() {
        let harness = GraphHarness {
            Text("Content").navigationTitle("Untitled")
        }
        harness.render()

        #expect(harness.texts == ["Content"])
    }

    @Test("The innermost title wins, and toolbar(removing: .title) hides it")
    func innermostTitleWinsAndCanBeRemoved() {
        let removesTitle = StateBox(false)
        let harness = GraphHarness {
            NavigationStack {
                Text("Content")
                    .navigationTitle("Inner")
                    .toolbar(removing: removesTitle.value ? .title : nil)
                    .navigationTitle("Outer")
            }
        }
        harness.render()
        #expect(harness.texts == ["Inner", "Content"])

        removesTitle.value = true
        harness.render()
        #expect(harness.texts == ["Content"])
    }

    @Test("A hidden bar draws nothing")
    func hiddenBarDrawsNothing() {
        let harness = GraphHarness {
            NavigationStack {
                Text("Content")
                    .navigationTitle("Title")
                    .toolbar(.hidden)
            }
        }
        harness.render()

        #expect(harness.texts == ["Content"])
    }

    @Test("A typed path resolves destinations declared inside the stack, and Back pops it")
    func typedPathResolvesDeclaredDestinations() {
        let path = StateBox<[Page]>([])
        let harness = GraphHarness {
            NavigationStack(path: path.binding) {
                NavigationLink(value: Page.detail("Physics")) { Text("Open") }
                    .navigationDestination(for: Page.self) { page in
                        switch page {
                            case .detail(let name): Text("Detail \(name)")
                        }
                    }
            }
        }
        harness.render()
        #expect(harness.texts == ["Open"])

        harness.click("Open")
        #expect(path.value == [.detail("Physics")])
        harness.render()
        #expect(harness.texts == ["Back", "Detail Physics"])

        harness.click("Back")
        #expect(path.value.isEmpty)
        harness.render()
        #expect(harness.texts == ["Open"])
    }

    @Test("A path set before the stack first appears still finds its destination")
    func presetPathFindsItsDestination() {
        let path = StateBox<[Page]>([.detail("Chemistry")])
        let harness = GraphHarness {
            NavigationStack(path: path.binding) {
                Text("Root")
                    .navigationDestination(for: Page.self) { page in
                        switch page {
                            case .detail(let name): Text("Detail \(name)")
                        }
                    }
            }
        }
        // The root shows first, declares the destination, and the stack then
        // shows the page.
        harness.render(passes: 3)

        #expect(harness.texts == ["Back", "Detail Chemistry"])
    }

    @Test("A value path shows a Back button that removes the last element")
    func valuePathShowsABackButton() {
        let path = PathSource()
        let harness = GraphHarness {
            NavigationStack(path: path.binding) {
                Text("Root")
            }
            .navigationDestination(for: NavigationSubject.self) { subject in
                Text(subject.name)
            }
        }
        path.value.append(NavigationSubject(name: "Biology"))
        harness.render()
        #expect(harness.texts == ["Back", "Biology"])

        harness.click("Back")
        harness.render()
        #expect(harness.texts == ["Root"])
        #expect(path.value.isEmpty)
    }

    @Test("A search field edits its binding and submits through onSubmit(of: .search)")
    func searchFieldEditsItsBindingAndSubmits() throws {
        let query = StateBox("")
        let submitted = StateBox(0)
        let harness = GraphHarness {
            NavigationStack {
                Text(query.value.isEmpty ? "Everything" : "Results for \(query.value)")
                    .searchable(text: query.binding, prompt: "Movies")
                    .onSubmit(of: .search) { submitted.value += 1 }
            }
        }
        harness.render()
        let field = try #require(harness.first(DummyBackend.TextField.self))
        #expect(field.placeholder == "Movies")

        field.changeHandler?("dune")
        #expect(query.value == "dune")
        harness.render()
        #expect(harness.texts.contains("Results for dune"))

        field.submitHandler?()
        #expect(submitted.value == 1)
    }

    @Test("onSubmit(of: .text) still runs for ordinary text fields, and not for search")
    func textSubmitTriggerIsSeparateFromSearch() throws {
        let text = StateBox("")
        let submitted = StateBox(0)
        let harness = GraphHarness {
            TextField("Name", text: text.binding)
                .onSubmit(of: .search) { submitted.value += 100 }
                .onSubmit(of: .text) { submitted.value += 1 }
        }
        harness.render()
        let field = try #require(harness.first(DummyBackend.TextField.self))
        field.submitHandler?()

        #expect(submitted.value == 1)
    }
}
