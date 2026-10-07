@_spi(Backends) import SwiftCrossUI
import Foundation
import WindowsFoundation
import WinUI

extension WinUIBackend: BackendFeatures.WidgetGeometry {
    public func frame(
        of widget: Widget,
        in ancestor: Widget
    ) -> (origin: SIMD2<Double>, size: SIMD2<Double>)? {
        // Positions are `Canvas.Left`/`Top` values, which WinUI only arranges on
        // its next layout pass; run it now, as it would before rendering.
        try? ancestor.updateLayout()
        guard let transform = try? widget.transformToVisual(ancestor),
              let origin = try? transform.transformPoint(WindowsFoundation.Point(x: 0, y: 0))
        else {
            return nil
        }
        return (
            SIMD2(Double(origin.x), Double(origin.y)),
            SIMD2(widget.actualWidth, widget.actualHeight)
        )
    }
}
