extension View {
    /// Adds a context menu to a view.
    ///
    /// The menu is shown when the user secondary-clicks the view (or
    /// long-presses it on touch platforms). Its contents are specified the same
    /// way as a ``Menu``'s: with ``Button``s, ``Toggle``s, ``Divider``s, and
    /// nested ``Menu``s.
    ///
    /// ```swift
    /// placementRow.contextMenu {
    ///     Button("Duplicate") { duplicate() }
    ///     Divider()
    ///     Button("Delete") { delete() }
    /// }
    /// ```
    ///
    /// Backends that don't implement ``BackendFeatures/ContextMenus`` render
    /// the view without a context menu rather than failing.
    ///
    /// - Parameter menuItems: The items to show in the menu.
    /// - Returns: A view with a context menu attached.
    public func contextMenu<MenuItems: View>(
        @ViewBuilder menuItems: () -> MenuItems
    ) -> some View {
        ContextMenuModifierView(content: self, menuItems: menuItems())
    }
}

/// The implementation of ``View/contextMenu(menuItems:)``.
struct ContextMenuModifierView<Content: View, MenuItems: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children

    /// The view that the menu is attached to.
    var content: Content
    /// The view describing the menu's items.
    var menuItems: MenuItems

    var body: TupleView1<Content> { content }

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
        let child: Backend.Widget = children.child0.widget.into()

        // A manual cast rather than @CastBackend, so that backends without
        // context menu support render the plain view instead of trapping.
        guard
            let menuBackend = backend as? any BaseAppBackend & BackendFeatures.ContextMenus
        else {
            logger.warnOnce(
                "contextMenu is unsupported by the current backend; ignoring it"
            )
            return child
        }

        return Self.createTarget(wrapping: child, backend: menuBackend) as! Backend.Widget
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
        let size = children.child0.commit().size
        backend.setSize(of: widget, to: size.vector)

        guard
            let menuBackend = backend as? any BaseAppBackend & BackendFeatures.ContextMenus
        else {
            return
        }

        Self.updateTarget(
            widget,
            content: Menu.resolve(items: menuItems._asMenuItems),
            environment: environment,
            backend: menuBackend
        )
    }

    /// Wraps a child widget in a context menu target.
    ///
    /// Type-erased at the boundary so that the backend's associated widget type
    /// can be recovered by the generic parameter.
    ///
    /// - Parameters:
    ///   - child: The widget to wrap.
    ///   - backend: The app's backend.
    /// - Returns: The context menu target.
    private static func createTarget<
        Backend: BaseAppBackend & BackendFeatures.ContextMenus
    >(
        wrapping child: Any,
        backend: Backend
    ) -> Any {
        backend.createContextMenuTarget(wrapping: child as! Backend.Widget)
    }

    /// Updates the menu presented by a context menu target.
    ///
    /// - Parameters:
    ///   - target: The context menu target.
    ///   - content: The menu to present.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private static func updateTarget<
        Backend: BaseAppBackend & BackendFeatures.ContextMenus
    >(
        _ target: Any,
        content: ResolvedMenu,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.updateContextMenuTarget(
            target as! Backend.Widget,
            content: content,
            environment: environment
        )
    }
}
