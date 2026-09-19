import CWinRT
import Foundation
@_spi(Backends) import SwiftCrossUI
import WinAppSDK
import WinSDK

/// Wakes WinUI when Swift's dispatch main queue has work, instead of waiting for
/// swift-winui's Foundation run-loop polling timer.
///
/// libdispatch's CoreFoundation integration exposes an auto-reset event that is
/// signaled when main-queue work arrives. A one-shot Windows thread-pool wait
/// forwards that signal to WinUI, then remains disarmed until the UI thread has
/// drained the queue. This bounds pending wakeups and adds no idle polling.
///
/// These exports are runtime SPI, not public API. Resolve them only from the
/// already-loaded dispatch.dll, and fall back to swift-winui's existing run-loop
/// bridge when unavailable. That bridge remains responsible for Foundation
/// timers and other run-loop sources even while this supplement is active.
///
/// - Safety: The dispatcher queue is used from worker threads only to enqueue
///   callbacks, which its API permits. All mutable state and dispatch draining
///   belong to the main actor. The owner must call `stop()` before releasing the
///   bridge, so the thread-pool callback's unretained context stays alive.
final class MainQueueWakeupBridge: @unchecked Sendable {
    private typealias GetMainQueueHandle = @convention(c) () -> HANDLE?
    private typealias DrainMainQueue = @convention(c) (UnsafeMutableRawPointer?) -> Void

    private let dispatcherQueue: WinAppSDK.DispatcherQueue
    /// Borrowed from libdispatch. Never reset or close this handle ourselves.
    private let dispatchEvent: HANDLE
    private let drainMainQueue: DrainMainQueue
    private var wait: PTP_WAIT?
    private var isDraining = false

    @MainActor
    init?() {
        guard ProcessInfo.processInfo.environment["SCUI_DISABLE_MAIN_QUEUE_WAKEUP"] != "1",
            let dispatcherQueue = WinAppSDK.DispatcherQueue.getForCurrentThread(),
            let module = GetModuleHandleA("dispatch.dll"),
            let getHandleAddress = GetProcAddress(module, "_dispatch_get_main_queue_handle_4CF")
                ?? GetProcAddress(module, "_dispatch_get_main_queue_port_4CF"),
            let drainAddress = GetProcAddress(module, "_dispatch_main_queue_callback_4CF")
        else {
            return nil
        }

        let getHandle = unsafeBitCast(getHandleAddress, to: GetMainQueueHandle.self)
        guard let dispatchEvent = getHandle() else { return nil }

        self.dispatcherQueue = dispatcherQueue
        self.dispatchEvent = dispatchEvent
        self.drainMainQueue = unsafeBitCast(drainAddress, to: DrainMainQueue.self)
        self.wait = CreateThreadpoolWait(
            { _, context, _, _ in
                guard let context else { return }
                let bridge = Unmanaged<MainQueueWakeupBridge>.fromOpaque(context)
                    .takeUnretainedValue()
                bridge.forwardSignal()
            },
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
        guard wait != nil else { return nil }

        // Bootstrap on the UI queue before arming the wait. Besides draining any
        // work that predated setup, this initializes swift-winui's lazy COM
        // interface cache on its owning thread before workers use tryEnqueue.
        guard enqueueDrain() else {
            stop()
            return nil
        }
    }

    /// Cancels the borrowed-event wait while the application still owns us.
    /// Already queued UI callbacks become no-ops after `wait` is cleared.
    @MainActor
    func stop() {
        guard let wait else { return }
        self.wait = nil
        SetThreadpoolWait(wait, nil, nil)
        // Worker callbacks only enqueue work; they never wait on the UI thread.
        // Therefore waiting here cannot create a UI/worker dependency cycle.
        WaitForThreadpoolWaitCallbacks(wait, true)
        CloseThreadpoolWait(wait)
        // A cancelled callback may already have consumed the auto-reset signal.
        // Restore it so the Foundation bridge can service any remaining work.
        SetEvent(dispatchEvent)
    }

    /// The only entry point used by the Windows thread-pool callback.
    private func forwardSignal() {
        let timing = WinUITimingDiagnostics.begin(cpu: true)
        defer { WinUITimingDiagnostics.end(.mainQueueForward, timing) }
        // Pool threads do not inherit the application's apartment.
        // Balance initialization before returning the thread to its pool.
        guard RoInitialize(RO_INIT_MULTITHREADED) >= 0 else {
            SetEvent(dispatchEvent)
            return
        }
        defer { RoUninitialize() }
        enqueueDrain()
    }

    @discardableResult
    private func enqueueDrain() -> Bool {
        let queued = WinUITimingDiagnostics.begin()
        let accepted = (try? dispatcherQueue.tryEnqueue(.normal) { [weak self] in
            MainActor.assumeIsolated {
                WinUITimingDiagnostics.end(.mainQueueWait, queued)
                self?.drain()
            }
        }) == true
        if !accepted {
            WinUITimingDiagnostics.count("mainQueue.enqueueRejected")
            // The wait consumed the signal before forwarding. Restore it for
            // the Foundation bridge, and leave this wait disarmed to avoid a
            // retry loop if the dispatcher has begun shutting down.
            SetEvent(dispatchEvent)
        }
        return accepted
    }

    @MainActor
    private func drain() {
        guard wait != nil, !isDraining else { return }
        isDraining = true
        let timing = WinUITimingDiagnostics.begin(cpu: true)
        defer { WinUITimingDiagnostics.end(.mainQueueDrain, timing) }
        BackendCallStatistics.record("mainQueue.wakeup")
        // The wait has consumed the auto-reset event. RunLoop.limitDate alone
        // cannot reliably observe it now, so invoke libdispatch's own drain.
        // libdispatch drains one snapshot and guards against recursive drains.
        drainMainQueue(nil)
        isDraining = false

        // A task may have closed the application while draining. Do not rearm a
        // wait that stop() has already closed. Work arriving during the drain
        // remains signaled and will trigger the newly armed one-shot wait.
        if let wait {
            SetThreadpoolWait(wait, dispatchEvent, nil)
        }
    }
}
