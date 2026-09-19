extension View {
    /// Controls whether this view and its descendants participate in pointer hit testing.
    /// A `false` ancestor excludes the whole subtree even if a descendant uses `true`.
    /// Layout, appearance, enabled state and keyboard focus are unchanged.
    /// Backends without `BackendFeatures.HitTesting` retain their existing behavior.
    public func allowsHitTesting(_ allowsHitTesting: Bool) -> some View {
        HitTestingModifier(body: TupleView1(self), allowsHitTesting: allowsHitTesting)
    }
}

struct HitTestingModifier<Content: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children
    var body: TupleView1<Content>
    var allowsHitTesting: Bool

    func children<Backend: BaseAppBackend>(
        backend: Backend, snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children, backend: Backend
    ) -> Backend.Widget {
        guard let hitBackend = backend as? any BaseAppBackend & BackendFeatures.HitTesting else {
            return children.child0.widget.into()
        }
        return createContainer(children, backend: hitBackend) as! Backend.Widget
    }

    private func createContainer<Backend>(
        _ children: Children, backend: Backend
    ) -> Backend.Widget where Backend: BaseAppBackend & BackendFeatures.HitTesting {
        let container = backend.createHitTestingContainer(wrapping: children.child0.widget.into())
        backend.setAllowsHitTesting(allowsHitTesting, of: container)
        return container
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget, children: Children, proposedSize: ProposedViewSize,
        environment: EnvironmentValues, backend: Backend
    ) -> ViewLayoutResult {
        children.child0.computeLayout(
            with: body.view0, proposedSize: proposedSize, environment: environment)
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget, children: Children, layout: ViewLayoutResult,
        environment: EnvironmentValues, backend: Backend
    ) {
        if let hitBackend = backend as? any BaseAppBackend & BackendFeatures.HitTesting {
            updateContainer(widget, backend: hitBackend)
        }
        let size = children.child0.commit().size.vector
        backend.setSize(of: widget, to: size)
    }

    private func updateContainer<Backend>(
        _ widget: Any, backend: Backend
    ) where Backend: BaseAppBackend & BackendFeatures.HitTesting {
        backend.setAllowsHitTesting(allowsHitTesting, of: widget as! Backend.Widget)
    }
}
