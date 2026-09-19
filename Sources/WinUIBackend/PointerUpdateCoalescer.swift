import Foundation
import WinUI
import WindowsFoundation

/// Delivers at most one pointer update per composition frame.
///
/// ## Why
///
/// A mouse reports its position between 125 and 1000 times a second, and WinUI
/// raises `PointerMoved` for every report. Each one that reaches SwiftCrossUI
/// mutates observable state, which starts an update pass over the view graph.
/// A CAD-shaped window's pass costs tens of milliseconds, so an uncoalesced
/// stream asks for many times more passes than the frame rate can run: the
/// queue backs up and every frame drawn describes a pointer position from
/// several frames ago. That is the "lags while I'm dragging" failure, and no
/// amount of making the pass itself cheaper fixes it, because the input rate
/// isn't bounded by the frame rate.
///
/// AppKit coalesces mouse-moved and mouse-dragged events by default
/// (`NSEvent.isMouseCoalescingEnabled`), so this brings the Windows backend to
/// the behaviour the macOS one already had rather than inventing a new one.
///
/// ## What is dropped, and what isn't
///
/// Moves and drag updates are *absolute-position* events: the newest one
/// entirely supersedes the ones before it. Coalescing therefore loses
/// intermediate positions and nothing else — the app is always told the latest
/// position, never a stale one. Velocity is still sampled from every raw event
/// (see ``PointerGestureTarget``), so it keeps its full resolution.
///
/// Every other event — presses, releases, taps, exits, scrolls, pinches —
/// flushes the pending update first, so an app never sees a drag end at a
/// position older than the last move it was told about, and the order the
/// events are delivered in is the order they happened in.
///
/// ## Why the rendering event
///
/// `CompositionTarget.rendering` is raised once per composition frame, which is
/// exactly the rate at which delivering a new position can still be seen. A
/// dispatcher-queue callback would either need an interval picked out of thin
/// air or, at low priority, risk being starved for the whole drag by the input
/// it is trying to keep up with.
///
/// The handler is installed only while an update is pending, because an
/// installed handler keeps the compositor rendering continuously, which an idle
/// window has no business doing.
final class PointerUpdateCoalescer {
    /// The delivery waiting for the next frame, if any.
    private var pending: (@MainActor () -> Void)?

    /// The registration on `CompositionTarget.rendering`, held only while
    /// something is pending.
    private var subscription: EventCleanup?

    /// Schedules a delivery for the next composition frame, replacing whatever
    /// delivery hasn't run yet.
    ///
    /// - Parameter deliver: The update to deliver. Runs on the main actor.
    @MainActor
    func schedule(_ deliver: @escaping @MainActor () -> Void) {
        pending = deliver
        guard subscription == nil else {
            return
        }
        subscription = WinUI.CompositionTarget.rendering.addHandler { [weak self] _, _ in
            // WinUI raises this on the UI thread, which is the main actor, but
            // the handler is a plain closure; the same assumption the gesture
            // targets' event handlers make.
            MainActor.assumeIsolated {
                self?.flush()
            }
        }
    }

    /// Delivers the pending update now, if there is one.
    ///
    /// Called before any other pointer event is delivered, so that the app sees
    /// events in the order they happened.
    @MainActor
    func flush() {
        unsubscribe()
        guard let pending else {
            return
        }
        self.pending = nil
        pending()
    }

    /// Discards the pending update without delivering it.
    ///
    /// For a gesture that has been cancelled, where the update describes
    /// something that is no longer happening.
    @MainActor
    func cancel() {
        unsubscribe()
        pending = nil
    }

    private func unsubscribe() {
        subscription?.dispose()
        subscription = nil
    }

    deinit {
        // Otherwise a target that goes away mid-drag would leave the compositor
        // rendering every frame for a handler that can no longer do anything.
        unsubscribe()
    }
}
