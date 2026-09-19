import AppKit
@_spi(Backends) import SwiftCrossUI

/// The view that `AppKitBackend` recognizes drags, spatial taps, scroll
/// wheel scrolling, pinches and button-less pointer movement on.
///
/// It is flipped so that `location(in:)` hands back SwiftCrossUI's
/// top-leading-origin coordinates rather than AppKit's bottom-leading ones.
final class NSCustomPointerGestureTarget: NSView {
    /// How far the pointer must move from where it went down before a drag
    /// starts being reported.
    var minimumDragDistance: Double = 0.0

    /// The largest click count any tap gesture needs.
    ///
    /// Unused on AppKit: the click recognizer fires for every click and
    /// reports `NSEvent.clickCount`, which is what SwiftCrossUI routes on.
    var tapCount: Int = 1

    /// The buttons a drag may be made with.
    var dragButtons: PointerButtons = .primary {
        didSet {
            panRecognizer?.buttonMask = dragButtons.appKitButtonMask
        }
    }

    /// The button the current drag is being made with.
    private var dragButton: PointerButton = .primary

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
                    action: #selector(click(sender:))
                )
                // Every click is reported with its count; a double click
                // arrives as a click with `clickCount` 1 and then one with 2.
                recognizer.numberOfClicksRequired = 1
                addGestureRecognizer(recognizer)
                clickRecognizer = recognizer
            } else if tapHandler == nil, let clickRecognizer {
                removeGestureRecognizer(clickRecognizer)
                self.clickRecognizer = nil
            }
        }
    }

    /// The action to run for each scroll wheel or trackpad scroll step.
    ///
    /// While `nil`, scroll events are passed up the responder chain so that
    /// an enclosing scroll view still scrolls.
    var scrollHandler: (@MainActor (PointerScrollEvent) -> Void)?

    /// The action to run for each step of a trackpad pinch.
    var magnifyHandler: (@MainActor (PointerMagnifyEvent) -> Void)? {
        didSet {
            if magnifyHandler != nil, magnificationRecognizer == nil {
                let recognizer = NSMagnificationGestureRecognizer(
                    target: self,
                    action: #selector(magnify(sender:))
                )
                addGestureRecognizer(recognizer)
                magnificationRecognizer = recognizer
            } else if magnifyHandler == nil, let magnificationRecognizer {
                removeGestureRecognizer(magnificationRecognizer)
                self.magnificationRecognizer = nil
            }
        }
    }

    /// The action to run for each mouse move with no button held, and once
    /// with ``HoverPhase/ended`` when the mouse leaves.
    ///
    /// Moves are only delivered while a tracking area is installed, which
    /// is the case exactly while this is non-`nil`.
    var moveHandler: (@MainActor (PointerMoveEvent) -> Void)? {
        didSet {
            if moveHandler != nil, trackingArea == nil {
                installTrackingArea()
            } else if moveHandler == nil, let trackingArea {
                removeTrackingArea(trackingArea)
                self.trackingArea = nil
            }
        }
    }

    private var panRecognizer: NSPanGestureRecognizer?
    private var clickRecognizer: NSClickGestureRecognizer?
    private var magnificationRecognizer: NSMagnificationGestureRecognizer?
    private var trackingArea: NSTrackingArea?

    /// Whether the last move reported the pointer as inside, so that leaving
    /// is reported exactly once.
    private var pointerIsInside = false

    /// Where the pointer was when the current drag began.
    private var dragStartLocation: CGPoint?

    /// Per-target identity distinguishes a new press after cancellation.
    private var dragInteractionID: UInt64 = 0

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
            || tapHandler != nil || scrollHandler != nil
            || magnifyHandler != nil || moveHandler != nil
        else {
            return nil
        }
        return super.hitTest(point)
    }

    /// Installs the tracking area that turns mouse movement into events.
    ///
    /// `inVisibleRect` keeps the area in step with the view's bounds, so it
    /// doesn't have to be rebuilt when the view resizes.
    private func installTrackingArea() {
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        reportMove(of: event)
    }

    /// Delivers a button-less move to ``moveHandler``. Not private so that
    /// tests can replay a move without a running event loop.
    override func mouseMoved(with event: NSEvent) {
        reportMove(of: event)
    }

    override func mouseExited(with event: NSEvent) {
        guard let moveHandler, pointerIsInside else {
            return
        }
        pointerIsInside = false
        moveHandler(
            PointerMoveEvent(
                phase: .ended,
                modifiers: PointerModifiers(event.modifierFlags),
                time: Date()
            )
        )
    }

    /// Reports where a mouse event puts the pointer.
    ///
    /// - Parameter event: The move or enter event.
    private func reportMove(of event: NSEvent) {
        guard let moveHandler else {
            return
        }
        pointerIsInside = true
        moveHandler(
            PointerMoveEvent(
                phase: .active(reported(convert(event.locationInWindow, from: nil))),
                modifiers: PointerModifiers(event.modifierFlags),
                time: Date()
            )
        )
    }

    /// Delivers a scroll wheel or trackpad scroll to ``scrollHandler``, or
    /// passes it on to the next responder while there is none.
    override func scrollWheel(with event: NSEvent) {
        guard let scrollHandler else {
            super.scrollWheel(with: event)
            return
        }

        let phase: PointerEventPhase
        if event.phase.contains(.began) {
            phase = .began
        } else if event.phase.contains(.cancelled) {
            phase = .cancelled
        } else if event.phase.contains(.ended) || event.momentumPhase.contains(.ended) {
            phase = .ended
        } else {
            // Discrete wheel notches have no phase at all, and momentum
            // scrolling is a continuation of the swipe that started it.
            phase = .changed
        }

        scrollHandler(
            PointerScrollEvent(
                location: reported(convert(event.locationInWindow, from: nil)),
                deltaX: Double(event.scrollingDeltaX),
                deltaY: Double(event.scrollingDeltaY),
                isPrecise: event.hasPreciseScrollingDeltas,
                phase: phase,
                modifiers: PointerModifiers(event.modifierFlags),
                time: Date()
            )
        )
    }

    /// Adds or removes the pan recognizer to match the drag handlers.
    private func updatePanRecognizer() {
        let wantsDrag = dragChangedHandler != nil || dragEndedHandler != nil
        if wantsDrag, panRecognizer == nil {
            let recognizer = NSPanGestureRecognizer(
                target: self,
                action: #selector(pan(sender:))
            )
            recognizer.buttonMask = dragButtons.appKitButtonMask
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
        reported(recognizer.location(in: self))
    }

    /// Converts a position in this view's (flipped) coordinates into the
    /// space the gesture asked for.
    ///
    /// - Parameter local: The position in this view's coordinates.
    /// - Returns: The position to report.
    private func reported(_ local: CGPoint) -> CGPoint {
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
            velocity: CGSize(width: velocity.x, height: velocity.y),
            modifiers: PointerModifiers(NSEvent.modifierFlags),
            button: dragButton,
            interactionID: dragInteractionID
        )
    }

    /// The button behind the event AppKit is currently delivering.
    private static var currentButton: PointerButton {
        guard let event = NSApp.currentEvent else {
            return .primary
        }
        switch event.buttonNumber {
            case 0: return .primary
            case 1: return .secondary
            default: return .middle
        }
    }

    /// Driven by the gesture recognizer. Not private so that tests
    /// can replay a gesture without synthesising real mouse events.
    @objc
    func pan(sender: NSPanGestureRecognizer) {
        pan(sender: sender, button: Self.currentButton)
    }

    /// Replays a pan made with a given button. Not private so that tests can
    /// drive it without an `NSApp.currentEvent`.
    func pan(sender: NSPanGestureRecognizer, button: PointerButton) {
        switch sender.state {
            case .began:
                dragInteractionID &+= 1
                dragButton = button
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
        click(sender: sender, clickCount: NSApp.currentEvent?.clickCount ?? 1)
    }

    /// Replays a click with a given count. Not private so that tests can
    /// drive it without an `NSApp.currentEvent`.
    func click(sender: NSClickGestureRecognizer, clickCount: Int) {
        let point = location(of: sender)
        tapHandler?(
            PointerGestureEvent(
                startLocation: point,
                location: point,
                modifiers: PointerModifiers(NSEvent.modifierFlags),
                clickCount: max(clickCount, 1)
            )
        )
    }

    /// Driven by the gesture recognizer. Not private so that tests
    /// can replay a pinch without synthesising real trackpad events.
    @objc
    func magnify(sender: NSMagnificationGestureRecognizer) {
        let phase: PointerEventPhase
        switch sender.state {
            case .began:
                phase = .began
            case .changed:
                phase = .changed
            case .ended:
                phase = .ended
            case .cancelled, .failed:
                phase = .cancelled
            default:
                return
        }

        magnifyHandler?(
            PointerMagnifyEvent(
                location: location(of: sender),
                // AppKit accumulates the change in scale from zero;
                // SwiftUI (and SwiftCrossUI) report the scale factor itself.
                magnification: 1.0 + Double(sender.magnification),
                phase: phase,
                modifiers: PointerModifiers(NSEvent.modifierFlags),
                time: Date()
            )
        )
    }
}

extension PointerButtons {
    /// The `NSPanGestureRecognizer.buttonMask` selecting these buttons.
    var appKitButtonMask: Int {
        var mask = 0
        if contains(.primary) {
            mask |= 0x1
        }
        if contains(.secondary) {
            mask |= 0x2
        }
        if contains(.middle) {
            mask |= 0x4
        }
        return mask
    }
}

extension PointerModifiers {
    /// The SwiftCrossUI modifiers corresponding to AppKit's modifier flags.
    ///
    /// - Parameter flags: The flags reported by an `NSEvent`.
    init(_ flags: NSEvent.ModifierFlags) {
        var modifiers: PointerModifiers = []
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        if flags.contains(.control) {
            modifiers.insert(.control)
        }
        if flags.contains(.option) {
            modifiers.insert(.option)
        }
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        if flags.contains(.capsLock) {
            modifiers.insert(.capsLock)
        }
        self = modifiers
    }
}
