import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.ScrollOffsets {
    public func scrollOffset(of scrollContainer: Widget) -> SIMD2<Double> {
        let scrollView = scrollContainer as! NSScrollView
        guard let documentView = scrollView.documentView else {
            return .zero
        }
        let visible = scrollView.contentView.documentVisibleRect
        return SIMD2(
            Double(visible.minX),
            Double(Self.distanceFromTop(of: visible, in: documentView))
        )
    }

    public func setScrollOffset(
        of scrollContainer: Widget,
        to offset: SIMD2<Double>,
        animated: Bool
    ) {
        let scrollView = scrollContainer as! NSScrollView
        guard let documentView = scrollView.documentView else {
            return
        }
        let clipView = scrollView.contentView
        let viewport = clipView.bounds.size
        let content = documentView.frame.size
        let x = min(max(0, CGFloat(offset.x)), max(0, content.width - viewport.width))
        let top = min(max(0, CGFloat(offset.y)), max(0, content.height - viewport.height))
        // A flipped document measures from its top; an unflipped one from its
        // bottom.
        let y = documentView.isFlipped ? top : content.height - viewport.height - top
        let origin = NSPoint(x: x, y: y)

        if animated {
            NSAnimationContext.runAnimationGroup { _ in
                clipView.animator().setBoundsOrigin(origin)
            } completionHandler: {
                scrollView.reflectScrolledClipView(clipView)
            }
        } else {
            clipView.setBoundsOrigin(origin)
            scrollView.reflectScrolledClipView(clipView)
        }
    }

    public func frame(
        of widget: Widget,
        inContentOf scrollContainer: Widget
    ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)? {
        let scrollView = scrollContainer as! NSScrollView
        guard let documentView = scrollView.documentView,
              widget.isDescendant(of: documentView)
        else {
            return nil
        }
        let rect = widget.convert(widget.bounds, to: documentView)
        return (
            SIMD2(Double(rect.minX), Double(Self.distanceFromTop(of: rect, in: documentView))),
            SIMD2(Double(rect.width), Double(rect.height))
        )
    }

    /// How far a rectangle in a scroll view's document is from the document's
    /// top, whichever way the document is flipped.
    ///
    /// - Parameters:
    ///   - rect: The rectangle, in the document's coordinates.
    ///   - documentView: The document.
    /// - Returns: The distance from the document's top to the rectangle's.
    private static func distanceFromTop(of rect: NSRect, in documentView: NSView) -> CGFloat {
        documentView.isFlipped ? rect.minY : documentView.bounds.height - rect.maxY
    }
}
