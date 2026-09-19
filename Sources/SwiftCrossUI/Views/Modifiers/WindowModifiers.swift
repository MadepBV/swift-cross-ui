extension View {
    /// Authorizes closing the enclosing window before its content is released.
    ///
    /// Return true after saving or explicitly discarding changes, and false
    /// when the user cancels or saving fails. The handler runs on the main
    /// actor; the window stays alive while it is suspended. Repeated close
    /// requests share the pending decision. Programmatic `dismissWindow()`
    /// requests use the same handler.
    ///
    /// Apply one handler to the window's root content. If multiple descendants
    /// provide handlers, the first value in content order is used.
    ///
    /// - Important: Supported by WinUIBackend and AppKitBackend. Other backends
    ///   ignore this modifier and issue a warning; they cannot guarantee close
    ///   authorization. This does not intercept application termination.
    public func onWindowCloseRequested(
        _ action: @escaping @MainActor @Sendable () async -> Bool
    ) -> some View {
        preference(key: \.onWindowCloseRequested, value: action)
    }

    /// Sets the closability of the enclosing window.
    ///
    /// This only controls whether user can close the window via the title
    /// bar close button, built-in keyboard shortcuts such as Cmd+W or Alt+F4,
    /// etc. Windows can always be closed programmatically.
    public func windowDismissBehavior(_ behavior: WindowInteractionBehavior) -> some View {
        preference(key: \.windowDismissBehavior, value: behavior)
    }

    /// Sets the minimizability of the enclosing window.
    ///
    /// - Important: This isn't supported on GtkBackend or Gtk3Backend, both of
    ///   which ignore the corresponding preference value.
    public func preferredWindowMinimizeBehavior(
        _ behavior: WindowInteractionBehavior
    ) -> some View {
        preference(key: \.preferredWindowMinimizeBehavior, value: behavior)
    }

    /// Sets the resizability of the enclosing window.
    ///
    /// This modifier controls whether the user can resize the enclosing window,
    /// whereas ``Scene/windowResizability(_:)`` controls how SwiftCrossUI
    /// determines the bounds within which windows can be resized. The only time
    /// that ``Scene/windowResizability(_:)`` can disable interactive resizing
    /// is when the window's content has a fixed size and the
    /// ``WindowResizability`` is ``WindowResizability/contentSize``.
    public func windowResizeBehavior(_ behavior: WindowInteractionBehavior) -> some View {
        preference(key: \.windowResizeBehavior, value: behavior)
    }
}
