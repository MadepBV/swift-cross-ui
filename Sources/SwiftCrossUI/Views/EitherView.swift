/// A view used by ``ViewBuilder`` to support if/else conditional statements.
public struct EitherView<A: View, B: View> {
    typealias NodeChildren = EitherViewChildren<A, B>

    public var body = EmptyView()

    /// Stores one of two possible view types.
    enum Storage {
        case a(A)
        case b(B)
    }

    var storage: Storage

    /// Creates an either view with its first case visible initially.
    init(_ a: A) {
        storage = .a(a)
    }

    /// Creates an either view with its second case visible initially.
    init(_ b: B) {
        storage = .b(b)
    }
}

extension EitherView: View {
    public var _asMenuItems: [MenuItem] {
        switch storage {
            case .a(let a): a._asMenuItems
            case .b(let b): b._asMenuItems
        }
    }
}

extension EitherView: TypeSafeView {
    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> NodeChildren {
        return EitherViewChildren(
            from: self,
            backend: backend,
            snapshots: snapshots,
            environment: environment
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: EitherViewChildren<A, B>,
        backend: Backend
    ) -> Backend.Widget {
        return backend.createContainer()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: EitherViewChildren<A, B>,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        let result: ViewLayoutResult
        let hasSwitchedCase: Bool
        switch storage {
            case .a(let a):
                switch children.node {
                    case .a(let nodeA):
                        result = nodeA.computeLayout(
                            with: a,
                            proposedSize: proposedSize,
                            environment: environment
                        )
                        hasSwitchedCase = false
                    case .b:
                        let nodeA = AnyViewGraphNode(
                            for: a,
                            backend: backend,
                            environment: environment
                        )
                        children.node = .a(nodeA)
                        result = nodeA.computeLayout(
                            with: a,
                            proposedSize: proposedSize,
                            environment: environment
                        )
                        hasSwitchedCase = true
                }
            case .b(let b):
                switch children.node {
                    case .b(let nodeB):
                        result = nodeB.computeLayout(
                            with: b,
                            proposedSize: proposedSize,
                            environment: environment
                        )
                        hasSwitchedCase = false
                    case .a:
                        let nodeB = AnyViewGraphNode(
                            for: b,
                            backend: backend,
                            environment: environment
                        )
                        children.node = .b(nodeB)
                        result = nodeB.computeLayout(
                            with: b,
                            proposedSize: proposedSize,
                            environment: environment
                        )
                        hasSwitchedCase = true
                }
        }
        children.hasSwitchedCase = children.hasSwitchedCase || hasSwitchedCase
        _ = result
        // Lay the chosen branch out through the stack machinery rather than
        // returning its result directly. With no layout published this is a
        // one-child stack and gives exactly the result the branch gave — but
        // when an enclosing grid has published its cell layout, the branch
        // is handed to it as a participant (or, if the branch is itself a
        // grouping container such as a tuple, the layout is published on
        // into it). That is what makes `LazyVGrid { switch … }` flatten
        // to cells as SwiftUI does, instead of one tall column.
        var layoutableChildren = branchLayoutableChildren(children)
        LayoutSystem.markGroupingContainers(&layoutableChildren, using: children)
        return LayoutSystem.computeStackLayout(
            container: widget,
            children: layoutableChildren,
            cache: &children.stackLayoutCache,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend,
            inheritStackLayoutParticipation: true,
            participatesInParentLayout: true
        )
    }

    /// The chosen branch as the one layoutable child, handing the node the
    /// current view value exactly as the direct call did.
    @MainActor
    private func branchLayoutableChildren(
        _ children: EitherViewChildren<A, B>
    ) -> [LayoutSystem.LayoutableChild] {
        switch (storage, children.node) {
            case (.a(let a), .a(let node)):
                return [LayoutSystem.LayoutableChild(node, child: { a })]
            case (.b(let b), .b(let node)):
                return [LayoutSystem.LayoutableChild(node, child: { b })]
            default:
                // `computeLayout` brings the node in line with the storage
                // before this is called, so this is unreachable.
                return []
        }
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: EitherViewChildren<A, B>,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        if children.hasSwitchedCase {
            backend.removeAllChildren(of: widget)
            backend.insert(children.node.widget.into(), into: widget, at: 0)
            backend.setPosition(ofChildAt: 0, in: widget, to: .zero)
            children.hasSwitchedCase = false
        }

        var layoutableChildren = branchLayoutableChildren(children)
        LayoutSystem.markGroupingContainers(&layoutableChildren, using: children)
        LayoutSystem.commitStackLayout(
            container: widget,
            children: layoutableChildren,
            cache: &children.stackLayoutCache,
            layout: layout,
            environment: environment,
            backend: backend,
            participatesInParentLayout: true
        )
    }
}

/// Uses an `enum` to store a view graph node for one of two possible child view types.
class EitherViewChildren<A: View, B: View>: ViewGraphNodeChildren {
    /// The stack machinery's cache for the one-child stack the branch is
    /// laid out as; see `EitherView.computeLayout`.
    var stackLayoutCache = StackLayoutCache.initial
    /// A view graph node that wraps one of two possible child view types.
    @MainActor
    enum EitherNode {
        case a(AnyViewGraphNode<A>)
        case b(AnyViewGraphNode<B>)

        /// The widget corresponding to the currently displayed child view.
        var widget: AnyWidget {
            switch self {
                case .a(let node):
                    return node.widget
                case .b(let node):
                    return node.widget
            }
        }

        var erasedNode: ErasedViewGraphNode {
            switch self {
                case .a(let node):
                    return ErasedViewGraphNode(wrapping: node)
                case .b(let node):
                    return ErasedViewGraphNode(wrapping: node)
            }
        }
    }

    /// The view graph node for the currently displayed child.
    var node: EitherNode

    /// Tracks whether the view has switched cases since the last non-dryrun update.
    /// Initially `true`.
    var hasSwitchedCase = true

    var widgets: [AnyWidget] {
        return [node.widget]
    }

    var erasedNodes: [ErasedViewGraphNode] {
        [node.erasedNode]
    }

    /// Creates storage for an either view's current child (which can change at any time).
    init<Backend: BaseAppBackend>(
        from view: EitherView<A, B>,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        // TODO: Ensure that this is valid in all circumstances. It should be, given that
        //   we're assuming that the parent view's state was restored from the same snapshot
        //   which should mean that the same EitherView case will be selected (if we assume
        //   that views are pure, which we have to).
        let snapshot = snapshots?.first
        switch view.storage {
            case .a(let a):
                node = .a(
                    AnyViewGraphNode(
                        for: a,
                        backend: backend,
                        snapshot: snapshot,
                        environment: environment
                    )
                )
            case .b(let b):
                node = .b(
                    AnyViewGraphNode(
                        for: b,
                        backend: backend,
                        snapshot: snapshot,
                        environment: environment
                    )
                )
        }
    }
}

/// An `if`/`switch` in a builder groups views the way ``Group`` does: the
/// enclosing container may lay the chosen branch's contents out itself.
extension EitherView: GroupingContainer {}
