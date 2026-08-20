// This file was generated using gyb. Do not edit it directly. Edit
// TupleViewChildren.swift.gyb instead.

// swiftformat:options --allow-partial-wrapping true

protocol TupleViewChildren: ViewGraphNodeChildren {
    @MainActor
    var stackLayoutCache: StackLayoutCache { get nonmutating set }
}

/// A helper function to shorten node initialisations to a single line. This
/// helps compress the generated code a bit and minimise the number of additions
/// and deletions caused by updating the generator.
@MainActor
private func node<V: View, Backend: BaseAppBackend>(
    for view: V,
    _ backend: Backend,
    _ snapshot: ViewGraphSnapshotter.NodeSnapshot?,
    _ environment: EnvironmentValues
) -> AnyViewGraphNode<V> {
    AnyViewGraphNode(
        for: view,
        backend: backend,
        snapshot: snapshot,
        environment: environment
    )
}

/// A fixed-length strongly-typed collection of 1 child nodes. A counterpart to
/// ``TupleView1``.
public class TupleViewChildren1<
    Child0: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [child0.widget]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>

    /// Creates the nodes for 1 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
    }
}

/// A fixed-length strongly-typed collection of 2 child nodes. A counterpart to
/// ``TupleView2``.
public class TupleViewChildren2<
    Child0: View, Child1: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [child0.widget, child1.widget]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>

    /// Creates the nodes for 2 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
    }
}

/// A fixed-length strongly-typed collection of 3 child nodes. A counterpart to
/// ``TupleView3``.
public class TupleViewChildren3<
    Child0: View, Child1: View, Child2: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [child0.widget, child1.widget, child2.widget]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>

    /// Creates the nodes for 3 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
    }
}

/// A fixed-length strongly-typed collection of 4 child nodes. A counterpart to
/// ``TupleView4``.
public class TupleViewChildren4<
    Child0: View, Child1: View, Child2: View, Child3: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [child0.widget, child1.widget, child2.widget, child3.widget]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>

    /// Creates the nodes for 4 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
    }
}

/// A fixed-length strongly-typed collection of 5 child nodes. A counterpart to
/// ``TupleView5``.
public class TupleViewChildren5<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [child0.widget, child1.widget, child2.widget, child3.widget, child4.widget]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>

    /// Creates the nodes for 5 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
    }
}

/// A fixed-length strongly-typed collection of 6 child nodes. A counterpart to
/// ``TupleView6``.
public class TupleViewChildren6<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>

    /// Creates the nodes for 6 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
    }
}

/// A fixed-length strongly-typed collection of 7 child nodes. A counterpart to
/// ``TupleView7``.
public class TupleViewChildren7<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View, Child6: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>

    /// Creates the nodes for 7 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
    }
}

/// A fixed-length strongly-typed collection of 8 child nodes. A counterpart to
/// ``TupleView8``.
public class TupleViewChildren8<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>

    /// Creates the nodes for 8 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
    }
}

/// A fixed-length strongly-typed collection of 9 child nodes. A counterpart to
/// ``TupleView9``.
public class TupleViewChildren9<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>

    /// Creates the nodes for 9 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
    }
}

/// A fixed-length strongly-typed collection of 10 child nodes. A counterpart to
/// ``TupleView10``.
public class TupleViewChildren10<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>

    /// Creates the nodes for 10 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
    }
}

/// A fixed-length strongly-typed collection of 11 child nodes. A counterpart to
/// ``TupleView11``.
public class TupleViewChildren11<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>

    /// Creates the nodes for 11 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
    }
}

/// A fixed-length strongly-typed collection of 12 child nodes. A counterpart to
/// ``TupleView12``.
public class TupleViewChildren12<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>

    /// Creates the nodes for 12 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
    }
}

/// A fixed-length strongly-typed collection of 13 child nodes. A counterpart to
/// ``TupleView13``.
public class TupleViewChildren13<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>

    /// Creates the nodes for 13 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
    }
}

/// A fixed-length strongly-typed collection of 14 child nodes. A counterpart to
/// ``TupleView14``.
public class TupleViewChildren14<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>

    /// Creates the nodes for 14 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
    }
}

/// A fixed-length strongly-typed collection of 15 child nodes. A counterpart to
/// ``TupleView15``.
public class TupleViewChildren15<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>

    /// Creates the nodes for 15 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
    }
}

/// A fixed-length strongly-typed collection of 16 child nodes. A counterpart to
/// ``TupleView16``.
public class TupleViewChildren16<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>

    /// Creates the nodes for 16 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
    }
}

/// A fixed-length strongly-typed collection of 17 child nodes. A counterpart to
/// ``TupleView17``.
public class TupleViewChildren17<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>

    /// Creates the nodes for 17 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
    }
}

/// A fixed-length strongly-typed collection of 18 child nodes. A counterpart to
/// ``TupleView18``.
public class TupleViewChildren18<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>

    /// Creates the nodes for 18 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
    }
}

/// A fixed-length strongly-typed collection of 19 child nodes. A counterpart to
/// ``TupleView19``.
public class TupleViewChildren19<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>

    /// Creates the nodes for 19 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
    }
}

/// A fixed-length strongly-typed collection of 20 child nodes. A counterpart to
/// ``TupleView20``.
public class TupleViewChildren20<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>

    /// Creates the nodes for 20 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
    }
}

/// A fixed-length strongly-typed collection of 21 child nodes. A counterpart to
/// ``TupleView21``.
public class TupleViewChildren21<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>

    /// Creates the nodes for 21 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
    }
}

/// A fixed-length strongly-typed collection of 22 child nodes. A counterpart to
/// ``TupleView22``.
public class TupleViewChildren22<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>

    /// Creates the nodes for 22 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
    }
}

/// A fixed-length strongly-typed collection of 23 child nodes. A counterpart to
/// ``TupleView23``.
public class TupleViewChildren23<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>

    /// Creates the nodes for 23 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
    }
}

/// A fixed-length strongly-typed collection of 24 child nodes. A counterpart to
/// ``TupleView24``.
public class TupleViewChildren24<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>

    /// Creates the nodes for 24 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
    }
}

/// A fixed-length strongly-typed collection of 25 child nodes. A counterpart to
/// ``TupleView25``.
public class TupleViewChildren25<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>

    /// Creates the nodes for 25 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
    }
}

/// A fixed-length strongly-typed collection of 26 child nodes. A counterpart to
/// ``TupleView26``.
public class TupleViewChildren26<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>

    /// Creates the nodes for 26 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
    }
}

/// A fixed-length strongly-typed collection of 27 child nodes. A counterpart to
/// ``TupleView27``.
public class TupleViewChildren27<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>

    /// Creates the nodes for 27 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
    }
}

/// A fixed-length strongly-typed collection of 28 child nodes. A counterpart to
/// ``TupleView28``.
public class TupleViewChildren28<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>

    /// Creates the nodes for 28 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
    }
}

/// A fixed-length strongly-typed collection of 29 child nodes. A counterpart to
/// ``TupleView29``.
public class TupleViewChildren29<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>

    /// Creates the nodes for 29 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
    }
}

/// A fixed-length strongly-typed collection of 30 child nodes. A counterpart to
/// ``TupleView30``.
public class TupleViewChildren30<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>

    /// Creates the nodes for 30 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
    }
}

/// A fixed-length strongly-typed collection of 31 child nodes. A counterpart to
/// ``TupleView31``.
public class TupleViewChildren31<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>

    /// Creates the nodes for 31 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
    }
}

/// A fixed-length strongly-typed collection of 32 child nodes. A counterpart to
/// ``TupleView32``.
public class TupleViewChildren32<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>

    /// Creates the nodes for 32 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
    }
}

/// A fixed-length strongly-typed collection of 33 child nodes. A counterpart to
/// ``TupleView33``.
public class TupleViewChildren33<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>

    /// Creates the nodes for 33 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
    }
}

/// A fixed-length strongly-typed collection of 34 child nodes. A counterpart to
/// ``TupleView34``.
public class TupleViewChildren34<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>

    /// Creates the nodes for 34 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
    }
}

/// A fixed-length strongly-typed collection of 35 child nodes. A counterpart to
/// ``TupleView35``.
public class TupleViewChildren35<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>

    /// Creates the nodes for 35 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
    }
}

/// A fixed-length strongly-typed collection of 36 child nodes. A counterpart to
/// ``TupleView36``.
public class TupleViewChildren36<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>

    /// Creates the nodes for 36 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
    }
}

/// A fixed-length strongly-typed collection of 37 child nodes. A counterpart to
/// ``TupleView37``.
public class TupleViewChildren37<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>

    /// Creates the nodes for 37 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
    }
}

/// A fixed-length strongly-typed collection of 38 child nodes. A counterpart to
/// ``TupleView38``.
public class TupleViewChildren38<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>

    /// Creates the nodes for 38 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
    }
}

/// A fixed-length strongly-typed collection of 39 child nodes. A counterpart to
/// ``TupleView39``.
public class TupleViewChildren39<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>

    /// Creates the nodes for 39 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
    }
}

/// A fixed-length strongly-typed collection of 40 child nodes. A counterpart to
/// ``TupleView40``.
public class TupleViewChildren40<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>

    /// Creates the nodes for 40 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
    }
}

/// A fixed-length strongly-typed collection of 41 child nodes. A counterpart to
/// ``TupleView41``.
public class TupleViewChildren41<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>

    /// Creates the nodes for 41 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
    }
}

/// A fixed-length strongly-typed collection of 42 child nodes. A counterpart to
/// ``TupleView42``.
public class TupleViewChildren42<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View, Child41: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget,
            child41.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
            ErasedViewGraphNode(wrapping: child41),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child41: AnyViewGraphNode<Child41>

    /// Creates the nodes for 42 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40, _ child41: Child41,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self),
            ViewGraphSnapshotter.name(of: Child41.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
        self.child41 = node(for: child41, backend, snapshots[41], environment)
    }
}

/// A fixed-length strongly-typed collection of 43 child nodes. A counterpart to
/// ``TupleView43``.
public class TupleViewChildren43<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View, Child41: View, Child42: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget,
            child41.widget,
            child42.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
            ErasedViewGraphNode(wrapping: child41),
            ErasedViewGraphNode(wrapping: child42),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child41: AnyViewGraphNode<Child41>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child42: AnyViewGraphNode<Child42>

    /// Creates the nodes for 43 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40, _ child41: Child41,
        _ child42: Child42,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self),
            ViewGraphSnapshotter.name(of: Child41.self),
            ViewGraphSnapshotter.name(of: Child42.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
        self.child41 = node(for: child41, backend, snapshots[41], environment)
        self.child42 = node(for: child42, backend, snapshots[42], environment)
    }
}

/// A fixed-length strongly-typed collection of 44 child nodes. A counterpart to
/// ``TupleView44``.
public class TupleViewChildren44<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View, Child41: View, Child42: View,
    Child43: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget,
            child41.widget,
            child42.widget,
            child43.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
            ErasedViewGraphNode(wrapping: child41),
            ErasedViewGraphNode(wrapping: child42),
            ErasedViewGraphNode(wrapping: child43),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child41: AnyViewGraphNode<Child41>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child42: AnyViewGraphNode<Child42>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child43: AnyViewGraphNode<Child43>

    /// Creates the nodes for 44 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40, _ child41: Child41,
        _ child42: Child42, _ child43: Child43,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self),
            ViewGraphSnapshotter.name(of: Child41.self),
            ViewGraphSnapshotter.name(of: Child42.self),
            ViewGraphSnapshotter.name(of: Child43.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
        self.child41 = node(for: child41, backend, snapshots[41], environment)
        self.child42 = node(for: child42, backend, snapshots[42], environment)
        self.child43 = node(for: child43, backend, snapshots[43], environment)
    }
}

/// A fixed-length strongly-typed collection of 45 child nodes. A counterpart to
/// ``TupleView45``.
public class TupleViewChildren45<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View, Child41: View, Child42: View,
    Child43: View, Child44: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget,
            child41.widget,
            child42.widget,
            child43.widget,
            child44.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
            ErasedViewGraphNode(wrapping: child41),
            ErasedViewGraphNode(wrapping: child42),
            ErasedViewGraphNode(wrapping: child43),
            ErasedViewGraphNode(wrapping: child44),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child41: AnyViewGraphNode<Child41>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child42: AnyViewGraphNode<Child42>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child43: AnyViewGraphNode<Child43>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child44: AnyViewGraphNode<Child44>

    /// Creates the nodes for 45 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40, _ child41: Child41,
        _ child42: Child42, _ child43: Child43, _ child44: Child44,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self),
            ViewGraphSnapshotter.name(of: Child41.self),
            ViewGraphSnapshotter.name(of: Child42.self),
            ViewGraphSnapshotter.name(of: Child43.self),
            ViewGraphSnapshotter.name(of: Child44.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
        self.child41 = node(for: child41, backend, snapshots[41], environment)
        self.child42 = node(for: child42, backend, snapshots[42], environment)
        self.child43 = node(for: child43, backend, snapshots[43], environment)
        self.child44 = node(for: child44, backend, snapshots[44], environment)
    }
}

/// A fixed-length strongly-typed collection of 46 child nodes. A counterpart to
/// ``TupleView46``.
public class TupleViewChildren46<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View, Child41: View, Child42: View,
    Child43: View, Child44: View, Child45: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget,
            child41.widget,
            child42.widget,
            child43.widget,
            child44.widget,
            child45.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
            ErasedViewGraphNode(wrapping: child41),
            ErasedViewGraphNode(wrapping: child42),
            ErasedViewGraphNode(wrapping: child43),
            ErasedViewGraphNode(wrapping: child44),
            ErasedViewGraphNode(wrapping: child45),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child41: AnyViewGraphNode<Child41>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child42: AnyViewGraphNode<Child42>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child43: AnyViewGraphNode<Child43>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child44: AnyViewGraphNode<Child44>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child45: AnyViewGraphNode<Child45>

    /// Creates the nodes for 46 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40, _ child41: Child41,
        _ child42: Child42, _ child43: Child43, _ child44: Child44, _ child45: Child45,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self),
            ViewGraphSnapshotter.name(of: Child41.self),
            ViewGraphSnapshotter.name(of: Child42.self),
            ViewGraphSnapshotter.name(of: Child43.self),
            ViewGraphSnapshotter.name(of: Child44.self),
            ViewGraphSnapshotter.name(of: Child45.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
        self.child41 = node(for: child41, backend, snapshots[41], environment)
        self.child42 = node(for: child42, backend, snapshots[42], environment)
        self.child43 = node(for: child43, backend, snapshots[43], environment)
        self.child44 = node(for: child44, backend, snapshots[44], environment)
        self.child45 = node(for: child45, backend, snapshots[45], environment)
    }
}

/// A fixed-length strongly-typed collection of 47 child nodes. A counterpart to
/// ``TupleView47``.
public class TupleViewChildren47<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View, Child41: View, Child42: View,
    Child43: View, Child44: View, Child45: View, Child46: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget,
            child41.widget,
            child42.widget,
            child43.widget,
            child44.widget,
            child45.widget,
            child46.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
            ErasedViewGraphNode(wrapping: child41),
            ErasedViewGraphNode(wrapping: child42),
            ErasedViewGraphNode(wrapping: child43),
            ErasedViewGraphNode(wrapping: child44),
            ErasedViewGraphNode(wrapping: child45),
            ErasedViewGraphNode(wrapping: child46),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child41: AnyViewGraphNode<Child41>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child42: AnyViewGraphNode<Child42>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child43: AnyViewGraphNode<Child43>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child44: AnyViewGraphNode<Child44>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child45: AnyViewGraphNode<Child45>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child46: AnyViewGraphNode<Child46>

    /// Creates the nodes for 47 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40, _ child41: Child41,
        _ child42: Child42, _ child43: Child43, _ child44: Child44, _ child45: Child45,
        _ child46: Child46,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self),
            ViewGraphSnapshotter.name(of: Child41.self),
            ViewGraphSnapshotter.name(of: Child42.self),
            ViewGraphSnapshotter.name(of: Child43.self),
            ViewGraphSnapshotter.name(of: Child44.self),
            ViewGraphSnapshotter.name(of: Child45.self),
            ViewGraphSnapshotter.name(of: Child46.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
        self.child41 = node(for: child41, backend, snapshots[41], environment)
        self.child42 = node(for: child42, backend, snapshots[42], environment)
        self.child43 = node(for: child43, backend, snapshots[43], environment)
        self.child44 = node(for: child44, backend, snapshots[44], environment)
        self.child45 = node(for: child45, backend, snapshots[45], environment)
        self.child46 = node(for: child46, backend, snapshots[46], environment)
    }
}

/// A fixed-length strongly-typed collection of 48 child nodes. A counterpart to
/// ``TupleView48``.
public class TupleViewChildren48<
    Child0: View, Child1: View, Child2: View, Child3: View, Child4: View, Child5: View,
    Child6: View,
    Child7: View, Child8: View, Child9: View, Child10: View, Child11: View, Child12: View,
    Child13: View, Child14: View, Child15: View, Child16: View, Child17: View, Child18: View,
    Child19: View, Child20: View, Child21: View, Child22: View, Child23: View, Child24: View,
    Child25: View, Child26: View, Child27: View, Child28: View, Child29: View, Child30: View,
    Child31: View, Child32: View, Child33: View, Child34: View, Child35: View, Child36: View,
    Child37: View, Child38: View, Child39: View, Child40: View, Child41: View, Child42: View,
    Child43: View, Child44: View, Child45: View, Child46: View, Child47: View
>: TupleViewChildren {
    public var widgets: [AnyWidget] {
        return [
            child0.widget,
            child1.widget,
            child2.widget,
            child3.widget,
            child4.widget,
            child5.widget,
            child6.widget,
            child7.widget,
            child8.widget,
            child9.widget,
            child10.widget,
            child11.widget,
            child12.widget,
            child13.widget,
            child14.widget,
            child15.widget,
            child16.widget,
            child17.widget,
            child18.widget,
            child19.widget,
            child20.widget,
            child21.widget,
            child22.widget,
            child23.widget,
            child24.widget,
            child25.widget,
            child26.widget,
            child27.widget,
            child28.widget,
            child29.widget,
            child30.widget,
            child31.widget,
            child32.widget,
            child33.widget,
            child34.widget,
            child35.widget,
            child36.widget,
            child37.widget,
            child38.widget,
            child39.widget,
            child40.widget,
            child41.widget,
            child42.widget,
            child43.widget,
            child44.widget,
            child45.widget,
            child46.widget,
            child47.widget
        ]
    }

    public var erasedNodes: [ErasedViewGraphNode] {
        return [
            ErasedViewGraphNode(wrapping: child0),
            ErasedViewGraphNode(wrapping: child1),
            ErasedViewGraphNode(wrapping: child2),
            ErasedViewGraphNode(wrapping: child3),
            ErasedViewGraphNode(wrapping: child4),
            ErasedViewGraphNode(wrapping: child5),
            ErasedViewGraphNode(wrapping: child6),
            ErasedViewGraphNode(wrapping: child7),
            ErasedViewGraphNode(wrapping: child8),
            ErasedViewGraphNode(wrapping: child9),
            ErasedViewGraphNode(wrapping: child10),
            ErasedViewGraphNode(wrapping: child11),
            ErasedViewGraphNode(wrapping: child12),
            ErasedViewGraphNode(wrapping: child13),
            ErasedViewGraphNode(wrapping: child14),
            ErasedViewGraphNode(wrapping: child15),
            ErasedViewGraphNode(wrapping: child16),
            ErasedViewGraphNode(wrapping: child17),
            ErasedViewGraphNode(wrapping: child18),
            ErasedViewGraphNode(wrapping: child19),
            ErasedViewGraphNode(wrapping: child20),
            ErasedViewGraphNode(wrapping: child21),
            ErasedViewGraphNode(wrapping: child22),
            ErasedViewGraphNode(wrapping: child23),
            ErasedViewGraphNode(wrapping: child24),
            ErasedViewGraphNode(wrapping: child25),
            ErasedViewGraphNode(wrapping: child26),
            ErasedViewGraphNode(wrapping: child27),
            ErasedViewGraphNode(wrapping: child28),
            ErasedViewGraphNode(wrapping: child29),
            ErasedViewGraphNode(wrapping: child30),
            ErasedViewGraphNode(wrapping: child31),
            ErasedViewGraphNode(wrapping: child32),
            ErasedViewGraphNode(wrapping: child33),
            ErasedViewGraphNode(wrapping: child34),
            ErasedViewGraphNode(wrapping: child35),
            ErasedViewGraphNode(wrapping: child36),
            ErasedViewGraphNode(wrapping: child37),
            ErasedViewGraphNode(wrapping: child38),
            ErasedViewGraphNode(wrapping: child39),
            ErasedViewGraphNode(wrapping: child40),
            ErasedViewGraphNode(wrapping: child41),
            ErasedViewGraphNode(wrapping: child42),
            ErasedViewGraphNode(wrapping: child43),
            ErasedViewGraphNode(wrapping: child44),
            ErasedViewGraphNode(wrapping: child45),
            ErasedViewGraphNode(wrapping: child46),
            ErasedViewGraphNode(wrapping: child47),
        ]
    }

    var stackLayoutCache = StackLayoutCache.initial

    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child0: AnyViewGraphNode<Child0>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child1: AnyViewGraphNode<Child1>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child2: AnyViewGraphNode<Child2>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child3: AnyViewGraphNode<Child3>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child4: AnyViewGraphNode<Child4>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child5: AnyViewGraphNode<Child5>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child6: AnyViewGraphNode<Child6>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child7: AnyViewGraphNode<Child7>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child8: AnyViewGraphNode<Child8>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child9: AnyViewGraphNode<Child9>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child10: AnyViewGraphNode<Child10>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child11: AnyViewGraphNode<Child11>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child12: AnyViewGraphNode<Child12>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child13: AnyViewGraphNode<Child13>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child14: AnyViewGraphNode<Child14>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child15: AnyViewGraphNode<Child15>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child16: AnyViewGraphNode<Child16>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child17: AnyViewGraphNode<Child17>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child18: AnyViewGraphNode<Child18>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child19: AnyViewGraphNode<Child19>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child20: AnyViewGraphNode<Child20>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child21: AnyViewGraphNode<Child21>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child22: AnyViewGraphNode<Child22>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child23: AnyViewGraphNode<Child23>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child24: AnyViewGraphNode<Child24>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child25: AnyViewGraphNode<Child25>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child26: AnyViewGraphNode<Child26>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child27: AnyViewGraphNode<Child27>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child28: AnyViewGraphNode<Child28>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child29: AnyViewGraphNode<Child29>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child30: AnyViewGraphNode<Child30>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child31: AnyViewGraphNode<Child31>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child32: AnyViewGraphNode<Child32>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child33: AnyViewGraphNode<Child33>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child34: AnyViewGraphNode<Child34>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child35: AnyViewGraphNode<Child35>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child36: AnyViewGraphNode<Child36>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child37: AnyViewGraphNode<Child37>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child38: AnyViewGraphNode<Child38>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child39: AnyViewGraphNode<Child39>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child40: AnyViewGraphNode<Child40>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child41: AnyViewGraphNode<Child41>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child42: AnyViewGraphNode<Child42>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child43: AnyViewGraphNode<Child43>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child44: AnyViewGraphNode<Child44>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child45: AnyViewGraphNode<Child45>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child46: AnyViewGraphNode<Child46>
    /// ``AnyViewGraphNode`` is used instead of ``ViewGraphNode`` because otherwise the backend leaks into views.
    public var child47: AnyViewGraphNode<Child47>

    /// Creates the nodes for 48 child views.
    public init<Backend: BaseAppBackend>(
        _ child0: Child0, _ child1: Child1, _ child2: Child2, _ child3: Child3, _ child4: Child4,
        _ child5: Child5, _ child6: Child6, _ child7: Child7, _ child8: Child8,
        _ child9: Child9,
        _ child10: Child10, _ child11: Child11, _ child12: Child12, _ child13: Child13,
        _ child14: Child14, _ child15: Child15, _ child16: Child16, _ child17: Child17,
        _ child18: Child18, _ child19: Child19, _ child20: Child20, _ child21: Child21,
        _ child22: Child22, _ child23: Child23, _ child24: Child24, _ child25: Child25,
        _ child26: Child26, _ child27: Child27, _ child28: Child28, _ child29: Child29,
        _ child30: Child30, _ child31: Child31, _ child32: Child32, _ child33: Child33,
        _ child34: Child34, _ child35: Child35, _ child36: Child36, _ child37: Child37,
        _ child38: Child38, _ child39: Child39, _ child40: Child40, _ child41: Child41,
        _ child42: Child42, _ child43: Child43, _ child44: Child44, _ child45: Child45,
        _ child46: Child46, _ child47: Child47,
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) {
        let viewTypeNames = [
            ViewGraphSnapshotter.name(of: Child0.self), ViewGraphSnapshotter.name(of: Child1.self),
            ViewGraphSnapshotter.name(of: Child2.self),
            ViewGraphSnapshotter.name(of: Child3.self),
            ViewGraphSnapshotter.name(of: Child4.self),
            ViewGraphSnapshotter.name(of: Child5.self),
            ViewGraphSnapshotter.name(of: Child6.self),
            ViewGraphSnapshotter.name(of: Child7.self),
            ViewGraphSnapshotter.name(of: Child8.self),
            ViewGraphSnapshotter.name(of: Child9.self),
            ViewGraphSnapshotter.name(of: Child10.self),
            ViewGraphSnapshotter.name(of: Child11.self),
            ViewGraphSnapshotter.name(of: Child12.self),
            ViewGraphSnapshotter.name(of: Child13.self),
            ViewGraphSnapshotter.name(of: Child14.self),
            ViewGraphSnapshotter.name(of: Child15.self),
            ViewGraphSnapshotter.name(of: Child16.self),
            ViewGraphSnapshotter.name(of: Child17.self),
            ViewGraphSnapshotter.name(of: Child18.self),
            ViewGraphSnapshotter.name(of: Child19.self),
            ViewGraphSnapshotter.name(of: Child20.self),
            ViewGraphSnapshotter.name(of: Child21.self),
            ViewGraphSnapshotter.name(of: Child22.self),
            ViewGraphSnapshotter.name(of: Child23.self),
            ViewGraphSnapshotter.name(of: Child24.self),
            ViewGraphSnapshotter.name(of: Child25.self),
            ViewGraphSnapshotter.name(of: Child26.self),
            ViewGraphSnapshotter.name(of: Child27.self),
            ViewGraphSnapshotter.name(of: Child28.self),
            ViewGraphSnapshotter.name(of: Child29.self),
            ViewGraphSnapshotter.name(of: Child30.self),
            ViewGraphSnapshotter.name(of: Child31.self),
            ViewGraphSnapshotter.name(of: Child32.self),
            ViewGraphSnapshotter.name(of: Child33.self),
            ViewGraphSnapshotter.name(of: Child34.self),
            ViewGraphSnapshotter.name(of: Child35.self),
            ViewGraphSnapshotter.name(of: Child36.self),
            ViewGraphSnapshotter.name(of: Child37.self),
            ViewGraphSnapshotter.name(of: Child38.self),
            ViewGraphSnapshotter.name(of: Child39.self),
            ViewGraphSnapshotter.name(of: Child40.self),
            ViewGraphSnapshotter.name(of: Child41.self),
            ViewGraphSnapshotter.name(of: Child42.self),
            ViewGraphSnapshotter.name(of: Child43.self),
            ViewGraphSnapshotter.name(of: Child44.self),
            ViewGraphSnapshotter.name(of: Child45.self),
            ViewGraphSnapshotter.name(of: Child46.self),
            ViewGraphSnapshotter.name(of: Child47.self)
        ]
        let snapshots = ViewGraphSnapshotter.match(snapshots ?? [], to: viewTypeNames)
        self.child0 = node(for: child0, backend, snapshots[0], environment)
        self.child1 = node(for: child1, backend, snapshots[1], environment)
        self.child2 = node(for: child2, backend, snapshots[2], environment)
        self.child3 = node(for: child3, backend, snapshots[3], environment)
        self.child4 = node(for: child4, backend, snapshots[4], environment)
        self.child5 = node(for: child5, backend, snapshots[5], environment)
        self.child6 = node(for: child6, backend, snapshots[6], environment)
        self.child7 = node(for: child7, backend, snapshots[7], environment)
        self.child8 = node(for: child8, backend, snapshots[8], environment)
        self.child9 = node(for: child9, backend, snapshots[9], environment)
        self.child10 = node(for: child10, backend, snapshots[10], environment)
        self.child11 = node(for: child11, backend, snapshots[11], environment)
        self.child12 = node(for: child12, backend, snapshots[12], environment)
        self.child13 = node(for: child13, backend, snapshots[13], environment)
        self.child14 = node(for: child14, backend, snapshots[14], environment)
        self.child15 = node(for: child15, backend, snapshots[15], environment)
        self.child16 = node(for: child16, backend, snapshots[16], environment)
        self.child17 = node(for: child17, backend, snapshots[17], environment)
        self.child18 = node(for: child18, backend, snapshots[18], environment)
        self.child19 = node(for: child19, backend, snapshots[19], environment)
        self.child20 = node(for: child20, backend, snapshots[20], environment)
        self.child21 = node(for: child21, backend, snapshots[21], environment)
        self.child22 = node(for: child22, backend, snapshots[22], environment)
        self.child23 = node(for: child23, backend, snapshots[23], environment)
        self.child24 = node(for: child24, backend, snapshots[24], environment)
        self.child25 = node(for: child25, backend, snapshots[25], environment)
        self.child26 = node(for: child26, backend, snapshots[26], environment)
        self.child27 = node(for: child27, backend, snapshots[27], environment)
        self.child28 = node(for: child28, backend, snapshots[28], environment)
        self.child29 = node(for: child29, backend, snapshots[29], environment)
        self.child30 = node(for: child30, backend, snapshots[30], environment)
        self.child31 = node(for: child31, backend, snapshots[31], environment)
        self.child32 = node(for: child32, backend, snapshots[32], environment)
        self.child33 = node(for: child33, backend, snapshots[33], environment)
        self.child34 = node(for: child34, backend, snapshots[34], environment)
        self.child35 = node(for: child35, backend, snapshots[35], environment)
        self.child36 = node(for: child36, backend, snapshots[36], environment)
        self.child37 = node(for: child37, backend, snapshots[37], environment)
        self.child38 = node(for: child38, backend, snapshots[38], environment)
        self.child39 = node(for: child39, backend, snapshots[39], environment)
        self.child40 = node(for: child40, backend, snapshots[40], environment)
        self.child41 = node(for: child41, backend, snapshots[41], environment)
        self.child42 = node(for: child42, backend, snapshots[42], environment)
        self.child43 = node(for: child43, backend, snapshots[43], environment)
        self.child44 = node(for: child44, backend, snapshots[44], environment)
        self.child45 = node(for: child45, backend, snapshots[45], environment)
        self.child46 = node(for: child46, backend, snapshots[46], environment)
        self.child47 = node(for: child47, backend, snapshots[47], environment)
    }
}
