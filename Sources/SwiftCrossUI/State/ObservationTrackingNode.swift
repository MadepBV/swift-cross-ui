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
}
