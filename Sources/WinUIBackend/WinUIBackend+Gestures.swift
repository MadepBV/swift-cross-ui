import Foundation
@_spi(Backends) import SwiftCrossUI
import UWP
import WinAppSDK
import WinUI
import WindowsFoundation

// MARK: - Tap gestures

extension WinUIBackend {
    public func createTapGestureTarget(wrapping child: Widget, gesture: TapGesture) -> Widget {
        let tapGestureTarget = TapGestureTarget()
        insert(child, into: tapGestureTarget, at: 0)
        tapGestureTarget.child = child
        return tapGestureTarget
    }

    public func updateTapGestureTarget(
        _ tapGestureTarget: Widget,
        gesture: TapGesture,
        environment: EnvironmentValues,
        action: @escaping () -> Void
    ) {
        let tapGestureTarget = tapGestureTarget as! TapGestureTarget
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
        let hoverTarget = HoverGestureTarget()
        insert(child, into: hoverTarget, at: 0)
        hoverTarget.child = child

        // Ensure the hover target covers the full area of the child.
        // Use a transparent background so the visual appearance doesn't change but
        // the hit-testing covers the whole region.
        let brush = SolidColorBrush()
        brush.color = UWP.Color(a: 0, r: 0, g: 0, b: 0)
        hoverTarget.background = brush

        hoverTarget.pointerEntered.addHandler { [weak hoverTarget] _, _ in
            guard let hoverTarget else { return }
            hoverTarget.enterHandler?()
        }
        hoverTarget.pointerExited.addHandler { [weak hoverTarget] _, _ in
            guard let hoverTarget else { return }
            hoverTarget.exitHandler?()
        }
        return hoverTarget
    }

    public func updateHoverTarget(
        _ hoverTarget: Widget,
        environment: EnvironmentValues,
        action: @escaping (Bool) -> Void
    ) {
        let hoverTarget = hoverTarget as! HoverGestureTarget
        hoverTarget.enterHandler = environment.isEnabled ? { action(true) } : {}
        hoverTarget.exitHandler = environment.isEnabled ? { action(false) } : {}
    }
}

/// The element that `WinUIBackend` recognizes primary, secondary and long
/// press taps on.
///
/// The child is a member of the canvas, so pointer events raised on the child
/// bubble up to here unless a control in between marks them as handled (which
/// is what a `Button` does with its own clicks, exactly as on AppKit where the
/// button sits in front of the gesture target).
///
/// - Primary taps fire on the press of the left mouse button (or a touch or
///   pen contact), matching the Gtk backend and this backend's previous
///   behaviour.
/// - Secondary taps use WinUI's `RightTapped`, which is a right click for a
///   mouse and press-and-hold for touch.
/// - Long presses are timed by hand, because WinUI's `Holding` event is never
///   raised for a mouse. The press has to stay within
///   ``allowableLongPressMovement`` for ``longPressDuration``.
@MainActor
final class TapGestureTarget: WinUI.Canvas {
    /// How long the pointer must stay down for a long press. Both GTK and
    /// UIKit default to half a second for long presses.
    private static let longPressDuration: TimeInterval = 0.5

    /// How far a long press may drift before it's cancelled.
    private static let allowableLongPressMovement = 10.0

    var child: WinUI.FrameworkElement?

    var leftClickHandler: (() -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    var rightClickHandler: (() -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    var longPressHandler: (() -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    /// The timer counting down to a long press, created on first use.
    private var longPressTimer: WinAppSDK.DispatcherQueueTimer?

    /// The pointer whose long press is being timed, if any.
    private var longPressPointerId: UInt32?

    /// Where the pointer went down for the long press being timed.
    private var longPressLocation: CGPoint?

    override init() {
        super.init()

        pointerPressed.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.handlePointerPressed(args)
        }
        pointerMoved.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.handlePointerMoved(args)
        }
        pointerReleased.addHandler { [weak self] _, _ in
            self?.cancelLongPress()
        }
        pointerCaptureLost.addHandler { [weak self] _, _ in
            self?.cancelLongPress()
        }
        pointerCanceled.addHandler { [weak self] _, _ in
            self?.cancelLongPress()
        }
        pointerExited.addHandler { [weak self] _, _ in
            self?.cancelLongPress()
        }
        rightTapped.addHandler { [weak self] _, _ in
            guard let self else { return }
            self.rightClickHandler?()
        }
    }

    /// Lets pointer events through to whatever is behind the target while no
    /// gesture is attached. A panel without a background isn't hit-testable
    /// in its empty areas, but its children still are.
    private func updateHitTesting() {
        let wantsEvents =
            leftClickHandler != nil || rightClickHandler != nil
            || longPressHandler != nil
        if wantsEvents {
            let brush = SolidColorBrush()
            brush.color = UWP.Color(a: 0, r: 0, g: 0, b: 0)
            background = brush
        } else {
            background = nil
        }
    }

    private func handlePointerPressed(_ args: WinUI.PointerRoutedEventArgs) {
        guard let point = try? args.getCurrentPoint(self) else {
            return
        }
        guard point.isPrimaryContact else {
            return
        }

        leftClickHandler?()

        guard longPressHandler != nil else {
            return
        }
        longPressPointerId = point.pointerId
        longPressLocation = point.position.cgPoint
        startLongPressTimer()
    }

    private func handlePointerMoved(_ args: WinUI.PointerRoutedEventArgs) {
        guard
            let longPressLocation,
            let point = try? args.getCurrentPoint(self),
            point.pointerId == longPressPointerId
        else {
            return
        }

        let current = point.position.cgPoint
        let dx = current.x - longPressLocation.x
        let dy = current.y - longPressLocation.y
        if (dx * dx + dy * dy).squareRoot() > Self.allowableLongPressMovement {
            cancelLongPress()
        }
    }

    private func startLongPressTimer() {
        if longPressTimer == nil {
            longPressTimer = Self.makeLongPressTimer { [weak self] in
                self?.longPressTimerFired()
            }
        }
        guard let longPressTimer else {
            return
        }
        try? longPressTimer.stop()
        try? longPressTimer.start()
    }

    private func cancelLongPress() {
        longPressPointerId = nil
        longPressLocation = nil
        if let longPressTimer {
            try? longPressTimer.stop()
        }
    }

    private func longPressTimerFired() {
        guard longPressPointerId != nil else {
            return
        }
        cancelLongPress()
        longPressHandler?()
    }

    /// Creates a one-shot timer on the UI thread's dispatcher queue.
    ///
    /// - Parameter action: The action to run when the timer fires.
    /// - Returns: The timer, or `nil` if the current thread has no dispatcher
    ///   queue (which shouldn't happen on the UI thread).
    private static func makeLongPressTimer(
        _ action: @escaping () -> Void
    ) -> WinAppSDK.DispatcherQueueTimer? {
        guard
            let queue = WinAppSDK.DispatcherQueue.getForCurrentThread(),
            let timer = try? queue.createTimer()
        else {
            logger.warning("no dispatcher queue on the current thread; long presses are unavailable")
            return nil
        }
        // WinRT durations are in 100 nanosecond ticks.
        timer.interval = WindowsFoundation.TimeSpan(
            duration: Int64(longPressDuration * 10_000_000)
        )
        timer.isRepeating = false
        timer.tick.addHandler { _, _ in
            action()
        }
        return timer
    }
}

final class HoverGestureTarget: WinUI.Canvas {
    var enterHandler: (() -> Void)?
    var exitHandler: (() -> Void)?
    var child: WinUI.FrameworkElement?
}

// MARK: - Pointer gestures

extension WinUIBackend: BackendFeatures.PointerGestures {
    public func createPointerGestureTarget(wrapping child: Widget) -> Widget {
        let target = PointerGestureTarget()
        insert(child, into: target, at: 0)
        target.child = child
        return target
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
        let target = container as! PointerGestureTarget
        target.minimumDragDistance = minimumDragDistance
        target.dragButtons = dragButtons
        target.tapCount = tapCount
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
        target.scrollHandler = onScroll
        target.magnifyHandler = onMagnify
        target.moveHandler = onMove
    }
}

/// The element that `WinUIBackend` recognizes drags and spatial taps on.
///
/// Positions are reported in device-independent pixels from the target's own
/// top-leading corner, which is the coordinate system SwiftCrossUI lays out
/// in; ``reportsWindowCoordinates`` switches to the window's content.
///
/// Drags are driven by the raw pointer events rather than a manipulation, so
/// that they work identically for a mouse, a pen and touch, and so that the
/// pointer can be captured for the duration of the drag (letting it leave the
/// element without the drag being cut short).
///
/// Single and double taps use WinUI's own `Tapped` and `DoubleTapped`, which
/// only fire when the pointer didn't move far enough to become a drag. Taps
/// needing three or more clicks have no native counterpart and are counted by
/// hand from presses instead, so they fire on the final press rather than its
/// release.
///
/// Scrolling comes from `PointerWheelChanged`, in wheel notches (a delta of
/// 120 is one notch; a precision touchpad reports finer deltas, which are
/// flagged as precise). Pinching comes from the manipulation events with
/// `ManipulationModes.scale` enabled, which WinUI only raises for touch (and
/// pen): a precision touchpad pinch reaches every Windows app as a
/// Control+wheel `PointerWheelChanged` instead, so it arrives here as a scroll
/// event carrying ``PointerModifiers/control``.
///
/// Every event carries the modifier keys WinUI reported with it; the tap
/// and manipulation events, which don't carry any, use the modifiers of the
/// most recent pointer event instead.
@MainActor
final class PointerGestureTarget: WinUI.Canvas {
    /// How long two presses may be apart to count as one multi-tap: the
    /// system's double-click time.
    private static let multiTapInterval: TimeInterval = {
        let milliseconds = UWP.UISettings().doubleClickTime
        return milliseconds > 0 ? Double(milliseconds) / 1000.0 : 0.5
    }()

    /// How far apart two presses may be to count as one multi-tap.
    private static let multiTapDistance = 8.0

    var child: WinUI.FrameworkElement?

    /// How far the pointer must move from where it went down before a drag
    /// starts being reported.
    var minimumDragDistance = 0.0

    /// The largest click count any tap gesture needs. Single and double
    /// clicks come from WinUI's own `Tapped` and `DoubleTapped`; only counts
    /// of three or more are tallied by hand.
    var tapCount = 1

    /// The buttons a drag may be made with.
    var dragButtons: PointerButtons = .primary

    /// The button the current drag is being made with.
    private var dragButton: PointerButton = .primary

    /// Whether positions are reported in window coordinates rather than in
    /// this element's own.
    var reportsWindowCoordinates = false

    /// The action to run each time a recognized drag moves.
    var dragChangedHandler: (@MainActor (PointerGestureEvent) -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    /// The action to run when a recognized drag finishes.
    var dragEndedHandler: (@MainActor (PointerGestureEvent) -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    /// The action to run when a tap is recognized.
    var tapHandler: (@MainActor (PointerGestureEvent) -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    /// The action to run for each mouse wheel or touchpad scroll step.
    ///
    /// While `nil`, wheel events are left unhandled so that an enclosing
    /// `ScrollViewer` still scrolls.
    var scrollHandler: (@MainActor (PointerScrollEvent) -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    /// The action to run for each step of a touch pinch.
    var magnifyHandler: (@MainActor (PointerMagnifyEvent) -> Void)? {
        didSet {
            updateHitTesting()
            updateManipulationMode()
        }
    }

    /// The action to run for each pointer move with no button held (a mouse
    /// or a hovering pen), and once with ``HoverPhase/ended`` when the
    /// pointer leaves. Touch never hovers, so it never reports here.
    var moveHandler: (@MainActor (PointerMoveEvent) -> Void)? {
        didSet {
            updateHitTesting()
        }
    }

    /// Whether the last move reported the pointer as inside, so that leaving
    /// is reported exactly once.
    private var pointerIsInside = false

    /// The modifier keys reported by the most recent pointer event.
    private var lastModifiers: PointerModifiers = []

    /// The pointer currently held down on the target, if any.
    private var pressedPointerId: UInt32?

    /// Where the pointer went down, in the reported coordinate space.
    private var dragStartLocation: CGPoint?

    /// Whether the current press has passed ``minimumDragDistance`` yet.
    private var dragIsRecognized = false

    /// The most recent pointer position, used to derive the velocity.
    private var lastLocation: CGPoint?

    /// When ``lastLocation`` was sampled.
    private var lastTime: Date?

    /// The velocity derived from the last two samples.
    private var velocity = CGSize(width: 0.0, height: 0.0)

    /// How many presses in quick succession have been seen, for taps that
    /// need three or more clicks.
    private var consecutivePresses = 0

    /// When the last press happened, for multi-tap counting.
    private var lastPressTime: Date?

    /// Where the last press happened, for multi-tap counting.
    private var lastPressLocation: CGPoint?

    override init() {
        super.init()

        pointerPressed.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.handlePointerPressed(args)
        }
        pointerMoved.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.handlePointerMoved(args)
        }
        pointerReleased.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.handlePointerReleased(args)
        }
        pointerCaptureLost.addHandler { [weak self] _, _ in
            // A cancelled drag never happened, so no handler runs; SwiftUI
            // doesn't call `onEnded` for one either.
            self?.resetDrag()
        }
        pointerCanceled.addHandler { [weak self] _, _ in
            self?.resetDrag()
        }
        pointerExited.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.handlePointerExited(args)
        }
        // Every click is reported with its count and SwiftCrossUI routes it
        // to the gesture asking for that count. WinUI raises Tapped for the
        // first click of a double click and DoubleTapped for the second.
        tapped.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            let relativeTo: WinUI.UIElement? = self.reportsWindowCoordinates ? nil : self
            guard let position = try? args.getPosition(relativeTo) else { return }
            self.sendTap(at: position.cgPoint, clickCount: 1)
        }
        doubleTapped.addHandler { [weak self] _, args in
            guard let self, let args, self.tapCount >= 2 else { return }
            let relativeTo: WinUI.UIElement? = self.reportsWindowCoordinates ? nil : self
            guard let position = try? args.getPosition(relativeTo) else { return }
            self.sendTap(at: position.cgPoint, clickCount: 2)
        }
        pointerWheelChanged.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.handlePointerWheelChanged(args)
        }
        manipulationStarted.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.sendMagnify(
                cumulativeScale: args.cumulative.scale,
                position: args.position,
                phase: .began
            )
        }
        manipulationDelta.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.sendMagnify(
                cumulativeScale: args.cumulative.scale,
                position: args.position,
                phase: .changed
            )
        }
        manipulationCompleted.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.sendMagnify(
                cumulativeScale: args.cumulative.scale,
                position: args.position,
                phase: .ended
            )
        }
    }

    /// Lets pointer events through to whatever is behind the target while no
    /// gesture is attached. A panel without a background isn't hit-testable
    /// in its empty areas, but its children still are.
    private func updateHitTesting() {
        let wantsEvents =
            dragChangedHandler != nil || dragEndedHandler != nil
            || tapHandler != nil || scrollHandler != nil
            || magnifyHandler != nil || moveHandler != nil
        if wantsEvents {
            let brush = SolidColorBrush()
            brush.color = UWP.Color(a: 0, r: 0, g: 0, b: 0)
            background = brush
        } else {
            background = nil
        }
    }

    /// Enables scale manipulations while a magnify handler is attached.
    ///
    /// `ManipulationModes` is projected as a plain C enum rather than an
    /// `OptionSet`, so the flags are combined through their raw values.
    /// `system` stays set so that an enclosing `ScrollViewer` keeps panning
    /// with one finger.
    private func updateManipulationMode() {
        if magnifyHandler != nil {
            manipulationMode = WinUI.ManipulationModes(
                rawValue: WinUI.ManipulationModes.scale.rawValue
                    | WinUI.ManipulationModes.system.rawValue
            )
        } else {
            manipulationMode = .system
        }
    }

    private var wantsDrag: Bool {
        dragChangedHandler != nil || dragEndedHandler != nil
    }

    /// Reads the pointer's position in the space the gesture asked for.
    ///
    /// - Parameter args: The event to read.
    /// - Returns: The pointer's position, or `nil` if WinUI couldn't provide
    ///   one.
    private func location(of args: WinUI.PointerRoutedEventArgs) -> CGPoint? {
        let relativeTo: WinUI.UIElement? = reportsWindowCoordinates ? nil : self
        guard let point = try? args.getCurrentPoint(relativeTo) else {
            return nil
        }
        return point.position.cgPoint
    }

    /// Builds an event describing where a drag is now.
    private func dragEvent(start: CGPoint, location: CGPoint) -> PointerGestureEvent {
        PointerGestureEvent(
            startLocation: start,
            location: location,
            time: Date(),
            velocity: velocity,
            modifiers: lastModifiers,
            button: dragButton
        )
    }

    /// Updates ``velocity`` from a new sample.
    private func sample(_ location: CGPoint) {
        let now = Date()
        if let lastLocation, let lastTime {
            let elapsed = now.timeIntervalSince(lastTime)
            if elapsed > 0.0 {
                velocity = CGSize(
                    width: (location.x - lastLocation.x) / elapsed,
                    height: (location.y - lastLocation.y) / elapsed
                )
            }
        }
        lastLocation = location
        lastTime = now
    }

    private func resetDrag() {
        pressedPointerId = nil
        dragStartLocation = nil
        dragIsRecognized = false
        lastLocation = nil
        lastTime = nil
        velocity = CGSize(width: 0.0, height: 0.0)
    }

    private func handlePointerPressed(_ args: WinUI.PointerRoutedEventArgs) {
        lastModifiers = PointerModifiers(virtualKeyModifiers: args.keyModifiers)

        guard let point = try? args.getCurrentPoint(self), let button = point.pressedButton else {
            return
        }

        if button == .primary, tapHandler != nil, tapCount >= 3 {
            countPress(at: point.position.cgPoint)
        }

        guard wantsDrag, dragButtons.contains(button), let location = location(of: args) else {
            return
        }

        dragButton = button
        pressedPointerId = point.pointerId
        dragStartLocation = location
        dragIsRecognized = minimumDragDistance <= 0.0
        velocity = CGSize(width: 0.0, height: 0.0)
        lastLocation = location
        lastTime = Date()

        // Capturing keeps the move and release events coming even once the
        // pointer leaves the element.
        _ = try? capturePointer(args.pointer)
    }

    private func handlePointerMoved(_ args: WinUI.PointerRoutedEventArgs) {
        let modifiers = PointerModifiers(virtualKeyModifiers: args.keyModifiers)
        lastModifiers = modifiers

        // A move with nothing pressed is a hover. `isInContact` is false for
        // a mouse with no button down and for a pen hovering above the
        // screen; a drag in progress is reported through the drag handlers
        // below instead.
        if let moveHandler,
            pressedPointerId == nil,
            let point = try? args.getCurrentPoint(self),
            !point.isInContact,
            let location = location(of: args)
        {
            pointerIsInside = true
            moveHandler(
                PointerMoveEvent(
                    phase: .active(location),
                    modifiers: modifiers,
                    time: Date()
                )
            )
        }

        guard
            let pressedPointerId,
            let start = dragStartLocation,
            args.pointer.pointerId == pressedPointerId,
            let current = location(of: args)
        else {
            return
        }

        sample(current)

        if !dragIsRecognized {
            let dx = current.x - start.x
            let dy = current.y - start.y
            guard (dx * dx + dy * dy).squareRoot() >= minimumDragDistance else {
                return
            }
            dragIsRecognized = true
        }

        dragChangedHandler?(dragEvent(start: start, location: current))
    }

    private func handlePointerExited(_ args: WinUI.PointerRoutedEventArgs) {
        let modifiers = PointerModifiers(virtualKeyModifiers: args.keyModifiers)
        lastModifiers = modifiers

        guard let moveHandler, pointerIsInside else {
            return
        }
        pointerIsInside = false
        moveHandler(PointerMoveEvent(phase: .ended, modifiers: modifiers, time: Date()))
    }

    private func handlePointerReleased(_ args: WinUI.PointerRoutedEventArgs) {
        lastModifiers = PointerModifiers(virtualKeyModifiers: args.keyModifiers)

        guard
            let pressedPointerId,
            args.pointer.pointerId == pressedPointerId
        else {
            return
        }

        defer {
            try? releasePointerCapture(args.pointer)
            resetDrag()
        }

        guard let start = dragStartLocation, dragIsRecognized else {
            return
        }
        let current = location(of: args) ?? lastLocation ?? start
        sample(current)
        dragEndedHandler?(dragEvent(start: start, location: current))
    }

    /// Counts presses towards a tap that needs three or more clicks.
    ///
    /// - Parameter location: Where the press happened, relative to this
    ///   element.
    private func countPress(at location: CGPoint) {
        let now = Date()
        if let lastPressTime, let lastPressLocation,
            now.timeIntervalSince(lastPressTime) <= Self.multiTapInterval,
            abs(location.x - lastPressLocation.x) <= Self.multiTapDistance,
            abs(location.y - lastPressLocation.y) <= Self.multiTapDistance
        {
            consecutivePresses += 1
        } else {
            consecutivePresses = 1
        }
        lastPressTime = now
        lastPressLocation = location

        // The first two clicks are reported by Tapped/DoubleTapped.
        guard consecutivePresses >= 3 else {
            return
        }
        let clickCount = consecutivePresses
        if consecutivePresses >= tapCount {
            consecutivePresses = 0
            lastPressTime = nil
            lastPressLocation = nil
        }

        if reportsWindowCoordinates,
            let transform = try? transformToVisual(nil),
            let transformed = try? transform.transformPoint(
                WindowsFoundation.Point(x: Float(location.x), y: Float(location.y))
            )
        {
            sendTap(at: transformed.cgPoint, clickCount: clickCount)
        } else {
            sendTap(at: location, clickCount: clickCount)
        }
    }

    private func sendTap(at location: CGPoint, clickCount: Int) {
        tapHandler?(
            PointerGestureEvent(
                startLocation: location,
                location: location,
                modifiers: lastModifiers,
                clickCount: clickCount
            )
        )
    }

    /// One notch of a mouse wheel, as `PointerPointProperties.mouseWheelDelta`
    /// reports it (`WHEEL_DELTA`).
    private static let wheelNotch = 120.0

    private func handlePointerWheelChanged(_ args: WinUI.PointerRoutedEventArgs) {
        let modifiers = PointerModifiers(virtualKeyModifiers: args.keyModifiers)
        lastModifiers = modifiers

        guard
            let scrollHandler,
            let location = location(of: args),
            let point = try? args.getCurrentPoint(self),
            let properties = point.properties
        else {
            return
        }

        let delta = Double(properties.mouseWheelDelta)
        let notches = delta / Self.wheelNotch
        let isHorizontal = properties.isHorizontalMouseWheel

        // A notched wheel reports whole multiples of WHEEL_DELTA; a precision
        // touchpad reports finer, pixel-like deltas.
        let isPrecise = properties.mouseWheelDelta % 120 != 0

        scrollHandler(
            PointerScrollEvent(
                location: location,
                deltaX: isHorizontal ? notches : 0.0,
                deltaY: isHorizontal ? 0.0 : notches,
                isPrecise: isPrecise,
                phase: .changed,
                modifiers: modifiers,
                time: Date()
            )
        )

        // Consumed, so an enclosing ScrollViewer doesn't scroll as well.
        args.handled = true
    }

    /// Delivers one step of a touch pinch.
    ///
    /// - Parameters:
    ///   - cumulativeScale: The scale accumulated since the manipulation
    ///     began, which WinUI reports as a factor (1 means unchanged).
    ///   - position: The manipulation's position relative to this element.
    ///   - phase: Where the pinch is in its lifetime.
    private func sendMagnify(
        cumulativeScale: Float,
        position: WindowsFoundation.Point,
        phase: PointerEventPhase
    ) {
        guard let magnifyHandler else {
            return
        }

        var location = position.cgPoint
        if reportsWindowCoordinates,
            let transform = try? transformToVisual(nil),
            let transformed = try? transform.transformPoint(position)
        {
            location = transformed.cgPoint
        }

        magnifyHandler(
            PointerMagnifyEvent(
                location: location,
                magnification: Double(cumulativeScale),
                phase: phase,
                modifiers: lastModifiers,
                time: Date()
            )
        )
    }
}

// MARK: - Helpers

extension WindowsFoundation.Point {
    /// This point as a Core Graphics point.
    var cgPoint: CGPoint {
        CGPoint(x: Double(x), y: Double(y))
    }
}

extension PointerModifiers {
    /// The SwiftCrossUI modifiers corresponding to WinUI's modifier flags.
    ///
    /// `VirtualKeyModifiers` is projected as a plain C enum rather than an
    /// `OptionSet`, so the flags are tested through their raw values.
    ///
    /// - Parameter virtualKeyModifiers: The flags reported by a pointer
    ///   event.
    init(virtualKeyModifiers: UWP.VirtualKeyModifiers) {
        let rawValue = virtualKeyModifiers.rawValue
        var modifiers: PointerModifiers = []
        if rawValue & UWP.VirtualKeyModifiers.shift.rawValue != 0 {
            modifiers.insert(.shift)
        }
        if rawValue & UWP.VirtualKeyModifiers.control.rawValue != 0 {
            modifiers.insert(.control)
        }
        if rawValue & UWP.VirtualKeyModifiers.menu.rawValue != 0 {
            modifiers.insert(.option)
        }
        if rawValue & UWP.VirtualKeyModifiers.windows.rawValue != 0 {
            modifiers.insert(.command)
        }
        self = modifiers
    }
}

extension WinAppSDK.PointerPoint {
    /// Whether this is the left mouse button, a touch contact or a pen tip
    /// (as opposed to a secondary button).
    ///
    /// WinUI reports a touch or pen contact as the left button being pressed,
    /// so one check covers every kind of pointer.
    var isPrimaryContact: Bool {
        guard let properties else {
            return false
        }
        return properties.isLeftButtonPressed
    }

    /// The button held down, or `nil` if none is (a hover, or a pointer
    /// WinUI reports no button for).
    var pressedButton: PointerButton? {
        guard let properties else {
            return nil
        }
        if properties.isLeftButtonPressed {
            return .primary
        } else if properties.isRightButtonPressed {
            return .secondary
        } else if properties.isMiddleButtonPressed {
            return .middle
        }
        return nil
    }
}
