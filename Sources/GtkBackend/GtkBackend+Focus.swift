import CGtk
import Gtk
@_spi(Backends) import SwiftCrossUI

extension GtkBackend: BackendFeatures.KeyboardShortcuts, BackendFeatures.Focus {}

// MARK: - Keyboard shortcuts

extension GtkBackend {
    /// Gtk attaches shortcut controllers to widgets directly, so no wrapper
    /// widget is needed.
    public func createKeyboardShortcutTarget(wrapping child: Widget) -> Widget {
        child
    }

    public func updateKeyboardShortcutTarget(
        _ target: Widget,
        shortcut: KeyboardShortcut?,
        environment: EnvironmentValues
    ) {
        let entry = GtkShortcutRegistry.shared.entry(for: target)
        entry.isEnabled = environment.isEnabled
        entry.apply(shortcut)
    }
}

/// Tracks the `GtkShortcutController` installed on each shortcut target.
///
/// A single `GtkShortcut` is created per target and its trigger is swapped
/// whenever the shortcut changes, which avoids having to add and remove
/// shortcuts from the controller's list.
@MainActor
final class GtkShortcutRegistry {
    static let shared = GtkShortcutRegistry()

    /// The shortcut state for a single target widget.
    final class Entry {
        /// The widget the shortcut activates.
        let widget: UnsafeMutablePointer<GtkWidget>
        /// The `GtkShortcut` whose trigger gets swapped on each update.
        ///
        /// Assigned just after initialization, because creating the shortcut's
        /// action needs a pointer to this entry.
        var shortcut: OpaquePointer?
        /// Whether the shortcut is allowed to fire.
        var isEnabled = true
        /// The shortcut most recently applied.
        private var current: KeyboardShortcut?

        init(widget: UnsafeMutablePointer<GtkWidget>) {
            self.widget = widget
        }

        /// Swaps in a new trigger for the shortcut.
        func apply(_ new: KeyboardShortcut?) {
            guard let shortcut, new != current else { return }
            current = new

            guard let new, let keyval = new.key.gdkKeyval else {
                // `GtkNeverTrigger` is the canonical "this shortcut is off"
                // trigger.
                gtk_shortcut_set_trigger(shortcut, gtk_never_trigger_get())
                return
            }

            let trigger = gtk_keyval_trigger_new(
                keyval,
                new.modifiers.gdkModifierType
            )
            gtk_shortcut_set_trigger(shortcut, trigger)
        }
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    private init() {}

    /// Returns the entry for a widget, installing a shortcut controller on
    /// first use.
    func entry(for widget: Gtk.Widget) -> Entry {
        let key = ObjectIdentifier(widget)
        if let existing = entries[key] {
            return existing
        }

        let pointer = widget.widgetPointer

        // A global-scope controller fires while anything in the same window
        // has focus, which is what SwiftUI's window-scoped shortcuts do.
        let controller = gtk_shortcut_controller_new()
        gtk_shortcut_controller_set_scope(
            OpaquePointer(controller),
            GTK_SHORTCUT_SCOPE_GLOBAL
        )

        let callback: GtkShortcutFunc = { _, _, data in
            guard let data else { return 0 }
            return MainActor.assumeIsolated {
                let entry = Unmanaged<Entry>.fromOpaque(data)
                    .takeUnretainedValue()
                guard entry.isEnabled else { return 0 }
                return activateFirstActivatable(entry.widget) ? 1 : 0
            }
        }

        let entry = Entry(widget: pointer)
        entries[key] = entry

        // The callback's user data is the entry, which `entries` keeps alive
        // for as long as the controller exists.
        let action = gtk_callback_action_new(
            callback,
            Unmanaged.passUnretained(entry).toOpaque(),
            nil
        )
        let shortcut = gtk_shortcut_new(gtk_never_trigger_get(), action)
        entry.shortcut = OpaquePointer(shortcut)

        gtk_shortcut_controller_add_shortcut(OpaquePointer(controller), shortcut)
        gtk_widget_add_controller(pointer, controller)

        return entry
    }
}

/// Activates the first activatable widget in a subtree.
///
/// `gtk_widget_activate` returns false for widgets with no activation (such as
/// boxes), so the tree is walked until something accepts.
private func activateFirstActivatable(
    _ widget: UnsafeMutablePointer<GtkWidget>
) -> Bool {
    if gtk_widget_activate(widget) != 0 {
        return true
    }

    var child = gtk_widget_get_first_child(widget)
    while let next = child {
        if activateFirstActivatable(next) {
            return true
        }
        child = gtk_widget_get_next_sibling(next)
    }
    return false
}

// MARK: - Focus

extension GtkBackend {
    /// Focus is driven and observed on the widget itself, so no wrapper widget
    /// is needed.
    public func createFocusTarget(wrapping child: Widget) -> Widget {
        child
    }

    public func updateFocusTarget(
        _ target: Widget,
        isFocused: Bool,
        environment: EnvironmentValues,
        onFocusChange: @escaping (Bool) -> Void
    ) {
        let entry = GtkFocusRegistry.shared.entry(for: target)
        entry.onFocusChange = onFocusChange
        entry.isEnabled = environment.isEnabled
        entry.applyDesiredFocus(isFocused)
    }
}

/// Tracks focus state for each focus target.
///
/// Focus is fully bidirectional on Gtk: `gtk_widget_grab_focus` moves focus,
/// and the `notify::has-focus` signal on the focusable descendant reports
/// changes back.
@MainActor
final class GtkFocusRegistry {
    static let shared = GtkFocusRegistry()

    /// The focus state for a single target widget.
    final class Entry {
        /// The root of the target subtree.
        let root: UnsafeMutablePointer<GtkWidget>
        /// Called when the platform changes focus.
        var onFocusChange: ((Bool) -> Void)?
        /// Whether the target may take focus.
        var isEnabled = true
        /// The focus state most recently reported or applied.
        var lastKnownFocus = false
        /// The descendant that actually receives focus, resolved lazily
        /// because the subtree may still be empty when the target is created.
        private var focusable: UnsafeMutablePointer<GtkWidget>?

        init(root: UnsafeMutablePointer<GtkWidget>) {
            self.root = root
        }

        /// Resolves and starts observing the focusable descendant.
        func resolveFocusableIfNeeded() -> UnsafeMutablePointer<GtkWidget>? {
            if let focusable {
                return focusable
            }
            guard let found = firstFocusable(in: root) else {
                return nil
            }
            focusable = found

            let handler: @convention(c) (
                UnsafeMutableRawPointer?,
                UnsafeMutableRawPointer?,
                UnsafeMutableRawPointer?
            ) -> Void = { _, _, data in
                guard let data else { return }
                MainActor.assumeIsolated {
                    Unmanaged<Entry>.fromOpaque(data)
                        .takeUnretainedValue()
                        .reportPlatformFocus()
                }
            }

            g_signal_connect_data(
                UnsafeMutableRawPointer(found),
                "notify::has-focus",
                unsafeBitCast(handler, to: GCallback.self),
                Unmanaged.passUnretained(self).toOpaque(),
                nil,
                GConnectFlags(0)
            )

            return found
        }

        /// Moves platform focus to match the bound focus state.
        func applyDesiredFocus(_ shouldFocus: Bool) {
            guard let focusable = resolveFocusableIfNeeded() else { return }

            let hasFocus = gtk_widget_has_focus(focusable) != 0
            lastKnownFocus = hasFocus

            if shouldFocus {
                guard !hasFocus, isEnabled else { return }
                gtk_widget_grab_focus(focusable)
            } else if hasFocus {
                // Gtk clears focus by setting the root's focus widget to null.
                if let root = gtk_widget_get_root(focusable) {
                    gtk_root_set_focus(root, nil)
                }
            }

            lastKnownFocus = gtk_widget_has_focus(focusable) != 0
        }

        /// Reports a platform-driven focus change.
        func reportPlatformFocus() {
            guard let focusable else { return }
            let hasFocus = gtk_widget_has_focus(focusable) != 0
            guard hasFocus != lastKnownFocus else { return }
            lastKnownFocus = hasFocus
            onFocusChange?(hasFocus)
        }
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    private init() {}

    /// Returns the entry for a widget, creating one on first use.
    func entry(for widget: Gtk.Widget) -> Entry {
        let key = ObjectIdentifier(widget)
        if let existing = entries[key] {
            return existing
        }
        let entry = Entry(root: widget.widgetPointer)
        entries[key] = entry
        return entry
    }
}

/// Finds the first widget in a subtree that can take keyboard focus.
private func firstFocusable(
    in widget: UnsafeMutablePointer<GtkWidget>
) -> UnsafeMutablePointer<GtkWidget>? {
    if gtk_widget_get_focusable(widget) != 0 {
        return widget
    }

    var child = gtk_widget_get_first_child(widget)
    while let next = child {
        if let found = firstFocusable(in: next) {
            return found
        }
        child = gtk_widget_get_next_sibling(next)
    }
    return nil
}

// MARK: - Platform mapping

extension EventModifiers {
    /// The Gdk modifier mask corresponding to these modifiers.
    ///
    /// ``SwiftCrossUI/EventModifiers/command`` maps to Control, matching what
    /// users of a ported app expect on Linux; the Super key is claimed by the
    /// desktop environment.
    var gdkModifierType: GdkModifierType {
        var mask = GdkModifierType(0)
        if contains(.command) || contains(.control) {
            mask = GdkModifierType(mask.rawValue | GDK_CONTROL_MASK.rawValue)
        }
        if contains(.option) {
            mask = GdkModifierType(mask.rawValue | GDK_ALT_MASK.rawValue)
        }
        if contains(.shift) {
            mask = GdkModifierType(mask.rawValue | GDK_SHIFT_MASK.rawValue)
        }
        if contains(.capsLock) {
            mask = GdkModifierType(mask.rawValue | GDK_LOCK_MASK.rawValue)
        }
        return mask
    }
}

extension KeyEquivalent {
    /// The Gdk keyval corresponding to this key equivalent.
    var gdkKeyval: guint? {
        let named: Int32? =
            switch self {
                case .upArrow: GDK_KEY_Up
                case .downArrow: GDK_KEY_Down
                case .leftArrow: GDK_KEY_Left
                case .rightArrow: GDK_KEY_Right
                case .clear: GDK_KEY_Clear
                case .delete: GDK_KEY_BackSpace
                case .deleteForward: GDK_KEY_Delete
                case .end: GDK_KEY_End
                case .escape: GDK_KEY_Escape
                case .home: GDK_KEY_Home
                case .pageDown: GDK_KEY_Page_Down
                case .pageUp: GDK_KEY_Page_Up
                case .return: GDK_KEY_Return
                case .space: GDK_KEY_space
                case .tab: GDK_KEY_Tab
                default: nil
            }

        if let named {
            return guint(named)
        }

        // Everything else is an ordinary character, which Gdk can convert
        // directly. Shortcuts are declared in lowercase with an explicit
        // shift modifier, matching SwiftUI.
        guard
            let lowercased = character.lowercased().unicodeScalars.first
        else {
            return nil
        }
        let keyval = gdk_unicode_to_keyval(guint32(lowercased.value))
        return keyval == 0 ? nil : keyval
    }
}
