extension View {
    /// Clips drawing to this view's rectangular bounds without changing layout.
    ///
    /// Uses the same backend capability as `cornerRadius(_:)`, with a zero
    /// radius. AppKit and WinUI clip overflowing descendants, including when
    /// a bound becomes zero. Backends without CornerRadius support retain the
    /// content and layout without clipping, as they do for cornerRadius.
    public func clipped() -> some View {
        CornerRadiusModifier(content: self, cornerRadius: 0)
    }

    public func cornerRadius(_ radius: Int) -> some View {
        CornerRadiusModifier(content: self, cornerRadius: radius)
    }
}

struct CornerRadiusModifier<Content: View>: View, TypeSafeView {
    var content: Content
    var cornerRadius: Int

    var body: TupleView1<Content> { content }

    typealias Children = TupleView1<Content>.Children

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    @CastBackend<BackendFeatures.CornerRadius>(returnsWidget: true)
    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        backend.createCornerRadiusContainer(wrapping: body.asWidget(children, backend: backend))
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: Children
    ) -> [LayoutSystem.LayoutableChild] {
        body.layoutableChildren(backend: backend, children: children)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        body.computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
    }

    @CastBackend<BackendFeatures.CornerRadius>
    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = children.child0.commit().size
        backend.setSize(of: widget, to: size.vector)
        backend.setCornerRadius(of: widget, to: cornerRadius)
    }
}
