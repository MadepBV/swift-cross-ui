@_spi(Backends) import SwiftCrossUI
import WinUI

extension WinUIBackend: BackendFeatures.HitTesting {
    public func createHitTestingContainer(wrapping child: Widget) -> Widget {
        let container = WinUI.Canvas()
        // A nil background adds no hit surface. Explicit transparent fills and
        // gesture targets inside the child keep their own native semantics.
        container.children.append(child)
        return container
    }

    public func setAllowsHitTesting(_ allowsHitTesting: Bool, of container: Widget) {
        guard container.isHitTestVisible != allowsHitTesting else { return }
        container.isHitTestVisible = allowsHitTesting
    }
}
