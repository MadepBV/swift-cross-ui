@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.WidgetGeometry {
    public func frame(
        of widget: Widget,
        in ancestor: Widget
    ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)? {
        guard let origin = Self.origin(of: widget, below: ancestor, at: .zero) else {
            return nil
        }
        return (origin, SIMD2<Double>(widget.size))
    }

    /// Finds a widget below `ancestor`, adding up the positions on the way and
    /// taking off how far each scroll container on the way is scrolled.
    private static func origin(
        of widget: Widget,
        below ancestor: Widget,
        at origin: SIMD2<Double>
    ) -> SIMD2<Double>? {
        if ancestor === widget {
            return origin
        }
        if let container = ancestor as? Container {
            for child in container.children {
                let childOrigin = origin + SIMD2<Double>(child.position)
                if let found = Self.origin(of: widget, below: child.widget, at: childOrigin) {
                    return found
                }
            }
            return nil
        }
        let scrolled = (ancestor as? ScrollContainer).map { origin - $0.scrollOffset } ?? origin
        for child in ancestor.getChildren() {
            if let found = Self.origin(of: widget, below: child, at: scrolled) {
                return found
            }
        }
        return nil
    }
}
