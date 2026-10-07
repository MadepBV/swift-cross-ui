extension View {
    /// Adds an action to be performed before this view appears.
    ///
    /// The exact moment that the action gets called is an internal detail and
    /// may change at any time, but it is guaranteed to be after accessing the
    /// view's ``View/body`` and before the view appears on screen. Currently,
    /// if these docs have been kept up to date, the action gets called just
    /// before creating the view's widget.
    ///
    /// Inside a lazy stack or grid in a ``ScrollView``, as in SwiftUI, the
    /// action waits until the view is scrolled within a screen's length of the
    /// visible region, on backends that can tell (see
    /// `LazyAppearanceRegistry`).
    ///
    /// - Parameter action: The action to perform when this view appears.
    public func onAppear(perform action: @escaping @MainActor () -> Void) -> some View {
        OnAppearModifier(body: TupleView1(self), action: action)
    }
}

struct OnAppearModifier<Content: View>: TypeSafeView {
    var body: TupleView1<Content>
    var action: @MainActor () -> Void

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> OnAppearModifierChildren {
        let canWait = backend is any BackendFeatures.WidgetGeometry
            && backend is any BackendFeatures.ScrollObservation
        return OnAppearModifierChildren(
            wrappedChildren: defaultChildren(
                backend: backend,
                snapshots: snapshots,
                environment: environment
            ),
            gate: environment.appearsLazily && canWait ? environment.lazyAppearance : nil
        )
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: OnAppearModifierChildren
    ) -> [LayoutSystem.LayoutableChild] {
        defaultLayoutableChildren(backend: backend, children: children.wrappedChildren)
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: OnAppearModifierChildren,
        backend: Backend
    ) -> Backend.Widget {
        if children.gate == nil {
            children.hasAppeared = true
            action()
        }
        return defaultAsWidget(children.wrappedChildren, backend: backend)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: OnAppearModifierChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        defaultComputeLayout(
            widget,
            children: children.wrappedChildren,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: OnAppearModifierChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        defaultCommit(
            widget,
            children: children.wrappedChildren,
            layout: layout,
            environment: environment,
            backend: backend
        )
        guard !children.hasAppeared, let gate = children.gate else {
            return
        }
        // Waits with the latest action, so that it runs with the view's
        // values as of when it appears.
        children.latestAction = action
        if children.entry == nil {
            let entry = LazyAppearanceRegistry.Entry(widget: AnyWidget(widget)) { [weak children] in
                guard let children, !children.hasAppeared else { return }
                children.hasAppeared = true
                children.latestAction?()
            }
            children.entry = entry
            gate.add(entry)
        }
    }
}

final class OnAppearModifierChildren: ViewGraphNodeChildren {
    var wrappedChildren: any ViewGraphNodeChildren
    /// The scroll view's registry when the view waits to be scrolled near.
    let gate: LazyAppearanceRegistry?
    var hasAppeared = false
    var latestAction: (@MainActor () -> Void)?
    var entry: LazyAppearanceRegistry.Entry?

    var widgets: [AnyWidget] {
        wrappedChildren.widgets
    }

    var erasedNodes: [ErasedViewGraphNode] {
        wrappedChildren.erasedNodes
    }

    init(wrappedChildren: any ViewGraphNodeChildren, gate: LazyAppearanceRegistry?) {
        self.wrappedChildren = wrappedChildren
        self.gate = gate
    }
}
