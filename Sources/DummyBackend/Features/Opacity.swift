@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.Opacity {
    public func setOpacity(of widget: Widget, to opacity: Double) {
        widget.opacity = opacity
    }
}
