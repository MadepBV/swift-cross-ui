import UIKit
@_spi(Backends) import SwiftCrossUI

extension UIKitBackend: BackendFeatures.Accessibility {
    /// Applies accessibility metadata to a widget's `UIView` using
    /// `UIAccessibility`.
    ///
    /// ## Mapping
    ///
    /// | SwiftCrossUI | UIKit |
    /// | --- | --- |
    /// | `label` | `accessibilityLabel` |
    /// | `hint` | `accessibilityHint` |
    /// | `value` | `accessibilityValue` |
    /// | `identifier` | `accessibilityIdentifier` |
    /// | `traits` | `accessibilityTraits` |
    /// | `isHidden` | `accessibilityElementsHidden` |
    /// | `childBehavior` | `isAccessibilityElement`/`shouldGroupAccessibilityChildren` |
    ///
    /// Because most of this backend's widgets wrap their real view in a
    /// layout container, the metadata is forwarded to the one accessibility
    /// element beneath the widget when there is exactly one -- so a label
    /// applied to a ``SwiftCrossUI/Button`` lands on the `UIButton` rather
    /// than on the wrapper that positions it.
    ///
    /// ## Known limitations
    ///
    /// - Traits are added to whatever UIKit already exposes rather than
    ///   replacing it, so that describing a `UIButton` doesn't strip its
    ///   built-in `.button` trait. Removing an inherent trait isn't possible.
    /// - `.isModal` has no `UIAccessibilityTraits` counterpart and is ignored.
    ///
    /// - Parameters:
    ///   - widget: The widget to describe.
    ///   - properties: The complete set of metadata to expose.
    public func updateAccessibility(
        of widget: Widget,
        to properties: BackendFeatures.AccessibilityProperties
    ) {
        let view = Self.target(for: widget)

        view.accessibilityIdentifier = properties.identifier
        view.accessibilityLabel = properties.label
        view.accessibilityHint = properties.hint
        view.accessibilityValue = properties.value

        let traits = Self.traits(for: properties.traits)
        if !traits.isEmpty {
            view.accessibilityTraits.formUnion(traits)
        }

        guard properties.isHidden != true else {
            view.accessibilityElementsHidden = true
            return
        }
        view.accessibilityElementsHidden = false

        switch properties.childBehavior {
            case .combine:
                view.accessibilityLabel =
                    properties.label ?? Self.combinedLabel(of: view)
                view.isAccessibilityElement = true
            case .ignore:
                // Marking a `UIView` as an accessibility element is exactly
                // what stops UIKit from descending into its subviews.
                view.isAccessibilityElement = true
            case .contain:
                view.shouldGroupAccessibilityChildren = true
            case nil:
                // A label on a view that isn't an accessibility element goes
                // nowhere, so promote it -- but only when doing so can't hide
                // anything, i.e. when nothing beneath it is exposed already.
                let describesSomething =
                    properties.label != nil || properties.value != nil
                if describesSomething && !view.isAccessibilityElement,
                    case .none = Self.searchForElements(under: view)
                {
                    view.isAccessibilityElement = true
                }
        }
    }

    /// The result of looking for accessibility elements beneath a view.
    private enum ElementSearchResult {
        /// Nothing beneath the view is exposed to assistive technologies.
        case none
        /// Exactly one view beneath is exposed.
        case one(UIView)
        /// More than one view beneath is exposed.
        case many
    }

    /// Chooses the view that should carry a widget's accessibility metadata.
    ///
    /// - Parameter widget: The widget being described.
    /// - Returns: The widget's own view, or the single accessibility element
    ///   it wraps.
    private static func target(for widget: Widget) -> UIView {
        let view = widget.view!
        guard !view.isAccessibilityElement else {
            return view
        }
        guard case .one(let element) = searchForElements(under: view) else {
            return view
        }
        return element
    }

    /// Looks for accessibility elements in a view's subtree, stopping as soon
    /// as a second one turns up.
    ///
    /// - Parameter view: The root of the subtree to search. The root itself is
    ///   not considered.
    /// - Returns: What the search found.
    private static func searchForElements(
        under view: UIView
    ) -> ElementSearchResult {
        var found: UIView?
        for subview in view.subviews {
            let result: ElementSearchResult
            if subview.isAccessibilityElement {
                result = .one(subview)
            } else {
                result = searchForElements(under: subview)
            }

            switch result {
                case .none:
                    continue
                case .many:
                    return .many
                case .one(let element):
                    guard found == nil else {
                        return .many
                    }
                    found = element
            }
        }

        guard let found else {
            return .none
        }
        return .one(found)
    }

    /// Translates SwiftCrossUI traits into their UIKit counterparts.
    ///
    /// - Parameter traits: The traits applied to the view.
    /// - Returns: The equivalent `UIAccessibilityTraits`.
    private static func traits(
        for traits: AccessibilityTraits
    ) -> UIAccessibilityTraits {
        var result: UIAccessibilityTraits = []
        if traits.contains(.isButton) {
            result.insert(.button)
        }
        if traits.contains(.isHeader) {
            result.insert(.header)
        }
        if traits.contains(.isLink) {
            result.insert(.link)
        }
        if traits.contains(.isSearchField) {
            result.insert(.searchField)
        }
        if traits.contains(.isImage) {
            result.insert(.image)
        }
        if traits.contains(.playsSound) {
            result.insert(.playsSound)
        }
        if traits.contains(.isKeyboardKey) {
            result.insert(.keyboardKey)
        }
        if traits.contains(.isStaticText) {
            result.insert(.staticText)
        }
        if traits.contains(.isSummaryElement) {
            result.insert(.summaryElement)
        }
        if traits.contains(.updatesFrequently) {
            result.insert(.updatesFrequently)
        }
        if traits.contains(.startsMediaSession) {
            result.insert(.startsMediaSession)
        }
        if traits.contains(.allowsDirectInteraction) {
            result.insert(.allowsDirectInteraction)
        }
        if traits.contains(.causesPageTurn) {
            result.insert(.causesPageTurn)
        }
        if traits.contains(.isTabBar) {
            result.insert(.tabBar)
        }
        if traits.contains(.isSelected) {
            result.insert(.selected)
        }
        if traits.contains(.isToggle) {
            if #available(iOS 17.0, tvOS 17.0, visionOS 1.0, *) {
                result.insert(.toggleButton)
            } else {
                result.insert(.button)
            }
        }
        return result
    }

    /// Builds a single description out of everything beneath a view.
    ///
    /// This backs ``SwiftCrossUI/AccessibilityChildBehavior/combine``.
    ///
    /// - Parameter view: The view whose descendants to describe.
    /// - Returns: The merged description, or `nil` if nothing beneath the view
    ///   describes itself.
    private static func combinedLabel(of view: UIView) -> String? {
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
        of view: UIView,
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
    private static func description(of view: UIView) -> String? {
        if let label = view.accessibilityLabel, !label.isEmpty {
            return label
        }
        if let label = view as? UILabel, let text = label.text, !text.isEmpty {
            return text
        }
        if let textView = view as? TextView, !textView.text.isEmpty {
            return textView.text
        }
        if let button = view as? UIButton,
            let title = button.title(for: .normal),
            !title.isEmpty
        {
            return title
        }
        if let value = view.accessibilityValue, !value.isEmpty {
            return value
        }
        return nil
    }
}
