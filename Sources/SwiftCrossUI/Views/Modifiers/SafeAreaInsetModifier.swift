extension View {
    /// Shows a view alongside this one, insetting this view to make room for
    /// it.
    ///
    /// Use this to keep a toolbar, status bar, or inspector pinned to an edge
    /// while the primary content shrinks to fit the space that's left.
    ///
    /// ```swift
    /// viewport.safeAreaInset(edge: .bottom) {
    ///     StatusBar()
    /// }
    /// ```
    ///
    /// This is a pure layout modifier; no backend support is required.
    ///
    /// - Parameters:
    ///   - edge: The edge of this view to place `content` along.
    ///   - alignment: How to align `content` horizontally within the available
    ///     width. Defaults to ``HorizontalAlignment/center``.
    ///   - spacing: The gap between this view and `content`. Defaults to `nil`,
    ///     which means no gap.
    ///   - content: The view to place along `edge`.
    /// - Returns: A view showing this view inset by `content`.
    public func safeAreaInset<Inset: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Inset
    ) -> some View {
        SafeAreaInsetModifierView(
            content: self,
            inset: content(),
            edge: edge.edge,
            insetAlignment: Alignment(horizontal: alignment, vertical: .center),
            spacing: spacing ?? 0
        )
    }

    /// Shows a view alongside this one, insetting this view to make room for
    /// it.
    ///
    /// See ``View/safeAreaInset(edge:alignment:spacing:content:)-(VerticalEdge,_,_,_)``
    /// for details.
    ///
    /// - Parameters:
    ///   - edge: The edge of this view to place `content` along.
    ///   - alignment: How to align `content` vertically within the available
    ///     height. Defaults to ``VerticalAlignment/center``.
    ///   - spacing: The gap between this view and `content`. Defaults to `nil`,
    ///     which means no gap.
    ///   - content: The view to place along `edge`.
    /// - Returns: A view showing this view inset by `content`.
    public func safeAreaInset<Inset: View>(
        edge: HorizontalEdge,
        alignment: VerticalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Inset
    ) -> some View {
        SafeAreaInsetModifierView(
            content: self,
            inset: content(),
            edge: edge.edge,
            insetAlignment: Alignment(horizontal: .center, vertical: alignment),
            spacing: spacing ?? 0
        )
    }
}

/// An edge of a rectangle along the vertical axis.
public enum VerticalEdge: Int8, CaseIterable, Hashable, Sendable {
    /// The top edge.
    case top
    /// The bottom edge.
    case bottom

    /// This edge as a general-purpose ``Edge``.
    var edge: Edge {
        switch self {
            case .top: .top
            case .bottom: .bottom
        }
    }
}

/// An edge of a rectangle along the horizontal axis.
public enum HorizontalEdge: Int8, CaseIterable, Hashable, Sendable {
    /// The leading edge (the left edge in left to right layouts).
    case leading
    /// The trailing edge (the right edge in left to right layouts).
    case trailing

    /// This edge as a general-purpose ``Edge``.
    var edge: Edge {
        switch self {
            case .leading: .leading
            case .trailing: .trailing
        }
    }
}

/// The implementation of ``View/safeAreaInset(edge:alignment:spacing:content:)-(VerticalEdge,_,_,_)``
/// and its horizontal counterpart.
struct SafeAreaInsetModifierView<Content: View, Inset: View>: TypeSafeView {
    typealias Children = TupleView2<Content, Inset>.Children

    var body: TupleView2<Content, Inset>
    /// The edge that the inset view sits along.
    var edge: Edge
    /// How the inset view is aligned along the cross axis.
    var insetAlignment: Alignment
    /// The gap between the primary content and the inset view.
    var spacing: Double

    /// Creates the modifier view.
    ///
    /// - Parameters:
    ///   - content: The primary content.
    ///   - inset: The view placed along `edge`.
    ///   - edge: The edge that `inset` sits along.
    ///   - insetAlignment: How `inset` is aligned along the cross axis.
    ///   - spacing: The gap between `content` and `inset`.
    init(
        content: Content,
        inset: Inset,
        edge: Edge,
        insetAlignment: Alignment,
        spacing: Double
    ) {
        self.body = TupleView2(content, inset)
        self.edge = edge
        self.insetAlignment = insetAlignment
        self.spacing = spacing
    }

    /// Whether the inset view is stacked vertically with the content.
    private var isVertical: Bool {
        edge == .top || edge == .bottom
    }

    /// Whether the inset view comes before the content in layout order.
    private var insetComesFirst: Bool {
        edge == .top || edge == .leading
    }

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

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: Children
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        body.asWidget(children, backend: backend)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // The inset view is measured first, against the full cross-axis
        // proposal and an unspecified main-axis proposal, so that it takes on
        // its ideal thickness.
        var insetProposal = proposedSize
        if isVertical {
            insetProposal.height = nil
        } else {
            insetProposal.width = nil
        }

        let insetResult = children.child1.computeLayout(
            with: body.view1,
            proposedSize: insetProposal,
            environment: environment
        )
        let insetSize = insetResult.size

        // Whatever the inset view took (plus the spacing) is then withheld from
        // the primary content's proposal.
        let consumed =
            (isVertical ? insetSize.height : insetSize.width) + spacing

        var contentProposal = proposedSize
        if isVertical {
            contentProposal.height = proposedSize.height.map { proposedHeight in
                max(proposedHeight - consumed, 0)
            }
        } else {
            contentProposal.width = proposedSize.width.map { proposedWidth in
                max(proposedWidth - consumed, 0)
            }
        }

        let contentResult = children.child0.computeLayout(
            with: body.view0,
            proposedSize: contentProposal,
            environment: environment
        )
        let contentSize = contentResult.size

        let size =
            if isVertical {
                ViewSize(
                    max(contentSize.width, insetSize.width),
                    contentSize.height + consumed
                )
            } else {
                ViewSize(
                    contentSize.width + consumed,
                    max(contentSize.height, insetSize.height)
                )
            }

        return ViewLayoutResult(
            size: size,
            childResults: [contentResult, insetResult]
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let frameSize = layout.size
        let contentSize = children.child0.commit().size
        let insetSize = children.child1.commit().size

        let contentPosition: SIMD2<Int>
        let insetPosition: SIMD2<Int>

        if isVertical {
            let insetY =
                insetComesFirst
                    ? 0.0
                    : frameSize.height - insetSize.height
            let contentY =
                insetComesFirst
                    ? insetSize.height + spacing
                    : 0.0

            contentPosition = SIMD2(
                LayoutSystem.roundSize(
                    HorizontalAlignment.center.position(
                        ofChild: contentSize.width,
                        in: frameSize.width
                    )
                ),
                LayoutSystem.roundSize(contentY)
            )
            insetPosition = SIMD2(
                LayoutSystem.roundSize(
                    insetAlignment.horizontal.position(
                        ofChild: insetSize.width,
                        in: frameSize.width
                    )
                ),
                LayoutSystem.roundSize(insetY)
            )
        } else {
            let insetX =
                insetComesFirst
                    ? 0.0
                    : frameSize.width - insetSize.width
            let contentX =
                insetComesFirst
                    ? insetSize.width + spacing
                    : 0.0

            contentPosition = SIMD2(
                LayoutSystem.roundSize(contentX),
                LayoutSystem.roundSize(
                    VerticalAlignment.center.position(
                        ofChild: contentSize.height,
                        in: frameSize.height
                    )
                )
            )
            insetPosition = SIMD2(
                LayoutSystem.roundSize(insetX),
                LayoutSystem.roundSize(
                    insetAlignment.vertical.position(
                        ofChild: insetSize.height,
                        in: frameSize.height
                    )
                )
            )
        }

        backend.setPosition(ofChildAt: 0, in: widget, to: contentPosition)
        backend.setPosition(ofChildAt: 1, in: widget, to: insetPosition)
        backend.setSize(of: widget, to: frameSize.vector)
    }
}
