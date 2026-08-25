import Foundation
import Mutex
import Logging

private struct SourceLocation: Hashable {
    let file: String
    let line: UInt
}
private let warnedSourceLocations: Mutex<Set<SourceLocation>> = Mutex([])

extension Logger {
    /// Logs a warning the first time a call site is reached, and never again.
    ///
    /// Exposed to backends so that a degraded rendering can be reported once
    /// without flooding the log on every update.
    @_spi(Backends) public func warnOnce(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        warnedSourceLocations.withLock { sourceLocations in
            guard sourceLocations.insert(.init(file: file, line: line)).inserted else {
                return
            }
            warning(
                message(),
                metadata: metadata(),
                file: file,
                function: function,
                line: line
            )
        }
    }
}
