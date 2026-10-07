import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.WidgetGeometry {
    public func frame(
        of widget: Widget,
        in ancestor: Widget
    ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)? {
        guard widget.isDescendant(of: ancestor) else {
            return nil
        }
        // Positions are Auto Layout constraints, which AppKit only turns into
        // frames on its next layout pass; run it now for the ancestor's
        // subtree, which the window would otherwise do before drawing anyway.
        ancestor.layoutSubtreeIfNeeded()
        let rect = widget.convert(widget.bounds, to: ancestor)
        let top = ancestor.isFlipped ? rect.minY : ancestor.bounds.height - rect.maxY
        return (
            SIMD2(Double(rect.minX), Double(top)),
            SIMD2(Double(rect.width), Double(rect.height))
        )
    }
}
