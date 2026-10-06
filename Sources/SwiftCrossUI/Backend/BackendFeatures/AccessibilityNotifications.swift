extension BackendFeatures {
    /// Backend methods for telling assistive technologies about something
    /// that happened, without the user having moved to it.
    ///
    /// These are used by ``AccessibilityNotification``'s `post()` methods. The
    /// feature is optional: on a backend without it, posting a notification
    /// does nothing, because there is no assistive technology to tell.
    ///
    /// ## Platform mapping
    ///
    /// - term AppKit: `NSAccessibility.post(element:notification:userInfo:)`
    ///   with `.announcementRequested` and `.layoutChanged`.
    /// - term WinUI: not implemented. Narrator reads announcements raised with
    ///   `AutomationPeer.RaiseNotificationEvent`, but that needs the element's
    ///   own peer, and the WinUI projection doesn't project
    ///   `FrameworkElementAutomationPeer.FromElement` or
    ///   `CreatePeerForElement`. Once it does, the backend can conform with
    ///   `RaiseNotificationEvent(.other, .importantMostRecent/.mostRecent, …)`
    ///   and `RaiseAutomationEvent(.layoutInvalidated)` on the window content.
    @MainActor
    public protocol AccessibilityNotifications: BaseAppBackend {
        /// Posts a notification to the platform's assistive technologies.
        ///
        /// - Parameter notification: What happened.
        func postAccessibilityNotification(_ notification: AccessibilityNotificationEvent)
    }
}

/// A notification for assistive technologies, as handed to a backend.
///
/// The backend-facing counterpart of ``AccessibilityNotification``.
public enum AccessibilityNotificationEvent: Equatable, Sendable {
    /// Words to read out now, with how urgently.
    case announcement(String, priority: AccessibilityAnnouncementPriority)
    /// Part of the screen changed its layout; assistive technologies should
    /// refresh what they know about it, optionally moving to `focus`.
    case layoutChanged
    /// Most of the screen changed, as when a new page appears.
    case screenChanged
    /// The content scrolled by a page; `description` says where it is now
    /// ("Page 2 of 5").
    case pageScrolled(String)
}

/// How urgently an announcement is read out relative to other speech.
///
/// SwiftUI reads this from an announcement's
/// `accessibilitySpeechAnnouncementPriority` attribute.
public enum AccessibilityAnnouncementPriority: Hashable, Sendable {
    /// Read when the assistive technology is idle; it may be dropped.
    case low
    /// Queued behind the current speech.
    case `default`
    /// Interrupts the current speech.
    case high
}

/// Hands posted notifications to the running app's backend.
///
/// ``AccessibilityNotification``'s `post()` takes no environment (it's
/// called from tasks and callbacks as often as from views), so the app
/// registers its backend here when it starts.
@MainActor
enum AccessibilityNotificationCenter {
    /// Delivers a notification, or `nil` before an app with a supporting
    /// backend has started.
    static var deliver: ((AccessibilityNotificationEvent) -> Void)?

    /// Registers an app's backend, if it can post notifications.
    ///
    /// - Parameter backend: The app's backend.
    static func register<Backend: BaseAppBackend>(_ backend: Backend) {
        guard let backend = backend as? any BackendFeatures.AccessibilityNotifications else {
            deliver = nil
            return
        }
        deliver = { [backend] event in
            backend.postAccessibilityNotification(event)
        }
    }

    /// Posts a notification, doing nothing when no backend can.
    ///
    /// - Parameter event: What happened.
    static func post(_ event: AccessibilityNotificationEvent) {
        deliver?(event)
    }
}
