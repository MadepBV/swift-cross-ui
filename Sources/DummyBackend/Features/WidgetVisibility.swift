@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.WidgetVisibility {
    public func setVisibility(of widget: Widget, visible: Bool) {
        record("setVisibility")
        widget.isHidden = !visible
    }
}
