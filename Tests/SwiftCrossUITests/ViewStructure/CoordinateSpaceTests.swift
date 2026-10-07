import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Named coordinate spaces")
struct CoordinateSpaceTests {
    @MainActor
    @Test("A frame in a named space is where the view sits below the view that named it")
    func frameInNamedSpace() {
        let recorder = ValueRecorder<CGRect>()
        let view = VStack(spacing: 10) {
            block(50, 30)
            HStack(spacing: 4) {
                block(20, 20)
                block(40, 12).onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named("page"))
                } action: { frame in
                    recorder.values.append(frame)
                }
            }
        }
        .padding(8)
        .coordinateSpace(name: "page")

        _ = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(200, 200))
        // Positions are only known once the whole commit has finished.
        #expect(recorder.values.isEmpty)
        DeferredGeometryObservations.runPending()

        let frame = try! #require(recorder.values.last)
        #expect(frame.size == CGSize(width: 40, height: 12))
        // Padding, the first block and the spacing above the row, and the
        // row centres the shorter block against the taller one.
        let expectedTop: CGFloat = 8 + 30 + 10 + 4
        #expect(frame.origin.y == expectedTop, "\(frame.origin.y.description)")
        #expect(frame.minX > 8 + 20)
    }

    @MainActor
    @Test("A local frame is reported during the commit, as before")
    func localFrameIsImmediate() {
        let recorder = ValueRecorder<CGFloat>()
        let view = block(30, 12)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .local).maxY } action: { recorder.values.append($0) }
            .coordinateSpace(name: "page")
        _ = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        #expect(recorder.values == [12])
    }

    @MainActor
    @Test("A name no ancestor gave falls back to the view's own bounds")
    func unknownNameIsLocal() {
        let recorder = ValueRecorder<CGFloat>()
        let view = VStack {
            block(10, 10)
            block(30, 12).onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("elsewhere")).minY } action: {
                recorder.values.append($0)
            }
        }
        _ = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        DeferredGeometryObservations.runPending()
        #expect(recorder.values == [0])
    }

    @MainActor
    @Test("A frame in the scroll view's space is relative to its visible region")
    func frameInScrollViewSpace() {
        let recorder = ValueRecorder<CGFloat>()
        let view = ScrollView {
            VStack(spacing: 0) {
                block(50, 70)
                block(50, 20).onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).minY } action: {
                    recorder.values.append($0)
                }
                block(50, 200)
            }
        }
        _ = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        DeferredGeometryObservations.runPending()
        #expect(recorder.values == [70])
    }
}
