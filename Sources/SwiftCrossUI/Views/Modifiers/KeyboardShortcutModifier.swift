extension View {
    /// Binds a keyboard shortcut to this view's primary action.
    ///
    /// ```swift
    /// Button("Save") { save() }
    ///     .keyboardShortcut("s", modifiers: [.command])
    /// ```
    ///
    /// Pressing the shortcut activates the view exactly as clicking it would.
    /// The shortcut is scoped to the window containing the view and is
    /// suppressed while the view is disabled.
    ///
    /// - Parameters:
    ///   - key: The key that triggers the shortcut.
    ///   - modifiers: The modifier keys that must be held. Defaults to
    ///     ``EventModifiers/command``, matching SwiftUI.
    /// - Returns: A view with the shortcut attached.
    public func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = .command
    ) -> some View {
        KeyboardShortcutModifier(
            body: TupleView1(self),
            shortcut: KeyboardShortcut(key, modifiers: modifiers)
        )
    }

    /// Binds a keyboard shortcut to this view's primary action.
    ///
    /// Useful with the standard shortcuts:
    ///
    /// ```swift
    /// Button("OK") { confirm() }
    ///     .keyboardShortcut(.defaultAction)
    /// Button("Cancel") { dismiss() }
    ///     .keyboardShortcut(.cancelAction)
    /// ```
    ///
    /// - Parameter shortcut: The shortcut to attach.
    /// - Returns: A view with the shortcut attached.
    public func keyboardShortcut(_ shortcut: KeyboardShortcut) -> some View {
        KeyboardShortcutModifier(body: TupleView1(self), shortcut: shortcut)
    }

    /// Binds a keyboard shortcut to this view's primary action, or removes an
    /// inherited one.
    ///
    /// - Parameter shortcut: The shortcut to attach, or `nil` to attach none.
    /// - Returns: A view with the shortcut attached.
    public func keyboardShortcut(_ shortcut: KeyboardShortcut?) -> some View {
        KeyboardShortcutModifier(body: TupleView1(self), shortcut: shortcut)
    }
}

/// Attaches a ``KeyboardShortcut`` to its child.
///
/// Backends opt in by conforming to ``BackendFeatures/KeyboardShortcuts``.
/// Rather than using the `@CastBackend` macro, which traps on backends that
/// don't conform, this modifier casts by hand and passes the child straight
/// through when the backend has no keyboard shortcut support, so that shared
/// view code stays portable across backends.
struct KeyboardShortcutModifier<Content: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children

    var body: TupleView1<Content>
    var shortcut: KeyboardShortcut?

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
            let shortcutBackend = backend
                as? any BaseAppBackend & BackendFeatures.KeyboardShortcuts
        else {
            return children.child0.widget.into()
        }
        let target = createTarget(children, backend: shortcutBackend)
        return target as! Backend.Widget
    }

    /// Creates the backend's shortcut target.
    ///
    /// Exists purely to bind the opened existential to a generic parameter.
    private func createTarget<Backend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget where Backend: BaseAppBackend & BackendFeatures.KeyboardShortcuts {
        backend.createKeyboardShortcutTarget(
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
            let shortcutBackend = backend
                as? any BaseAppBackend & BackendFeatures.KeyboardShortcuts
        else {
            return
        }
        updateTarget(widget, backend: shortcutBackend, environment: environment)
    }

    /// Updates the backend's shortcut target.
    ///
    /// Exists purely to bind the opened existential to a generic parameter.
    private func updateTarget<Backend>(
        _ widget: Any,
        backend: Backend,
        environment: EnvironmentValues
    ) where Backend: BaseAppBackend & BackendFeatures.KeyboardShortcuts {
        backend.updateKeyboardShortcutTarget(
            widget as! Backend.Widget,
            shortcut: shortcut,
            environment: environment
        )
    }
}
