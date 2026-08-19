import CGtk
import Gtk
@_spi(Backends) import SwiftCrossUI

extension GtkBackend: BackendFeatures.Accessibility {
    /// Applies accessibility metadata to a `GtkWidget` through the
    /// `GtkAccessible` interface that every widget implements.
    ///
    /// ## Mapping
    ///
    /// | SwiftCrossUI | Gtk |
    /// | --- | --- |
    /// | `label` | `GTK_ACCESSIBLE_PROPERTY_LABEL` |
    /// | `hint` | `GTK_ACCESSIBLE_PROPERTY_DESCRIPTION` |
    /// | `value` | `GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT` |
    /// | `traits` | `GTK_ACCESSIBLE_PROPERTY_ROLE_DESCRIPTION`, `GTK_ACCESSIBLE_STATE_SELECTED` |
    /// | `isHidden` | `GTK_ACCESSIBLE_STATE_HIDDEN` |
    /// | `childBehavior` | `GTK_ACCESSIBLE_STATE_HIDDEN` on descendants |
    ///
    /// ## Known limitations
    ///
    /// - Gtk has no accessibility identifier. A widget's AT-SPI accessible id
    ///   comes from its `GtkBuildable` id, which only `GtkBuilder` can assign,
    ///   so ``SwiftCrossUI/View/accessibilityIdentifier(_:)`` does nothing
    ///   here. Nothing else in Gtk's accessibility vocabulary means the same
    ///   thing, so nothing is written rather than writing something
    ///   misleading.
    /// - A widget's accessible role is fixed when the widget is constructed,
    ///   so traits set the human-readable role *description* instead of the
    ///   role itself.
    /// - ``SwiftCrossUI/AccessibilityChildBehavior/combine`` hides the
    ///   descendants but does not build a description out of them, so it needs
    ///   an explicit ``SwiftCrossUI/View/accessibilityLabel(_:)`` to be useful.
    ///
    /// - Parameters:
    ///   - widget: The widget to describe.
    ///   - properties: The complete set of metadata to expose.
    public func updateAccessibility(
        of widget: Widget,
        to properties: BackendFeatures.AccessibilityProperties
    ) {
        let pointer = widget.widgetPointer

        Self.update(.label, of: pointer, to: properties.label)
        Self.update(.description, of: pointer, to: properties.hint)
        Self.update(.valueText, of: pointer, to: properties.value)
        Self.update(
            .roleDescription,
            of: pointer,
            to: Self.roleDescription(for: properties.traits)
        )
        Self.update(
            .selected,
            of: pointer,
            to: properties.traits.contains(.isSelected)
        )

        let isHidden = properties.isHidden == true
        Self.update(.hidden, of: pointer, to: isHidden)

        if isHidden
            || properties.childBehavior == .combine
            || properties.childBehavior == .ignore
        {
            Self.setDescendantsHidden(true, of: pointer)
        } else if properties.isHidden == false {
            // Only an explicit request to un-hide reaches back into the
            // subtree. Doing it unconditionally would undo a nested
            // `accessibilityHidden(_:)`, since children commit first.
            Self.setDescendantsHidden(false, of: pointer)
        }
    }

    /// Sets or clears a string-valued accessible property.
    ///
    /// - Parameters:
    ///   - property: The property to update.
    ///   - widget: The widget to update it on.
    ///   - text: The new value, or `nil` to reset the property.
    private static func update(
        _ property: Gtk.AccessibleProperty,
        of widget: UnsafeMutablePointer<GtkWidget>,
        to text: String?
    ) {
        let accessible = OpaquePointer(widget)
        var gtkProperty = property.toGtk()

        guard let text else {
            gtk_accessible_reset_property(accessible, gtkProperty)
            return
        }

        var storage = GValue()
        guard let value = g_value_init(&storage, String.type) else {
            return
        }
        g_value_set_string(value, text)
        gtk_accessible_update_property_value(
            accessible,
            1,
            &gtkProperty,
            value
        )
        g_value_unset(value)
    }

    /// Sets a boolean accessible state.
    ///
    /// - Parameters:
    ///   - state: The state to update.
    ///   - widget: The widget to update it on.
    ///   - isSet: The new value.
    private static func update(
        _ state: Gtk.AccessibleState,
        of widget: UnsafeMutablePointer<GtkWidget>,
        to isSet: Bool
    ) {
        let accessible = OpaquePointer(widget)
        var gtkState = state.toGtk()

        var storage = GValue()
        guard let value = g_value_init(&storage, Bool.type) else {
            return
        }
        g_value_set_boolean(value, isSet ? 1 : 0)
        gtk_accessible_update_state_value(accessible, 1, &gtkState, value)
        g_value_unset(value)
    }

    /// Hides or reveals every widget beneath a widget.
    ///
    /// This is how both ``SwiftCrossUI/View/accessibilityHidden(_:)`` and the
    /// single-element child behaviours take a subtree out of the accessibility
    /// tree, since Gtk has no way to detach children from an accessible
    /// without detaching the widgets themselves.
    ///
    /// - Parameters:
    ///   - hidden: Whether the descendants should be hidden.
    ///   - widget: The root of the subtree. The root itself is not changed.
    private static func setDescendantsHidden(
        _ hidden: Bool,
        of widget: UnsafeMutablePointer<GtkWidget>
    ) {
        var child = gtk_widget_get_first_child(widget)
        while let current = child {
            update(.hidden, of: current, to: hidden)
            setDescendantsHidden(hidden, of: current)
            child = gtk_widget_get_next_sibling(current)
        }
    }

    /// Chooses the role description that best matches a trait set.
    ///
    /// A widget's accessible role is fixed at construction time, so traits are
    /// surfaced as the localizable role description that assistive
    /// technologies read in place of the role's own name.
    ///
    /// - Parameter traits: The traits applied to the view.
    /// - Returns: The role description, or `nil` when no trait implies one.
    private static func roleDescription(
        for traits: AccessibilityTraits
    ) -> String? {
        if traits.contains(.isButton) {
            return "button"
        } else if traits.contains(.isLink) {
            return "link"
        } else if traits.contains(.isSearchField) {
            return "search field"
        } else if traits.contains(.isImage) {
            return "image"
        } else if traits.contains(.isHeader) {
            return "heading"
        } else if traits.contains(.isToggle) {
            return "toggle"
        } else if traits.contains(.isTabBar) {
            return "tab list"
        } else if traits.contains(.isStaticText) {
            return "text"
        } else {
            return nil
        }
    }
}
