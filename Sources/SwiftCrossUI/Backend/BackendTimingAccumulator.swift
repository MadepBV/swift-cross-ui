/// A bounded, value-type accumulator for opt-in backend diagnostics.
///
/// Counts, totals and maxima cover every record. Percentiles describe only the
/// most recent `sampleLimit` wall durations; they are not a random sample of an
/// unbounded stream. Take a value snapshot under the recorder's lock and compute
/// `summary` outside that lock. This type performs no I/O or clock reads.
@_spi(Backends)
public struct BackendTimingAccumulator: Sendable {
    public struct Summary: Sendable {
        public let count: UInt64
        public let wallNanoseconds: UInt64
        public let maximumWallNanoseconds: UInt64
        public let maximumWallStartTick: UInt64
        public let cpuAtMaximumWallNanoseconds: UInt64?
        public let cpuSampleCount: UInt64
        public let cpuNanoseconds: UInt64
        public let maximumCPUNanoseconds: UInt64
        public let retainedSampleCount: Int
        public let p50WallNanoseconds: UInt64
        public let p95WallNanoseconds: UInt64
    }

    private let sampleLimit: Int
    private var count: UInt64 = 0
    private var wall: UInt64 = 0
    private var maximumWall: UInt64 = 0
    private var maximumWallStartTick: UInt64 = 0
    private var cpuAtMaximumWall: UInt64?
    private var cpuCount: UInt64 = 0
    private var cpu: UInt64 = 0
    private var maximumCPU: UInt64 = 0
    private var samples: [UInt64] = []
    private var nextSample = 0

    public init(sampleLimit: Int = 512) {
        self.sampleLimit = max(0, sampleLimit)
    }

    public mutating func record(
        wallNanoseconds: UInt64,
        cpuNanoseconds: UInt64? = nil,
        startTick: UInt64 = 0
    ) {
        count &+= 1
        wall &+= wallNanoseconds
        if wallNanoseconds > maximumWall {
            maximumWall = wallNanoseconds
            maximumWallStartTick = startTick
            cpuAtMaximumWall = cpuNanoseconds
        }
        if let cpuNanoseconds {
            cpuCount &+= 1
            cpu &+= cpuNanoseconds
            maximumCPU = max(maximumCPU, cpuNanoseconds)
        }
        if samples.count < sampleLimit {
            samples.append(wallNanoseconds)
        } else if sampleLimit > 0 {
            samples[nextSample] = wallNanoseconds
            nextSample = (nextSample + 1) % sampleLimit
        }
    }

    public var summary: Summary {
        let sorted = samples.sorted()
        func percentile(_ numerator: Int, _ denominator: Int) -> UInt64 {
            guard !sorted.isEmpty else { return 0 }
            let rank = (sorted.count * numerator + denominator - 1) / denominator
            return sorted[max(0, rank - 1)]
        }
        return Summary(
            count: count, wallNanoseconds: wall,
            maximumWallNanoseconds: maximumWall,
            maximumWallStartTick: maximumWallStartTick,
            cpuAtMaximumWallNanoseconds: cpuAtMaximumWall,
            cpuSampleCount: cpuCount, cpuNanoseconds: cpu,
            maximumCPUNanoseconds: maximumCPU,
            retainedSampleCount: sorted.count,
            p50WallNanoseconds: percentile(1, 2),
            p95WallNanoseconds: percentile(95, 100))
    }
}
