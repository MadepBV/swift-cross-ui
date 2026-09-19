/// Keeps native picker notifications separate from model-to-control updates.
/// The binding is refreshed even when cached option titles remain unchanged.
@MainActor
final class PickerSelectionState {
    private var binding: Binding<Int?>?
    private var optionCount = 0
    private var isEnabled = false
    private var programmaticUpdateDepth = 0
    private var nativeWidgetGeneration: UInt64 = 0

    func update(binding: Binding<Int?>, optionCount: Int, isEnabled: Bool) {
        self.binding = binding
        self.optionCount = optionCount
        self.isEnabled = isEnabled
    }

    /// Retire callbacks before removing the old control, including notifications
    /// that arrive after the replacement's programmatic update has finished.
    func nativeWidgetWillBeReplaced() { nativeWidgetGeneration &+= 1 }

    func makeNativeSelectionHandler() -> (Int?) -> Void {
        let generation = nativeWidgetGeneration
        return { [weak self] index in
            guard let self, self.nativeWidgetGeneration == generation else { return }
            // Reusing this control keeps its callback valid; update(binding:)
            // still supplies whichever document/row is current at delivery.
            self.selectionChanged(index)
        }
    }

    func beginProgrammaticUpdate() { programmaticUpdateDepth += 1 }

    func endProgrammaticUpdate() {
        precondition(programmaticUpdateDepth > 0)
        programmaticUpdateDepth -= 1
    }

    func selectionChanged(_ index: Int?) {
        guard programmaticUpdateDepth == 0, isEnabled, let binding else { return }
        if let index, !(0..<optionCount).contains(index) { return }
        // Native events may echo a programmatic change after the write returns.
        // Binding setters can commit documents; do not call one for an echo.
        guard binding.wrappedValue != index else { return }
        binding.wrappedValue = index
    }
}
