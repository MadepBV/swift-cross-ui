import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.WindowCloseRequests {
    public func setCloseRequestHandler(
        ofWindow window: Window,
        to action: (@MainActor @Sendable () async -> Bool)?
    ) {
        window.closeRequestCoordinator.setHandler(action)
    }
}

extension NSCustomWindow {
    func requestAuthorizedClose() {
        // NSWindow.close() bypasses windowShouldClose, so programmatic close
        // requests need the same authorization as the title bar close button.
        if !shouldDeferClose() { close() }
    }

    func shouldDeferClose() -> Bool {
        closeRequestCoordinator.shouldDeferClose { [weak self] in
            self?.close()
        }
    }
}
