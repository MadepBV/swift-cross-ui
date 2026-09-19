/// Coalesces asynchronous authorization of one native application Quit request.
///
/// Unlike window closing, native termination uses a deferred reply, not a
/// second close/terminate call. Every accepted pending request receives one
/// reply, including denial when the handler is removed or the owner is released.
@_spi(Backends)
@MainActor
public final class ApplicationTerminationRequestCoordinator {
    private var handler: (@MainActor @Sendable () async -> Bool)?
    private var pendingReply: (@MainActor @Sendable (Bool) -> Void)?
    private var generation: UInt64 = 0
    private(set) var pendingTask: Task<Void, Never>?

    public init() {}

    deinit {
        pendingTask?.cancel()
        if let reply = pendingReply {
            // Deinitialization need not run on the main actor. Retain only the
            // reply, never this coordinator, until native deferral is denied.
            Task { @MainActor in reply(false) }
        }
    }

    /// Non-nil replacement applies to the next request. Removal denies an
    /// outstanding native deferral even if its handler ignores cancellation.
    public func setHandler(_ handler: (@MainActor @Sendable () async -> Bool)?) {
        self.handler = handler
        if handler == nil { cancelPendingRequest() }
    }

    /// Returns true when the backend must return its native "terminate later"
    /// result. Reply is never called synchronously from this method. With no
    /// handler, return false so the backend preserves its existing behavior.
    ///
    /// Repeated calls while pending retain the original request's reply only.
    /// Capture the native application weakly in `reply`.
    public func shouldDeferTermination(
        reply: @escaping @MainActor @Sendable (Bool) -> Void
    ) -> Bool {
        guard let handler else { return false }
        guard pendingTask == nil else { return true }
        generation &+= 1
        let requestGeneration = generation
        pendingReply = reply
        pendingTask = Task { @MainActor [weak self] in
            await withTaskCancellationHandler {
                let permitted = await handler()
                self?.completeRequest(
                    generation: requestGeneration,
                    permitted: permitted && !Task.isCancelled
                )
            } onCancel: { [weak self] in
                // A suspended handler may not cooperate with cancellation.
                // Deny without waiting for it to return; its late value is stale.
                Task { @MainActor in
                    self?.cancelPendingRequest(generation: requestGeneration)
                }
            }
        }
        return true
    }

    /// Denies an outstanding request without removing the installed handler.
    /// Future native Quit requests may ask again.
    public func cancelPendingRequest() {
        generation &+= 1
        let task = pendingTask
        let reply = pendingReply
        pendingTask = nil
        pendingReply = nil
        task?.cancel()
        reply?(false)
    }

    private func cancelPendingRequest(generation: UInt64) {
        guard generation == self.generation else { return }
        cancelPendingRequest()
    }

    private func completeRequest(generation: UInt64, permitted: Bool) {
        guard generation == self.generation else { return }
        self.generation &+= 1
        pendingTask = nil
        let reply = pendingReply
        pendingReply = nil
        // Clear all state before native code can synchronously re-enter.
        reply?(permitted)
    }
}
