/// A view that arranges its subviews vertically, only creating them as they
/// become visible.
///
/// - Important: SwiftCrossUI's ``LazyVStack`` is currently **eager**; it
///   creates all of its children up-front and lays them out exactly like a
///   ``VStack`` does. It exists so that code written against SwiftUI's
///   `LazyVStack` compiles and renders correctly. Virtualising the children
///   (only instantiating the ones that are scrolled into view) requires
///   support from the view graph and remains future work, so a
///   ``LazyVStack`` currently costs just as much as a ``VStack`` with the
///   same content.
public struct LazyVStack<Content: View>: View {
    public var body: Content

    /// The alignment of the stack's children in the horizontal direction.
    private var alignment: HorizontalAlignment
    /// The amount of spacing to apply between children.
    private var spacing: Double?

    /// Creates a lazy vertical stack with the given spacing and alignment.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the stack's children in the horizontal
    ///     direction.
    ///   - spacing: The amount of spacing to apply between children. `nil`
    ///     uses ``VStack``'s default spacing.
    ///   - content: The content of the stack.
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(alignment: alignment, spacing: spacing, content: content())
    }

    /// Creates a lazy vertical stack with the given spacing and alignment.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the stack's children in the horizontal
    ///     direction.
    ///   - spacing: The amount of spacing to apply between children. `nil`
    ///     uses ``VStack``'s default spacing.
    ///   - content: The content of the stack.
    init(
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        content: Content
    ) {
        body = content
        self.alignment = alignment
        self.spacing = spacing
    }

    /// The eager stack that the lazy stack currently delegates its layout to.
    ///
    /// ``VStack`` measures spacing in whole points, so fractional spacing gets
    /// rounded up to the nearest point.
    private var stack: VStack<Content> {
        VStack(
            alignment: alignment,
            spacing: spacing.map(LayoutSystem.roundSize),
            content: body
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
            environment: environment,
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
            environment: environment,
            backend: backend
        )
    }
}
