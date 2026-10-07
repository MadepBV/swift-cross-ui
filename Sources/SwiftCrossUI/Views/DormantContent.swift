/// A page that stays alive while it's out of sight: a navigation stack's
/// covered pages and a tab view's unselected tabs, as SwiftUI keeps them.
///
/// While dormant the content keeps its view graph — its state, its widgets
/// and where it's scrolled to — but is neither laid out nor committed, takes
/// no space, and is hidden. Showing it again lays out and commits what's
/// already there instead of building the page from nothing, which on WinUI
/// had been most of a second for a screen of cards, on every Back and every
/// tab switch.
///
/// Lifecycle follows SwiftUI: going dormant runs the content's `onDisappear`
/// actions (and so cancels its `task`s), and waking runs `onAppear` again
/// (restarting them) for the views that had appeared. Pages nested in a page
/// that is already dormant are left as they are.
struct DormantContent<Content: View>: TypeSafeView {
    var isActive: Bool
    var body: TupleView1<Content>

    init(isActive: Bool, content: Content) {
        self.isActive = isActive
        self.body = TupleView1(content)
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> DormantContentChildren {
        let scope = DormancyScope(parent: environment.dormancyScope)
        return DormantContentChildren(
            wrapped: body.children(
                backend: backend,
                snapshots: snapshots,
                environment: environment.with(\.dormancyScope, scope)
            ),
            isActive: isActive,
            scope: scope
        )
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: DormantContentChildren
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: DormantContentChildren,
        backend: Backend
    ) -> Backend.Widget {
        // `TupleView1` wraps the content in a container of its own, so hiding
        // it never touches a widget the content manages.
        body.asWidget(children.wrapped, backend: backend)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: DormantContentChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // Before the content's bodies run, so that a page being shown again
        // contributes its title to the bar in this very pass.
        children.scope.isOwnPageDormant = !isActive
        guard isActive else {
            return .leafView(size: .zero)
        }
        return body.computeLayout(
            widget,
            children: children.wrapped,
            proposedSize: proposedSize,
            environment: environment.with(\.dormancyScope, children.scope),
            backend: backend
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: DormantContentChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let wasActive = children.isActive
        children.isActive = isActive
        children.scope.isOwnPageDormant = !isActive
        if isActive {
            body.commit(
                widget,
                children: children.wrapped,
                layout: layout,
                environment: environment.with(\.dormancyScope, children.scope),
                backend: backend
            )
        } else {
            backend.setSize(of: widget, to: .zero)
        }
        if wasActive != isActive || !children.hasSetVisibility {
            children.hasSetVisibility = true
            DormantContentVisibility.set(widget, visible: isActive, backend: backend)
        }
        if wasActive && !isActive {
            DormancyBroadcast.disappear(children.wrapped, scope: children.scope)
        } else if !wasActive && isActive {
            DormancyBroadcast.appear(children.wrapped)
        }
    }
}

/// The persistent storage of a ``DormantContent``.
final class DormantContentChildren: ViewGraphNodeChildren {
    let wrapped: any ViewGraphNodeChildren
    /// Whether the content was showing as of the last commit.
    var isActive: Bool
    var hasSetVisibility = false
    /// What the content registered that must be withdrawn while it's dormant.
    let scope: DormancyScope

    var widgets: [AnyWidget] { wrapped.widgets }
    var erasedNodes: [ErasedViewGraphNode] { wrapped.erasedNodes }

    init(wrapped: any ViewGraphNodeChildren, isActive: Bool, scope: DormancyScope) {
        self.wrapped = wrapped
        self.isActive = isActive
        self.scope = scope
    }
}

/// Shows or hides a dormant page's widget.
@MainActor
enum DormantContentVisibility {
    static func set<Backend: BaseAppBackend>(_ widget: Backend.Widget, visible: Bool, backend: Backend) {
        if let visibilityBackend = backend as? any BackendFeatures.WidgetVisibility {
            setVisibility(of: widget, visible: visible, with: visibilityBackend)
        } else if let opacityBackend = backend as? any BackendFeatures.Opacity {
            setOpacity(of: widget, visible: visible, with: opacityBackend)
        }
    }

    private static func setVisibility<VisibilityBackend: BackendFeatures.WidgetVisibility>(
        of widget: Any, visible: Bool, with backend: VisibilityBackend
    ) {
        backend.setVisibility(of: widget as! VisibilityBackend.Widget, visible: visible)
    }

    private static func setOpacity<OpacityBackend: BackendFeatures.Opacity>(
        of widget: Any, visible: Bool, with backend: OpacityBackend
    ) {
        backend.setOpacity(of: widget as! OpacityBackend.Widget, to: visible ? 1 : 0)
    }
}

/// Delivers a page's disappearance and reappearance to the lifecycle
/// modifiers inside it.
@MainActor
enum DormancyBroadcast {
    static func disappear(_ children: any ViewGraphNodeChildren, scope: DormancyScope) {
        scope.withdrawAll()
        visit(children) { storage in
            if let storage = storage as? OnDisappearModifierChildren {
                storage.action.run()
            } else if let nested = storage as? DormantContentChildren, nested.isActive {
                nested.scope.withdrawAll()
            }
        }
    }

    static func appear(_ children: any ViewGraphNodeChildren) {
        visit(children) { storage in
            if let storage = storage as? OnAppearModifierChildren {
                storage.reappear()
            }
        }
    }

    /// Visits every node's storage below `children`, outermost first, without
    /// entering pages that are dormant on their own account.
    private static func visit(
        _ children: any ViewGraphNodeChildren,
        _ body: (any ViewGraphNodeChildren) -> Void
    ) {
        body(children)
        if let dormant = children as? DormantContentChildren, !dormant.isActive {
            return
        }
        for node in children.erasedNodes {
            visit(node.transform(with: NodeChildrenReader()), body)
        }
    }
}

/// Reads an erased node's children storage.
@MainActor
private struct NodeChildrenReader: ErasedViewGraphNodeTransformer {
    func transform<V: View, Backend: BaseAppBackend>(
        node: ViewGraphNode<V, Backend>
    ) -> any ViewGraphNodeChildren {
        node.children
    }
}

/// What a page's views registered outside the view graph that has to be
/// withdrawn while the page is dormant: its contributions to the navigation
/// bar. They contribute again as the page's bodies run when it's shown.
@MainActor
final class DormancyScope {
    private struct WeakSlot {
        weak var slot: NavigationChromeSlot?
    }

    private var slots: [ObjectIdentifier: WeakSlot] = [:]
    private weak var parent: DormancyScope?
    /// Whether this page itself is dormant.
    var isOwnPageDormant = false

    init(parent: DormancyScope?) {
        self.parent = parent
    }

    /// Whether this page, or a page around it, is out of sight. A view in a
    /// dormant page can still update (its own state changed), and must not
    /// contribute to the bar then.
    var isDormant: Bool {
        isOwnPageDormant || (parent?.isDormant ?? false)
    }

    func register(_ slot: NavigationChromeSlot) {
        slots[ObjectIdentifier(slot)] = WeakSlot(slot: slot)
    }

    func withdrawAll() {
        for entry in slots.values {
            entry.slot?.withdraw()
        }
        slots.removeAll()
    }
}

extension EnvironmentValues {
    /// The scope of the nearest page kept alive by ``DormantContent``.
    @Entry var dormancyScope: DormancyScope? = nil
}
