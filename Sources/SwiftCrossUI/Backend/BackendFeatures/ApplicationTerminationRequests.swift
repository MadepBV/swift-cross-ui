extension BackendFeatures {
    /// Optional authorization of a normal application Quit request.
    ///
    /// Unlike ``WindowCloseRequests``, this protects application termination,
    /// which may bypass individual window-close delegates. It does not protect
    /// force termination, crashes, or process signals. Backends without this
    /// capability retain their existing application termination behavior.
    @MainActor
    public protocol ApplicationTerminationRequests: Core {
        /// Installs one application-wide authorization handler, typically from
        /// `App.init`. Return true only when the application may terminate.
        ///
        /// The backend defers the native request while awaiting the handler on
        /// the main actor. Repeated requests share the pending decision. The
        /// backend does not close windows to gather decisions; the application
        /// must authorize all relevant state itself before returning true.
        ///
        /// Replacing a non-nil handler affects future requests. Setting nil
        /// cancels and denies any pending request, then restores the backend's
        /// original behavior for later requests. Cancellation is cooperative:
        /// application code must also handle cancellation of its own UI/work.
        /// Avoid retaining the backend from its handler.
        func setApplicationTerminationRequestHandler(
            _ handler: (@MainActor @Sendable () async -> Bool)?
        )
    }
}
