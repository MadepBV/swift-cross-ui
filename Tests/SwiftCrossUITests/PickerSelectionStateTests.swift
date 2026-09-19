import Testing
@_spi(Backends) @testable import SwiftCrossUI
#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

@Suite("Picker model-update feedback")
@MainActor
struct PickerSelectionStateTests {
    @Test("Programmatic option/index notifications never invoke document setters")
    func programmaticEventsAreNotEdits() {
        let state = PickerSelectionState()
        var selected: Int? = 2
        var edits: [Int?] = []
        state.update(binding: Binding { selected } set: { edits.append($0); selected = $0 },
                     optionCount: 3, isEnabled: true)
        state.beginProgrammaticUpdate()
        // Item rebuilds can temporarily clear selection or select the first item.
        state.selectionChanged(nil)
        state.selectionChanged(0)
        state.selectionChanged(2)
        state.endProgrammaticUpdate()
        #expect(edits.isEmpty)
        #expect(selected == 2)
        // A delayed echo after the model-to-control write is still a no-op.
        state.selectionChanged(2)
        #expect(edits.isEmpty)
        state.selectionChanged(1)
        state.selectionChanged(1)
        #expect(edits == [1])
        #expect(selected == 1)
    }

    @Test("Unchanged option titles retain the latest binding, not the initial row")
    func latestBindingReplacesCapturedRow() {
        let state = PickerSelectionState()
        var oldValue: Int? = 0
        var newValue: Int? = 0
        var oldEdits = 0
        var newEdits = 0
        state.update(binding: Binding { oldValue } set: { oldValue = $0; oldEdits += 1 },
                     optionCount: 3, isEnabled: true)
        let installedCallback: (Int?) -> Void = { [weak state] in state?.selectionChanged($0) }
        state.update(binding: Binding { newValue } set: { newValue = $0; newEdits += 1 },
                     optionCount: 3, isEnabled: true)
        installedCallback(2)
        #expect(oldValue == 0)
        #expect(oldEdits == 0)
        #expect(newValue == 2)
        #expect(newEdits == 1)
    }

    @Test("No-selection echoes do not turn into selecting the first option")
    func nilSelectionDoesNotCommit() {
        let state = PickerSelectionState()
        var value: Int?
        var edits: [Int?] = []
        state.update(binding: Binding { value } set: { value = $0; edits.append($0) },
                     optionCount: 3, isEnabled: true)
        state.beginProgrammaticUpdate()
        state.selectionChanged(0)
        state.endProgrammaticUpdate()
        state.selectionChanged(nil)
        #expect(value == nil)
        #expect(edits.isEmpty)
        state.selectionChanged(0)
        state.selectionChanged(nil)
        #expect(edits == [0, nil])
    }

    @Test("Out-of-range and disabled native notifications cannot mutate bindings")
    func invalidAndDisabledSelectionsAreIgnored() {
        let state = PickerSelectionState()
        var value: Int? = 0
        var writes = 0
        let binding = Binding { value } set: { value = $0; writes += 1 }
        state.update(binding: binding, optionCount: 2, isEnabled: true)
        state.selectionChanged(-1)
        state.selectionChanged(2)
        state.selectionChanged(Int.max)
        #expect(writes == 0)
        state.update(binding: binding, optionCount: 2, isEnabled: false)
        state.selectionChanged(1)
        state.selectionChanged(nil)
        #expect(writes == 0)
        state.update(binding: binding, optionCount: 2, isEnabled: true)
        state.selectionChanged(1)
        #expect(value == 1)
        #expect(writes == 1)
    }

    @Test("Nested native model updates remain suppressed until the outer scope ends")
    func nestedProgrammaticUpdates() {
        let state = PickerSelectionState()
        var value: Int? = 0
        var writes = 0
        state.update(binding: Binding { value } set: { value = $0; writes += 1 },
                     optionCount: 3, isEnabled: true)
        state.beginProgrammaticUpdate()
        state.beginProgrammaticUpdate()
        state.selectionChanged(1)
        state.endProgrammaticUpdate()
        state.selectionChanged(2)
        state.endProgrammaticUpdate()
        #expect(writes == 0)
        state.selectionChanged(2)
        #expect(value == 2)
        #expect(writes == 1)
    }

    @Test("Replacing the binding releases the previous captured document")
    func bindingLifetime() {
        final class Owner { var value: Int? = 0 }
        let state = PickerSelectionState()
        weak var oldOwner: Owner?
        do {
            let owner = Owner()
            oldOwner = owner
            state.update(binding: Binding { owner.value } set: { owner.value = $0 },
                         optionCount: 2, isEnabled: true)
        }
        #expect(oldOwner != nil)
        state.update(binding: Binding(get: { nil }, set: { _ in }), optionCount: 0, isEnabled: false)
        #expect(oldOwner == nil)
    }

    #if canImport(AppKitBackend)
    @Test("Built-in picker layout refreshes a replaced binding while cached titles stay equal")
    func cachedNativeWidgetUsesLatestBinding() throws {
        let backend = AppKitBackend()
        let environment = EnvironmentValues(backend: backend)
        var oldValue: Int? = 0
        var newValue: Int? = 0
        var oldWrites = 0
        var newWrites = 0
        var view = _BuiltinPickerImplementation(
            style: .menu, options: ["None", "90 degrees", "135 degrees"],
            selectedIndex: Binding { oldValue } set: { oldValue = $0; oldWrites += 1 })
        let children = view.children(backend: backend, snapshots: nil, environment: environment)
        let widget = view.asWidget(children, backend: backend)
        _ = view.computeLayout(widget, children: children,
            proposedSize: ProposedViewSize(240, 80), environment: environment, backend: backend)
        let popup = try #require(children.picker?.widget as? NSPopUpButton)
        view.selectedIndex = Binding { newValue } set: { newValue = $0; newWrites += 1 }
        _ = view.computeLayout(widget, children: children,
            proposedSize: ProposedViewSize(241, 80), environment: environment, backend: backend)
        #expect(oldWrites == 0 && newWrites == 0)
        #expect(children.picker?.widget as? NSPopUpButton === popup)
        popup.selectItem(at: 2)
        popup.onAction?(popup)
        #expect(oldWrites == 0 && oldValue == 0)
        #expect(newWrites == 1 && newValue == 2)
        popup.onAction?(popup)
        #expect(newWrites == 1)
    }
    @Test("Callbacks from a replaced native picker cannot edit the new binding")
    func retiredNativeWidgetCannotWriteIntoReplacementBinding() throws {
        let backend = AppKitBackend()
        let environment = EnvironmentValues(backend: backend)
        var oldValue: Int? = 0
        var newValue: Int? = 0
        var oldWrites = 0
        var newWrites = 0
        var view = _BuiltinPickerImplementation(
            style: .menu, options: ["None", "90 degrees", "135 degrees"],
            selectedIndex: Binding { oldValue } set: { oldValue = $0; oldWrites += 1 })
        let children = view.children(backend: backend, snapshots: nil, environment: environment)
        let widget = view.asWidget(children, backend: backend)
        _ = view.computeLayout(widget, children: children,
            proposedSize: ProposedViewSize(240, 80), environment: environment, backend: backend)
        // Native delivery can retain the old control/action across a rebuild.
        let oldPopup = try #require(children.picker?.widget as? NSPopUpButton)
        let oldAction = try #require(oldPopup.onAction)

        view.style = .segmented
        view.selectedIndex = Binding { newValue } set: { newValue = $0; newWrites += 1 }
        _ = view.computeLayout(widget, children: children,
            proposedSize: ProposedViewSize(241, 80), environment: environment, backend: backend)
        let replacement = try #require(children.picker?.widget as? NSSegmentedControl)
        #expect(oldWrites == 0 && newWrites == 0)

        // Delivered after computeLayout returns: depth suppression alone no
        // longer applies. This index is valid and differs from the new model.
        oldPopup.selectItem(at: 2)
        oldAction(oldPopup)
        #expect(oldValue == 0 && oldWrites == 0)
        #expect(newValue == 0 && newWrites == 0)

        replacement.selectedSegment = 1
        let replacementAction = try #require(replacement.onAction)
        replacementAction(replacement)
        #expect(newValue == 1 && newWrites == 1)
        oldAction(oldPopup)
        #expect(oldValue == 0 && oldWrites == 0)
        #expect(newValue == 1 && newWrites == 1)
    }
    #endif
}
