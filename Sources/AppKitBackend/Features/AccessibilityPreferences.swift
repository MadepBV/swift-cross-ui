import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.AccessibilityPreferences {
    public var prefersReducedMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    public var isScreenReaderRunning: Bool {
        NSWorkspace.shared.isVoiceOverEnabled
    }

    public var isSwitchControlRunning: Bool {
        NSWorkspace.shared.isSwitchControlEnabled
    }

    /// macOS has no system-wide text size for apps to follow, so text stays
    /// at its default size.
    public var preferredTextScaleFactor: Double {
        1
    }
}
