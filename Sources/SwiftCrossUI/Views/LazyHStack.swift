/// A view that arranges its subviews horizontally, only creating them as
/// they become visible.
///
/// - Important: Like ``LazyVStack``, SwiftCrossUI's ``LazyHStack`` is
///   currently **eager**: it creates all of its children up-front and lays
///   them out exactly like an ``HStack`` does. It exists so that code written
///   against SwiftUI's `LazyHStack` compiles and renders correctly.
public struct LazyHStack<Content: View>: View {
    public var body: Content

    /// The alignment of the stack's children in the vertical direction.
    private var alignment: VerticalAlignment
    /// The amount of spacing to apply between children.
    private var spacing: Double?

    /// Creates a lazy horizontal stack with the given spacing and alignment.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the stack's children in the vertical
    ///     direction.
    ///   - spacing: The amount of spacing to apply between children. `nil`
    ///     uses ``HStack``'s default spacing.
    ///   - content: The content of the stack.
    public init(
        alignment: VerticalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) {
        body = content()
        self.alignment = alignment
        self.spacing = spacing
    }

    /// The eager stack that the lazy stack currently delegates its layout to.
    private var stack: HStack<Content> {
        HStack(
            alignment: alignment,
            spacing: spacing.map(LayoutSystem.roundSize),
            content: body
        )
    }

    public func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        // Its children appear as they're scrolled near (`LazyAppearanceRegistry`).
        stack.children(
            backend: backend,
            snapshots: snapshots,
            environment: environment.with(\.appearsLazily, true)
        )
    }

    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        stack.asWidget(children, backend: backend)
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        stack.computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment.with(\.appearsLazily, true),
            backend: backend
        )
    }

    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        stack.commit(
            widget,
            children: children,
            layout: layout,
            environment: environment.with(\.appearsLazily, true),
            backend: backend
        )
    }
}
