import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.ApplicationTerminationRequests {
    public func setApplicationTerminationRequestHandler(
        _ handler: (@MainActor @Sendable () async -> Bool)?
    ) {
        appDelegate.terminationRequests.setHandler(handler)
    }
}
