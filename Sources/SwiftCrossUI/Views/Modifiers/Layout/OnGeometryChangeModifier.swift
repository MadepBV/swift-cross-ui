import Foundation

extension View {
    /// Adds an action to be performed when a value, created from a geometry
    /// proxy, changes.
    ///
    /// The proxy describes the view's committed size, so the action runs
    /// once the view's layout has been committed: first with the initial
    /// value, then whenever the transformed value changes.
    ///
    /// - Parameters:
    ///   - type: The type of value the transform produces.
    ///   - transform: Produces a value from the view's geometry.
    ///   - action: The action to perform, given the new value.
    /// - Returns: A view that watches its geometry.
    public func onGeometryChange<T: Equatable>(
        for type: T.Type,
        of transform: @escaping (GeometryProxy) -> T,
        action: @escaping (_ newValue: T) -> Void
    ) -> some View {
        OnGeometryChangeModifier(
            body: TupleView1(self),
            transform: transform,
            action: { _, newValue in action(newValue) }
        )
    }

    /// Adds an action to be performed when a value, created from a geometry
    /// proxy, changes, handing the action the old and new values.
    ///
    /// On the initial run both values are the initial value.
    ///
    /// - Parameters:
    ///   - type: The type of value the transform produces.
    ///   - transform: Produces a value from the view's geometry.
    ///   - action: The action to perform, given the old and new values.
    /// - Returns: A view that watches its geometry.
    public func onGeometryChange<T: Equatable>(
        for type: T.Type,
        of transform: @escaping (GeometryProxy) -> T,
        action: @escaping (_ oldValue: T, _ newValue: T) -> Void
    ) -> some View {
        OnGeometryChangeModifier(body: TupleView1(self), transform: transform, action: action)
    }

    /// Assigns a name to the view's coordinate space, so other code can
    /// operate on dimensions like points and sizes relative to the named
    /// space.
    ///
    /// The space's origin is this view's top-leading corner. Frames in it are
    /// resolved for ``View/onGeometryChange(for:of:action:)-(_,_,(T)->Void)``
    /// on backends that can locate widgets (``BackendFeatures/WidgetGeometry``);
    /// see ``GeometryProxy/frame(in:)``.
    ///
    /// - Parameter name: The name of the coordinate space.
    /// - Returns: A view that names its coordinate space.
    public func coordinateSpace<Name: Hashable>(name: Name) -> some View {
        CoordinateSpaceModifier(body: TupleView1(self), space: .named(AnyHashable(name)))
    }
}

/// Runs an action when a value computed from its content's committed
/// geometry changes.
struct OnGeometryChangeModifier<Value: Equatable, Child: View>: View {
    /// Reference storage for the last value seen, which must not schedule
    /// an update of its own when recorded (see `OnChangeModifier`).
    struct PreviousValue {
        var box = Box<Value?>(nil)
    }

    @State private var previousValue = PreviousValue()

    var body: TupleView1<Child>
    var transform: (GeometryProxy) -> Value
    var action: (Value, Value) -> Void

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        defaultCommit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )

        let size = CGSize(width: layout.size.width, height: layout.size.height)
        var proxy = GeometryProxy(size: size)
        let unresolved = Box(false)
        proxy.unresolvedFrameRequest = unresolved
        let value = transform(proxy)
        guard unresolved.value else {
            deliver(value)
            return
        }

        // The transform asked where the view is, which isn't known until the
        // parents committing around this view have positioned it. Ask again
        // once the whole commit has finished.
        let anchoredEnvironment = environment
        let transform = transform
        DeferredGeometryObservations.schedule(on: backend) { [widget] in
            var proxy = GeometryProxy(size: size)
            // The proxy only lives for this call, on the main thread.
            proxy.resolveFrame = { space in
                MainActor.assumeIsolated {
                    anchoredEnvironment.frame(of: widget, in: space, backend: backend)
                }
            }
            self.deliver(transform(proxy))
        }
    }

    /// Runs the action if `value` differs from the last value seen.
    private func deliver(_ value: Value) {
        let box = previousValue.box
        let previous = box.value
        guard previous != value else {
            return
        }
        box.value = value
        action(previous ?? value, value)
    }
}

/// Names a view's coordinate space; see ``View/coordinateSpace(name:)``.
struct CoordinateSpaceModifier<Child: View>: View {
    /// Keeps one anchor for the life of the view, without its writes
    /// scheduling updates.
    struct Anchor {
        var anchor = CoordinateSpaceAnchor()
    }

    @State private var anchor = Anchor()

    var body: TupleView1<Child>
    var space: CoordinateSpace

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        body.children(
            backend: backend,
            snapshots: snapshots,
            environment: environment.addingCoordinateSpace(space, anchoredAt: anchor.anchor)
        )
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        body.computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment.addingCoordinateSpace(space, anchoredAt: anchor.anchor),
            backend: backend
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        anchor.anchor.widget = AnyWidget(widget)
        body.commit(
            widget,
            children: children,
            layout: layout,
            environment: environment.addingCoordinateSpace(space, anchoredAt: anchor.anchor),
            backend: backend
        )
    }
}

/// Geometry observations waiting for a commit to finish positioning widgets.
///
/// A view commits before its parent positions it, so a frame in an
/// ancestor's coordinate space can only be read once the outermost commit
/// returns. The observations run together on the backend's main thread right
/// after it.
@MainActor
enum DeferredGeometryObservations {
    private static var pending: [@MainActor () -> Void] = []
    private static var isScheduled = false

    /// Runs `observation` after the current commit.
    static func schedule<Backend: BaseAppBackend>(
        on backend: Backend,
        _ observation: @escaping @MainActor () -> Void
    ) {
        pending.append(observation)
        guard !isScheduled else {
            return
        }
        isScheduled = true
        backend.runInMainThread {
            runPending()
        }
    }

    /// Runs every waiting observation. Tests call it directly.
    static func runPending() {
        isScheduled = false
        let observations = pending
        pending = []
        for observation in observations {
            observation()
        }
    }
}
