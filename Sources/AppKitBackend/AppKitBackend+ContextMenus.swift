import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.ContextMenus {
    /// No wrapper view is needed; AppKit looks up the view hierarchy for a
    /// view with a menu when the user secondary-clicks, so the menu can live on
    /// the child itself.
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
            contextMenuTarget.menu = nil
            return
        }

        let menu = NSMenu()
        menu.appearance = environment.colorScheme.nsAppearance
        menu.items = content.items.map { item in
            Self.renderMenuItem(item, environment: environment)
        }
        contextMenuTarget.menu = menu
    }
}
