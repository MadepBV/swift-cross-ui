import Testing
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Window close authorization")
@MainActor
struct WindowCloseRequestTests {
    @MainActor
    private final class Counter {
        var value = 0
    }

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

        func resolve(_ permitted: Bool) {
            let answer = answer
            self.answer = nil
            answer?.resume(returning: permitted)
        }
    }

    @Test("No handler preserves synchronous native closing")
    func noHandler() {
        let coordinator = WindowCloseRequestCoordinator()
        let close = Counter()
        #expect(!coordinator.shouldDeferClose { close.value += 1 })
        #expect(close.value == 0)
        #expect(coordinator.pendingTask == nil)
    }

    @Test("Repeated close clicks share one pending decision")
    func coalescesRequests() async throws {
        let coordinator = WindowCloseRequestCoordinator()
        let decision = Decision()
        let close = Counter()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferClose { close.value += 1 })
        let pending = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        for _ in 0..<5 { #expect(coordinator.shouldDeferClose { close.value += 10 }) }
        #expect(decision.calls == 1)
        #expect(close.value == 0)
        decision.resolve(true)
        await pending.value
        #expect(close.value == 1)
        #expect(coordinator.pendingTask == nil)
    }

    @Test("Deny keeps the window alive and a later request can be approved")
    func denyThenApprove() async throws {
        let coordinator = WindowCloseRequestCoordinator()
        let decision = Decision()
        let close = Counter()
        coordinator.setHandler { await decision.request() }
        for permitted in [false, true] {
            #expect(coordinator.shouldDeferClose { close.value += 1 })
            let pending = try #require(coordinator.pendingTask)
            await decision.waitUntilRequested()
            decision.resolve(permitted)
            await pending.value
            #expect(close.value == (permitted ? 1 : 0))
        }
        #expect(decision.calls == 2)
    }

    @Test("An approved native retry does not prompt recursively")
    func approvedRetry() async throws {
        let coordinator = WindowCloseRequestCoordinator()
        let prompts = Counter()
        let close = Counter()
        coordinator.setHandler { prompts.value += 1; return true }
        let deferred = coordinator.shouldDeferClose {
            close.value += 1
            #expect(!coordinator.shouldDeferClose { close.value += 100 })
            coordinator.windowDidClose()
        }
        #expect(deferred)
        let pending = try #require(coordinator.pendingTask)
        await pending.value
        #expect(prompts.value == 1)
        #expect(close.value == 1)
        #expect(coordinator.shouldDeferClose { close.value += 10 })
    }

    @Test("Removing a handler invalidates an uncooperative pending decision")
    func handlerRemoved() async throws {
        let coordinator = WindowCloseRequestCoordinator()
        let decision = Decision()
        let close = Counter()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferClose { close.value += 1 })
        let pending = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        coordinator.setHandler(nil)
        #expect(pending.isCancelled)
        decision.resolve(true)
        await pending.value
        #expect(close.value == 0)
        #expect(!coordinator.shouldDeferClose { close.value += 10 })
    }

    @Test("View updates replace future handlers without restarting a prompt")
    func handlerUpdated() async throws {
        let coordinator = WindowCloseRequestCoordinator()
        let decision = Decision()
        let replacement = Counter()
        let close = Counter()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferClose { close.value += 1 })
        let first = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        coordinator.setHandler { replacement.value += 1; return true }
        #expect(coordinator.shouldDeferClose { close.value += 10 })
        #expect(replacement.value == 0)
        decision.resolve(false)
        await first.value
        #expect(coordinator.shouldDeferClose { close.value += 1 })
        let second = try #require(coordinator.pendingTask)
        await second.value
        #expect(replacement.value == 1)
        #expect(close.value == 1)
    }

    @Test("Teardown cannot be followed by a delayed approved close")
    func closedWhilePending() async throws {
        let coordinator = WindowCloseRequestCoordinator()
        let decision = Decision()
        let close = Counter()
        coordinator.setHandler { await decision.request() }
        #expect(coordinator.shouldDeferClose { close.value += 1 })
        let pending = try #require(coordinator.pendingTask)
        await decision.waitUntilRequested()
        coordinator.windowDidClose()
        decision.resolve(true)
        await pending.value
        #expect(close.value == 0)
        #expect(pending.isCancelled)
        coordinator.setHandler { true }
        #expect(coordinator.shouldDeferClose { close.value += 10 })
        #expect(coordinator.pendingTask == nil)
    }

    @Test("A pending decision does not retain its coordinator")
    func releasedWhilePending() async throws {
        var coordinator: WindowCloseRequestCoordinator? = WindowCloseRequestCoordinator()
        let getWeakCoordinator = { [weak coordinator] in coordinator }
        let decision = Decision()
        let close = Counter()
        coordinator?.setHandler { await decision.request() }
        #expect(coordinator?.shouldDeferClose { close.value += 1 } == true)
        let pending = try #require(coordinator?.pendingTask)
        await decision.waitUntilRequested()
        coordinator = nil
        #expect(getWeakCoordinator() == nil)
        #expect(pending.isCancelled)
        decision.resolve(true)
        await pending.value
        #expect(close.value == 0)
    }

    @Test("A failed native retry cannot authorize an unrelated later request")
    func authorizationIsScopedToRetry() async throws {
        let coordinator = WindowCloseRequestCoordinator()
        let prompts = Counter()
        let close = Counter()
        coordinator.setHandler { prompts.value += 1; return true }
        for _ in 0..<2 {
            #expect(coordinator.shouldDeferClose { close.value += 1 })
            let pending = try #require(coordinator.pendingTask)
            await pending.value
        }
        #expect(prompts.value == 2)
        #expect(close.value == 2)
    }

    @Test("Close authorization preferences merge in content order")
    func preferenceMerge() async throws {
        let first = PreferenceValues.default.with(\.onWindowCloseRequested, { false })
        let second = PreferenceValues.default.with(\.onWindowCloseRequested, { true })
        let merged = PreferenceValues(merging: [.default, first, second])
        let handler = try #require(merged.onWindowCloseRequested)
        #expect(await handler() == false)
        #expect(PreferenceValues.default.onWindowCloseRequested == nil)
    }
}
