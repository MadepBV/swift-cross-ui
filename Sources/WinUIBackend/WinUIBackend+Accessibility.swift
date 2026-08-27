@_spi(Backends) import SwiftCrossUI
import WinUI
@preconcurrency import WindowsFoundation

extension WinUIBackend: BackendFeatures.Accessibility {
    /// Applies accessibility metadata to a `FrameworkElement` using the
    /// `AutomationProperties` attached properties that feed UI Automation.
    ///
    /// ## Mapping
    ///
    /// | SwiftCrossUI | UI Automation |
    /// | --- | --- |
    /// | `label` | `AutomationProperties.Name` |
    /// | `hint` | `AutomationProperties.HelpText` |
    /// | `value` | `AutomationProperties.FullDescription` |
    /// | `identifier` | `AutomationProperties.AutomationId` |
    /// | `traits` | `AutomationProperties.LocalizedControlType`/`HeadingLevel` |
    /// | `isHidden` | `AutomationProperties.AccessibilityView` of `Raw` |
    /// | `childBehavior` | `AutomationProperties.AccessibilityView` on descendants |
    ///
    /// ## Known limitations
    ///
    /// - A property is only written when SwiftCrossUI has a value for it.
    ///   Writing an empty `Name` or `AutomationId` would suppress the name
    ///   WinUI derives from a control's own content, which is worse than
    ///   leaving it alone.
    /// - UI Automation takes a control's `ControlType` from its automation
    ///   peer, which an attached property can't override. Traits therefore
    ///   set `LocalizedControlType`, the string Narrator reads out, rather
    ///   than the underlying control type. `.isHeader` additionally sets
    ///   `HeadingLevel`, which is a real UIA property.
    /// - `.isSelected` belongs to UIA's `SelectionItem` pattern, which an
    ///   attached property can't provide, so it is ignored.
    ///
    /// - Parameters:
    ///   - widget: The element to describe.
    ///   - properties: The complete set of metadata to expose.
    public func updateAccessibility(
        of widget: Widget,
        to properties: BackendFeatures.AccessibilityProperties
    ) {
        // Every branch below is an attached-property write across the WinRT
        // projection, and `.combine`/`.ignore`/hidden additionally walk the
        // whole subtree. This runs for every accessibility-annotated widget on
        // every update pass, and the metadata almost never changes.
        let entry = WidgetPropertyCache.shared.entry(for: widget)
        guard entry.accessibility != properties else {
            return
        }
        entry.accessibility = properties

        if let identifier = properties.identifier {
            AutomationProperties.setAutomationId(widget, identifier)
        }
        if let hint = properties.hint {
            AutomationProperties.setHelpText(widget, hint)
        }
        if let value = properties.value {
            AutomationProperties.setFullDescription(widget, value)
        }
        if let controlType = Self.localizedControlType(for: properties.traits)
        {
            AutomationProperties.setLocalizedControlType(widget, controlType)
        }
        if properties.traits.contains(.isHeader) {
            AutomationProperties.setHeadingLevel(widget, .level1)
        }

        guard properties.isHidden != true else {
            // `Raw` takes the element out of the views that assistive
            // technologies walk, but UI Automation re-parents its children
            // rather than dropping them, so the subtree has to be hidden too.
            AutomationProperties.setAccessibilityView(widget, .raw)
            Self.hideDescendants(of: widget)
            return
        }

        if properties.childBehavior != nil || properties.label != nil {
            AutomationProperties.setAccessibilityView(widget, .content)
        }

        switch properties.childBehavior {
            case .combine:
                let name =
                    properties.label ?? Self.combinedName(of: widget) ?? ""
                AutomationProperties.setName(widget, name)
                Self.hideDescendants(of: widget)
            case .ignore:
                if let label = properties.label {
                    AutomationProperties.setName(widget, label)
                }
                Self.hideDescendants(of: widget)
            case .contain, nil:
                // `Content` is already UI Automation's default arrangement for
                // a container, so the descendants are left as they are. That
                // also keeps a nested `accessibilityHidden(_:)` intact.
                if let label = properties.label {
                    AutomationProperties.setName(widget, label)
                }
        }
    }

    /// Removes every descendant of an element from the UI Automation tree.
    ///
    /// - Parameter widget: The element whose descendants to hide.
    private static func hideDescendants(of widget: WinUI.UIElement) {
        guard let panel = widget as? WinUI.Panel,
            let children = panel.children
        else {
            return
        }
        for case let child? in children {
            AutomationProperties.setAccessibilityView(child, .raw)
            hideDescendants(of: child)
        }
    }

    /// Builds a single name out of everything beneath an element.
    ///
    /// This backs ``SwiftCrossUI/AccessibilityChildBehavior/combine``.
    ///
    /// - Parameter widget: The element whose descendants to describe.
    /// - Returns: The merged name, or `nil` if nothing beneath the element
    ///   names itself.
    private static func combinedName(of widget: Widget) -> String? {
        var parts: [String] = []
        collectNames(under: widget, into: &parts)
        guard !parts.isEmpty else {
            return nil
        }
        return parts.joined(separator: ", ")
    }

    /// Appends the names of every descendant of an element.
    ///
    /// - Parameters:
    ///   - widget: The element whose descendants to describe.
    ///   - parts: The names collected so far.
    private static func collectNames(
        under widget: WinUI.UIElement,
        into parts: inout [String]
    ) {
        guard let panel = widget as? WinUI.Panel,
            let children = panel.children
        else {
            return
        }
        for case let child? in children {
            if let name = name(of: child) {
                parts.append(name)
            } else {
                collectNames(under: child, into: &parts)
            }
        }
    }

    /// The text that a single element contributes to a combined name.
    ///
    /// - Parameter widget: The element to describe.
    /// - Returns: The element's name, or `nil` if it has none.
    private static func name(of widget: WinUI.UIElement) -> String? {
        let name = AutomationProperties.getName(widget)
        if !name.isEmpty {
            return name
        }
        if let textBlock = widget as? WinUI.TextBlock, !textBlock.text.isEmpty
        {
            return textBlock.text
        }
        return nil
    }

    /// Chooses the localized control type that best matches a trait set.
    ///
    /// UI Automation exposes one control type per element, so the traits are
    /// checked in order of how strongly they determine an element's
    /// behaviour.
    ///
    /// - Parameter traits: The traits applied to the view.
    /// - Returns: The string Narrator should read as the control's type, or
    ///   `nil` when no trait implies one.
    private static func localizedControlType(
        for traits: AccessibilityTraits
    ) -> String? {
        if traits.contains(.isButton) {
            return "button"
        } else if traits.contains(.isLink) {
            return "link"
        } else if traits.contains(.isSearchField) {
            return "search box"
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
