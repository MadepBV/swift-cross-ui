import Foundation

/// What a ``ScrollView`` does after committing: carrying out scroll requests
/// and reporting its geometry and visible views to the observers around it.
extension ScrollView {
    /// Carries out the request of a ``View/scrollPosition(_:)`` or
    /// ``View/scrollPosition(id:anchor:)`` around this scroll view, once per
    /// request.
    ///
    /// - Parameters:
    ///   - request: The request, if any.
    ///   - children: The scroll view's children.
    func performScrollRequest(
        _ request: ScrollRequest?,
        children: ScrollViewChildren<Content>,
        viewportSize: SIMD2<Double>
    ) {
        guard let request, let controller = children.scrollTargets.controller else {
            return
        }
        // A resize moves content laid out by the viewport's size (the pages
        // of a paging carousel) out from under an unchanged offset, so the
        // request is applied again, keeping its target where it was, as in
        // SwiftUI.
        guard request.identity != children.lastScrollRequest
            || viewportSize != children.lastScrollRequestViewport
        else {
            return
        }
        children.lastScrollRequest = request.identity
        children.lastScrollRequestViewport = viewportSize
        request.apply(controller, children.scrollTargets)
    }

    /// Reports which identified views are visible to the
    /// ``View/onScrollTargetVisibilityChange(idType:threshold:_:)``s around
    /// this scroll view.
    ///
    /// - Parameters:
    ///   - observers: The observers.
    ///   - children: The scroll view's children.
    func reportVisibleTargets(
        to observers: [ScrollTargetVisibilityObserver],
        children: ScrollViewChildren<Content>
    ) {
        let previous = children.reportedVisibleTargets
        children.reportedVisibleTargets = observers.indices.map { index in
            let observer = observers[index]
            let visible = children.scrollTargets.visibleTargets(
                ofType: observer.idType,
                threshold: observer.threshold
            )
            return observer.report(visible, previous.indices.contains(index) ? previous[index] : nil)
        }
    }

    /// Reports this scroll view's geometry to the
    /// ``View/onScrollGeometryChange(for:of:action:)``s around it.
    ///
    /// - Parameters:
    ///   - observers: The observers.
    ///   - children: The scroll view's children.
    ///   - viewportSize: The size of the visible region.
    ///   - contentSize: The size of the content, margins included.
    func reportGeometry(
        to observers: [ScrollGeometryObserver],
        children: ScrollViewChildren<Content>,
        viewportSize: ViewSize,
        contentSize: ViewSize
    ) {
        guard !observers.isEmpty else {
            children.reportedGeometryValues = []
            return
        }
        let offset = children.scrollTargets.controller?.currentOffset() ?? .zero
        let margins = children.contentMargins
        let geometry = ScrollGeometry(
            contentOffset: CGPoint(x: offset.x, y: offset.y),
            contentSize: CGSize(
                width: max(contentSize.width, viewportSize.width),
                height: max(contentSize.height, viewportSize.height)
            ),
            contentInsets: ScrollGeometry.Insets(
                top: margins.top,
                leading: margins.leading,
                bottom: margins.bottom,
                trailing: margins.trailing
            ),
            containerSize: CGSize(width: viewportSize.width, height: viewportSize.height)
        )
        let previous = children.reportedGeometryValues
        children.reportedGeometryValues = observers.indices.map { index in
            observers[index].report(geometry, previous.indices.contains(index) ? previous[index] : nil)
        }
    }
}
