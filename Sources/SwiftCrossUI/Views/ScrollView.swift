import Foundation

/// A view that is scrollable when it would otherwise overflow available space.
///
/// Use the ``View/frame(width:height:alignment:)-(Double?,_,_)`` modifier to
/// constrain width or height if necessary.
public struct ScrollView<Content: View>: TypeSafeView, View {
    public var body: VStack<Content>
    public var axes: Axis.Set

    /// Whether the scroll view is allowed to display scroll indicators.
    ///
    /// When this is `false` the scroll view never reserves room for a scroll
    /// bar and never asks the backend to show one, but the content still
    /// scrolls along ``ScrollView/axes``.
    public var showsIndicators: Bool

    /// Wraps a view in a scrollable container.
    ///
    /// - Parameters:
    ///   - axes: The axes of to enable scrolling on. Defaults to
    ///     ``Axis/Set/vertical``.
    ///   - content: The content of the scroll view.
    public init(_ axes: Axis.Set = .vertical, @ViewBuilder _ content: () -> Content) {
        self.axes = axes
        showsIndicators = true
        body = VStack(content: content())
    }

    /// Wraps a view in a scrollable container, optionally hiding its scroll
    /// indicators.
    ///
    /// This is SwiftUI's spelling. `showsIndicators` deliberately has no
    /// default value: giving it one would make every trailing-closure call of
    /// the form `ScrollView { ... }` ambiguous between this initializer and
    /// ``ScrollView/init(_:_:)``.
    ///
    /// - Parameters:
    ///   - axes: The axes of to enable scrolling on. Defaults to
    ///     ``Axis/Set/vertical``.
    ///   - showsIndicators: Whether to display scroll indicators when the
    ///     content overflows.
    ///   - content: The content of the scroll view.
    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        body = VStack(content: content())
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> ScrollViewChildren<Content> {
        // TODO: Verify that snapshotting works correctly with this
        return ScrollViewChildren(
            wrapping: TupleViewChildren1(
                body,
                backend: backend,
                snapshots: snapshots,
                environment: environment
            ),
            backend: backend
        )
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: TupleViewChildren1<VStack<Content>>
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: ScrollViewChildren<Content>,
        backend: Backend
    ) -> Backend.Widget {
        return backend.createScrollContainer(for: children.innerContainer.into())
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: ScrollViewChildren<Content>,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // If all scroll axes are unspecified, then our size is exactly that of
        // the child view. This includes when we have no scroll axes.
        let willEarlyExit = Axis.allCases.allSatisfy({ axis in
            !axes.contains(axis) || proposedSize[component: axis] == nil
        })

        // The content's environment: this scroll view's targets, and none of
        // the scroll requests that were meant for this scroll view.
        let contentEnvironment = environment
            .with(\.scrollTargets, children.scrollTargets)
            .with(\.scrollRequest, nil)
            .with(\.scrollGeometryObservers, [])
            .with(\.scrollTargetVisibilityObservers, [])
        environment.scrollViewReaderScope?.add(children.scrollTargets)

        // Margins from `contentMargins(_:_:for:)` scroll with the content, so
        // they come off the proposal along the axes that don't scroll and get
        // added to the content's size along every axis.
        let margins = environment.scrollContentMargins
        children.contentMargins = margins

        // Probe how big the child would like to be
        var childProposal = proposedSize
        for axis in Axis.allCases where axes.contains(axis) {
            childProposal[component: axis] = nil
        }
        for axis in Axis.allCases where !axes.contains(axis) {
            if let length = childProposal[component: axis] {
                childProposal[component: axis] = max(
                    0,
                    length - margins.totals[axis == .horizontal ? 0 : 1]
                )
            }
        }

        let childResult = children.child.computeLayout(
            with: body,
            proposedSize: childProposal,
            environment: contentEnvironment.with(
                \.allowLayoutCaching,
                !willEarlyExit || environment.allowLayoutCaching
            )
        )

        if willEarlyExit {
            return childResult
        }

        var contentSize = childResult.size
        contentSize.width += margins.totals.x
        contentSize.height += margins.totals.y
        let hiddenIndicatorAxes = environment.scrollIndicatorsHiddenAxes

        // An axis is present when it's a scroll axis AND the corresponding
        // child content size is bigger then the proposed size. If the proposed
        // size along the axis is nil then we don't have a scroll bar.
        let hasHorizontalScrollBar: Bool
        if showsIndicators, axes.contains(.horizontal),
           !hiddenIndicatorAxes.contains(.horizontal),
           let proposedWidth = proposedSize.width
        {
            hasHorizontalScrollBar = contentSize.width > proposedWidth
        } else {
            hasHorizontalScrollBar = false
        }
        children.hasHorizontalScrollBar = hasHorizontalScrollBar

        let hasVerticalScrollBar: Bool
        if showsIndicators, axes.contains(.vertical),
           !hiddenIndicatorAxes.contains(.vertical),
           let proposedHeight = proposedSize.height
        {
            hasVerticalScrollBar = contentSize.height > proposedHeight
        } else {
            hasVerticalScrollBar = false
        }
        children.hasVerticalScrollBar = hasVerticalScrollBar

        let scrollBarWidth = Double(backend.scrollBarWidth)
        let verticalScrollBarWidth = hasVerticalScrollBar ? scrollBarWidth : 0
        let horizontalScrollBarHeight = hasHorizontalScrollBar ? scrollBarWidth : 0

        // Compute the final size to propose to the child view. Subtract off
        // scroll bar sizes from non-scrolling axes.
        var finalContentSizeProposal = childProposal
        if !axes.contains(.horizontal), let proposedWidth = childProposal.width {
            finalContentSizeProposal.width = proposedWidth - verticalScrollBarWidth
        }

        if !axes.contains(.vertical), let proposedHeight = childProposal.height {
            finalContentSizeProposal.height = proposedHeight - horizontalScrollBarHeight
        }

        // Propose a final size to the child view.
        let finalChildResult = children.child.computeLayout(
            with: nil,
            proposedSize: finalContentSizeProposal,
            environment: contentEnvironment
        )

        // Compute the outer size.
        var outerSize = finalChildResult.size
        outerSize.width += margins.totals.x
        outerSize.height += margins.totals.y
        if axes.contains(.horizontal) {
            outerSize.width =
                proposedSize.width
                    ?? (outerSize.width + verticalScrollBarWidth)
        } else {
            outerSize.width += verticalScrollBarWidth
        }

        if axes.contains(.vertical) {
            outerSize.height =
                proposedSize.height
                    ?? (outerSize.height + horizontalScrollBarHeight)
        } else {
            outerSize.height += horizontalScrollBarHeight
        }

        return ViewLayoutResult(
            size: outerSize,
            childResults: [finalChildResult],
            participateInStackLayoutsWhenEmpty: true
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: ScrollViewChildren<Content>,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let scrollViewSize = layout.size
        let margins = children.contentMargins
        var finalContentSize = children.child.commit().size
        finalContentSize.width += margins.totals.x
        finalContentSize.height += margins.totals.y

        backend.setSize(of: widget, to: scrollViewSize.vector)
        backend.setSize(
            of: children.innerContainer.into(),
            to: SIMD2(
                max(finalContentSize.vector.x, scrollViewSize.vector.x),
                max(finalContentSize.vector.y, scrollViewSize.vector.y)
            )
        )

        let contentX: Double
        if finalContentSize.width < scrollViewSize.width {
            let alignment = axes.contains(.vertical)
                ? HorizontalAlignment.center : HorizontalAlignment.leading
            contentX = alignment.position(
                ofChild: finalContentSize.width,
                in: scrollViewSize.width
            )
        } else {
            contentX = 0
        }

        let contentY: Double
        if finalContentSize.height < scrollViewSize.height {
            let alignment = axes.contains(.horizontal)
                ? VerticalAlignment.center : VerticalAlignment.top
            contentY = alignment.position(
                ofChild: finalContentSize.height,
                in: scrollViewSize.height
            )
        } else {
            contentY = 0
        }

        backend.setPosition(
            ofChildAt: 0,
            in: children.innerContainer.into(),
            to: SIMD2(
                LayoutSystem.roundSize(contentX + margins.leading),
                LayoutSystem.roundSize(contentY + margins.top)
            )
        )

        // `scrollBounceBehavior(.basedOnSize)` only bounces content that
        // overflows.
        let bouncesBasedOnSize = environment.scrollBouncesBasedOnSizeAxes
        backend.updateScrollContainer(
            widget,
            environment: environment,
            bounceHorizontally: axes.contains(.horizontal)
                && (!bouncesBasedOnSize.contains(.horizontal)
                    || finalContentSize.width > scrollViewSize.width),
            bounceVertically: axes.contains(.vertical)
                && (!bouncesBasedOnSize.contains(.vertical)
                    || finalContentSize.height > scrollViewSize.height),
            hasHorizontalScrollBar: children.hasHorizontalScrollBar,
            hasVerticalScrollBar: children.hasVerticalScrollBar
        )

        children.scrollTargets.controller = ScrollController.make(
            backend: backend,
            widget: widget,
            viewportSize: SIMD2(scrollViewSize.width, scrollViewSize.height),
            contentSize: SIMD2(
                max(finalContentSize.width, scrollViewSize.width),
                max(finalContentSize.height, scrollViewSize.height)
            )
        )
        performScrollRequest(environment.scrollRequest, children: children)
        reportGeometry(
            to: environment.scrollGeometryObservers,
            children: children,
            viewportSize: scrollViewSize,
            contentSize: finalContentSize
        )
        reportVisibleTargets(to: environment.scrollTargetVisibilityObservers, children: children)
    }
}
