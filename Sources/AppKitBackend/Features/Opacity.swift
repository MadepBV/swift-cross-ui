import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.Opacity {
    public func setOpacity(of widget: Widget, to opacity: Double) {
        widget.alphaValue = CGFloat(opacity)
    }
}
