extension View {
    /// Binds this view's focus state to a value of a ``FocusState``.
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .focused($focusedField, equals: .name)
    /// ```
    ///
    /// The binding runs both ways: setting `focusedField` to `.name` moves
    /// focus to the text field, and the user clicking or tabbing into the
    /// field sets `focusedField` to `.name`.
    ///
    /// - Parameters:
    ///   - binding: The focus state to bind to, via its `$` projection.
    ///   - value: The value that means "this view has focus".
    /// - Returns: A view that participates in focus management.
    public func focused<Value: Hashable>(
        _ binding: FocusState<Value>.Binding,
        equals value: Value
    ) -> some View {
        FocusModifier(
            body: TupleView1(self),
            binding: binding.erased(matching: value)
        )
    }

    /// Binds this view's focus state to a boolean ``FocusState``.
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .focused($isNameFocused)
    /// ```
    ///
    /// - Parameter condition: The focus state to bind to, via its `$`
    ///   projection.
    /// - Returns: A view that participates in focus management.
    public func focused(_ condition: FocusState<Bool>.Binding) -> some View {
        focused(condition, equals: true)
    }

    /// Publishes a value that views elsewhere in the app can read with
    /// ``FocusedValue`` while this view's scene is focused.
    ///
    /// - Important: SwiftCrossUI resolves focused values at *scene*
    ///   granularity, so this modifier behaves identically to
    ///   ``View/focusedSceneValue(_:_:)``: the value is published while the
    ///   enclosing scene is active, not only while this particular view holds
    ///   keyboard focus. Prefer ``View/focusedSceneValue(_:_:)`` in new code,
    ///   where that meaning is explicit.
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the ``FocusedValues`` property to publish
    ///     under.
    ///   - value: The value to publish.
    /// - Returns: A view that publishes the value.
    public func focusedValue<T>(
        _ keyPath: WritableKeyPath<FocusedValues, T?>,
        _ value: T
    ) -> some View {
        focusedSceneValue(keyPath, value)
    }

    /// Publishes a value that views elsewhere in the app can read with
    /// ``FocusedValue`` while this view's scene is focused.
    ///
    /// This is how a document app tells its menu bar what the frontmost window
    /// is working on:
    ///
    /// ```swift
    /// DocumentView(document: document)
    ///     .focusedSceneValue(\.activeDocument, document)
    /// ```
    ///
    /// The value is published only while the enclosing scene's
    /// ``EnvironmentValues/scenePhase`` is ``ScenePhase/active``, so in a
    /// multi-window app the frontmost window wins. Passing `nil` withdraws
    /// the value.
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the ``FocusedValues`` property to publish
    ///     under.
    ///   - value: The value to publish, or `nil` to publish nothing.
    /// - Returns: A view that publishes the value.
    public func focusedSceneValue<T>(
        _ keyPath: WritableKeyPath<FocusedValues, T?>,
        _ value: T?
    ) -> some View {
        FocusedSceneValueModifier(
            body: TupleView1(self),
            keyPath: keyPath,
            value: value
        )
    }
}

/// Drives and observes its child's keyboard focus on behalf of a
/// ``FocusState``.
///
/// Backends opt in by conforming to ``BackendFeatures/Focus``. Like
/// ``KeyboardShortcutModifier``, this casts the backend by hand rather than
/// using `@CastBackend` so that backends without focus support degrade to a
/// no-op instead of trapping.
struct FocusModifier<Content: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children

    var body: TupleView1<Content>
    var binding: AnyFocusBinding

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
            let focusBackend = backend as? any BaseAppBackend & BackendFeatures.Focus
        else {
            return children.child0.widget.into()
        }
        let target = createTarget(children, backend: focusBackend)
        return target as! Backend.Widget
    }

    /// Creates the backend's focus target.
    ///
    /// Exists purely to bind the opened existential to a generic parameter.
    private func createTarget<Backend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget where Backend: BaseAppBackend & BackendFeatures.Focus {
        backend.createFocusTarget(wrapping: children.child0.widget.into())
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
            let focusBackend = backend as? any BaseAppBackend & BackendFeatures.Focus
        else {
            return
        }
        updateTarget(widget, backend: focusBackend, environment: environment)
    }

    /// Updates the backend's focus target.
    ///
    /// Exists purely to bind the opened existential to a generic parameter.
    private func updateTarget<Backend>(
        _ widget: Any,
        backend: Backend,
        environment: EnvironmentValues
    ) where Backend: BaseAppBackend & BackendFeatures.Focus {
        let binding = self.binding
        backend.updateFocusTarget(
            widget as! Backend.Widget,
            isFocused: binding.isFocused(),
            environment: environment,
            onFocusChange: { isFocused in
                binding.setFocused(isFocused)
            }
        )
    }
}

/// Publishes a focused value while its enclosing scene is active.
struct FocusedSceneValueModifier<T, Content: View>: View {
    var body: TupleView1<Content>
    var keyPath: WritableKeyPath<FocusedValues, T?>
    var value: T?

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        if isSceneActive(in: environment) {
            FocusedValuesStore.shared.publish(value, for: keyPath)
        }

        defaultCommit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )
    }

    /// Whether the enclosing scene currently has focus.
    ///
    /// ``EnvironmentValues/scenePhase`` traps when read outside a scene, so
    /// check for a window first; a view with no window can't be the focused
    /// scene anyway.
    private func isSceneActive(in environment: EnvironmentValues) -> Bool {
        guard environment.window != nil else {
            return false
        }
        return environment.scenePhase == .active
    }
}
