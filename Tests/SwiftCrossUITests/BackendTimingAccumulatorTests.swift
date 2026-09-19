import Testing
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Bounded backend timing diagnostics")
struct BackendTimingAccumulatorTests {
    @Test func emptyAndMissingCPUAreDistinctFromMeasuredZero() {
        var accumulator = BackendTimingAccumulator()
        #expect(accumulator.summary.count == 0)
        #expect(accumulator.summary.retainedSampleCount == 0)
        accumulator.record(wallNanoseconds: 100, startTick: 5)
        accumulator.record(wallNanoseconds: 20, cpuNanoseconds: 0, startTick: 10)
        let value = accumulator.summary
        #expect(value.count == 2)
        #expect(value.wallNanoseconds == 120)
        #expect(value.maximumWallStartTick == 5)
        #expect(value.cpuSampleCount == 1)
        #expect(value.cpuNanoseconds == 0)
    }

    @Test func boundedWindowRetainsRecentSamplesButAllTotalsAndMaxima() {
        var accumulator = BackendTimingAccumulator(sampleLimit: 3)
        accumulator.record(wallNanoseconds: 1_000, cpuNanoseconds: 900, startTick: 7)
        for value in UInt64(1)...6 {
            accumulator.record(wallNanoseconds: value, cpuNanoseconds: value, startTick: value + 10)
        }
        let value = accumulator.summary
        #expect(value.count == 7)
        #expect(value.wallNanoseconds == 1_021)
        #expect(value.maximumWallNanoseconds == 1_000)
        #expect(value.maximumWallStartTick == 7)
        #expect(value.cpuSampleCount == 7)
        #expect(value.cpuNanoseconds == 921)
        #expect(value.maximumCPUNanoseconds == 900)
        #expect(value.retainedSampleCount == 3)
        #expect(value.p50WallNanoseconds == 5)
        #expect(value.p95WallNanoseconds == 6)
    }

    @Test func snapshotsStayIndependentWhileRecordingContinues() {
        var accumulator = BackendTimingAccumulator(sampleLimit: 2)
        accumulator.record(wallNanoseconds: 4)
        accumulator.record(wallNanoseconds: 8)
        let snapshot = accumulator
        accumulator.record(wallNanoseconds: 12)
        #expect(snapshot.summary.count == 2)
        #expect(snapshot.summary.p50WallNanoseconds == 4)
        #expect(accumulator.summary.count == 3)
        #expect(accumulator.summary.p50WallNanoseconds == 8)
    }

    @Test func worstWallIntervalRetainsItsOwnCPUTime() {
        var accumulator = BackendTimingAccumulator()
        accumulator.record(wallNanoseconds: 100, cpuNanoseconds: 80, startTick: 1)
        accumulator.record(wallNanoseconds: 20, cpuNanoseconds: 150, startTick: 2)
        #expect(accumulator.summary.cpuAtMaximumWallNanoseconds == 80)
        #expect(accumulator.summary.maximumCPUNanoseconds == 150)
        #expect(accumulator.summary.maximumWallStartTick == 1)
    }

    @Test func disabledSamplesStillCountAllEvents() {
        var accumulator = BackendTimingAccumulator(sampleLimit: 0)
        accumulator.record(wallNanoseconds: 30)
        #expect(accumulator.summary.count == 1)
        #expect(accumulator.summary.wallNanoseconds == 30)
        #expect(accumulator.summary.retainedSampleCount == 0)
        #expect(accumulator.summary.p95WallNanoseconds == 0)
    }
}
