import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Masks")
struct MaskTests {
    @MainActor
    @Test("A mask is proposed the content's size, never changes it and is never drawn")
    func maskKeepsTheContentsLayout() {
        let view = Color.red.frame(width: 120, height: 80)
            .mask(alignment: .bottomTrailing) { Color.black.frame(width: 40, height: 20) }

        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(300, 300))
        let container = try! #require(node.widget.firstWidget(ofType: DummyBackend.MaskContainer.self))

        #expect(container.size == SIMD2(120, 80))
        #expect(container.getChildren().count == 1)
        #expect(container.mask?.size == SIMD2(40, 20))
        #expect(container.maskOrigin == SIMD2(80, 60))
    }

    @MainActor
    @Test("A view-filling mask, such as a colour or a gradient, takes the content's size")
    func gradientMaskFillsTheContent() {
        let view = Color.red.frame(width: 120, height: 80)
            .mask { Color.black.opacity(0.5) }

        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(300, 300))
        let container = try! #require(node.widget.firstWidget(ofType: DummyBackend.MaskContainer.self))
        #expect(container.mask?.size == SIMD2(120, 80))
        #expect(container.maskOrigin == .zero)
    }
}
