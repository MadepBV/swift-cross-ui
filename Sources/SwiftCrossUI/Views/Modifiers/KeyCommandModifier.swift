extension View {
    /// Handles commands while this passive content's native scope owns focus.
    /// Pointer presses give the scope focus; native child controls keep theirs.
    /// Return `.ignored` to preserve the original event and native traversal.
    /// Disabling commands does not disable pointer interaction with the content.
    /// This is not an IME/text-input API. Unsupported backends leave content unchanged.
    public func onKeyCommand(
        isEnabled: Bool = true,
        _ handler: @escaping @MainActor (KeyCommandEvent) -> KeyCommandResult
    ) -> some View {
        KeyCommandModifier(body: TupleView1(self), isEnabled: isEnabled, handler: handler)
    }
}

struct KeyCommandModifier<Content: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children

    var body: TupleView1<Content>
    var isEnabled: Bool
    var handler: @MainActor (KeyCommandEvent) -> KeyCommandResult

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(
            backend: backend,
            snapshots: snapshots,
            environment: environment
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        guard
            let commandBackend = backend
            as? any BaseAppBackend & BackendFeatures.KeyCommands
        else {
            return children.child0.widget.into()
        }
        let target = createTarget(children, backend: commandBackend)
        return target as! Backend.Widget
    }

    /// Creates the backend's key-command target.
    ///
    /// Exists purely to bind the opened existential to a generic parameter.
    private func createTarget<Backend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget where Backend: BaseAppBackend & BackendFeatures.KeyCommands {
        backend.createKeyCommandTarget(
            wrapping: children.child0.widget.into()
        )
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        children.child0.computeLayout(
            with: body.view0,
            proposedSize: proposedSize,
            environment: environment
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = children.child0.commit().size.vector
        backend.setSize(of: widget, to: size)

        guard
            let commandBackend = backend
            as? any BaseAppBackend & BackendFeatures.KeyCommands
        else {
            return
        }
        updateTarget(widget, backend: commandBackend, environment: environment)
    }

    /// Updates the backend's key-command target.
    ///
    /// Exists purely to bind the opened existential to a generic parameter.
    private func updateTarget<Backend>(
        _ widget: Any,
        backend: Backend,
        environment: EnvironmentValues
    ) where Backend: BaseAppBackend & BackendFeatures.KeyCommands {
        backend.updateKeyCommandTarget(
            widget as! Backend.Widget,
            isEnabled: isEnabled,
            environment: environment,
            handler: handler
        )
    }
}
