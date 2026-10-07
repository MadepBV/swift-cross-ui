import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Lazy stacks")
struct LazyStackWidthTests {
    @MainActor
    @Test("A lazy vertical stack takes the width it's offered and aligns its children in it")
    func lazyVStackFillsTheProposedWidth() {
        for (alignment, expected) in [(HorizontalAlignment.leading, [0, 0]), (.center, [85, 75]), (.trailing, [170, 150])] {
            let view = LazyVStack(alignment: alignment, spacing: 0) {
                Color.blue.frame(width: 30, height: 10)
                Color.blue.frame(width: 50, height: 10)
            }
            let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(200, 100))
            let stack = try! #require(node.widget.firstWidget(ofType: DummyBackend.Container.self))
            #expect(stack.size == SIMD2(200, 20))
            #expect(stack.children.map(\.position.x) == expected)
        }
    }

    @MainActor
    @Test("Asked for its ideal size, a lazy vertical stack is as wide as its widest child")
    func lazyVStackIdealWidth() {
        let view = LazyVStack {
            Color.blue.frame(width: 30, height: 10)
            Color.blue.frame(width: 50, height: 10)
        }
        #expect(ViewGraphHelpers.computeLayout(of: view).size.width == 50)
    }
}
