import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.Masks {
    public func createMaskContainer(content: Widget, mask: Widget) -> Widget {
        let container = NSMaskContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        insert(content, into: container, at: 0)
        // The mask is never drawn in place: it stays out of the view
        // hierarchy, and its rendering becomes the container layer's mask.
        mask.translatesAutoresizingMaskIntoConstraints = true
        container.maskView = mask
        return container
    }

    public func updateMaskContainer(
        _ container: Widget,
        size: SIMD2<Int>,
        maskOrigin: SIMD2<Int>,
        maskSize: SIMD2<Int>
    ) {
        setPosition(ofChildAt: 0, in: container, to: .zero)
        setSize(of: container, to: size)
        guard let container = container as? NSMaskContainerView, let mask = container.maskView else {
            return
        }
        // Outside a window nothing lays the mask out or draws it, so both
        // happen here, once per commit.
        mask.frame = NSRect(x: 0, y: 0, width: maskSize.x, height: maskSize.y)
        mask.layoutSubtreeIfNeeded()
        container.maskImage = nil
        if maskSize.x > 0, maskSize.y > 0, let rep = mask.bitmapImageRepForCachingDisplay(in: mask.bounds) {
            mask.cacheDisplay(in: mask.bounds, to: rep)
            container.maskImage = rep.cgImage
        }
        container.maskOrigin = maskOrigin
        container.maskSize = maskSize
        container.needsLayout = true
    }
}

/// A container whose layer is masked by a rendering of a view outside the
/// hierarchy.
final class NSMaskContainerView: NSView {
    var maskView: NSView?
    var maskImage: CGImage?
    var maskOrigin = SIMD2<Int>.zero
    var maskSize = SIMD2<Int>.zero
    private let maskLayer = CALayer()

    override func layout() {
        super.layout()
        guard let layer else {
            return
        }
        // Layer geometry starts at the bottom unless the view is flipped.
        let height = CGFloat(maskSize.y)
        let y = isFlipped ? CGFloat(maskOrigin.y) : bounds.height - CGFloat(maskOrigin.y) - height
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.frame = CGRect(x: CGFloat(maskOrigin.x), y: y, width: CGFloat(maskSize.x), height: height)
        maskLayer.contents = maskImage
        CATransaction.commit()
        if layer.mask !== maskLayer {
            layer.mask = maskLayer
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}
