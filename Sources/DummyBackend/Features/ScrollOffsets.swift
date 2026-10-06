@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.ScrollOffsets {
    public func scrollOffset(of scrollContainer: Widget) -> SIMD2<Double> {
        (scrollContainer as! ScrollContainer).scrollOffset
    }

    public func setScrollOffset(
        of scrollContainer: Widget,
        to offset: SIMD2<Double>,
        animated: Bool
    ) {
        let scrollContainer = scrollContainer as! ScrollContainer
        let contentSize = SIMD2<Double>(scrollContainer.child.size)
        let viewportSize = SIMD2<Double>(scrollContainer.size)
        let maximum = SIMD2<Double>(
            max(0, contentSize.x - viewportSize.x),
            max(0, contentSize.y - viewportSize.y)
        )
        scrollContainer.scrollOffset = SIMD2(
            min(max(0, offset.x), maximum.x),
            min(max(0, offset.y), maximum.y)
        )
        scrollContainer.lastScrollWasAnimated = animated
    }

    public func frame(
        of widget: Widget,
        inContentOf scrollContainer: Widget
    ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)? {
        let content = (scrollContainer as! ScrollContainer).child
        guard let origin = Self.position(of: widget, in: content, at: .zero) else {
            return nil
        }
        return (SIMD2<Double>(origin), SIMD2<Double>(widget.size))
    }

    /// Finds a widget below `ancestor` and adds up the positions on the way.
    ///
    /// - Parameters:
    ///   - widget: The widget to find.
    ///   - ancestor: The widget to search below (and including).
    ///   - origin: Where `ancestor` is.
    /// - Returns: Where `widget` is, or `nil` if it isn't below `ancestor`.
    private static func position(
        of widget: Widget,
        in ancestor: Widget,
        at origin: SIMD2<Int>
    ) -> SIMD2<Int>? {
        if ancestor === widget {
            return origin
        }
        if let container = ancestor as? Container {
            for child in container.children {
                if let found = position(of: widget, in: child.widget, at: origin &+ child.position) {
                    return found
                }
            }
            return nil
        }
        for child in ancestor.getChildren() {
            if let found = position(of: widget, in: child, at: origin) {
                return found
            }
        }
        return nil
    }
}
