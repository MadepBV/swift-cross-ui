import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("ViewModifier")
struct ViewModifierTests {
    struct Inset: ViewModifier {
        var amount: Int

        func body(content: Content) -> some View {
            content.padding(amount)
        }
    }

    struct Counter: ViewModifier {
        @State var count = 0
        @Environment(\.layoutSpacing) var spacing

        func body(content: Content) -> some View {
            content
        }
    }

    @MainActor
    @Test("A modifier's body is applied to the content")
    func modifierApplies() {
        let result = ViewGraphHelpers.computeLayout(
            of: block(10, 10).modifier(Inset(amount: 5)),
            proposedSize: ProposedViewSize(100, 100)
        )
        #expect(result.size == ViewSize(20, 20))
    }

    @MainActor
    @Test("Concatenated modifiers apply in order")
    func concatenatedModifiers() {
        let result = ViewGraphHelpers.computeLayout(
            of: block(10, 10).modifier(Inset(amount: 2).concat(Inset(amount: 3))),
            proposedSize: ProposedViewSize(100, 100)
        )
        #expect(result.size == ViewSize(20, 20))
    }

    @MainActor
    @Test("The empty modifier leaves the content alone")
    func emptyModifier() {
        let result = ViewGraphHelpers.computeLayout(
            of: block(10, 10).modifier(EmptyModifier()),
            proposedSize: ProposedViewSize(100, 100)
        )
        #expect(result.size == ViewSize(10, 10))
    }

    @MainActor
    @Test("A modifier's dynamic properties are visible to the view graph")
    func modifierDynamicPropertiesAreFound() {
        let view = block(10, 10).modifier(Counter())
        var dynamicFields: [String] = []
        forEachViewField(of: view) { name, _, value in
            if value is any DynamicProperty {
                dynamicFields.append(name ?? "")
            }
        }
        #expect(dynamicFields.sorted() == ["_count", "_spacing"])
    }

    @MainActor
    @Test("A modifier's state is updated through its nested offset")
    func modifierStateIsUpdated() {
        // The updater reads each dynamic property at its byte offset in the
        // view; a wrong offset for a field nested in the modifier would read
        // garbage (or crash) rather than the modifier's own environment.
        let view = block(10, 10).modifier(Counter())
        let updater = DynamicPropertyUpdater(for: view)
        let environment = ViewGraphHelpers.environment.with(\.layoutSpacing, 42)
        updater.update(view, with: environment, previousValue: nil)
        #expect(view.modifier.spacing == 42)
    }
}
