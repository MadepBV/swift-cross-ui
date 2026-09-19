import Testing
@_spi(Backends) @testable import SwiftCrossUI

@Suite("Deferred native selection echoes")
struct NativeSelectionTrackerTests {
    @Test("Pre-load model writes collapse to the realized current index without an edit")
    func delayedRealizationOfLatestModelSelection() {
        var state = NativeSelectionTracker<Int?>(initialSelection: nil)
        state.recordProgrammaticSelection(1)
        state.recordProgrammaticSelection(nil)
        state.recordProgrammaticSelection(2)
        // WinUI's loaded repeater reports the current property after all three
        // model setters returned, outside their synchronous suppression scope.
        #expect(state.shouldForwardNativeSelection(2) == false)
        #expect(state.shouldForwardNativeSelection(2) == false)
        #expect(state.shouldForwardNativeSelection(1) == true)
        #expect(state.shouldForwardNativeSelection(2) == true)
    }

    @Test("The next real selection is accepted even when no model echo is emitted")
    func absenceOfEchoDoesNotConsumeNextChange() {
        var state = NativeSelectionTracker<Int?>(initialSelection: nil)
        state.recordProgrammaticSelection(2)
        // Loaded controls may deliver only a synchronous, already-suppressed
        // echo. Do not reserve or discard the next notification blindly.
        #expect(state.shouldForwardNativeSelection(1) == true)
        #expect(state.shouldForwardNativeSelection(2) == true)
        #expect(state.shouldForwardNativeSelection(2) == false)
    }

    @Test("An equal native property write still acknowledges its pending realization")
    func skippedNativeSetterStillAcknowledgesModel() {
        var state = NativeSelectionTracker<Int?>(initialSelection: nil)
        let nativeProperty: Int? = 2 // Property changed; delivery has not occurred.
        state.recordProgrammaticSelection(nativeProperty)
        // The backend may now return early because nativeProperty == model.
        #expect(state.shouldForwardNativeSelection(nativeProperty) == false)
        #expect(state.shouldForwardNativeSelection(0) == true)
        #expect(state.shouldForwardNativeSelection(nativeProperty) == true)
    }

    @Test("No-selection is a value and can be selected again after a real change")
    func nilRoundTrip() {
        var state = NativeSelectionTracker<Int?>(initialSelection: nil)
        state.recordProgrammaticSelection(2)
        state.recordProgrammaticSelection(nil)
        #expect(state.shouldForwardNativeSelection(nil) == false)
        #expect(state.shouldForwardNativeSelection(1) == true)
        #expect(state.shouldForwardNativeSelection(nil) == true)
        #expect(state.shouldForwardNativeSelection(nil) == false)
    }

    @Test("A reentrant model write inside the callback remains the acknowledged value")
    func reentrantModelWriteWins() {
        var state = NativeSelectionTracker<Int?>(initialSelection: 0)
        var delivered: [Int?] = []
        if state.shouldForwardNativeSelection(1) {
            delivered.append(1)
            // Application validation chooses another value synchronously.
            state.recordProgrammaticSelection(2)
        }
        #expect(state.shouldForwardNativeSelection(2) == false)
        if state.shouldForwardNativeSelection(1) { delivered.append(1) }
        #expect(delivered == [1, 1])
    }
}
