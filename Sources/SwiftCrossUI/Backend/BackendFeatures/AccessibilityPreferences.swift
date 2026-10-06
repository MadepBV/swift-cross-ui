extension BackendFeatures {
    /// Backend methods for reading the user's system-wide accessibility and
    /// display preferences.
    ///
    /// These back ``EnvironmentValues/accessibilityReduceMotion``,
    /// ``EnvironmentValues/accessibilityVoiceOverEnabled``,
    /// ``EnvironmentValues/accessibilitySwitchControlEnabled`` and
    /// ``EnvironmentValues/dynamicTypeSize``. Views reach this protocol
    /// through a conditional cast; a backend that doesn't implement it gets
    /// the platform-neutral defaults (no reduced motion, no assistive
    /// technology, the default text size).
    ///
    /// The values are read whenever a view reads the environment value, so a
    /// change in the system settings shows up the next time a view updates.
    @MainActor
    public protocol AccessibilityPreferences: Core {
        /// Whether the user has asked the system to minimise animation.
        var prefersReducedMotion: Bool { get }
        /// Whether a screen reader (VoiceOver, Narrator, Orca, …) is running.
        var isScreenReaderRunning: Bool { get }
        /// Whether a switch-access technology is running.
        var isSwitchControlRunning: Bool { get }
        /// The user's preferred text scale, where `1` is the default size.
        var preferredTextScaleFactor: Double { get }
    }
}
