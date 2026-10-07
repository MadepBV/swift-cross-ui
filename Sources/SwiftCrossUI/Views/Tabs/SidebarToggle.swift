/// Shows and hides the sidebar of a tab view styled
/// ``SidebarAdaptableTabViewStyle``, as a Mac window's sidebar button and
/// View › Show/Hide Sidebar do.
///
/// The tab view draws the button at the top of its sidebar; while the sidebar
/// is hidden, the selected tab's navigation bar draws it before its back
/// button, so it stays where a Mac window's toolbar keeps it.
struct SidebarToggle {
    /// Whether the sidebar is showing.
    var isVisible: Bool
    /// Shows a hidden sidebar or hides a showing one.
    var toggle: @MainActor () -> Void

    /// The shortcut: ⌃⌘S, as on a Mac. Windows has no Control key distinct
    /// from Ctrl (which is ``EventModifiers/command`` there), so it's
    /// Ctrl+Shift+S, Ctrl+Alt being the AltGr of many keyboard layouts.
    static var shortcutModifiers: EventModifiers {
        #if os(Windows)
            [.command, .shift]
        #else
            [.command, .control]
        #endif
    }
}

extension EnvironmentValues {
    /// The sidebar button a navigation bar draws while its tab view's sidebar
    /// is hidden.
    @Entry var sidebarToggle: SidebarToggle? = nil
}

/// The button that shows and hides a tab view's sidebar.
struct SidebarToggleButton: View {
    var toggle: SidebarToggle

    var body: some View {
        let title = toggle.isVisible ? "Hide Sidebar" : "Show Sidebar"
        Button {
            toggle.toggle()
        } label: {
            Image(systemName: "sidebar.left")
        }
        .buttonStyle(.borderless)
        .keyboardShortcut("s", modifiers: SidebarToggle.shortcutModifiers)
        .accessibilityLabel(title)
    }
}
