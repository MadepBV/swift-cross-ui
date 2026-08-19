/// A set of behaviours that an accessibility element can exhibit.
///
/// Traits tell assistive technologies how to describe and interact with a
/// view. Add them with ``View/accessibilityAddTraits(_:)``.
///
/// ```swift
/// Text("Chapter 1")
///     .accessibilityAddTraits(.isHeader)
/// ```
///
/// Not every trait can be expressed by every platform. Each backend maps the
/// traits it understands onto its own accessibility vocabulary (an
/// `NSAccessibility.Role` on macOS, a `UIAccessibilityTraits` bitmask on iOS,
/// a localized control type on Windows, and a role description on Gtk) and
/// ignores the rest. See the documentation of
/// ``BackendFeatures/Accessibility`` for the per-backend details.
public struct AccessibilityTraits: OptionSet, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// The element behaves like a button.
    public static let isButton = AccessibilityTraits(rawValue: 1 << 0)

    /// The element behaves like a header that divides content into sections.
    public static let isHeader = AccessibilityTraits(rawValue: 1 << 1)

    /// The element behaves like a link.
    public static let isLink = AccessibilityTraits(rawValue: 1 << 2)

    /// The element behaves like a search field.
    public static let isSearchField = AccessibilityTraits(rawValue: 1 << 3)

    /// The element behaves like an image.
    public static let isImage = AccessibilityTraits(rawValue: 1 << 4)

    /// The element plays its own sound when activated.
    public static let playsSound = AccessibilityTraits(rawValue: 1 << 5)

    /// The element behaves like a keyboard key.
    public static let isKeyboardKey = AccessibilityTraits(rawValue: 1 << 6)

    /// The element behaves like static text that cannot change.
    public static let isStaticText = AccessibilityTraits(rawValue: 1 << 7)

    /// The element provides a summary of the information on the screen.
    public static let isSummaryElement = AccessibilityTraits(rawValue: 1 << 8)

    /// The element updates its contents or label frequently.
    public static let updatesFrequently = AccessibilityTraits(rawValue: 1 << 9)

    /// The element starts a media session when activated.
    public static let startsMediaSession =
        AccessibilityTraits(rawValue: 1 << 10)

    /// The element allows direct touch interaction.
    public static let allowsDirectInteraction =
        AccessibilityTraits(rawValue: 1 << 11)

    /// Activating the element scrolls the screen by a page.
    public static let causesPageTurn = AccessibilityTraits(rawValue: 1 << 12)

    /// The element behaves like a tab bar.
    public static let isTabBar = AccessibilityTraits(rawValue: 1 << 13)

    /// The element is currently selected.
    public static let isSelected = AccessibilityTraits(rawValue: 1 << 14)

    /// The element prevents interaction with views behind it.
    public static let isModal = AccessibilityTraits(rawValue: 1 << 15)

    /// The element behaves like a toggle.
    public static let isToggle = AccessibilityTraits(rawValue: 1 << 16)
}
