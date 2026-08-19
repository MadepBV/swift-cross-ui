import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend {
    public func createTapGestureTarget(wrapping child: Widget, gesture _: TapGesture) -> Widget {
        let container = NSView()

        container.addSubview(child)
        child.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        child.topAnchor.constraint(equalTo: container.topAnchor)
            .isActive = true
        child.translatesAutoresizingMaskIntoConstraints = false

        let tapGestureTarget = NSCustomTapGestureTarget()
        container.addSubview(tapGestureTarget)
        tapGestureTarget.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        tapGestureTarget.topAnchor.constraint(equalTo: container.topAnchor)
            .isActive = true
        tapGestureTarget.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            .isActive = true
        tapGestureTarget.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            .isActive = true
        tapGestureTarget.translatesAutoresizingMaskIntoConstraints = false

        return container
    }

    public func updateTapGestureTarget(
        _ container: Widget,
        gesture: TapGesture,
        environment: EnvironmentValues,
        action: @escaping () -> Void
    ) {
        let tapGestureTarget = container.subviews[1] as! NSCustomTapGestureTarget
        switch (gesture.kind, environment.isEnabled) {
            case (_, false):
                tapGestureTarget.leftClickHandler = nil
                tapGestureTarget.rightClickHandler = nil
                tapGestureTarget.longPressHandler = nil
            case (.primary, true):
                tapGestureTarget.leftClickHandler = action
                tapGestureTarget.rightClickHandler = nil
                tapGestureTarget.longPressHandler = nil
            case (.secondary, true):
                tapGestureTarget.leftClickHandler = nil
                tapGestureTarget.rightClickHandler = action
                tapGestureTarget.longPressHandler = nil
            case (.longPress, true):
                tapGestureTarget.leftClickHandler = nil
                tapGestureTarget.rightClickHandler = nil
                tapGestureTarget.longPressHandler = action
        }
    }

    public func createHoverTarget(wrapping child: Widget) -> Widget {
        let container = NSView()

        container.addSubview(child)
        child.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        child.topAnchor.constraint(equalTo: container.topAnchor)
            .isActive = true
        child.translatesAutoresizingMaskIntoConstraints = false

        let hoverGestureTarget = NSCustomHoverTarget()
        container.addSubview(hoverGestureTarget)
        hoverGestureTarget.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        hoverGestureTarget.topAnchor.constraint(equalTo: container.topAnchor)
            .isActive = true
        hoverGestureTarget.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            .isActive = true
        hoverGestureTarget.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            .isActive = true
        hoverGestureTarget.translatesAutoresizingMaskIntoConstraints = false

        return container
    }

    public func updateHoverTarget(
        _ container: Widget,
        environment: EnvironmentValues,
        action: @escaping (Bool) -> Void
    ) {
        let hoverGestureTarget = container.subviews[1] as! NSCustomHoverTarget
        hoverGestureTarget.hoverChangesHandler = action
    }
}

final class NSCustomTapGestureTarget: NSView {
    var leftClickHandler: (() -> Void)? {
        didSet {
            if leftClickHandler != nil && leftClickRecognizer == nil {
                let gestureRecognizer = NSClickGestureRecognizer(
                    target: self,
                    action: #selector(leftClick)
                )
                addGestureRecognizer(gestureRecognizer)
                leftClickRecognizer = gestureRecognizer
            } else if leftClickHandler == nil, let leftClickRecognizer {
                removeGestureRecognizer(leftClickRecognizer)
                self.leftClickRecognizer = nil
            }
        }
    }

    var rightClickHandler: (() -> Void)? {
        didSet {
            if rightClickHandler != nil && rightClickRecognizer == nil {
                let gestureRecognizer = NSClickGestureRecognizer(
                    target: self,
                    action: #selector(rightClick)
                )
                gestureRecognizer.buttonMask = 1 << 1
                addGestureRecognizer(gestureRecognizer)
                rightClickRecognizer = gestureRecognizer
            } else if rightClickHandler == nil, let rightClickRecognizer {
                removeGestureRecognizer(rightClickRecognizer)
                self.rightClickRecognizer = nil
            }
        }
    }

    var longPressHandler: (() -> Void)? {
        didSet {
            if longPressHandler != nil && longPressRecognizer == nil {
                let gestureRecognizer = NSPressGestureRecognizer(
                    target: self,
                    action: #selector(longPress)
                )
                // Both GTK and UIKit default to half a second for long presses
                gestureRecognizer.minimumPressDuration = 0.5
                addGestureRecognizer(gestureRecognizer)
                longPressRecognizer = gestureRecognizer
            } else if longPressHandler == nil, let longPressRecognizer {
                removeGestureRecognizer(longPressRecognizer)
                self.longPressRecognizer = nil
            }
        }
    }

    private var leftClickRecognizer: NSClickGestureRecognizer?
    private var rightClickRecognizer: NSClickGestureRecognizer?
    private var longPressRecognizer: NSPressGestureRecognizer?

    @objc
    func leftClick() {
        leftClickHandler?()
    }

    @objc
    func rightClick() {
        rightClickHandler?()
    }

    @objc
    func longPress(sender: NSPressGestureRecognizer) {
        // GTK emits the event once as soon as the gesture is recognized.
        // AppKit emits it twice, once when it's recognized and once when you release the mouse button.
        // For consistency, ignore the second event.
        if sender.state != .ended {
            longPressHandler?()
        }
    }
}

final class NSCustomHoverTarget: NSView {
    var hoverChangesHandler: ((Bool) -> Void)? {
        didSet {
            if hoverChangesHandler != nil && trackingArea == nil {
                setNewTrackingArea()
            } else if hoverChangesHandler == nil, let trackingArea {
                removeTrackingArea(trackingArea)
                self.trackingArea = nil
            }
        }
    }

    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        setNewTrackingArea()
    }

    override func mouseEntered(with event: NSEvent) {
        hoverChangesHandler?(true)
    }

    override func mouseExited(with event: NSEvent) {
        hoverChangesHandler?(false)
    }

    private func setNewTrackingArea() {
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeInKeyWindow,
        ]
        let area = NSTrackingArea(
            rect: self.bounds,
            options: options,
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }
}

// MARK: - Pointer gestures

extension AppKitBackend: BackendFeatures.PointerGestures {
    public func createPointerGestureTarget(wrapping child: Widget) -> Widget {
        let container = NSView()

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
        tapCount: Int,
        coordinateSpace: SwiftCrossUI.CoordinateSpace,
        environment: EnvironmentValues,
        onDragChanged: (@MainActor (PointerGestureEvent) -> Void)?,
        onDragEnded: (@MainActor (PointerGestureEvent) -> Void)?,
        onTap: (@MainActor (PointerGestureEvent) -> Void)?
    ) {
        let target = container.subviews[1] as! NSCustomPointerGestureTarget
        target.minimumDragDistance = minimumDragDistance
        target.reportsWindowCoordinates = coordinateSpace == .global

        guard environment.isEnabled else {
            target.dragChangedHandler = nil
            target.dragEndedHandler = nil
            target.tapHandler = nil
            return
        }

        target.dragChangedHandler = onDragChanged
        target.dragEndedHandler = onDragEnded
        target.tapHandler = onTap
        target.tapCount = tapCount
    }
}

/// The view that `AppKitBackend` recognizes drags and spatial taps on.
///
/// It is flipped so that `location(in:)` hands back SwiftCrossUI's
/// top-leading-origin coordinates rather than AppKit's bottom-leading ones.
final class NSCustomPointerGestureTarget: NSView {
    /// How far the pointer must move from where it went down before a drag
    /// starts being reported.
    var minimumDragDistance: Double = 0.0

    /// How many clicks in quick succession ``tapHandler`` needs.
    var tapCount: Int = 1 {
        didSet {
            clickRecognizer?.numberOfClicksRequired = tapCount
        }
    }

    /// Whether positions are reported in window coordinates rather than in
    /// this view's own.
    var reportsWindowCoordinates = false

    /// The action to run each time a recognized drag moves.
    var dragChangedHandler: (@MainActor (PointerGestureEvent) -> Void)? {
        didSet {
            updatePanRecognizer()
        }
    }

    /// The action to run when a recognized drag finishes.
    var dragEndedHandler: (@MainActor (PointerGestureEvent) -> Void)? {
        didSet {
            updatePanRecognizer()
        }
    }

    /// The action to run when a click is recognized.
    var tapHandler: (@MainActor (PointerGestureEvent) -> Void)? {
        didSet {
            if tapHandler != nil, clickRecognizer == nil {
                let recognizer = NSClickGestureRecognizer(
                    target: self,
                    action: #selector(click)
                )
                recognizer.numberOfClicksRequired = tapCount
                addGestureRecognizer(recognizer)
                clickRecognizer = recognizer
            } else if tapHandler == nil, let clickRecognizer {
                removeGestureRecognizer(clickRecognizer)
                self.clickRecognizer = nil
            }
        }
    }

    private var panRecognizer: NSPanGestureRecognizer?
    private var clickRecognizer: NSClickGestureRecognizer?

    /// Where the pointer was when the current drag began.
    private var dragStartLocation: CGPoint?

    /// Whether the current drag has passed ``minimumDragDistance`` yet.
    private var dragIsRecognized = false

    /// SwiftCrossUI lays out from the top-leading corner, so report positions
    /// from there too.
    override var isFlipped: Bool { true }

    /// Lets pointer events through to the widgets below while no gesture is
    /// attached, so that an inert target never breaks what's underneath it.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard
            dragChangedHandler != nil || dragEndedHandler != nil
                || tapHandler != nil
        else {
            return nil
        }
        return super.hitTest(point)
    }

    /// Adds or removes the pan recognizer to match the drag handlers.
    private func updatePanRecognizer() {
        let wantsDrag = dragChangedHandler != nil || dragEndedHandler != nil
        if wantsDrag, panRecognizer == nil {
            let recognizer = NSPanGestureRecognizer(
                target: self,
                action: #selector(pan)
            )
            addGestureRecognizer(recognizer)
            panRecognizer = recognizer
        } else if !wantsDrag, let panRecognizer {
            removeGestureRecognizer(panRecognizer)
            self.panRecognizer = nil
        }
    }

    /// Converts a recognizer's position into the space the gesture asked for.
    ///
    /// - Parameter recognizer: The recognizer to read.
    /// - Returns: The pointer's position.
    private func location(of recognizer: NSGestureRecognizer) -> CGPoint {
        let local = recognizer.location(in: self)
        guard reportsWindowCoordinates, let contentView = window?.contentView
        else {
            return local
        }
        let converted = convert(local, to: contentView)
        guard !contentView.isFlipped else {
            return converted
        }
        return CGPoint(
            x: converted.x,
            y: contentView.bounds.height - converted.y
        )
    }

    /// Builds an event describing where a drag is now.
    ///
    /// - Parameters:
    ///   - recognizer: The recognizer driving the drag.
    ///   - start: Where the drag began.
    /// - Returns: The event to hand to SwiftCrossUI.
    private func event(
        for recognizer: NSPanGestureRecognizer,
        start: CGPoint
    ) -> PointerGestureEvent {
        let velocity = recognizer.velocity(in: self)
        return PointerGestureEvent(
            startLocation: start,
            location: location(of: recognizer),
            time: Date(),
            velocity: CGSize(width: velocity.x, height: velocity.y)
        )
    }

    /// Driven by the gesture recognizer. Not private so that tests
    /// can replay a gesture without synthesising real mouse events.
    @objc
    func pan(sender: NSPanGestureRecognizer) {
        switch sender.state {
            case .began:
                dragStartLocation = location(of: sender)
                dragIsRecognized = minimumDragDistance <= 0.0
            case .changed:
                guard let start = dragStartLocation else {
                    return
                }
                let current = location(of: sender)
                if !dragIsRecognized {
                    let dx = current.x - start.x
                    let dy = current.y - start.y
                    guard
                        (dx * dx + dy * dy).squareRoot()
                            >= minimumDragDistance
                    else {
                        return
                    }
                    dragIsRecognized = true
                }
                dragChangedHandler?(event(for: sender, start: start))
            case .ended:
                defer {
                    dragStartLocation = nil
                    dragIsRecognized = false
                }
                guard let start = dragStartLocation, dragIsRecognized else {
                    return
                }
                dragEndedHandler?(event(for: sender, start: start))
            default:
                // A cancelled or failed drag never happened, so no handler
                // runs; SwiftUI doesn't call `onEnded` for one either.
                dragStartLocation = nil
                dragIsRecognized = false
        }
    }

    /// Driven by the gesture recognizer. Not private so that tests
    /// can replay a gesture without synthesising real mouse events.
    @objc
    func click(sender: NSClickGestureRecognizer) {
        let point = location(of: sender)
        tapHandler?(
            PointerGestureEvent(startLocation: point, location: point)
        )
    }
}
