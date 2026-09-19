import Foundation

/// A view graph node storing a view, its widget, and its children (likely a
/// collection of more nodes).
///
/// This is where updates are initiated when a view's state updates, and where state is persisted
/// even when a view gets recomputed by its parent.
///
/// ## On skipping unchanged subtrees
///
/// Every pass re-walks the whole graph. A short-circuit — a node returning its
/// committed layout without descending, once it can show that its view value,
/// its environment and its own state have all held still — was built and
/// withdrawn, and the reason is worth recording so it isn't rediscovered the
/// hard way.
///
/// It worked, and on a window resize it cut a pass from 11,353 node visits to
/// 1,519 and from 21 ms to 0.18 ms. It was withdrawn because of *when* a node
/// learns it is out of date. A `@State` mutation reaches its node through
/// ``Publisher/observeAsUIUpdater(backend:action:)``, which schedules the
/// update rather than running it, so a node is marked out of date when that
/// scheduled update *runs*, not when the state changes. A pass landing in
/// between would short-circuit straight past the node that changed and commit
/// stale content. Today that is invisible, because every pass re-walks and
/// re-reads the state regardless.
///
/// Making this safe needs the out-of-date mark to be set synchronously with the
/// mutation. There is a hook for that — ``Publisher/send()`` publishes on the
/// mutating thread, and ``Publisher/observe(with:)`` takes a synchronous
/// closure, so a node could mark itself out of date beside the scheduled update
/// rather than inside it. The scheduling in
/// ``Publisher/observeAsUIUpdater(backend:action:)`` exists to coalesce and
/// throttle the *re-render*, not to defer the bookkeeping.
///
/// What blocks it is isolation. Marking `send()` `@MainActor` so the mark is
/// provably safe cascades: `send()` forces `StateImpl.postSet()`, which forces
/// `StateImpl.wrappedValue`'s setter and `projectedValue`, which forces
/// `@State`, `@AppStorage`, `@FocusState` and `@Published`'s `wrappedValue` and
/// `projectedValue` — i.e. the framework's whole public state layer becomes
/// main-actor-only, and that propagates into app code. Measured by annotating
/// and rebuilding, three rounds deep, each round pushing the annotation one
/// level further out. It is not a narrow fix.
///
/// (An earlier note here claimed this was a single error in
/// ``Publisher/link(toUpstream:)``. That was wrong: the build fast-failed in
/// `Publisher.swift` before type-checking the senders. The real senders are
/// `StateImpl.postSet()`, `Published.valueDidChange(publish:)` and
/// `FocusedValue`, and they cascade as above.)
///
/// ``EnvironmentValues`` mutation is likewise not main-actor-only, and is not
/// expected to become so — the `@Entry` macro emits nonisolated accessors, so
/// around thirty public properties mutate from nonisolated context
/// structurally. But a short-circuit does not need that: the environment signal
/// is established once per pass at the root, from the three events a window
/// already observes, rather than by comparing environments anywhere. Don't
/// re-derive the revision-counter dead end.
///
/// ## The other constraint, which is about cost rather than correctness
///
/// The win comes from short-circuiting *probing* visits high in the tree, where
/// skipping one node prunes everything beneath it. Serving those across passes
/// means keeping a layout per probed proposal, and a ``ViewLayoutResult`` drags
/// a ``PreferenceValues`` along with it — closures and arrays, so retaining
/// several per node costs real reference counting. Measured, on
/// `window/resize`: an eight-entry cache short-circuited 915 of 11,353 visits
/// and took the pass from 21 ms to 0.18 ms, but cost ~20% on every scenario
/// where it never fired (cad/idle 20.7→24.9, list/idle 24.3→27.3,
/// window/update 20.7→24.7); keeping only the committed layout removed that
/// regression and dropped the win to 120 short-circuits. A future attempt has
/// to hold probe results as something cheaper than a full layout result — the
/// probing path reads only size, stack participation and layout priority off
/// them.
///
/// The behaviour any future attempt has to preserve is pinned by
/// `ShortCircuitTests`, whose deep-state-change case is exactly the one that
/// caught this.
@MainActor
public class ViewGraphNode<NodeView: View, Backend: BaseAppBackend>: Sendable {
    /// The view's single widget for the entirety of its lifetime in the view graph.
    ///
    public var widget: Backend.Widget {
        _widget!
    }
    /// Only optional because of some initialisation order requirements. Private and wrapped to
    /// hide this inconvenient detail.
    private var _widget: Backend.Widget?
    /// The view's children (usually just contains more view graph nodes, but can handle extra logic
    /// such as figuring out how to update variable length array of children efficiently).
    ///
    /// It's type-erased because otherwise complex implementation details would
    /// be forced to the user or other compromises would have to be made. I
    /// believe that this is the best option with Swift's current generics landscape.
    public var children: any ViewGraphNodeChildren {
        get {
            _children!
        }
        set {
            _children = newValue
        }
    }
    /// Only optional because of some initialisation order requirements. Private and wrapped to
    /// hide this inconvenient detail.
    private var _children: (any ViewGraphNodeChildren)?
    /// A copy of the view itself (from the latest computed body of its parent).
    public var view: NodeView
    /// The backend used to create the view's widget.
    public var backend: Backend

    /// The view's most recently computed layout. Doesn't include cached layouts,
    /// as this is the layout that is currently 'ready to commit'.
    public var currentLayout: ViewLayoutResult?
    /// A cache of update results keyed by the proposed size they were for. Gets
    /// cleared before the results' sizes become invalid.
    ///
    /// A node only ever sees a handful of distinct proposals within one pass (a
    /// stack probes its children's minimum and maximum sizes before proposing a
    /// final one), so this is a linear scan over a tiny array rather than a
    /// dictionary: hashing a proposal costs more than comparing three of them,
    /// and the array keeps its storage across passes instead of allocating a
    /// fresh dictionary on every commit.
    private var resultCache: [(proposal: ProposedViewSize, result: ViewLayoutResult)]
    /// The most recent size proposed by the parent view. Used when updating the wrapped
    /// view as a result of a state change rather than the parent view updating. Proposals
    /// that get cached responses don't update this size, as this size should stay in sync
    /// with currentLayout.
    private(set) var lastProposedSize: ProposedViewSize
    /// Whether the widget has had its first update yet.
    private var hasHadFirstUpdate = false

    /// A cancellable handle to the view's state property observations.
    private var cancellables: [Cancellable]

    /// The environment most recently provided by this node's parent.
    private var parentEnvironment: EnvironmentValues

    /// The dynamic property updater for this view.
    private var dynamicPropertyUpdater: DynamicPropertyUpdater<NodeView>

    /// Whether the view can never have child view graph nodes. Set once,
    /// during initialisation.
    ///
    /// Leaf views can't recurse into other nodes while computing their layout,
    /// which makes it safe to install observation tracking around their whole
    /// layout computation without accidentally capturing a descendant's
    /// property reads. See ``ViewObservationTracking`` for why that matters.
    private var isLeaf = false

    /// The body evaluated for this update pass, if one has been.
    ///
    /// Type-erased because the node can only hand it back through
    /// ``ObservationTrackingNode/body(evaluatedBy:)``, whose `Content` is a
    /// fresh generic parameter. In practice it is always `NodeView.Content`.
    private var cachedBody: Any?

    /// The pass ``cachedBody`` was evaluated during, so that a body is never
    /// reused across passes: a new pass may be running under a different
    /// environment, or after a state change.
    /// The pass during which the parent last handed this node a view value,
    /// so that only the first hand-over of a pass is treated as significant.
    private var lastHandOverPass: UInt64?

    /// Whether the parent has already handed this node a view value during the
    /// current update pass.
    ///
    /// A container rebuilds its layoutable children for each of its own layout
    /// computations, and each of those hands the child node the value it
    /// captured. Within one pass that is the same value every time, because
    /// the parent's body is evaluated once per pass and the captured values
    /// come from it, so only the first hand-over can actually have changed
    /// anything.
    ///
    /// The exception is a caller that genuinely produces a different view per
    /// layout computation — a ``GeometryReader``, whose content depends on the
    /// size it is proposed. Those call ``invalidateCachedSubtree()`` to say so.
    private var hasReceivedViewThisPass = false

    /// Bridges `Observation` change notifications to this node's updates.
    ///
    /// Created on demand by ``observationRegistration`` so that nodes which
    /// never evaluate anything under observation tracking (SwiftCrossUI's own
    /// container and modifier views, whose bodies are never user code) don't
    /// pay for it.
    private var _observationRegistration: ObservationRegistration?

    /// Creates a node for a given view while also creating the nodes for its children, creating
    /// the view's widget, and starting to observe its state for changes.
    public init(
        for nodeView: NodeView,
        backend: Backend,
        snapshot: ViewGraphSnapshotter.NodeSnapshot? = nil,
        environment: EnvironmentValues
    ) {
        self.backend = backend

        // Restore node snapshot if present.
        self.view = nodeView
        snapshot?.restore(to: view)

        // First create the view's child nodes and widgets
        let childSnapshots = snapshot.map { snapshot in
            snapshot.isValid(for: NodeView.self) ? snapshot.children : [snapshot]
        }

        currentLayout = nil
        resultCache = []
        lastProposedSize = .zero
        parentEnvironment = environment
        cancellables = []

        dynamicPropertyUpdater = DynamicPropertyUpdater(for: nodeView)

        let viewEnvironment = updateEnvironment(environment)

        dynamicPropertyUpdater.update(view, with: viewEnvironment, previousValue: nil)

        let children = view.children(
            backend: backend,
            snapshots: childSnapshots,
            environment: viewEnvironment
        )
        self.children = children
        self.isLeaf = Self.cannotHaveChildNodes(children)

        // Then create the widget for the view itself
        let widget = view.asWidget(
            children,
            backend: backend
        )
        _widget = widget

        let tag = String(String(describing: NodeView.self).split(separator: "<")[0])
        backend.tag(widget: widget, as: tag)

        // Update the view and its children when state changes (children are always updated first).
        forEachField(of: view) { name, _, fieldValue in
            #if DEBUG
                if name == "state", fieldValue is ObservableObject {
                    logger.warning(
                        """
                        the View.state protocol requirement has been removed in favour of \
                        SwiftUI-style @State annotations; decorate \(NodeView.self).state \
                        with the @State property wrapper to restore previous behaviour
                        """
                    )
                }
            #endif

            guard let value = fieldValue as? any ObservableProperty else {
                return // i.e. continue
            }

            let cancellable = value.didChange.observeAsUIUpdater(backend: backend) { [weak self] in
                self?.bottomUpUpdate()
            }
            cancellables.append(cancellable)
        }
    }

    /// Children collection types that can never contain child view graph
    /// nodes.
    ///
    /// ``EmptyViewChildren`` covers every ``ElementaryView`` (``Text``,
    /// ``TextField``, ``Slider`` and friends). The rest are persistent storage
    /// for views that render themselves directly through the backend rather
    /// than through child nodes.
    ///
    /// The list is deliberately conservative: a type that isn't listed just
    /// misses out on leaf-level observation tracking, which is never worse
    /// than the behaviour before observation existed.
    ///
    /// - Parameter children: The node's children.
    /// - Returns: Whether `children` can never contain child nodes.
    private static func cannotHaveChildNodes(
        _ children: any ViewGraphNodeChildren
    ) -> Bool {
        children is EmptyViewChildren
            || children is ShapeStorage
            || children is CanvasStorage
            || children is ImageChildren
            || children is MenuStorage
            || children is BuiltinPickerChildren
    }

    /// Recomputes the view after an `@Observable` property that it read
    /// changed.
    ///
    /// Runs on the main thread, after the mutation has completed, and never
    /// inside an update pass; see ``ObservationRegistration``.
    private func observationDidChange() {
        _observationRegistration?.updateWillRun()

        // Observation tracking closures fire at most once and are re-installed
        // by the next body evaluation, so an update that gets satisfied by the
        // layout cache would leave this node permanently unobserved. Clearing
        // the cache guarantees that the body runs again and re-registers.
        invalidateResultCache()

        bottomUpUpdate()
    }

    /// Triggers the view to be updated as part of a bottom-up chain of updates (where either the
    /// current view gets updated due to a state change and has potential to trigger its parent to
    /// update as well, or the current view's child has propagated such an update upwards).
    private func bottomUpUpdate() {
        // Whatever prompted this changed something a body may have read, and it
        // is an entry into the graph from outside, so it starts a new pass.
        LayoutPass.begin()


        // First we compute what size the view will be after the update. If it will change size,
        // propagate the update to this node's parent instead of updating straight away.
        let currentSize = currentLayout?.size
        let newLayout = self.computeLayout(
            proposedSize: lastProposedSize,
            environment: parentEnvironment
        )

        self.currentLayout = newLayout
        if newLayout.size != currentSize {
            cacheResult(newLayout, for: lastProposedSize)
            parentEnvironment.onResize(newLayout.size)
        } else {
            _ = self.commit()
        }
    }

    /// This node's resize handler, created once.
    ///
    /// It only captures `self` weakly, so it never changes; allocating a fresh
    /// closure on every layout computation of every node was pure overhead.
    private lazy var onResizeHandler: @MainActor (ViewSize) -> Void = { [weak self] _ in
        guard let self else { return }
        self.bottomUpUpdate()
    }

    private func updateEnvironment(_ environment: EnvironmentValues) -> EnvironmentValues {
        environment.with(\.onResize, onResizeHandler)
    }

    /// Recomputes the view's body and computes its layout and the layout of
    /// its children.
    ///
    /// The view may or may not propagate the update to its children depending
    /// on the nature of the update. If `newView` is provided (in the case that
    /// the parent's body got updated) then it simply replaces the old view
    /// while inheriting the old view's state.
    ///
    /// - Parameters:
    ///   - newView: The recomputed view.
    ///   - proposedSize: The view's proposed size.
    ///   - environment: The current environment.
    /// - Returns: The result of laying out the view.
    public func computeLayout(
        with newView: NodeView? = nil,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues
    ) -> ViewLayoutResult {
        // Defensively ensure that all future scene implementations obey this
        // precondition. By putting the check here instead of only in views
        // that require `environment.window` (such as the alert modifier view),
        // we decrease the likelihood of a bug like this flying under the radar.
        precondition(
            environment.window != nil,
            "View graph updated without parent window present in environment"
        )

        if !hasHadFirstUpdate {
            // We show the widget here instead of in init, because in init the widget
            // hasn't been added to its parent widget yet.
            backend.show(widget: widget)
            hasHadFirstUpdate = true
        }

        BackendCallStatistics.record("viewgraph.computeLayout")



        if proposedSize == lastProposedSize && !resultCache.isEmpty
            && (!parentEnvironment.allowLayoutCaching || environment.allowLayoutCaching),
            let currentLayout
        {
            // If the previous proposal is the same as the current one, and we
            // computed it during this pass, then we can reuse the current
            // layout. But only if the previous layout was computed without
            // caching, or the current layout is being computed with caching,
            // cause otherwise we could end up using a layout computed with
            // caching while computing a layout without caching.
            BackendCallStatistics.record("viewgraph.computeLayout.reusedCurrent")
            return currentLayout
        } else if environment.allowLayoutCaching,
            let cachedResult = cachedResult(for: proposedSize)
        {
            // If this layout pass is a probing pass (not a final pass), then we
            // can reuse any layouts we've computed during it. Restricted to
            // this pass because the cache now outlives the pass that filled it;
            // reuse across passes goes through the short-circuit above, which
            // has proven the inputs are unchanged.
            BackendCallStatistics.record("viewgraph.computeLayout.cacheHit")
            return cachedResult
        }

        BackendCallStatistics.record("viewgraph.computeLayout.recomputed")

        parentEnvironment = environment
        lastProposedSize = proposedSize

        let previousView: NodeView?
        if let newView {
            previousView = view
            view = newView
            // Only the first hand-over of a pass can have changed anything;
            // see `hasReceivedViewThisPass`.
            if !hasReceivedViewThisPass || lastHandOverPass != LayoutPass.token {
                hasReceivedViewThisPass = true
                lastHandOverPass = LayoutPass.token
                cachedBody = nil
            }
        } else {
            previousView = nil
        }

        let viewEnvironment = updateEnvironment(environment)

        dynamicPropertyUpdater.update(view, with: viewEnvironment, previousValue: previousView)

        let result = ViewObservationTracking.withNode(self) {
            // A leaf view has no children to recurse into, so tracking its
            // whole layout computation can't swallow a descendant's property
            // reads. Composite views instead get tracked around their body
            // evaluation alone (see `View.defaultComputeLayout`).
            // Everything below is reached from here, so this is where we tell
            // our children what we know. Their values come out of our body, and
            // their environment is ours plus whatever that body applied, so
            // both are unchanged exactly when we hand down the same values —
            // and the environment additionally needs ours to have held still.
            let computeLayout = {
                self.view.computeLayout(
                    self.widget,
                    children: self.children,
                    proposedSize: proposedSize,
                    environment: viewEnvironment,
                    backend: self.backend
                )
            }
            return isLeaf
                ? ViewObservationTracking.tracking(computeLayout)
                : computeLayout()
        }

        // We assume that the view's sizing behaviour won't change between consecutive
        // layout computations and the following commit, because groups of updates
        // following that pattern are assumed to be occurring within a single overarching
        // view update. Under that assumption, we can cache view layout results.
        cacheResult(result, for: proposedSize)

        currentLayout = result
        return result
    }

    /// The cached layout for a proposal, if one was computed since the cache was
    /// last invalidated.
    ///
    /// - Parameter proposal: The proposal to look up.
    /// - Returns: The cached layout, or `nil` if there isn't one.
    private func cachedResult(for proposal: ProposedViewSize) -> ViewLayoutResult? {
        for entry in resultCache where entry.proposal == proposal {
            return entry.result
        }
        return nil
    }

    /// Caches a layout against the proposal it was computed for.
    ///
    /// - Parameters:
    ///   - result: The layout to cache.
    ///   - proposal: The proposal it was computed for.
    private func cacheResult(_ result: ViewLayoutResult, for proposal: ProposedViewSize) {
        for index in resultCache.indices where resultCache[index].proposal == proposal {
            resultCache[index].result = result
            return
        }
        resultCache.append((proposal, result))
    }

    /// Empties the layout cache, keeping its storage so that the next pass
    /// doesn't have to allocate.
    ///
    /// The body evaluated for the pass goes with it: the two are valid over
    /// exactly the same window, from the first layout computation of a pass
    /// until it is committed or invalidated.
    private func invalidateResultCache() {
        resultCache.removeAll(keepingCapacity: true)
        invalidateCachedBody()
    }

    /// Discards the body evaluated for this pass, if any.
    ///
    /// For callers that hand the node a genuinely different view value part way
    /// through a pass; see ``hasReceivedViewThisPass``.
    public func invalidateCachedBody() {
        cachedBody = nil
        lastHandOverPass = nil
        hasReceivedViewThisPass = false
    }

    /// Discards bodies and layouts derived from an earlier value of this subtree.
    ///
    /// Geometry-dependent content can change more than once during a layout pass.
    /// Its descendants must receive the new values even when their proposed sizes
    /// stay the same. Clearing only this node's body leaves those descendants'
    /// bodies or layout results cached from an earlier geometry probe.
    ///
    /// Nodes, widgets, and their state are retained. Other subtrees keep their
    /// normal per-pass caches.
    func invalidateCachedSubtree() {
        invalidateResultCache()
        for child in children.erasedNodes {
            child.transform(with: CachedSubtreeInvalidator())
        }
    }

    /// Commits the view's most recently computed layout and any view state changes
    /// that have occurred since the last update (e.g. text content changes or font
    /// size changes).
    ///
    /// - Returns: The most recently computed layout. Guaranteed to match the
    ///   result of the last call to ``computeLayout(with:proposedSize:environment:)``.
    public func commit() -> ViewLayoutResult {
        guard let currentLayout else {
            logger.warning("layout committed before being computed, ignoring")
            return .leafView(size: .zero)
        }

        if parentEnvironment.allowLayoutCaching {
            logger.warning(
                "committing layout computed with caching enabled; results may be invalid",
                metadata: ["NodeView": "\(NodeView.self)"]
            )
        }
        if currentLayout.size.height == .infinity || currentLayout.size.width == .infinity {
            logger.warning(
                "infinite height or width on commit",
                metadata: [
                    "NodeView": "\(NodeView.self)",
                    "currentLayout.size": "\(currentLayout.size)",
                    "lastProposedSize": "\(lastProposedSize)",
                ]
            )
        }

        let commit = {
            self.view.commit(
                self.widget,
                children: self.children,
                layout: currentLayout,
                environment: self.parentEnvironment,
                backend: self.backend
            )
        }
        // The node is installed for both kinds of view so that a composite
        // view's `defaultCommit` can reuse the body evaluated during layout,
        // but only a leaf's commit is *tracked*: leaf views read the bindings
        // they were handed while committing (a `TextField` reads its text
        // here, for instance), whereas a composite view's tracking is
        // installed around its body evaluation during layout.
        ViewObservationTracking.withNode(self) {
            if isLeaf {
                ViewObservationTracking.tracking(commit)
            } else {
                commit()
            }
        }
        invalidateResultCache()

        backend.showUpdate(of: widget)

        return currentLayout
    }
}

extension ViewGraphNode: ObservationTrackingNode {
    /// Returns the body for this pass, evaluating it if it hasn't been.
    ///
    /// - Important: The cache is deliberately keyed on ``LayoutPass/token``, so
    ///   a body never survives the pass it was evaluated in. Widening that —
    ///   letting a body persist across passes while its node is "unchanged" —
    ///   requires proving the node's *environment* is unchanged too, because a
    ///   body reads the environment through its dynamic property wrappers
    ///   (`@Environment`, `@AppStorage`, `@FocusedValue`) and a reused body
    ///   bakes in the values it read. `View.body` takes no environment
    ///   parameter, so those wrappers are the only route.
    ///
    ///   A revision counter on ``EnvironmentValues`` would supply that proof,
    ///   but note the invariant it would rest on: **no reference-typed
    ///   environment value may be read by layout or by a body.** A revision can
    ///   only change when the struct is mutated, so anything reached through a
    ///   reference it holds — the `Box` behind
    ///   ``EnvironmentValues/openWindowFunctionsByID``, an object in
    ///   ``EnvironmentValues/subscript(observable:)``, an
    ///   `any ContainerChildLayout` — can change its contents with the revision
    ///   standing still. None of those are read by layout today. A future
    ///   environment value that is a mutable reference type and *is* read by
    ///   layout would silently freeze every view that reads it.
    func body<Content>(evaluatedBy evaluate: () -> Content) -> Content {
        if lastHandOverPass == LayoutPass.token, let cachedBody = cachedBody as? Content {
            BackendCallStatistics.record("viewgraph.body.reused")
            return cachedBody
        }
        BackendCallStatistics.record("viewgraph.body.evaluated")
        let body = evaluate()
        cachedBody = body
        lastHandOverPass = LayoutPass.token
        return body
    }

    /// The node's observation registration, created on first access.
    ///
    /// The registration schedules updates through the backend's main thread,
    /// which is always asynchronous. That's what keeps an invalidation raised
    /// part-way through a mutation (or part-way through an update pass) from
    /// running before the mutation has completed or re-entering the pass.
    var observationRegistration: ObservationRegistration {
        if let _observationRegistration {
            return _observationRegistration
        }

        let registration = ObservationRegistration { [weak self, backend] in
            backend.runInMainThread {
                self?.observationDidChange()
            }
        }
        _observationRegistration = registration
        return registration
    }
}

/// Opens erased child nodes without rebuilding them while invalidating caches.
@MainActor
private struct CachedSubtreeInvalidator: ErasedViewGraphNodeTransformer {
    func transform<V: View, Backend: BaseAppBackend>(node: ViewGraphNode<V, Backend>) {
        node.invalidateCachedSubtree()
    }
}
