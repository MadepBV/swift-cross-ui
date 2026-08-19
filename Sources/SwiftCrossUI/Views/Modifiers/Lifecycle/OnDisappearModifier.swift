extension View {
    /// Adds an action to be performed after this view disappears.
    ///
    /// `onDisappear` actions on outermost views are called first and propagate
    /// down to the leaf views due to essentially relying on the `deinit` of the
    /// modifier view's ``ViewGraphNode``.
    ///
    /// The action isn't `@Sendable`, matching ``View/onAppear(perform:)`` and
    /// every other callback on ``View``. It only ever runs on the main actor,
    /// so requiring `@Sendable` would reject the plain `@escaping () -> Void`
    /// closures that applications pass around without buying any safety.
    ///
    /// - Parameter action: The action to perform when this view disappears.
    public func onDisappear(perform action: @escaping @MainActor () -> Void) -> some View {
        OnDisappearModifier(body: TupleView1(self), action: action)
    }
}

struct OnDisappearModifier<Content: View>: TypeSafeView {
    var body: TupleView1<Content>
    var action: @MainActor () -> Void

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> OnDisappearModifierChildren {
        OnDisappearModifierChildren(
            wrappedChildren: defaultChildren(
                backend: backend,
                snapshots: snapshots,
                environment: environment
            ),
            action: action
        )
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: OnDisappearModifierChildren
    ) -> [LayoutSystem.LayoutableChild] {
        defaultLayoutableChildren(
            backend: backend,
            children: children.wrappedChildren
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: OnDisappearModifierChildren,
        backend: Backend
    ) -> Backend.Widget {
        defaultAsWidget(children.wrappedChildren, backend: backend)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: OnDisappearModifierChildren,
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
        children: OnDisappearModifierChildren,
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
    }
}

class OnDisappearModifierChildren: ViewGraphNodeChildren {
    var wrappedChildren: any ViewGraphNodeChildren
    /// The action to run once these children are deallocated.
    let action: OnDisappearAction

    var widgets: [AnyWidget] {
        wrappedChildren.widgets
    }

    var erasedNodes: [ErasedViewGraphNode] {
        wrappedChildren.erasedNodes
    }

    init(
        wrappedChildren: any ViewGraphNodeChildren,
        action: @escaping @MainActor () -> Void
    ) {
        self.wrappedChildren = wrappedChildren
        self.action = OnDisappearAction(action)
    }

    deinit {
        // `deinit` runs wherever the last reference is released, so it hands
        // the action back to the main actor rather than running it in place.
        let action = self.action
        Task { @MainActor in
            action.run()
        }
    }
}

/// Carries a view's `onDisappear` action from the deallocation that notices the
/// disappearance to the main actor that runs it.
///
/// The action deliberately isn't `@Sendable` (see ``View/onDisappear(perform:)``),
/// and a nonisolated `deinit` may only touch `Sendable` stored properties of a
/// main-actor-isolated class. Boxing the action makes what `deinit` touches a
/// reference, which is `Sendable` because the closure inside it is only ever
/// stored, read, and called on the main actor.
final class OnDisappearAction: Sendable {
    /// The action to run.
    @MainActor let run: @MainActor () -> Void

    /// Boxes an action.
    ///
    /// - Parameter run: The action to run when the view disappears.
    @MainActor
    init(_ run: @escaping @MainActor () -> Void) {
        self.run = run
    }
}
