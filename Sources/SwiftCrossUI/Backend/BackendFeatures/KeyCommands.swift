extension BackendFeatures {
    /// Optional native focus scopes for result-bearing commands on passive views.
    /// Unsupported backends leave content unchanged and do not call the handler.
    @MainActor
    public protocol KeyCommands: Core {
        /// Creates a focusable, visually transparent scope around passive content.
        /// Pointer presses on that content may give the scope native focus;
        /// pressing native child controls must preserve their own focus behavior.
        func createKeyCommandTarget(wrapping child: Widget) -> Widget

        /// Replaces the current handler without adding another native listener.
        /// Deliver synchronously, only while this scope itself owns native focus
        /// in its active window. Never intercept a descendant text editor or IME.
        /// Disabled/ignored commands leave the original native event untouched.
        func updateKeyCommandTarget(
            _ target: Widget,
            isEnabled: Bool,
            environment: EnvironmentValues,
            handler: @escaping @MainActor (KeyCommandEvent) -> KeyCommandResult
        )
    }
}
