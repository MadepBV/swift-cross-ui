import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Lazy appearance")
struct LazyAppearanceTests {
    @MainActor
    private func feed(_ recorder: ValueRecorder<Int>, lazy: Bool) -> some View {
        ScrollView {
            if lazy {
                LazyVStack(spacing: 0) { rows(recorder) }
            } else {
                VStack(spacing: 0) { rows(recorder) }
            }
        }
    }

    @MainActor
    private func rows(_ recorder: ValueRecorder<Int>) -> some View {
        ForEach(0..<40, id: \.self) { index in
            Color.blue.frame(height: 50).onAppear { recorder.values.append(index) }
        }
    }

    @MainActor
    @Test("Rows of a lazy stack appear as they come within a screen of the visible region")
    func lazyRowsAppearWhenNear() throws {
        let recorder = ValueRecorder<Int>()
        let node = ViewGraphHelpers.committedNode(
            for: feed(recorder, lazy: true),
            proposedSize: ProposedViewSize(100, 100)
        )
        #expect(recorder.values.isEmpty)
        DeferredGeometryObservations.runPending()
        // Visible: 0–100; a screen below reaches 200, so rows 0 to 3.
        #expect(recorder.values == [0, 1, 2, 3])

        let scrollView = try #require(node.widget.firstWidget(ofType: DummyBackend.ScrollContainer.self))
        scrollView.scrollOffset = SIMD2(0, 500)
        scrollView.scrollChangeHandler?()
        DeferredGeometryObservations.runPending()
        // Visible: 500–600, reaching 400–700: rows 8 to 13. Rows that already
        // appeared don't appear again.
        #expect(recorder.values == [0, 1, 2, 3, 8, 9, 10, 11, 12, 13])
    }

    @MainActor
    @Test("Rows of an ordinary stack appear at once, as in SwiftUI")
    func eagerRowsAppearAtOnce() {
        let recorder = ValueRecorder<Int>()
        _ = ViewGraphHelpers.committedNode(for: feed(recorder, lazy: false), proposedSize: ProposedViewSize(100, 100))
        #expect(recorder.values == Array(0..<40))
    }

    @MainActor
    @Test("A task in a lazy row starts when the row appears")
    func taskWaitsForAppearance() async throws {
        let started = ValueRecorder<Int>()
        let view = ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    Color.blue.frame(height: 50).task { started.values.append(index) }
                }
            }
        }
        // Kept alive: the scroll view's registry goes away with its node.
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        DeferredGeometryObservations.runPending()
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(Set(started.values) == [0, 1, 2, 3])
        withExtendedLifetime(node) {}
    }
}
