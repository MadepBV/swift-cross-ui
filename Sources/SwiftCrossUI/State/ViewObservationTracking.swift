/// Makes the view graph participate in the `Observation` system, so that
/// reading a property of an `@Observable` object from a view's body causes that
/// view to be re-rendered when the property changes.
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
/// Tracking is installed through ``ObservationSupport``, which decides between
/// `ObservationPolyfillCore` and the standard library's `Observation`; see
/// there for what each one covers.
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
        guard let node = currentNode else {
            return work()
        }

        let registration = node.observationRegistration
        let generation = registration.beginGeneration()
        return ObservationSupport.withTracking(work) {
            registration.reportChange(generation: generation)
        }
    }

    /// Evaluates a view's body while recording the `@Observable` properties it
    /// reads.
    ///
    /// The body is evaluated once per update pass and reused for the rest of
    /// it; see ``ObservationTrackingNode/body(evaluatedBy:)``. Reuse doesn't
    /// lose tracking: an observation closure fires at most once and stays armed
    /// until it does, and the node clears the cached body wherever it clears
    /// its layout cache, so the next pass re-evaluates and re-registers.
    ///
    /// - Parameter view: The view whose body should be evaluated.
    /// - Returns: The view's body.
    static func trackedBody<V: View>(of view: V) -> V.Content {
        guard let node = currentNode else {
            return tracking { view.body }
        }
        return node.body(evaluatedBy: { tracking { view.body } })
    }

    /// A view's body, reusing the one evaluated during this pass's layout if
    /// there is one.
    ///
    /// Used by ``View/defaultCommit(_:children:layout:environment:backend:)``,
    /// which needs a body only to reach its children's nodes — a layoutable
    /// child's commit closure never reads the view value — so re-running user
    /// code there produced nothing but the value that was already to hand.
    ///
    /// - Parameter view: The view whose body is wanted.
    /// - Returns: The view's body.
    static func body<V: View>(of view: V) -> V.Content {
        guard let node = currentNode else {
            return view.body
        }
        return node.body(evaluatedBy: { view.body })
    }
}
