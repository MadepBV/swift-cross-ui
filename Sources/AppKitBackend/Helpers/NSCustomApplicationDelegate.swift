import AppKit
@_spi(Backends) import SwiftCrossUI

@MainActor
final class NSCustomApplicationDelegate: NSObject, NSApplicationDelegate {
    var onOpenURLs: (([URL]) -> Void)?
    let terminationRequests = ApplicationTerminationRequestCoordinator()

    func application(_ application: NSApplication, open urls: [URL]) {
        onOpenURLs?(urls)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Normal Quit bypasses windowShouldClose. AppKit requires one deferred
        // reply; retrying terminate/closing windows would prompt recursively or
        // dispose documents before the application's decision is complete.
        let deferred = terminationRequests.shouldDeferTermination { [weak sender] permitted in
            sender?.reply(toApplicationShouldTerminate: permitted)
        }
        return deferred ? .terminateLater : .terminateNow
    }
}
