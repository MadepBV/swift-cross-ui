import Foundation

/// A built-in stack layout, which a ``LayoutView`` lays out with the
/// corresponding stack view rather than through the ``Layout`` protocol, so
/// that it gets the stack's full layout algorithm (flexibility, layout
/// priorities, alignment guides and ``ForEach`` handling).
@MainActor
protocol BuiltinStackLayout: Layout {
    /// The stack view that lays out the given content.
    func stack<StackContent: View>(content: StackContent) -> any View
}

extension BuiltinStackLayout {
    func computeStackLayout<StackContent: View, Backend: BaseAppBackend>(
        content: StackContent,
        widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        stack(content: content).computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
    }

    func commitStackLayout<StackContent: View, Backend: BaseAppBackend>(
        content: StackContent,
        widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        stack(content: content).commit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )
    }
}

/// A horizontal container that you can use in conditional layouts.
///
/// Laid out by ``HStack``'s algorithm when used as a container. Its
/// ``Layout`` methods, for calling from another layout, implement a simple
/// stack: each subview at its ideal width, aligned by size.
public struct HStackLayout: BuiltinStackLayout {
    /// The vertical alignment of subviews.
    public var alignment: VerticalAlignment
    /// The distance between adjacent subviews, or `nil` for the default.
    public var spacing: CGFloat?

    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    func stack<StackContent: View>(content: StackContent) -> any View {
        HStack(
            alignment: alignment,
            spacing: spacing.map { LayoutSystem.roundSize(Double($0)) },
            content: content
        )
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        SimpleStack(orientation: .horizontal, spacing: spacing)
            .size(of: subviews, proposal: proposal)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        SimpleStack(orientation: .horizontal, spacing: spacing).place(
            subviews,
            in: bounds,
            proposal: proposal,
            perpendicularPosition: { size, extent in
                alignment.position(ofChild: size, in: extent)
            }
        )
    }
}

/// A vertical container that you can use in conditional layouts.
///
/// Laid out by ``VStack``'s algorithm when used as a container. Its
/// ``Layout`` methods, for calling from another layout, implement a simple
/// stack: each subview at its ideal height, aligned by size.
public struct VStackLayout: BuiltinStackLayout {
    /// The horizontal alignment of subviews.
    public var alignment: HorizontalAlignment
    /// The distance between adjacent subviews, or `nil` for the default.
    public var spacing: CGFloat?

    public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    func stack<StackContent: View>(content: StackContent) -> any View {
        VStack(
            alignment: alignment,
            spacing: spacing.map { LayoutSystem.roundSize(Double($0)) },
            content: content
        )
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        SimpleStack(orientation: .vertical, spacing: spacing)
            .size(of: subviews, proposal: proposal)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        SimpleStack(orientation: .vertical, spacing: spacing).place(
            subviews,
            in: bounds,
            proposal: proposal,
            perpendicularPosition: { size, extent in
                alignment.position(ofChild: size, in: extent)
            }
        )
    }
}

/// An overlaying container that you can use in conditional layouts.
///
/// Laid out by ``ZStack``'s algorithm when used as a container.
public struct ZStackLayout: BuiltinStackLayout {
    /// The alignment of subviews.
    public var alignment: Alignment

    public init(alignment: Alignment = .center) {
        self.alignment = alignment
    }

    func stack<StackContent: View>(content: StackContent) -> any View {
        ZStack(alignment: alignment, content: content)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        subviews.reduce(CGSize(width: 0, height: 0)) { size, subview in
            let subviewSize = subview.sizeThatFits(proposal)
            return CGSize(
                width: max(size.width, subviewSize.width),
                height: max(size.height, subviewSize.height)
            )
        }
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            let x = alignment.horizontal.position(
                ofChild: Double(size.width),
                in: Double(bounds.size.width)
            )
            let y = alignment.vertical.position(
                ofChild: Double(size.height),
                in: Double(bounds.size.height)
            )
            subview.place(
                at: CGPoint(x: Double(bounds.origin.x) + x, y: Double(bounds.origin.y) + y),
                proposal: ProposedViewSize(size)
            )
        }
    }
}

/// The ``Layout`` protocol behaviour shared by ``HStackLayout`` and
/// ``VStackLayout`` when another layout calls them directly.
@MainActor
private struct SimpleStack {
    var orientation: Orientation
    var spacing: CGFloat?

    private var resolvedSpacing: Double {
        spacing.map { Double($0) } ?? Double(VStack<EmptyView>.defaultSpacing)
    }

    private func proposal(perpendicularTo proposal: ProposedViewSize) -> ProposedViewSize {
        var childProposal = ProposedViewSize.unspecified
        childProposal[component: orientation.perpendicular] =
            proposal[component: orientation.perpendicular]
        return childProposal
    }

    func size(of subviews: LayoutSubviews, proposal: ProposedViewSize) -> CGSize {
        let childProposal = self.proposal(perpendicularTo: proposal)
        var length = 0.0
        var extent = 0.0
        for subview in subviews {
            let size = ViewSize(subview.sizeThatFits(childProposal))
            length += size[component: orientation]
            extent = max(extent, size[component: orientation.perpendicular])
        }
        length += resolvedSpacing * Double(max(subviews.count - 1, 0))
        var size = ViewSize.zero
        size[component: orientation] = length
        size[component: orientation.perpendicular] = extent
        return CGSize(width: size.width, height: size.height)
    }

    func place(
        _ subviews: LayoutSubviews,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        perpendicularPosition: (Double, Double) -> Double
    ) {
        let childProposal = self.proposal(perpendicularTo: proposal)
        let origin = Position(Double(bounds.origin.x), Double(bounds.origin.y))
        let boundsSize = ViewSize(bounds.size)
        var position = origin
        for subview in subviews {
            let size = ViewSize(subview.sizeThatFits(childProposal))
            position[component: orientation.perpendicular] =
                origin[component: orientation.perpendicular]
                + perpendicularPosition(
                    size[component: orientation.perpendicular],
                    boundsSize[component: orientation.perpendicular]
                )
            subview.place(
                at: CGPoint(x: position.x, y: position.y),
                proposal: ProposedViewSize(size)
            )
            position[component: orientation] += size[component: orientation] + resolvedSpacing
        }
    }
}
