import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.WindowClosing {
    public func close(window: Window) {
        window.requestAuthorizedClose()
    }

    public func setCloseHandler(
        ofWindow window: Window,
        to action: @escaping () -> Void
    ) {
        window.customDelegate.setCloseHandler(action)
    }
}
