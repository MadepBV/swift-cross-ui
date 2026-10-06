import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Places subviews left to right, wrapping onto a new row when the next one
/// doesn't fit (the shape of the flow layout apps commonly write).
struct WrappingRow: Layout {
    var spacing: CGFloat = 2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = self.rows(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var y = bounds.origin.y
        for row in rows(width: Double(bounds.size.width), subviews: subviews) {
            var x = bounds.origin.x
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(width maxWidth: Double, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let extra = row.indices.isEmpty ? size.width : spacing + size.width
            if !row.indices.isEmpty, Double(row.width + extra) > maxWidth {
                rows.append(row)
                row = Row()
            }
            row.width += row.indices.isEmpty ? size.width : spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty {
            rows.append(row)
        }
        return rows
    }
}

@Suite("Custom layouts")
struct CustomLayoutTests {
    @MainActor
    @Test("A custom layout sizes and places its subviews")
    func customLayoutPlacesSubviews() {
        let view = WrappingRow {
            block(10, 10)
            block(10, 5)
            block(10, 10)
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(25, 100))
        #expect(node.currentLayout?.size == ViewSize(22, 22))
        #expect(
            leafFrames(of: node.widget).map(\.origin)
                == [SIMD2(0, 0), SIMD2(12, 0), SIMD2(0, 12)]
        )
    }

    @MainActor
    @Test("ForEach items are individual subviews of a custom layout")
    func forEachItemsAreSubviews() {
        let view = WrappingRow {
            ForEach([0, 1, 2], id: \.self) { _ in
                block(10, 10)
            }
            block(4, 4)
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(25, 100))
        #expect(
            leafFrames(of: node.widget).map(\.origin)
                == [SIMD2(0, 0), SIMD2(12, 0), SIMD2(0, 12), SIMD2(12, 12)]
        )
    }

    @MainActor
    @Test("A stack layout lays out like the matching stack")
    func stackLayoutMatchesStack() {
        let layout = HStackLayout(alignment: .top, spacing: 3) {
            block(10, 10)
            block(10, 20)
        }
        let stack = HStack(alignment: .top, spacing: 3) {
            block(10, 10)
            block(10, 20)
        }
        let layoutNode = ViewGraphHelpers.committedNode(for: layout, proposedSize: ProposedViewSize(100, 100))
        let stackNode = ViewGraphHelpers.committedNode(for: stack, proposedSize: ProposedViewSize(100, 100))
        #expect(layoutNode.currentLayout?.size == stackNode.currentLayout?.size)
        #expect(
            leafFrames(of: layoutNode.widget).map(\.origin)
                == leafFrames(of: stackNode.widget).map(\.origin)
        )
    }

    @MainActor
    @Test("Switching an AnyLayout rearranges the same views")
    func anyLayoutSwitches() {
        func view(vertical: Bool) -> some View {
            let layout = vertical ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
            return layout {
                block(10, 10)
                block(10, 10)
            }
        }

        let environment = ViewGraphHelpers.environment
        let node = ViewGraphNode(
            for: view(vertical: false),
            backend: ViewGraphHelpers.backend,
            environment: environment
        )
        _ = node.computeLayout(proposedSize: ProposedViewSize(100, 100), environment: environment)
        _ = node.commit()
        #expect(leafFrames(of: node.widget).map(\.origin) == [SIMD2(0, 0), SIMD2(10, 0)])

        LayoutPass.begin()
        _ = node.computeLayout(
            with: view(vertical: true),
            proposedSize: ProposedViewSize(100, 100),
            environment: environment
        )
        _ = node.commit()
        #expect(leafFrames(of: node.widget).map(\.origin) == [SIMD2(0, 0), SIMD2(0, 10)])
    }

    @MainActor
    @Test("AnyLayout forwards the Layout protocol to the wrapped layout")
    func anyLayoutForwardsLayoutProtocol() {
        // A custom layout wrapped in AnyLayout goes through `Layout`, not a
        // stack.
        let view = AnyLayout(WrappingRow()) {
            block(10, 10)
            block(10, 10)
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(15, 100))
        #expect(leafFrames(of: node.widget).map(\.origin) == [SIMD2(0, 0), SIMD2(0, 12)])
    }
}
