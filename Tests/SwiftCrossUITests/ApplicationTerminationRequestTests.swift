import Testing
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Application termination authorization")
@MainActor
struct ApplicationTerminationRequestTests {
    @MainActor
    private final class Decision {
        var calls = 0
        private var answer: CheckedContinuation<Bool, Never>?
        private var started: CheckedContinuation<Void, Never>?

        func request() async -> Bool {
            calls += 1
            return await withCheckedContinuation { answer in
                self.answer = answer
                started?.resume()
                started = nil
            }
        }

        func waitUntilRequested() async {
            if answer != nil { return }
            await withCheckedContinuation { started = $0 }
        }

        func resolve(_ value: Bool) {
            let answer = answer
            self.answer = nil
            answer?.resume(returning: value)
        }
    }

    @MainActor
    private final class Replies {
        var values: [Bool] = []
        private var waiter: CheckedContinuation<Void, Never>?

        func record(_ value: Bool) {
            values.append(value)
            waiter?.resume()
            waiter = nil
        }

        func waitForFirst() async {
            if !values.isEmpty { return }
            await withCheckedContinuation { waiter = $0 }
        }
    }

    @Test("No handler leaves native termination synchronous")
    func noHandler() {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let replies = Replies()
        #expect(!coordinator.shouldDeferTermination { replies.record($0) })
        #expect(replies.values.isEmpty)
        #expect(coordinator.pendingTask == nil)
        coordinator.cancelPendingRequest()
        #expect(replies.values.isEmpty)
    }

    @Test("Immediate approval is still deferred until the native callback returns")
    func immediateApprovalIsAsynchronous() async throws {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let replies = Replies()
        coordinator.setHandler { true }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        #expect(replies.values.isEmpty)
        let pending = try #require(coordinator.pendingTask)
        await pending.value
        #expect(replies.values == [true])
        #expect(coordinator.pendingTask == nil)
        coordinator.cancelPendingRequest()
        #expect(replies.values == [true])
    }

    @Test("Repeated Quit requests share the first native reply and decision")
    func coalescesRequests() async throws {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let decision = Decision()
        let replies = Replies()
        let duplicateReplies = Replies()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        let pending = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        for _ in 0..<5 {
            #expect(coordinator.shouldDeferTermination { duplicateReplies.record($0) })
        }
        #expect(decision.calls == 1)
        decision.resolve(true)
        await pending.value
        #expect(replies.values == [true])
        #expect(duplicateReplies.values.isEmpty)
    }

    @Test("Denial replies false once and permits a fresh later decision")
    func denialThenApproval() async throws {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let decision = Decision()
        let replies = Replies()
        coordinator.setHandler { await decision.request() }
        for answer in [false, true] {
            #expect(coordinator.shouldDeferTermination { replies.record($0) })
            let pending = try #require(coordinator.pendingTask)
            await decision.waitUntilRequested()
            decision.resolve(answer)
            await pending.value
        }
        #expect(replies.values == [false, true])
        #expect(decision.calls == 2)
    }

    @Test("Removing a handler denies immediately and ignores its late approval")
    func removalInvalidatesPendingApproval() async throws {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let decision = Decision()
        let replies = Replies()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        let pending = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        coordinator.setHandler(nil)
        #expect(replies.values == [false])
        #expect(pending.isCancelled)
        #expect(!coordinator.shouldDeferTermination { replies.record($0) })
        decision.resolve(true)
        await pending.value
        #expect(replies.values == [false])
    }

    @Test("Replacing the handler preserves a pending decision and updates the next one")
    func latestFutureHandler() async throws {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let decision = Decision()
        let replies = Replies()
        let replacements = Replies()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        let first = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        coordinator.setHandler { replacements.record(true); return true }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        #expect(replacements.values.isEmpty)
        decision.resolve(false)
        await first.value
        #expect(replies.values == [false])
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        let second = try #require(coordinator.pendingTask)
        await second.value
        #expect(replacements.values == [true])
        #expect(replies.values == [false, true])
    }

    @Test("Explicit cancellation denies before an uncooperative handler returns")
    func cancelledTaskRepliesWithoutHandlerCooperation() async throws {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let decision = Decision()
        let replies = Replies()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        let pending = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        pending.cancel()
        await replies.waitForFirst()
        #expect(replies.values == [false])
        #expect(coordinator.pendingTask == nil)
        decision.resolve(true)
        await pending.value
        #expect(replies.values == [false])
    }

    @Test("A stale completion cannot settle a newer Quit request")
    func cancelledOldRequestDoesNotCompleteNewRequest() async throws {
        let coordinator = ApplicationTerminationRequestCoordinator()
        let firstDecision = Decision()
        let secondDecision = Decision()
        let replies = Replies()
        coordinator.setHandler { await firstDecision.request() }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        let first = try #require(coordinator.pendingTask)
        await firstDecision.waitUntilRequested()
        coordinator.cancelPendingRequest()
        coordinator.setHandler { await secondDecision.request() }
        #expect(coordinator.shouldDeferTermination { replies.record($0) })
        let second = try #require(coordinator.pendingTask)
        await secondDecision.waitUntilRequested()
        firstDecision.resolve(true)
        await first.value
        #expect(replies.values == [false])
        #expect(coordinator.pendingTask != nil)
        secondDecision.resolve(true)
        await second.value
        #expect(replies.values == [false, true])
    }

    @Test("Release cancels and denies without retaining the coordinator")
    func deinitDeniesOutstandingRequest() async throws {
        var coordinator: ApplicationTerminationRequestCoordinator? = .init()
        let getWeakCoordinator = { [weak coordinator] in coordinator }
        let decision = Decision()
        let replies = Replies()
        coordinator?.setHandler { await decision.request() }
        #expect(coordinator?.shouldDeferTermination { replies.record($0) } == true)
        let pending = try #require(coordinator?.pendingTask)
        await decision.waitUntilRequested()
        coordinator = nil
        #expect(getWeakCoordinator() == nil)
        #expect(pending.isCancelled)
        await replies.waitForFirst()
        #expect(replies.values == [false])
        decision.resolve(true)
        await pending.value
        #expect(replies.values == [false])
    }
}
