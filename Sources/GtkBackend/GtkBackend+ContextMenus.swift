import CGtk
import Gtk
@_spi(Backends) import SwiftCrossUI

extension GtkBackend: BackendFeatures.ContextMenus {
    public func createContextMenuTarget(wrapping child: Widget) -> Widget {
        ContextMenuTarget(child)
    }

    public func updateContextMenuTarget(
        _ contextMenuTarget: Widget,
        content: ResolvedMenu?,
        environment: EnvironmentValues
    ) {
        guard let target = contextMenuTarget as? ContextMenuTarget else {
            return
        }

        guard let content, environment.isEnabled else {
            target.presentMenu = nil
            return
        }

        target.presentMenu = { [weak self, weak target] position in
            guard let self, let target else {
                return
            }

            // A fresh popover is built for every activation because GTK
            // popovers are parented to their anchor when shown, and reusing one
            // would mean reparenting it. `Menu` does the same thing.
            let menu = self.createPopoverMenu()
            target.menu = menu
            self.updatePopoverMenu(menu, content: content, environment: environment)
            self.showPopoverMenu(menu, at: position, relativeTo: target) {
                target.menu = nil
            }
        }
    }
}

/// A container that shows a popover menu when secondary-clicked.
final class ContextMenuTarget: Fixed {
    /// The popover currently on screen, kept alive for as long as it's shown.
    var menu: Gtk.PopoverMenu?

    /// Shows the context menu at a position relative to this widget, or `nil`
    /// if this widget has no context menu.
    var presentMenu: ((SIMD2<Int>) -> Void)?

    /// The gesture that detects secondary clicks.
    private let gesture = GestureClick()

    /// Wraps a child widget.
    ///
    /// - Parameter child: The widget to attach a context menu to.
    init(_ child: Gtk.Widget) {
        super.init()
        put(child, x: 0, y: 0)

        gtk_gesture_single_set_button(gesture.opaquePointer, guint(GDK_BUTTON_SECONDARY))
        addEventController(gesture)

        gesture.pressed = { [weak self] _, pressCount, x, y in
            guard let self, pressCount == 1 else {
                return
            }
            self.presentMenu?(SIMD2(Int(x), Int(y)))
        }
    }
}
