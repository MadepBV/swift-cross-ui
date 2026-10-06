import Foundation

extension EnvironmentValues {
    /// The size of the nearest container that
    /// ``View/containerRelativeFrame(_:alignment:)`` measures against: the
    /// visible region of the nearest ``ScrollView``. `nil` along an axis
    /// that no container has published, in which case the size proposed to
    /// the view stands in for it.
    @Entry var containerRelativeSize: ProposedViewSize = .unspecified

    /// Publishes a container's size for its content, keeping the outer
    /// container's size along any axis the proposal leaves unspecified.
    ///
    /// - Parameter size: The size proposed to the container.
    /// - Returns: The environment for the container's content.
    func publishingContainerSize(_ size: ProposedViewSize) -> EnvironmentValues {
        var containerSize = containerRelativeSize
        if let width = size.width, width.isFinite {
            containerSize.width = width
        }
        if let height = size.height, height.isFinite {
            containerSize.height = height
        }
        return with(\.containerRelativeSize, containerSize)
    }
}

extension View {
    /// Positions this view within an invisible frame with a size relative to
    /// the nearest container.
    ///
    /// - Parameters:
    ///   - axes: The axes along which to size the frame.
    ///   - alignment: The alignment of the view within the frame.
    /// - Returns: The framed view.
    public func containerRelativeFrame(
        _ axes: Axis.Set,
        alignment: Alignment = .center
    ) -> some View {
        containerRelativeFrame(axes, alignment: alignment) { length, _ in length }
    }

    /// Positions this view within an invisible frame sized as `span` of
    /// `count` equal columns or rows of the nearest container, separated by
    /// `spacing`.
    ///
    /// - Parameters:
    ///   - axes: The axes along which to size the frame.
    ///   - count: The number of equal parts to divide the container into.
    ///   - span: The number of parts the frame covers.
    ///   - spacing: The spacing between the parts.
    ///   - alignment: The alignment of the view within the frame.
    /// - Returns: The framed view.
    public func containerRelativeFrame(
        _ axes: Axis.Set,
        count: Int,
        span: Int = 1,
        spacing: CGFloat,
        alignment: Alignment = .center
    ) -> some View {
        containerRelativeFrame(axes, alignment: alignment) { length, _ in
            let count = CGFloat(max(count, 1))
            let span = CGFloat(max(span, 1))
            let part = (length - spacing * (count - 1)) / count
            return max(part * span + spacing * (span - 1), 0)
        }
    }

    /// Positions this view within an invisible frame whose size is computed
    /// from the nearest container's size.
    ///
    /// - Parameters:
    ///   - axes: The axes along which to size the frame.
    ///   - alignment: The alignment of the view within the frame.
    ///   - length: Computes the frame's length along an axis from the
    ///     container's length along that axis.
    /// - Returns: The framed view.
    public func containerRelativeFrame(
        _ axes: Axis.Set,
        alignment: Alignment = .center,
        _ length: @escaping (CGFloat, Axis) -> CGFloat
    ) -> some View {
        ContainerRelativeFrameView(self, axes: axes, alignment: alignment, length: length)
    }
}

/// The implementation of ``View/containerRelativeFrame(_:alignment:)``: an
/// exact frame whose lengths are resolved from the container's size at
/// layout time.
struct ContainerRelativeFrameView<Child: View>: TypeSafeView {
    var body: TupleView1<Child>
    var axes: Axis.Set
    var alignment: Alignment
    var length: (CGFloat, Axis) -> CGFloat

    init(
        _ child: Child,
        axes: Axis.Set,
        alignment: Alignment,
        length: @escaping (CGFloat, Axis) -> CGFloat
    ) {
        body = TupleView1(child)
        self.axes = axes
        self.alignment = alignment
        self.length = length
    }

    /// The exact frame for the given container.
    private func frame(
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues
    ) -> StrictFrameView<Child> {
        let container = environment.containerRelativeSize
        func resolvedLength(along axis: Axis) -> Double? {
            guard axes.contains(axis),
                let containerLength = container[component: axis] ?? proposedSize[component: axis],
                containerLength.isFinite
            else {
                return nil
            }
            return Double(length(CGFloat(containerLength), axis))
        }
        return StrictFrameView(
            body.view0,
            width: resolvedLength(along: .horizontal),
            height: resolvedLength(along: .vertical),
            alignment: alignment
        )
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> TupleViewChildren1<Child> {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: TupleViewChildren1<Child>,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        backend.insert(children.child0.widget.into(), into: container, at: 0)
        return container
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: TupleViewChildren1<Child>,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        frame(proposedSize: proposedSize, environment: environment).computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: TupleViewChildren1<Child>,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        // Committing only positions the child within the computed frame,
        // which doesn't depend on the frame's lengths.
        StrictFrameView(body.view0, width: nil, height: nil, alignment: alignment).commit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )
    }
}
