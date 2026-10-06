import Foundation
@_spi(Backends) import SwiftCrossUI
import WinUI
import WindowsFoundation

// MARK: - Programmatic scrolling

extension WinUIBackend: BackendFeatures.ScrollOffsets {
    public func scrollOffset(of scrollContainer: Widget) -> SIMD2<Double> {
        let scrollViewer = scrollContainer as! WinUI.ScrollViewer
        return SIMD2(scrollViewer.horizontalOffset, scrollViewer.verticalOffset)
    }

    public func setScrollOffset(
        of scrollContainer: Widget,
        to offset: SIMD2<Double>,
        animated: Bool
    ) {
        let scrollViewer = scrollContainer as! WinUI.ScrollViewer
        // `ChangeView` clamps to the scrollable range itself.
        _ = try? scrollViewer.changeView(offset.x, offset.y, nil, !animated)
    }

    public func frame(
        of widget: Widget,
        inContentOf scrollContainer: Widget
    ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)? {
        let scrollViewer = scrollContainer as! WinUI.ScrollViewer
        guard let content = scrollViewer.content as? WinUI.UIElement,
              let transform = try? widget.transformToVisual(content),
              let origin = try? transform.transformPoint(
                  WindowsFoundation.Point(x: 0, y: 0)
              )
        else {
            return nil
        }
        return (
            SIMD2(Double(origin.x), Double(origin.y)),
            SIMD2(widget.actualWidth, widget.actualHeight)
        )
    }
}
