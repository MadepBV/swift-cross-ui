@_spi(Backends) import SwiftCrossUI
import WinUI

extension WinUIBackend: BackendFeatures.ContextMenus {
    /// No wrapper element is needed; every `UIElement` has a context flyout of
    /// its own, and WinUI walks up the tree to find one when the user
    /// right-clicks.
    ///
    /// - Parameter child: The widget to attach a context menu to.
    /// - Returns: `child`, unmodified.
    public func createContextMenuTarget(wrapping child: Widget) -> Widget {
        child
    }

    public func updateContextMenuTarget(
        _ contextMenuTarget: Widget,
        content: ResolvedMenu?,
        environment: EnvironmentValues
    ) {
        guard let content, environment.isEnabled else {
            contextMenuTarget.contextFlyout = nil
            return
        }

        let flyout = (contextMenuTarget.contextFlyout as? Menu) ?? createPopoverMenu()
        updatePopoverMenu(flyout, content: content, environment: environment)
        contextMenuTarget.contextFlyout = flyout
    }
}
