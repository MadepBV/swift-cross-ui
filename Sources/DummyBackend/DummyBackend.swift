import Foundation
@_spi(Backends) import SwiftCrossUI

@MainActor
public final class DummyBackend: Sendable {
    public var incomingURLHandler: ((URL) -> Void)?
    public var appPhase = AppPhase.active

    public init() {}

    /// How many times each backend method has been called.
    ///
    /// Every one of these is a COM crossing on WinUI and a widget-tree mutation
    /// on AppKit and GTK, so the number of them per update pass is the
    /// backend-independent measure of how much work the framework is asking a
    /// real backend to do. Counting them here makes that measurable without a
    /// real backend.
    public private(set) var callCounts: [String: Int] = [:]

    /// Forgets the recorded call counts.
    public func resetCallCounts() {
        callCounts.removeAll(keepingCapacity: true)
    }

    /// The total number of backend calls recorded.
    public var totalCallCount: Int {
        callCounts.values.reduce(0, +)
    }

    /// Records a call to a backend method.
    ///
    /// - Parameter method: The method's name.
    @inline(__always)
    func record(_ method: String) {
        callCounts[method, default: 0] += 1
    }
}
