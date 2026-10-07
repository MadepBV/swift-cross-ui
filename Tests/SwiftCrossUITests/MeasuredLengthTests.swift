import Testing

@testable @_spi(Backends) import SwiftCrossUI

@Suite("Natively measured lengths")
struct MeasuredLengthTests {
    @Test("A fractional measurement rounds up, so a label sized to it never wraps")
    func fractionalMeasurementRoundsUp() {
        // WinUI reports a text block's desired width in half points at 200 %
        // scaling; truncating 102.5 to 102 wrapped "Sign in to Avelio".
        #expect(LayoutSystem.measuredLength(102.5) == 103)
        #expect(LayoutSystem.measuredLength(102.01) == 103)
        #expect(LayoutSystem.measuredLength(0.5) == 1)
    }

    @Test("Floating point noise on a whole measurement adds nothing")
    func wholeMeasurementStaysWhole() {
        #expect(LayoutSystem.measuredLength(102) == 102)
        #expect(LayoutSystem.measuredLength(102.0004) == 102)
        #expect(LayoutSystem.measuredLength(101.9996) == 102)
        #expect(LayoutSystem.measuredLength(0) == 0)
    }
}
