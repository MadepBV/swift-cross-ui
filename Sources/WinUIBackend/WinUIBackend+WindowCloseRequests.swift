@_spi(Backends) import SwiftCrossUI
import WinAppSDK
import WinUI
@preconcurrency import WindowsFoundation

extension WinUIBackend: BackendFeatures.WindowCloseRequests {
    public func setCloseRequestHandler(
        ofWindow window: Window,
        to action: (@MainActor @Sendable () async -> Bool)?
    ) {
        if let controller = window.closeRequestController {
            controller.coordinator.setHandler(action)
        } else if action != nil {
            let controller = WinUIWindowCloseRequestController(window: window)
            controller.coordinator.setHandler(action)
            window.closeRequestController = controller
        }
    }
}

extension CustomWindow {
    @MainActor
    func requestAuthorizedClose() {
        if let closeRequestController {
            closeRequestController.requestClose()
        } else {
            try! close()
        }
    }
}

@MainActor
final class WinUIWindowCloseRequestController {
    weak var window: CustomWindow?
    let coordinator = WindowCloseRequestCoordinator()
    private var closingSubscription: WindowsFoundation.EventCleanup?
    private var closedSubscription: WindowsFoundation.EventCleanup?

    init(window: CustomWindow) {
        self.window = window
        closingSubscription = window.cachedAppWindow.closing.addHandler { [weak self] _, args in
            MainActor.assumeIsolated {
                guard let self, let args, !args.cancel else { return }
                // AppWindow.Closing is synchronous: cancel before returning to
                // WinUI, while an asynchronous Save/Discard/Cancel flow runs.
                if self.shouldDeferClose() { args.cancel = true }
            }
        }
        closedSubscription = window.closed.addHandler { [weak self] _, _ in
            MainActor.assumeIsolated {
                self?.coordinator.windowDidClose()
                self?.closingSubscription?.dispose()
                self?.closedSubscription?.dispose()
                self?.closingSubscription = nil
                self?.closedSubscription = nil
            }
        }
    }

    func requestClose() {
        // Window.close() is also called by dismissWindow; do not depend on it
        // raising the user-originated AppWindow.Closing notification.
        if !shouldDeferClose() { try? window?.close() }
    }

    private func shouldDeferClose() -> Bool {
        coordinator.shouldDeferClose { [weak self] in
            try? self?.window?.close()
        }
    }
}
