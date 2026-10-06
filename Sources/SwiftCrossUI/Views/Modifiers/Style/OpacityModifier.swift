extension View {
    /// Sets the transparency of this view.
    ///
    /// The view keeps its layout at every opacity, as in SwiftUI, so fading a
    /// view out with `.opacity(0)` leaves its space in place.
    ///
    /// - Note: Drawn by backends that implement ``BackendFeatures/Opacity``
    ///   (AppKit and WinUI among them). Elsewhere the content stays opaque.
    ///
    /// - Parameter opacity: The opacity, from 0 (invisible) to 1 (opaque).
    ///   Values outside that range are clamped.
    /// - Returns: The view at the given opacity.
    public func opacity(_ opacity: Double) -> some View {
        OpacityModifier(content: self, opacity: min(max(opacity, 0), 1))
    }
}

struct OpacityModifier<Content: View>: View, TypeSafeView {
    var content: Content
    var opacity: Double

    var body: TupleView1<Content> { content }

    typealias Children = TupleView1<Content>.Children

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        // `TupleView1` wraps the child in a container of its own, so the
        // opacity below never touches a widget the child manages.
        body.asWidget(children, backend: backend)
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

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        body.commit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )
        if let opacityBackend = backend as? any BackendFeatures.Opacity {
            setOpacity(of: widget, with: opacityBackend)
        }
    }

    private func setOpacity<OpacityBackend: BackendFeatures.Opacity>(
        of widget: some Any,
        with backend: OpacityBackend
    ) {
        backend.setOpacity(of: widget as! OpacityBackend.Widget, to: opacity)
    }
}
