import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

extension VerticalAlignment {
    fileprivate enum Marker: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.top]
        }
    }

    fileprivate static let marker = VerticalAlignment(Marker.self)
}

@Suite("Alignment guides")
struct AlignmentGuideTests {
    @MainActor
    @Test("An explicit guide moves a child in a stack aligned on it")
    func explicitGuideInHStack() {
        let view = HStack(alignment: .bottom, spacing: 0) {
            block(10, 10)
            // Its "bottom" is 10 points above its real bottom.
            block(10, 30).alignmentGuide(.bottom) { $0.height - 10 }
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        let frames = leafFrames(of: node.widget)

        // Guides: 10 and 20, so the short block moves down by 10 and the stack
        // is 20 above the shared line plus 10 below it.
        #expect(node.currentLayout?.size == ViewSize(20, 30))
        #expect(frames.map(\.origin) == [SIMD2(0, 10), SIMD2(10, 0)])
    }

    @MainActor
    @Test("Custom guides default to their default value and carry out of a VStack")
    func customGuideThroughVStack() {
        let view = HStack(alignment: .marker, spacing: 0) {
            VStack(spacing: 0) {
                block(10, 10)
                block(10, 20).alignmentGuide(.marker) { $0[VerticalAlignment.center] }
            }
            block(10, 4)
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        let frames = leafFrames(of: node.widget)

        // The VStack's marker is 10 (its second block's top) + 10 (centre) =
        // 20; the lone block's marker defaults to its top, so it sits at 20.
        #expect(frames.map(\.origin) == [SIMD2(0, 0), SIMD2(0, 10), SIMD2(10, 20)])
        #expect(node.currentLayout?.size == ViewSize(20, 30))
    }

    @MainActor
    @Test("Text baselines default to the bottom edge")
    func firstTextBaselineDefaultsToBottom() {
        let view = HStack(alignment: .firstTextBaseline, spacing: 0) {
            block(10, 10)
            block(10, 30)
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        #expect(leafFrames(of: node.widget).map(\.origin) == [SIMD2(0, 20), SIMD2(10, 0)])
    }

    @MainActor
    @Test("Edge alignments without explicit guides place children by size")
    func edgeAlignmentUnchanged() {
        let view = HStack(alignment: .center, spacing: 0) {
            block(10, 10)
            block(10, 30)
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        #expect(leafFrames(of: node.widget).map(\.origin) == [SIMD2(0, 10), SIMD2(10, 0)])
    }

    @MainActor
    @Test("ViewDimensions reports explicit guides")
    func viewDimensionsExplicitGuides() {
        let dimensions = ViewDimensions(
            size: ViewSize(10, 40),
            explicitGuides: [VerticalAlignment.bottom.key: 30]
        )
        #expect(dimensions[VerticalAlignment.bottom] == 30)
        #expect(dimensions[explicit: VerticalAlignment.bottom] == 30)
        #expect(dimensions[explicit: VerticalAlignment.top] == nil)
        #expect(dimensions[VerticalAlignment.center] == 20)
        #expect(dimensions[HorizontalAlignment.trailing] == 10)
    }
}
