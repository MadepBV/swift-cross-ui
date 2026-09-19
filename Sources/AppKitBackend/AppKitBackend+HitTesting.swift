import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.HitTesting {
    public func createHitTestingContainer(wrapping child: Widget) -> Widget {
        let container = NSHitTestingContainer()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false
        child.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        child.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        return container
    }

    public func setAllowsHitTesting(_ allowsHitTesting: Bool, of container: Widget) {
        (container as! NSHitTestingContainer).allowsChildHitTesting = allowsHitTesting
    }
}

final class NSHitTestingContainer: NSView {
    var allowsChildHitTesting = true
    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard allowsChildHitTesting else { return nil }
        let hit = super.hitTest(point)
        // The wrapper must not introduce an input surface in empty space.
        return hit === self ? nil : hit
    }
}
