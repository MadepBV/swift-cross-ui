import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.WidgetVisibility {
    public func setVisibility(of widget: Widget, visible: Bool) {
        widget.isHidden = !visible
    }
}
