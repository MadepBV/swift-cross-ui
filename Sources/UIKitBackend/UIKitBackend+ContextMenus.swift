@_spi(Backends) import SwiftCrossUI
import UIKit

extension UIKitBackend: BackendFeatures.ContextMenus {
    public func createContextMenuTarget(wrapping child: Widget) -> Widget {
        ContextMenuWidget(child: child)
    }

    public func updateContextMenuTarget(
        _ contextMenuTarget: Widget,
        content: ResolvedMenu?,
        environment: EnvironmentValues
    ) {
        guard let widget = contextMenuTarget as? ContextMenuWidget else {
            return
        }

        if #available(iOS 14, macCatalyst 14, tvOS 17, *) {
            guard let content, environment.isEnabled else {
                widget.menu = nil
                return
            }
            widget.menu = UIKitBackend.buildMenu(
                content: content,
                label: "",
                environment: environment
            )
        }
    }
}

/// A widget that presents a context menu when long-pressed (or
/// secondary-clicked, where there's a pointer).
final class ContextMenuWidget: ContainerWidget {
    /// The menu to present, or `nil` for no context menu.
    ///
    /// Typed as `AnyObject` because `UIMenu` isn't available on every
    /// deployment target this backend supports, and stored properties can't be
    /// conditionally available.
    var menu: AnyObject?

    override init(child: some WidgetProtocol) {
        super.init(child: child)

        if #available(iOS 13, macCatalyst 13, tvOS 17, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            child.view.addInteraction(interaction)
        }
    }
}

@available(iOS 13, macCatalyst 13, tvOS 17, *)
extension ContextMenuWidget: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let menu = menu as? UIMenu else {
            return nil
        }
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil
        ) { _ in
            menu
        }
    }
}
