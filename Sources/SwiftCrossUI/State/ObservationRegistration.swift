import Foundation

/// Bridges the standard library's `Observation` change notifications to a
/// single view graph node's update mechanism.
///
/// `withObservationTracking(_:onChange:)` has three properties that make it
/// awkward to use directly from the view graph, and this class exists to
/// smooth over all three:
///
/// - **Change handlers fire at most once.** Tracking has to be re-installed
///   every time a view's body is evaluated. The standard library gives us no
///   way to cancel a previously installed handler, so old handlers stay armed
///   over a stale set of properties. Each installation is therefore stamped
///   with a *generation*, and only the newest generation is honoured. A
///   handler from an older generation reports into the void, which is exactly
///   the behaviour we want: if the latest body evaluation stopped reading a
///   property, changes to that property must no longer invalidate the node.
/// - **Change handlers run before the mutation completes**, so the new value
///   isn't observable yet. Updates are therefore never run inline; they're
///   handed to ``ObservationRegistration/init(schedule:)``'s closure, which
///   hops them onto the backend's main thread. That also means an invalidation
///   raised in the middle of an update pass can't corrupt the pass in
///   progress.
/// - **Change handlers run on whichever thread performed the mutation**, so
///   all mutable state here is guarded by a lock.
///
/// Notifications are also coalesced: while an update is already scheduled,
/// further changes don't schedule another one.
final class ObservationRegistration: @unchecked Sendable {
    /// Asks the node to update itself on the backend's main thread.
    ///
    /// Always asynchronous, even when called from the main thread; see the
    /// type's documentation for why that matters.
    private let schedule: @Sendable () -> Void

    /// Guards ``generation`` and ``isUpdateScheduled``, both of which are
    /// touched from whichever thread mutated an observed property.
    private let lock = NSLock()

    /// The generation of the most recently installed tracking closure.
    private var generation = 0

    /// Whether an update has been scheduled but hasn't started running yet.
    private var isUpdateScheduled = false

    /// Creates a registration for a view graph node.
    ///
    /// - Parameter schedule: Asks the node to update itself on the backend's
    ///   main thread. Must not run the update synchronously.
    init(schedule: @escaping @Sendable () -> Void) {
        self.schedule = schedule
    }

    /// Retires every previously installed tracking closure and returns the
    /// generation stamp for the closure about to be installed.
    ///
    /// - Returns: The new generation.
    func beginGeneration() -> Int {
        lock.lock()
        defer { lock.unlock() }
        generation += 1
        return generation
    }

    /// Reports that a property tracked by a given generation changed.
    ///
    /// Ignored if the generation has since been superseded, or if an update is
    /// already scheduled.
    ///
    /// - Parameter generation: The generation of the tracking closure that
    ///   observed the change.
    func reportChange(generation: Int) {
        lock.lock()
        let shouldSchedule = generation == self.generation && !isUpdateScheduled
        if shouldSchedule {
            isUpdateScheduled = true
        }
        lock.unlock()

        guard shouldSchedule else { return }
        schedule()
    }

    /// Records that the scheduled update is about to start running.
    ///
    /// Called before the update rather than after it so that mutations made
    /// while the update runs schedule a follow-up update instead of being
    /// dropped.
    func updateWillRun() {
        lock.lock()
        isUpdateScheduled = false
        lock.unlock()
    }
}
