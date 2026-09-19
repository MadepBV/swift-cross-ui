/// Horizontal peer panes with draggable dividers on backends supporting
/// ``BackendFeatures/PointerGestures`` (including AppKit and WinUI).
///
/// Each pane's minimum, ideal and maximum widths come from its sizing behavior,
/// including `frame(minWidth:idealWidth:maxWidth:)`. Flexible panes take spare
/// width before bounded panes grow beyond their ideal or user-selected width.
/// Dividers overlay the boundary, so they do not add spacing between panes.
///
/// Setting a pane's maximum width to zero hides its divider without removing
/// the pane or forgetting its user-selected width. If the window is narrower
/// than the sum of the pane minimums, those minimums take precedence.
/// Immediate builder children are panes: a Group, ForEach or conditional
/// remains one pane, retaining its own dynamic content and widget identity.
/// Pane width bounds replace stack layoutPriority as the allocation rule.
/// Backends without pointer gestures and per-drag event identifiers retain the
/// layout without resizing. The bundled AppKit and WinUI backends provide both.
public struct HSplitView<Content: View>: View {
    public var body: Content

    public init(@ViewBuilder content: () -> Content) {
        body = content()
    }

    public func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        HorizontalSplitChildren(panes: defaultChildren(
            backend: backend, snapshots: snapshots, environment: environment))
    }

    public func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend, children: any ViewGraphNodeChildren
    ) -> [LayoutSystem.LayoutableChild] {
        defaultLayoutableChildren(backend: backend, children: (children as! HorizontalSplitChildren).panes)
    }

    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren, backend: Backend
    ) -> Backend.Widget {
        let children = children as! HorizontalSplitChildren
        let container = backend.createContainer()
        for (index, pane) in children.widgets(for: backend).enumerated() {
            backend.insert(pane, into: container, at: index)
        }
        func installDividers<B: BaseAppBackend & BackendFeatures.PointerGestures & BackendFeatures.Colors>(_ backend: B) {
            let container = container as! B.Widget
            for index in 0..<max(0, children.widgets.count - 1) {
                let slot = backend.createContainer()
                let line = backend.createColorableRectangle()
                backend.insert(line, into: slot, at: 0)
                let target = backend.createPointerGestureTarget(wrapping: slot)
                backend.insert(target, into: container, at: children.widgets.count + index)
                children.dividers.append(.init(target: AnyWidget(target), slot: AnyWidget(slot), line: AnyWidget(line)))
            }
        }
        if let pointerBackend = backend as? any BaseAppBackend & BackendFeatures.PointerGestures & BackendFeatures.Colors {
            installDividers(pointerBackend)
        }
        return container
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget, children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize, environment: EnvironmentValues, backend: Backend
    ) -> ViewLayoutResult {
        let children = children as! HorizontalSplitChildren
        let panes = layoutableChildren(backend: backend, children: children)
        let environment = environment.with(\.containerChildLayout, nil)
            .withStackLayout(orientation: .horizontal, alignment: VerticalAlignment.center.asStackAlignment, spacing: 0)
        let probing = environment.with(\.allowLayoutCaching, true)
        let bounds = panes.map { pane in
            HorizontalSplitLayout.Bounds(
                minimum: pane.computeLayout(proposedSize: .init(0, proposedSize.height), environment: probing).size.width,
                ideal: pane.computeLayout(proposedSize: .init(nil, proposedSize.height), environment: probing).size.width,
                maximum: pane.computeLayout(proposedSize: .init(.infinity, proposedSize.height), environment: probing).size.width)
        }
        let widths = HorizontalSplitLayout.widths(bounds: bounds, preferred: children.preferredWidths,
            available: proposedSize.width)
        let results = panes.enumerated().map { index, pane in
            pane.computeLayout(proposedSize: .init(widths[index], proposedSize.height), environment: environment)
        }
        if !environment.allowLayoutCaching {
            children.bounds = bounds
            // computeLayout receives this node's own invalidation handler;
            // commit receives its parent environment instead.
            children.onResize = environment.onResize
        }
        return ViewLayoutResult(size: ViewSize(results.reduce(0) { $0 + $1.size.width },
            results.filter { $0.size.width > 0 }.map(\.size.height).max() ?? 0), childResults: results,
            participateInStackLayoutsWhenEmpty: results.contains(where: \.participateInStackLayoutsWhenEmpty))
    }

    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget, children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult, environment: EnvironmentValues, backend: Backend
    ) {
        let children = children as! HorizontalSplitChildren
        let results = layoutableChildren(backend: backend, children: children).map { $0.commit() }
        children.didCommit(widths: results.map(\.size.width), enabled: environment.isEnabled)
        backend.setSize(of: widget, to: layout.size.vector)
        var x = 0.0
        var boundaries: [Double] = []
        for (index, result) in results.enumerated() {
            backend.setPosition(ofChildAt: index, in: widget,
                to: SIMD2(LayoutSystem.roundSize(x), LayoutSystem.roundSize((layout.size.height - result.size.height) / 2)))
            x += result.size.width
            boundaries.append(x)
        }

        func updateDividers<B: BaseAppBackend & BackendFeatures.PointerGestures & BackendFeatures.Colors>(_ backend: B) {
            for (left, divider) in children.dividers.enumerated() {
                let right = results.indices.first { $0 > left && results[$0].size.width > 0 }
                let visible = environment.isEnabled && children.committedWidths.indices.contains(left)
                    && children.committedWidths[left] > 0 && right != nil
                // A six-point strip is the only gesture target. Pane contents
                // are siblings, never descendants of a divider target.
                let leadingHalf = visible ? min(3, children.committedWidths[left]) : 0
                let trailingHalf = visible ? min(3, children.committedWidths[right!]) : 0
                let width = leadingHalf + trailingHalf
                let height = visible ? layout.size.height : 0
                let target: B.Widget = divider.target.into()
                let slot: B.Widget = divider.slot.into()
                let line: B.Widget = divider.line.into()
                backend.setSize(of: target, to: SIMD2(LayoutSystem.roundSize(width), LayoutSystem.roundSize(height)))
                backend.setSize(of: slot, to: SIMD2(LayoutSystem.roundSize(width), LayoutSystem.roundSize(height)))
                backend.setSize(of: line, to: SIMD2(visible ? 1 : 0, LayoutSystem.roundSize(height)))
                backend.setColor(ofColorableRectangle: line, to: Color.gray.opacity(0.4).resolve(in: environment))
                backend.setPosition(ofChildAt: 0, in: slot, to: SIMD2(LayoutSystem.roundSize(leadingHalf), 0))
                backend.setPosition(ofChildAt: results.count + left, in: widget as! B.Widget,
                    to: SIMD2(visible ? LayoutSystem.roundSize(boundaries[left] - leadingHalf) : 0, 0))
                var changed: (@MainActor (PointerGestureEvent) -> Void)?
                var ended: (@MainActor (PointerGestureEvent) -> Void)?
                if visible, let right {
                    changed = { [weak children] event in
                        children?.receiveDrag(event, left: left, right: right, ended: false)
                    }
                    ended = { [weak children] event in
                        children?.receiveDrag(event, left: left, right: right, ended: true)
                    }
                }
                backend.updatePointerGestureTarget(target, minimumDragDistance: 0, dragButtons: .primary,
                    tapCount: 1, coordinateSpace: .global, environment: environment,
                    onDragChanged: changed, onDragEnded: ended, onTap: nil, onScroll: nil, onMagnify: nil, onMove: nil)
            }
        }
        if let pointerBackend = backend as? any BaseAppBackend & BackendFeatures.PointerGestures & BackendFeatures.Colors {
            updateDividers(pointerBackend)
        }
    }
}

@MainActor
final class HorizontalSplitChildren: ViewGraphNodeChildren {
    struct Divider {
        let target: AnyWidget
        let slot: AnyWidget
        let line: AnyWidget
    }
    let panes: any ViewGraphNodeChildren
    var dividers: [Divider] = []
    var bounds: [HorizontalSplitLayout.Bounds] = []
    var committedWidths: [Double] = []
    var preferredWidths: [Int: Double] = [:]
    var onResize: (@MainActor (ViewSize) -> Void)?
    private var isEnabled = true
    private struct Drag {
        let id: UInt64
        let left: Int
        let right: Int
        let initialWidths: [Double]
        let bounds: [HorizontalSplitLayout.Bounds]
    }
    private var drag: Drag?
    private var ignoredDrag: (left: Int, id: UInt64)?
    var widgets: [AnyWidget] { panes.widgets }
    var erasedNodes: [ErasedViewGraphNode] { panes.erasedNodes }

    init(panes: any ViewGraphNodeChildren) { self.panes = panes }

    func didCommit(widths: [Double], enabled: Bool) {
        if let drag, !enabled || drag.bounds != bounds
            || abs(widths.reduce(0, +) - drag.initialWidths.reduce(0, +)) > 0.000_001 {
            // An external pane/window change invalidates the drag's anchor.
            // Ignore its remaining queued samples until a different press.
            ignoredDrag = (drag.left, drag.id)
            self.drag = nil
        }
        committedWidths = widths
        isEnabled = enabled
    }

    func receiveDrag(_ event: PointerGestureEvent, left: Int, right: Int, ended: Bool) {
        guard isEnabled, let id = event.interactionID,
            event.button == .primary,
            !(ignoredDrag?.left == left && ignoredDrag?.id == id),
            committedWidths.indices.contains(left), committedWidths.indices.contains(right),
            committedWidths[left] > 0, committedWidths[right] > 0 else { return }
        let delta = Double(event.location.x - event.startLocation.x)
        guard delta.isFinite else { return }
        if drag?.id != id || drag?.left != left || drag?.right != right {
            drag = Drag(id: id, left: left, right: right,
                initialWidths: committedWidths, bounds: bounds)
        }
        guard let current = drag else { return }
        if let moved = HorizontalSplitLayout.movedWidths(current.initialWidths, bounds: bounds,
            left: left, right: right, delta: delta),
            moved[left] != committedWidths[left] || moved[right] != committedWidths[right] {
            // Freeze the untouched visible peers too. Otherwise a third
            // flexible pane would be redistributed from its original ideal
            // when only the dragged pair had remembered widths.
            for index in moved.indices where bounds[index].maximum > 0 {
                preferredWidths[index] = moved[index]
            }
            onResize?(.zero)
        }
        if ended {
            ignoredDrag = (left, id)
            drag = nil
        }
    }
}
