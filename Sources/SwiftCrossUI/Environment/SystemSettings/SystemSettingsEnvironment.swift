import Foundation

extension EnvironmentValues {
    /// The backend's accessibility and display preferences, if it reports
    /// them.
    @MainActor
    private var accessibilityPreferences: (any BackendFeatures.AccessibilityPreferences)? {
        backend as? any BackendFeatures.AccessibilityPreferences
    }

    /// Overrides for the system-derived values below, set with
    /// `.environment(_:_:)`.
    @Entry var accessibilityReduceMotionOverride: Bool?
    @Entry var accessibilityVoiceOverEnabledOverride: Bool?
    @Entry var accessibilitySwitchControlEnabledOverride: Bool?
    @Entry var dynamicTypeSizeOverride: DynamicTypeSize?

    /// Whether the user has asked for animations to be minimised.
    ///
    /// Read from the system where the backend reports it (Windows' "Animation
    /// effects" setting, macOS's "Reduce motion"), `false` otherwise.
    @MainActor
    public var accessibilityReduceMotion: Bool {
        get {
            accessibilityReduceMotionOverride
                ?? accessibilityPreferences?.prefersReducedMotion
                ?? false
        }
        set { accessibilityReduceMotionOverride = newValue }
    }

    /// Whether a screen reader is running: VoiceOver on macOS, Narrator or
    /// another screen reader on Windows. `false` when the backend can't tell.
    @MainActor
    public var accessibilityVoiceOverEnabled: Bool {
        get {
            accessibilityVoiceOverEnabledOverride
                ?? accessibilityPreferences?.isScreenReaderRunning
                ?? false
        }
        set { accessibilityVoiceOverEnabledOverride = newValue }
    }

    /// Whether Switch Control (or the platform's switch access) is running.
    /// `false` when the backend can't tell, and always on Windows, which has
    /// no system switch access.
    @MainActor
    public var accessibilitySwitchControlEnabled: Bool {
        get {
            accessibilitySwitchControlEnabledOverride
                ?? accessibilityPreferences?.isSwitchControlRunning
                ?? false
        }
        set { accessibilitySwitchControlEnabledOverride = newValue }
    }

    /// The preferred size of content.
    ///
    /// Derived from the system text size where the backend reports one
    /// (Windows' "Text size"), ``DynamicTypeSize/large`` otherwise.
    @MainActor
    public var dynamicTypeSize: DynamicTypeSize {
        get {
            dynamicTypeSizeOverride
                ?? accessibilityPreferences.map {
                    DynamicTypeSize(textScaleFactor: $0.preferredTextScaleFactor)
                }
                ?? .large
        }
        set { dynamicTypeSizeOverride = newValue }
    }

    /// The horizontal size class of the view.
    ///
    /// ``UserInterfaceSizeClass/regular`` by default: a desktop window is
    /// never laid out as a phone. Containers may set it explicitly.
    @Entry public var horizontalSizeClass: UserInterfaceSizeClass? = .regular

    /// The vertical size class of the view. ``UserInterfaceSizeClass/regular``
    /// by default; see ``horizontalSizeClass``.
    @Entry public var verticalSizeClass: UserInterfaceSizeClass? = .regular

    /// The display scale of this environment: the number of pixels per point
    /// of the window the view is displayed in.
    public var displayScale: CGFloat {
        get { CGFloat(windowScaleFactor) }
        set { windowScaleFactor = Double(newValue) }
    }

    /// Whether the nearest focusable ancestor has focus.
    ///
    /// - Important: SwiftCrossUI doesn't yet report focus changes per view,
    ///   so nothing sets this and it is always `false` unless set explicitly
    ///   with `.environment(\.isFocused, _:)`. Focus-driven styling (as on
    ///   tvOS) therefore shows its unfocused appearance, which is the
    ///   appearance pointer-driven desktop UIs expect.
    @Entry public var isFocused: Bool = false

    /// Asks the system to show its app rating prompt. Does nothing on the
    /// desktop platforms; see ``RequestReviewAction``.
    public var requestReview: RequestReviewAction {
        RequestReviewAction()
    }
}
