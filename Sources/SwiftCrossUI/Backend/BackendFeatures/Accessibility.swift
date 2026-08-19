extension BackendFeatures {
    /// Backend methods for describing widgets to assistive technologies.
    ///
    /// These are used by the `View.accessibility*` family of modifiers, e.g.
    /// ``View/accessibilityIdentifier(_:)`` and
    /// ``View/accessibilityElement(children:)``.
    ///
    /// Unlike most backend features, views reach this protocol through a
    /// conditional cast rather than ``CastBackend``. A backend that doesn't
    /// implement accessibility simply doesn't expose the metadata; it never
    /// traps.
    ///
    /// ## Platform mapping
    ///
    /// Every backend maps ``BackendFeatures/AccessibilityProperties`` onto its
    /// platform's native accessibility API rather than inventing its own:
    ///
    /// - term AppKit: `NSAccessibility` properties (`accessibilityLabel`,
    ///   `accessibilityHelp`, `accessibilityValue`, `accessibilityIdentifier`,
    ///   `accessibilityRole` and `isAccessibilityElement`).
    /// - term WinUI: `AutomationProperties` attached properties (`Name`,
    ///   `HelpText`, `FullDescription`, `AutomationId`, `LocalizedControlType`
    ///   and `AccessibilityView`), consumed by UI Automation.
    /// - term UIKit: `UIAccessibility` properties (`accessibilityLabel`,
    ///   `accessibilityHint`, `accessibilityValue`, `accessibilityIdentifier`,
    ///   `accessibilityTraits` and `isAccessibilityElement`).
    /// - term Gtk: `GtkAccessible` properties and states, updated through
    ///   `gtk_accessible_update_property_value` and
    ///   `gtk_accessible_update_state_value`.
    @MainActor
    public protocol Accessibility: Core {
        /// Replaces the accessibility metadata exposed by a widget.
        ///
        /// SwiftCrossUI owns every property in `properties` for the lifetime of
        /// the widget, so a `nil` property means "clear whatever was set
        /// before", not "leave the previous value alone". This method is only
        /// ever called for widgets that have at least one accessibility
        /// modifier applied.
        ///
        /// - Parameters:
        ///   - widget: The widget to describe.
        ///   - properties: The complete set of metadata to expose.
        func updateAccessibility(
            of widget: Widget,
            to properties: AccessibilityProperties
        )
    }

    /// The accessibility metadata that SwiftCrossUI attaches to a widget.
    ///
    /// A single value carries the merged result of every accessibility
    /// modifier applied to a view, so backends can apply the whole set in one
    /// pass instead of tracking partial state.
    public struct AccessibilityProperties: Equatable, Sendable {
        /// How a widget's descendants participate in the accessibility tree.
        ///
        /// This is the backend-facing counterpart of
        /// ``AccessibilityChildBehavior``.
        public enum ChildBehavior: Equatable, Sendable {
            /// The widget becomes a container; its descendants stay visible to
            /// assistive technologies as separate elements.
            case contain
            /// The widget becomes a single element whose description is built
            /// from its descendants.
            case combine
            /// The widget becomes a single element and its descendants are
            /// hidden from assistive technologies.
            case ignore
        }

        /// A short, localized description of the widget's content.
        public var label: String?

        /// A description of the outcome of interacting with the widget.
        public var hint: String?

        /// The widget's current value, as a localized string.
        public var value: String?

        /// A stable, non-localized identifier used by UI test automation.
        public var identifier: String?

        /// Behaviours that describe how the widget acts.
        public var traits: AccessibilityTraits

        /// Whether the widget and its descendants are hidden from assistive
        /// technologies. `nil` means that no modifier specified a preference.
        public var isHidden: Bool?

        /// How the widget's descendants participate in the accessibility tree.
        /// `nil` means that the platform's default grouping applies.
        public var childBehavior: ChildBehavior?

        /// Creates a set of accessibility metadata.
        ///
        /// - Parameters:
        ///   - label: A short, localized description of the content.
        ///   - hint: A description of the outcome of interacting.
        ///   - value: The current value, as a localized string.
        ///   - identifier: A stable identifier for UI test automation.
        ///   - traits: Behaviours that describe how the widget acts.
        ///   - isHidden: Whether to hide the widget from assistive tech.
        ///   - childBehavior: How descendants participate in the tree.
        public init(
            label: String? = nil,
            hint: String? = nil,
            value: String? = nil,
            identifier: String? = nil,
            traits: AccessibilityTraits = [],
            isHidden: Bool? = nil,
            childBehavior: ChildBehavior? = nil
        ) {
            self.label = label
            self.hint = hint
            self.value = value
            self.identifier = identifier
            self.traits = traits
            self.isHidden = isHidden
            self.childBehavior = childBehavior
        }

        /// Whether every property is unset.
        public var isEmpty: Bool {
            label == nil
                && hint == nil
                && value == nil
                && identifier == nil
                && traits.isEmpty
                && isHidden == nil
                && childBehavior == nil
        }

        /// Combines these properties with those of an enclosing modifier.
        ///
        /// `self` is the inner (closer to the view) set and wins every
        /// conflict, matching the rule that the modifier nearest a view
        /// describes it most specifically. Traits are unioned rather than
        /// replaced, so `accessibilityAddTraits(_:)` accumulates.
        ///
        /// - Parameter outer: The properties of the enclosing modifier.
        /// - Returns: The merged properties.
        func merging(
            _ outer: AccessibilityProperties
        ) -> AccessibilityProperties {
            AccessibilityProperties(
                label: label ?? outer.label,
                hint: hint ?? outer.hint,
                value: value ?? outer.value,
                identifier: identifier ?? outer.identifier,
                traits: traits.union(outer.traits),
                isHidden: isHidden ?? outer.isHidden,
                childBehavior: childBehavior ?? outer.childBehavior
            )
        }
    }
}

extension BackendFeatures.Accessibility {
    /// Ignores the metadata.
    ///
    /// This default lets a backend adopt ``BackendFeatures/Accessibility``
    /// incrementally, and lets platforms that genuinely have no accessibility
    /// story degrade silently instead of trapping. Backends that mean to
    /// support accessibility must override it.
    public func updateAccessibility(
        of widget: Widget,
        to properties: BackendFeatures.AccessibilityProperties
    ) {}
}
