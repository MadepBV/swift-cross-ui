import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.Accessibility {
    /// Applies accessibility metadata to an `NSView` using the
    /// `NSAccessibility` protocol properties.
    ///
    /// ## Mapping
    ///
    /// | SwiftCrossUI | AppKit |
    /// | --- | --- |
    /// | `label` | `accessibilityLabel` |
    /// | `hint` | `accessibilityHelp` |
    /// | `value` | `accessibilityValue` |
    /// | `identifier` | `accessibilityIdentifier` |
    /// | `traits` | `accessibilityRole`/`accessibilitySubrole`/`accessibilitySelected` |
    /// | `isHidden` | `isAccessibilityElement` plus an empty `accessibilityChildren` |
    /// | `childBehavior` | `isAccessibilityElement` plus `accessibilityChildren` |
    ///
    /// ## Known limitations
    ///
    /// - `NSTextField` computes `accessibilityValue` from its `stringValue`
    ///   and ignores any override, so ``SwiftCrossUI/View/accessibilityValue(_:)``
    ///   has no effect on a plain ``SwiftCrossUI/Text``. Use
    ///   ``SwiftCrossUI/View/accessibilityLabel(_:)`` there instead.
    /// - The traits that describe touch behaviour (`playsSound`,
    ///   `isKeyboardKey`, `isSummaryElement`, `updatesFrequently`,
    ///   `startsMediaSession`, `allowsDirectInteraction`, `causesPageTurn` and
    ///   `isModal`) have no `NSAccessibility` equivalent and are ignored.
    ///
    /// - Parameters:
    ///   - widget: The view to describe.
    ///   - properties: The complete set of metadata to expose.
    public func updateAccessibility(
        of widget: Widget,
        to properties: BackendFeatures.AccessibilityProperties
    ) {
        widget.setAccessibilityIdentifier(properties.identifier)

        guard properties.isHidden != true else {
            // NSAccessibility has no dedicated "hidden" flag. Describing
            // nothing, not being an element, and publishing no children is
            // the closest equivalent, and is what keeps a subtree out of
            // VoiceOver's navigation.
            widget.setAccessibilityLabel(nil)
            widget.setAccessibilityHelp(nil)
            widget.setAccessibilityValue(nil)
            widget.setAccessibilityElement(false)
            widget.setAccessibilityChildren([])
            return
        }

        widget.setAccessibilityHelp(properties.hint)
        widget.setAccessibilityValue(properties.value)
        widget.setAccessibilitySelected(
            properties.traits.contains(.isSelected)
        )

        let role = Self.role(for: properties.traits)
        if let role {
            widget.setAccessibilityRole(role)
        }
        if properties.traits.contains(.isSearchField) {
            widget.setAccessibilitySubrole(.searchField)
        }

        switch properties.childBehavior {
            case .combine:
                widget.setAccessibilityLabel(
                    properties.label ?? Self.combinedLabel(of: widget)
                )
                Self.makeElement(widget, role: role, hidingChildren: true)
            case .ignore:
                widget.setAccessibilityLabel(properties.label)
                Self.makeElement(widget, role: role, hidingChildren: true)
            case .contain:
                widget.setAccessibilityLabel(properties.label)
                Self.makeElement(widget, role: role, hidingChildren: false)
            case nil:
                widget.setAccessibilityLabel(properties.label)
                // A bare container is invisible to VoiceOver, so a label on
                // one would silently go nowhere. Promote it to a group so the
                // label is actually announced. Real controls are left alone --
                // AppKit already exposes them, and overriding their role would
                // do more harm than good.
                let describesSomething =
                    properties.label != nil || properties.value != nil
                if describesSomething && Self.isBareContainer(widget) {
                    Self.makeElement(widget, role: role, hidingChildren: false)
                } else if properties.isHidden == false {
                    // Explicitly un-hidden, so put back the children that a
                    // previously hidden state took away.
                    widget.setAccessibilityChildren(
                        NSAccessibility.unignoredChildren(from: widget.subviews)
                    )
                }
        }
    }

    /// Whether a view is one of the plain containers created by
    /// ``AppKitBackend/createContainer()`` rather than a real control.
    private static func isBareContainer(_ widget: Widget) -> Bool {
        type(of: widget) == NSView.self
    }

    /// Turns a view into a single accessibility element.
    ///
    /// - Parameters:
    ///   - widget: The view to promote.
    ///   - role: The role implied by the view's traits, if any.
    ///   - hidingChildren: Whether to remove the view's descendants from the
    ///     accessibility tree.
    private static func makeElement(
        _ widget: Widget,
        role: NSAccessibility.Role?,
        hidingChildren: Bool
    ) {
        widget.setAccessibilityElement(true)
        if role == nil && isBareContainer(widget) {
            widget.setAccessibilityRole(.group)
        }
        if hidingChildren {
            widget.setAccessibilityChildren([])
        } else {
            // Setting `nil` clears the list rather than restoring the default,
            // so the default has to be recomputed by hand.
            widget.setAccessibilityChildren(
                NSAccessibility.unignoredChildren(from: widget.subviews)
            )
        }
    }

    /// Chooses the single `NSAccessibility` role that best matches a trait
    /// set.
    ///
    /// AppKit allows exactly one role per element, so the traits are checked
    /// in order of how strongly they determine an element's behaviour.
    ///
    /// - Parameter traits: The traits applied to the view.
    /// - Returns: The matching role, or `nil` when no trait implies one.
    private static func role(
        for traits: AccessibilityTraits
    ) -> NSAccessibility.Role? {
        if traits.contains(.isButton) {
            return .button
        } else if traits.contains(.isLink) {
            return .link
        } else if traits.contains(.isSearchField) {
            return .textField
        } else if traits.contains(.isImage) {
            return .image
        } else if traits.contains(.isHeader) {
            // Not exposed as a constant by AppKit, but `AXHeading` is the role
            // macOS accessibility clients (and WebKit) use for headings.
            return NSAccessibility.Role(rawValue: "AXHeading")
        } else if traits.contains(.isToggle) {
            return .checkBox
        } else if traits.contains(.isTabBar) {
            return .tabGroup
        } else if traits.contains(.isStaticText) {
            return .staticText
        } else {
            return nil
        }
    }

    /// Builds a single description out of everything beneath a view.
    ///
    /// This backs ``SwiftCrossUI/AccessibilityChildBehavior/combine``, which
    /// asks for the descendants' descriptions to be merged into the element
    /// that replaces them.
    ///
    /// - Parameter view: The view whose descendants to describe.
    /// - Returns: The merged description, or `nil` if nothing beneath the view
    ///   describes itself.
    private static func combinedLabel(of view: NSView) -> String? {
        var parts: [String] = []
        for subview in view.subviews {
            collectDescriptions(of: subview, into: &parts)
        }
        guard !parts.isEmpty else {
            return nil
        }
        return parts.joined(separator: ", ")
    }

    /// Appends the description of a view, or of its descendants when the view
    /// doesn't describe itself.
    ///
    /// - Parameters:
    ///   - view: The view to describe.
    ///   - parts: The descriptions collected so far.
    private static func collectDescriptions(
        of view: NSView,
        into parts: inout [String]
    ) {
        if let description = description(of: view) {
            parts.append(description)
            return
        }
        for subview in view.subviews {
            collectDescriptions(of: subview, into: &parts)
        }
    }

    /// The text that a single view contributes to a combined description.
    ///
    /// - Parameter view: The view to describe.
    /// - Returns: The view's description, or `nil` if it has none.
    private static func description(of view: NSView) -> String? {
        if let label = view.accessibilityLabel(), !label.isEmpty {
            return label
        }
        if let field = view as? NSTextField, !field.stringValue.isEmpty {
            return field.stringValue
        }
        if let button = view as? NSButton, !button.title.isEmpty {
            return button.title
        }
        if let value = view.accessibilityValue() as? String, !value.isEmpty {
            return value
        }
        return nil
    }
}
