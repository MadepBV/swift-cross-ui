#if canImport(Observation)
    import Observation
#endif

/// Makes the view graph participate in the standard library's `Observation`
/// system, so that reading a property of an `@Observable` object from a view's
/// body causes that view to be re-rendered when the property changes.
///
/// ## How tracking is scoped
///
/// Tracking is installed *per view graph node*, never globally, so a mutation
/// only invalidates the nodes that actually read the mutated property. That
/// requires care, because `withObservationTracking(_:onChange:)` merges nested
/// tracking scopes into their enclosing scope: if a node tracked everything
/// that happened while its subtree was being laid out, then every ancestor of
/// a changed leaf would be invalidated too, and one mutation would re-render
/// the whole app.
///
/// Scopes are therefore kept disjoint:
///
/// - **Composite views** (anything with a real `body`) are tracked around the
///   `body` evaluation itself, in `View.defaultComputeLayout`. The body has
///   fully evaluated by the time the layout system recurses into the node's
///   children, so a child's reads are never captured by its parent.
/// - **Leaf views** (views that can't have child nodes, such as ``Text``,
///   ``TextField`` and ``Slider``) are tracked around their whole layout
///   computation and commit, since that's where they read the bindings they
///   were handed. They have no children to recurse into, so they can't nest
///   either.
///
/// ## Availability
///
/// `Observation` ships with the Swift toolchain rather than the platform SDKs,
/// so it's available on Linux and Windows as well as the Apple platforms.
/// Its declarations are annotated as macOS 14 / iOS 17 / tvOS 17 / watchOS 10,
/// however, and SwiftCrossUI supports deployment targets older than that. All
/// use of `Observation` is consequently behind a runtime availability check;
/// on older Apple platforms views simply fall back to the ``ObservableObject``
/// and ``State`` invalidation paths, which are unaffected by any of this.
@MainActor
enum ViewObservationTracking {
    /// The node that observed property reads are currently attributed to.
    private static var currentNode: (any ObservationTrackingNode)?

    /// Runs `work` with `node` installed as the node that observed property
    /// reads get attributed to.
    ///
    /// The previous node is restored afterwards, so nodes can nest freely.
    ///
    /// - Parameters:
    ///   - node: The node being evaluated.
    ///   - work: The work to perform.
    /// - Returns: The result of `work`.
    static func withNode<Result>(
        _ node: any ObservationTrackingNode,
        perform work: () -> Result
    ) -> Result {
        let previousNode = currentNode
        currentNode = node
        defer { currentNode = previousNode }
        return work()
    }

    /// Runs `work` while recording every `@Observable` property it reads,
    /// arranging for the current node to be re-rendered when one of them
    /// changes.
    ///
    /// A no-op (beyond running `work`) when there's no current node, or when
    /// the platform doesn't support `Observation`.
    ///
    /// - Parameter work: The work to perform under observation tracking.
    /// - Returns: The result of `work`.
    static func tracking<Result>(_ work: () -> Result) -> Result {
        #if canImport(Observation)
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *),
                let node = currentNode
            else {
                return work()
            }

            let registration = node.observationRegistration
            let generation = registration.beginGeneration()
            return withObservationTracking(
                work,
                onChange: { registration.reportChange(generation: generation) }
            )
        #else
            return work()
        #endif
    }

    /// Evaluates a view's body while recording the `@Observable` properties it
    /// reads.
    ///
    /// - Parameter view: The view whose body should be evaluated.
    /// - Returns: The view's body.
    static func trackedBody<V: View>(of view: V) -> V.Content {
        tracking { view.body }
    }
}
