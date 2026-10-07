@_spi(Backends) import SwiftCrossUI
import WinUI

extension WinUIBackend: BackendFeatures.WidgetVisibility {
    public func setVisibility(of widget: Widget, visible: Bool) {
        // Collapsed elements are skipped by layout, rendering, hit testing and
        // keyboard focus, and keep their subtree.
        let visibility: WinUI.Visibility = visible ? .visible : .collapsed
        guard widget.visibility != visibility else { return }
        BackendCallStatistics.record("winui.setVisibility")
        widget.visibility = visibility
    }
}
