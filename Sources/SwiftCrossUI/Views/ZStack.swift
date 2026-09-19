/// A container that lays its views on top of each other.
public struct ZStack<Content: View>: View {
    /// The stack's alignment.
    public var alignment: Alignment
    /// The stack's content.
    public var body: Content

    /// Creates a ``ZStack``.
    ///
    /// - Parameters:
    ///   - alignment: The stack's alignment.
    ///   - content: The stack's content.
    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            alignment: alignment,
            content: content()
        )
    }

    init(alignment: Alignment, content: Content) {
        self.alignment = alignment
        body = content
    }

    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        let zStack = backend.createContainer()
        for (index, child) in children.widgets(for: backend).enumerated() {
            backend.insert(child, into: zStack, at: index)
        }
        return zStack
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // Resolved once: a stack asks for its layout cache on every layout
        // computation and every commit, and a dynamic cast to an existential
        // protocol is one of the more expensive things in the layout path.
        let tupleChildren = children as? TupleViewChildren
        if tupleChildren == nil, !(children is EmptyViewChildren) {
            logger.warning(
                "ZStack will not function correctly with non-TupleView content",
                metadata: [
                    "childrenType": "\(type(of: children))",
                    "contentType": "\(Content.self)",
                ]
            )
        }

        var cache = tupleChildren?.stackLayoutCache ?? StackLayoutCache.initial
        let result = LayoutSystem.computeZStackLayout(
            container: widget,
            children: layoutableChildren(backend: backend, children: children),
            cache: &cache,
            proposedSize: proposedSize,
            environment: environment
                .with(\.usesZStackLayout, true)
                .with(\.zStackContentAlignment, alignment)
                .with(\.layoutOrientation, .vertical),
            backend: backend
        )
        tupleChildren?.stackLayoutCache = cache
        return result
    }

    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        var cache = (children as? TupleViewChildren)?.stackLayoutCache ?? StackLayoutCache.initial
        LayoutSystem.commitZStackLayout(
            container: widget,
            children: layoutableChildren(backend: backend, children: children),
            cache: &cache,
            layout: layout,
            environment: environment
                .with(\.usesZStackLayout, true)
                .with(\.zStackContentAlignment, alignment)
                .with(\.layoutOrientation, .vertical),
            backend: backend
        )
        (children as? TupleViewChildren)?.stackLayoutCache = cache
    }
}
