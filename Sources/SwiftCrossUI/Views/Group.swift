/// A view that groups views together without affecting their layout (allowing
/// modifiers to be applied to a whole group of views at once).
public struct Group<Content: View>: View {
    public var body: Content

    /// Creates a group.
    ///
    /// - Parameter content: The content of the group.
    public init(@ViewBuilder content: () -> Content) {
        self.init(content: content())
    }

    init(content: Content) {
        body = content
    }

    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        for (index, child) in children.widgets(for: backend).enumerated() {
            backend.insert(child, into: container, at: index)
        }
        return container
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        if !(children is TupleViewChildren || children is EmptyViewChildren) {
            logger.warning(
                "Group will not function correctly with non-TupleView content",
                metadata: ["childrenType": "\(type(of: children))"]
            )
        }
        var cache = (children as? TupleViewChildren)?.stackLayoutCache ?? StackLayoutCache.initial
        let result = LayoutSystem.computeStackLayout(
            container: widget,
            children: LayoutSystem.markingGroupingContainers(
                layoutableChildren(backend: backend, children: children),
                using: children
            ),
            cache: &cache,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend,
            inheritStackLayoutParticipation: true,
            participatesInParentLayout: true
        )
        (children as? TupleViewChildren)?.stackLayoutCache = cache
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
        LayoutSystem.commitStackLayout(
            container: widget,
            children: LayoutSystem.markingGroupingContainers(
                layoutableChildren(backend: backend, children: children),
                using: children
            ),
            cache: &cache,
            layout: layout,
            environment: environment,
            backend: backend,
            participatesInParentLayout: true
        )
        (children as? TupleViewChildren)?.stackLayoutCache = cache
    }
}

/// ``Group`` exists purely to group views together, so an enclosing container
/// may lay its contents out itself.
extension Group: GroupingContainer {}
