import Foundation
@_spi(Backends) import SwiftCrossUI
import WinUI

extension WinUIBackend: BackendFeatures.ScrollObservation {
    public func setScrollChangeHandler(
        of scrollContainer: Widget,
        to action: @escaping @MainActor () -> Void
    ) {
        let scrollViewer = scrollContainer as! WinUI.ScrollViewer
        // A handler is added once per scroll viewer; later calls replace the
        // action it runs.
        let key = ObjectIdentifier(scrollViewer)
        let isNew = ScrollChangeActions.actions[key] == nil
        ScrollChangeActions.actions[key] = action
        guard isNew else {
            return
        }
        scrollViewer.viewChanged.addHandler { [weak scrollViewer] _, _ in
            guard let scrollViewer else { return }
            ScrollChangeActions.actions[ObjectIdentifier(scrollViewer)]?()
        }
    }
}

@MainActor
enum ScrollChangeActions {
    static var actions: [ObjectIdentifier: @MainActor () -> Void] = [:]
}
