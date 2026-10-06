extension View {
    /// Clips this view to a shape.
    ///
    /// ```swift
    /// artwork
    ///     .clipShape(RoundedRectangle(cornerRadius: 12))
    /// ```
    ///
    /// The clip uses the same backend capability as ``View/cornerRadius(_:)``:
    /// a rounded-rectangle clip of the view's frame. That draws
    /// ``Rectangle``, ``RoundedRectangle``, ``Capsule`` and (in a square
    /// frame) ``Circle`` and ``Ellipse`` exactly. Other shapes clip to their
    /// frame: no backend exposes an arbitrary path clip yet.
    ///
    /// - Parameters:
    ///   - shape: The shape to clip to.
    ///   - style: Accepted for source compatibility; clips use the non-zero
    ///     rule.
    /// - Returns: The clipped view.
    public func clipShape<ClipShape: Shape>(
        _ shape: ClipShape,
        style: FillStyle = FillStyle()
    ) -> some View {
        ClipShapeModifier(content: self, shape: shape)
    }
}

/// A shape that a backend's rounded-rectangle clip can reproduce exactly.
protocol RoundedRectangularShape {
    /// The corner radius of this shape when drawn in a frame of `size`.
    func clipCornerRadius(in size: ViewSize) -> Double
}

extension Rectangle: RoundedRectangularShape {
    func clipCornerRadius(in size: ViewSize) -> Double { 0 }
}

extension RoundedRectangle: RoundedRectangularShape {
    func clipCornerRadius(in size: ViewSize) -> Double {
        min(cornerRadius, min(size.width, size.height) / 2)
    }
}

extension Capsule: RoundedRectangularShape {
    func clipCornerRadius(in size: ViewSize) -> Double {
        min(size.width, size.height) / 2
    }
}

extension Circle: RoundedRectangularShape {
    func clipCornerRadius(in size: ViewSize) -> Double {
        min(size.width, size.height) / 2
    }
}

extension Ellipse: RoundedRectangularShape {
    func clipCornerRadius(in size: ViewSize) -> Double {
        min(size.width, size.height) / 2
    }
}

struct ClipShapeModifier<Content: View, ClipShape: Shape>: View, TypeSafeView {
    var content: Content
    var shape: ClipShape

    var body: TupleView1<Content> { content }

    typealias Children = TupleView1<Content>.Children

    /// The radius to clip the corners of a frame of `size` with.
    func cornerRadius(in size: ViewSize) -> Int {
        let radius =
            (shape as? any RoundedRectangularShape)?.clipCornerRadius(in: size) ?? 0
        return Int(radius.rounded())
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    @CastBackend<BackendFeatures.CornerRadius>(returnsWidget: true)
    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        backend.createCornerRadiusContainer(wrapping: body.asWidget(children, backend: backend))
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: Children
    ) -> [LayoutSystem.LayoutableChild] {
        body.layoutableChildren(backend: backend, children: children)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        body.computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
    }

    @CastBackend<BackendFeatures.CornerRadius>
    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = children.child0.commit().size
        backend.setSize(of: widget, to: size.vector)
        backend.setCornerRadius(of: widget, to: cornerRadius(in: size))
    }
}
