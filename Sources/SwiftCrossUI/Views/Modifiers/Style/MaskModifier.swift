/// Draws its content through the opacity of a mask; see
/// ``View/mask(alignment:_:)``.
struct MaskModifier<Content: View, Mask: View>: TypeSafeView {
    typealias Children = TupleView2<Content, Mask>.Children

    var body: TupleView2<Content, Mask>
    var alignment: Alignment

    init(content: Content, mask: Mask, alignment: Alignment) {
        body = TupleView2(content, mask)
        self.alignment = alignment
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: Children
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        let content: Backend.Widget = children.child0.widget.into()
        if let maskBackend = backend as? any BackendFeatures.Masks {
            return Self.maskContainer(content: content, mask: children.child1.widget.into(), backend: maskBackend)
                as! Backend.Widget
        }
        // Without masks the content draws on its own and the mask has no
        // widget on screen.
        let container = backend.createContainer()
        backend.insert(content, into: container, at: 0)
        return container
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        let contentResult = children.child0.computeLayout(
            with: body.view0,
            proposedSize: proposedSize,
            environment: environment
        )
        // Laid out so that it's ready to commit, but the mask never changes
        // the view's size and its preferences don't reach the view's
        // ancestors.
        _ = children.child1.computeLayout(
            with: body.view1,
            proposedSize: ProposedViewSize(contentResult.size),
            environment: environment
        )
        return ViewLayoutResult(size: contentResult.size, childResults: [contentResult])
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = layout.size.vector
        _ = children.child0.commit()
        let maskSize = children.child1.commit().size.vector
        let maskOrigin = alignment.position(ofChild: maskSize, in: size)

        if let maskBackend = backend as? any BackendFeatures.Masks {
            Self.update(widget, size: size, maskOrigin: maskOrigin, maskSize: maskSize, backend: maskBackend)
        } else {
            backend.setPosition(ofChildAt: 0, in: widget, to: .zero)
            backend.setSize(of: widget, to: size)
        }
    }

    private static func maskContainer<MaskBackend: BackendFeatures.Masks>(
        content: Any,
        mask: Any,
        backend: MaskBackend
    ) -> MaskBackend.Widget {
        backend.createMaskContainer(
            content: content as! MaskBackend.Widget,
            mask: mask as! MaskBackend.Widget
        )
    }

    private static func update<MaskBackend: BackendFeatures.Masks>(
        _ container: Any,
        size: SIMD2<Int>,
        maskOrigin: SIMD2<Int>,
        maskSize: SIMD2<Int>,
        backend: MaskBackend
    ) {
        backend.updateMaskContainer(
            container as! MaskBackend.Widget,
            size: size,
            maskOrigin: maskOrigin,
            maskSize: maskSize
        )
    }
}
