import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.ScrollObservation {
    public func setScrollChangeHandler(
        of scrollContainer: Widget,
        to action: @escaping @MainActor () -> Void
    ) {
        let clipView = (scrollContainer as! NSScrollView).contentView
        clipView.postsBoundsChangedNotifications = true
        ScrollChangeObservers.shared.observe(clipView, action: action)
    }
}

/// One bounds-change observation per clip view, replaced when its action is.
@MainActor
final class ScrollChangeObservers {
    static let shared = ScrollChangeObservers()

    private var tokens: [ObjectIdentifier: NSObjectProtocol] = [:]

    func observe(_ clipView: NSClipView, action: @escaping @MainActor () -> Void) {
        let key = ObjectIdentifier(clipView)
        if let token = tokens[key] {
            NotificationCenter.default.removeObserver(token)
        }
        tokens[key] = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: clipView,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { action() }
        }
    }
}
