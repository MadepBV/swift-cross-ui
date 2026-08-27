/// A view graph node that observed property reads can be attributed to.
///
/// Implemented by ``ViewGraphNode``. It exists so that
/// ``ViewObservationTracking`` can hold on to 'the node currently being
/// evaluated' without knowing the node's view or backend types, and without
/// forcing every node to allocate an ``ObservationRegistration`` up front ---
/// the registration is only created for nodes that actually evaluate something
/// under observation tracking.
@MainActor
protocol ObservationTrackingNode: AnyObject {
    /// The node's observation registration, created on first access.
    ///
    /// Accessing this arms the node for `Observation`-driven invalidation, so
    /// only touch it when tracking is about to be installed.
    var observationRegistration: ObservationRegistration { get }

    /// The view's body for the current update pass, evaluating it with
    /// `evaluate` if it hasn't been evaluated yet.
    ///
    /// A view's body doesn't depend on the size it is proposed, but the layout
    /// system asks a view to lay itself out several times per pass — at its
    /// minimum, at its maximum and at the size its container settles on — and
    /// then commits it. Evaluating the body once and reusing it for the rest of
    /// the pass is what stops user code from running four times to produce the
    /// same answer.
    ///
    /// - Parameter evaluate: Evaluates the body. Called at most once per pass.
    /// - Returns: The view's body.
    func body<Content>(evaluatedBy evaluate: () -> Content) -> Content
}
