import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.Core {
    public var deviceClass: DeviceClass { DeviceClass.desktop }

    public func runMainLoop(_ callback: @escaping @MainActor () -> Void) {
        // Immediately set up the default menus so that the Window menu can populate
        // correctly.
        MenuBar.setUpMenuBar(extraMenus: [])

        callback()
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.run()
    }

    public func runInMainThread(action: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async {
            action()
        }
    }

    public func computeRootEnvironment(defaultEnvironment: EnvironmentValues) -> EnvironmentValues {
        let isDark = Self.systemPrefersDarkAppearance
        Self.matchApplicationAppearance(toDark: isDark)
        return
            defaultEnvironment
                .with(\.colorScheme, isDark ? .dark : .light)
                .with(\.appPhase, NSApplication.shared.isActive ? .active : .inactive)
    }

    /// Whether the user has chosen the dark appearance in System Settings.
    ///
    /// Read from the global preference rather than from
    /// `NSApplication.effectiveAppearance`, because a process without an
    /// `Info.plist` (anything launched with `swift run`) is pinned to the
    /// light appearance by AppKit regardless of the system setting.
    static var systemPrefersDarkAppearance: Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }

    /// Makes the whole application follow the colour scheme the root
    /// environment reports.
    ///
    /// SwiftCrossUI resolves its own colours (text, `Color.background`, ...)
    /// from `EnvironmentValues.colorScheme`, but everything AppKit draws by
    /// itself — window backgrounds, sidebars, menus, sheets, panels — follows
    /// the application's appearance. When the two disagree the result is
    /// dark-mode text on light-mode windows, which happens for any app pinned
    /// to Aqua (see ``systemPrefersDarkAppearance``). Setting the app-wide
    /// appearance keeps both in step; `updateWindow(_:environment:)` still
    /// sets each window's own appearance so that
    /// `View.preferredColorScheme(_:)` can override it per window.
    ///
    /// - Parameter isDark: Whether the dark appearance is wanted.
    static func matchApplicationAppearance(toDark isDark: Bool) {
        let wanted: NSAppearance.Name = isDark ? .darkAqua : .aqua
        let application = NSApplication.shared
        let current = application.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
        guard current != wanted else {
            return
        }
        application.appearance = NSAppearance(named: wanted)
    }

    public func setRootEnvironmentChangeHandler(
        to action: @escaping @Sendable @MainActor () -> Void
    ) {
        DistributedNotificationCenter.default.addObserver(
            forName: .AppleInterfaceThemeChangedNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            Task { @MainActor in
                action()
            }
        }

        // This doesn't strictly affect the root environment, but it does require us
        // to re-compute the app's layout, and this is how backends should trigger top
        // level updates.
        DistributedNotificationCenter.default.addObserver(
            forName: NSScroller.preferredScrollerStyleDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            // Self.scrollBarWidth has changed
            Task { @MainActor in
                action()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                action()
            }
        }

        // For updating views that rely on `appPhase`
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                action()
            }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                action()
            }
        }
    }
}

extension Notification.Name {
    static let AppleInterfaceThemeChangedNotification = Notification.Name(
        "AppleInterfaceThemeChangedNotification"
    )
}
