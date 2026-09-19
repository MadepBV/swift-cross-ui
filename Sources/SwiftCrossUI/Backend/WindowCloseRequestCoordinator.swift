/// Serializes asynchronous authorization before a native window closes.
///
/// Backends cancel the original native close event when `shouldDeferClose`
/// returns true. Approval retries the close once; any synchronous native close
/// notification raised by that retry is allowed without asking again.
@_spi(Backends)
@MainActor
public final class WindowCloseRequestCoordinator {
    private var handler: (@MainActor @Sendable () async -> Bool)?
    private var generation: UInt64 = 0
    private var isClosed = false
    private var isPerformingAuthorizedClose = false
    private(set) var pendingTask: Task<Void, Never>?

    public init() {}

    deinit {
        pendingTask?.cancel()
    }

    /// Updates the handler used by future requests. View updates do not restart
    /// an existing prompt. Removing the handler invalidates its pending result.
    public func setHandler(_ handler: (@MainActor @Sendable () async -> Bool)?) {
        guard !isClosed else { return }
        self.handler = handler
        if handler == nil { cancelPendingRequest() }
    }

    /// Returns whether the caller must cancel/defer this native close request.
    /// The close action must synchronously ask the native window to close, and
    /// should capture its window weakly so a pending decision cannot retain it.
    public func shouldDeferClose(
        performClose: @escaping @MainActor @Sendable () -> Void
    ) -> Bool {
        guard !isClosed else { return true }
        if isPerformingAuthorizedClose { return false }
        guard let handler else { return false }
        guard pendingTask == nil else { return true }
        generation &+= 1
        let requestGeneration = generation
        pendingTask = Task { @MainActor [weak self] in
            let permitted = await handler()
            guard !Task.isCancelled else { return }
            self?.completeRequest(
                generation: requestGeneration,
                permitted: permitted,
                performClose: performClose
            )
        }
        return true
    }

    /// Invalidates suspended authorization before the backend releases a scene.
    public func windowDidClose() {
        isClosed = true
        handler = nil
        cancelPendingRequest()
    }

    private func cancelPendingRequest() {
        generation &+= 1
        pendingTask?.cancel()
        pendingTask = nil
    }

    private func completeRequest(
        generation: UInt64,
        permitted: Bool,
        performClose: @MainActor @Sendable () -> Void
    ) {
        guard generation == self.generation, !isClosed else { return }
        pendingTask = nil
        guard permitted else { return }
        isPerformingAuthorizedClose = true
        defer { isPerformingAuthorizedClose = false }
        performClose()
    }
}
