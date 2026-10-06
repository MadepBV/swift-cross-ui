/// A phase of a scene's lifecycle.
///
/// Phases are ordered as SwiftUI orders them: ``background`` < ``inactive`` <
/// ``active``.
public struct ScenePhase: Hashable, Sendable, Comparable {
    private enum Phase: Int, Hashable, Sendable {
        case background
        case inactive
        case active
    }
    private var phase: Phase

    /// The scene is currently active.
    ///
    /// This indicates that the scene has focus and can recieve input events.
    public static let active = Self(phase: .active)
    /// The scene is currently inactive.
    ///
    /// This indicates that the scene does not have focus and does not recieve
    /// input events. The scene may or may not still be visible to the user.
    public static let inactive = Self(phase: .inactive)
    /// The scene isn't visible: its window is minimized, or the app is
    /// hidden.
    ///
    /// Desktop backends report this where the platform says so (a
    /// miniaturized window or a hidden app on AppKit, a minimized window on
    /// WinUI). As in SwiftUI, an app should finish or pause work it does on
    /// screen when its scene enters this phase.
    public static let background = Self(phase: .background)

    public static func < (lhs: ScenePhase, rhs: ScenePhase) -> Bool {
        lhs.phase.rawValue < rhs.phase.rawValue
    }
}

extension ScenePhase: CustomStringConvertible {
    public var description: String {
        String(describing: phase)
    }
}
