import Foundation

#if canImport(Accessibility)
    import Accessibility
#endif

/// Notifications that tell assistive technologies about something that
/// happened without the user having moved to it, posted with `post()`.
///
/// ```swift
/// AccessibilityNotification.Announcement("Download finished").post()
/// ```
///
/// Each notification goes to the running app's backend through
/// ``BackendFeatures/AccessibilityNotifications``: VoiceOver on macOS reads
/// an announcement out through `NSAccessibility`. On a backend without the
/// feature (WinUI for now; see the feature's documentation), or before the
/// app has started, posting does nothing.
public enum AccessibilityNotification {
    /// Words for an assistive technology to read out now.
    ///
    /// An `AttributedString` announcement takes its urgency from the
    /// `accessibilitySpeechAnnouncementPriority` attribute of its first run,
    /// as in SwiftUI.
    public struct Announcement: Sendable {
        /// The words to read.
        public let text: String
        /// How urgently to read them.
        public let priority: AccessibilityAnnouncementPriority

        /// Creates an announcement of a string.
        ///
        /// - Parameter announcement: The words to read.
        public init(_ announcement: String) {
            text = announcement
            priority = .default
        }

        /// Creates an announcement of a text view's string.
        ///
        /// - Parameter announcement: The words to read.
        public init(_ announcement: Text) {
            text = announcement.string
            priority = .default
        }

        /// Creates an announcement of an attributed string, reading its
        /// speech priority.
        ///
        /// - Parameter announcement: The words to read.
        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        public init(_ announcement: AttributedString) {
            text = String(announcement.characters)
            priority = Self.priority(of: announcement)
        }

        /// Reads the announcement out.
        @MainActor
        public func post() {
            AccessibilityNotificationCenter.post(.announcement(text, priority: priority))
        }

        /// The speech priority of an attributed announcement's first run.
        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        private static func priority(
            of announcement: AttributedString
        ) -> AccessibilityAnnouncementPriority {
            #if canImport(Darwin)
                guard let run = announcement.runs.first else {
                    return .default
                }
            #endif
            #if canImport(Accessibility)
                // Apple's own attribute, which SwiftUI source sets.
                guard #available(macOS 14, iOS 17, tvOS 17, watchOS 10, *) else {
                    return .default
                }
                switch run.accessibilitySpeechAnnouncementPriority {
                    case .low: return .low
                    case .high: return .high
                    default: return .default
                }
            #elseif canImport(Darwin)
                return run.accessibilitySpeechAnnouncementPriority ?? .default
            #else
                // Walking the runs makes the client reference
                // swift-foundation's internal `_FoundationCollections.BigString.Index`,
                // which its DLL does not export, so an app using this failed to
                // link (measured on Windows): the attribute is not read there.
                return .default
            #endif
        }
    }

    /// Part of the screen changed its layout, such as a row appearing.
    public struct LayoutChanged: Sendable {
        /// Creates the notification.
        public init() {}

        /// Creates the notification. SwiftUI moves the assistive technology to
        /// `element`; SwiftCrossUI has no handle on accessibility elements,
        /// so the element is not used and the platform keeps its own focus.
        ///
        /// - Parameter element: The element to move to.
        public init<Element>(_ element: Element?) {}

        /// Posts the notification.
        @MainActor
        public func post() {
            AccessibilityNotificationCenter.post(.layoutChanged)
        }
    }

    /// Most of the screen changed, as when a new page appears.
    public struct ScreenChanged: Sendable {
        /// Creates the notification.
        public init() {}

        /// Creates the notification. As with ``LayoutChanged``, the element
        /// to move to is not used.
        ///
        /// - Parameter element: The element to move to.
        public init<Element>(_ element: Element?) {}

        /// Posts the notification.
        @MainActor
        public func post() {
            AccessibilityNotificationCenter.post(.screenChanged)
        }
    }

    /// The content scrolled by a page.
    public struct PageScrolled: Sendable {
        /// Where the content is now, e.g. "Page 2 of 5".
        public let description: String

        /// Creates the notification.
        ///
        /// - Parameter description: Where the content is now.
        public init(_ description: String) {
            self.description = description
        }

        /// Creates the notification.
        ///
        /// - Parameter description: Where the content is now.
        public init(_ description: Text) {
            self.description = description.string
        }

        /// Posts the notification.
        @MainActor
        public func post() {
            AccessibilityNotificationCenter.post(.pageScrolled(description))
        }
    }
}

#if !canImport(Accessibility)
// Apple platforms have the attribute in their Accessibility framework, which
// SwiftUI source sets; elsewhere SwiftCrossUI declares it under the same name.

/// The speech priority SwiftUI reads from an announcement's
/// `accessibilitySpeechAnnouncementPriority` attribute.
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public enum AccessibilitySpeechAnnouncementPriorityAttribute: AttributedStringKey {
    public typealias Value = AccessibilityAnnouncementPriority
    public static let name = "SwiftCrossUI.AccessibilitySpeechAnnouncementPriority"
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes {
    /// The accessibility attributes SwiftCrossUI reads from attributed
    /// strings, spelled as Apple's Accessibility framework spells them.
    public struct SwiftCrossUIAccessibilityAttributes: AttributeScope {
        /// How urgently an announcement is read out.
        public let accessibilitySpeechAnnouncementPriority:
            AccessibilitySpeechAnnouncementPriorityAttribute
    }

    /// The accessibility attributes SwiftCrossUI reads.
    public var swiftCrossUIAccessibility: SwiftCrossUIAccessibilityAttributes.Type {
        SwiftCrossUIAccessibilityAttributes.self
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeDynamicLookup {
    /// Makes `string.accessibilitySpeechAnnouncementPriority = .low` work.
    public subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<
            AttributeScopes.SwiftCrossUIAccessibilityAttributes, T
        >
    ) -> T {
        self[T.self]
    }
}
#endif
