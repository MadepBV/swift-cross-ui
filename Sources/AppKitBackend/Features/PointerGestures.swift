import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.PointerGestures {
    public func createPointerGestureTarget(wrapping child: Widget) -> Widget {
        let container = NSLayoutContainerView()

        container.addSubview(child)
        child.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        child.topAnchor.constraint(equalTo: container.topAnchor)
            .isActive = true
        child.translatesAutoresizingMaskIntoConstraints = false

        let pointerGestureTarget = NSCustomPointerGestureTarget()
        container.addSubview(pointerGestureTarget)
        pointerGestureTarget.leadingAnchor
            .constraint(equalTo: container.leadingAnchor).isActive = true
        pointerGestureTarget.topAnchor
            .constraint(equalTo: container.topAnchor).isActive = true
        pointerGestureTarget.trailingAnchor
            .constraint(equalTo: container.trailingAnchor).isActive = true
        pointerGestureTarget.bottomAnchor
            .constraint(equalTo: container.bottomAnchor).isActive = true
        pointerGestureTarget.translatesAutoresizingMaskIntoConstraints = false

        return container
    }

    public func updatePointerGestureTarget(
        _ container: Widget,
        minimumDragDistance: Double,
        dragButtons: PointerButtons,
        tapCount: Int,
        coordinateSpace: SwiftCrossUI.CoordinateSpace,
        environment: EnvironmentValues,
        onDragChanged: (@MainActor (PointerGestureEvent) -> Void)?,
        onDragEnded: (@MainActor (PointerGestureEvent) -> Void)?,
        onTap: (@MainActor (PointerGestureEvent) -> Void)?,
        onScroll: (@MainActor (PointerScrollEvent) -> Void)?,
        onMagnify: (@MainActor (PointerMagnifyEvent) -> Void)?,
        onMove: (@MainActor (PointerMoveEvent) -> Void)?
    ) {
        let target = container.subviews[1] as! NSCustomPointerGestureTarget
        target.minimumDragDistance = minimumDragDistance
        target.dragButtons = dragButtons
        target.reportsWindowCoordinates = coordinateSpace == .global

        guard environment.isEnabled else {
            target.dragChangedHandler = nil
            target.dragEndedHandler = nil
            target.tapHandler = nil
            target.scrollHandler = nil
            target.magnifyHandler = nil
            target.moveHandler = nil
            return
        }

        target.dragChangedHandler = onDragChanged
        target.dragEndedHandler = onDragEnded
        target.tapHandler = onTap
        target.tapCount = tapCount
        target.scrollHandler = onScroll
        target.magnifyHandler = onMagnify
        target.moveHandler = onMove
    }
}
