/// Counts the work a commit asks of the backend, so that a phase's cost can be
/// attributed rather than guessed at.
///
/// Timings tell you which *phase* is expensive; they don't tell you which of
/// the dozen things a phase does is responsible. Twice now a plausible
/// explanation for a phase's cost has turned out to be wrong under measurement,
/// so the counts live here and any driver can turn them on.
///
/// Counting is off by default and costs one static `Bool` read when off, so
/// instrumented call sites can sit in the hot path.
///
/// ```swift
/// BackendCallStatistics.startCounting()
/// pass()
/// let counts = BackendCallStatistics.stopCounting()
/// ```
@_spi(Backends)
@MainActor
public enum BackendCallStatistics {
    /// Whether counting is on.
    ///
    /// Read on every instrumented call site, so it is a plain stored property
    /// rather than anything that could allocate or lock.
    public private(set) static var isCounting = false

    private static var counts: [String: Int] = [:]

    /// Starts counting, discarding anything counted before.
    public static func startCounting() {
        counts.removeAll(keepingCapacity: true)
        isCounting = true
    }

    /// Stops counting and returns what was counted.
    ///
    /// - Returns: The number of times each event was recorded.
    @discardableResult
    public static func stopCounting() -> [String: Int] {
        isCounting = false
        return counts
    }

    /// Records an event, if counting is on.
    ///
    /// - Parameters:
    ///   - event: What happened. Grouped by a dotted prefix naming the part of
    ///     the framework responsible, so a report can be read by area.
    ///   - count: How many times.
    @inline(__always)
    public static func record(_ event: String, _ count: Int = 1) {
        guard isCounting else { return }
        counts[event, default: 0] += count
    }
}
