import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing for stack layouts")
struct StackLayoutTests {
    @MainActor
    @Test("Empty ScrollView should still be greedy in stack (#328)")
    func emptyScrollViewInStack() {
        let view = VStack {
            Text("Dummy")
            ScrollView {}
        }

        let height = 200.0
        let result = ViewGraphHelpers.computeLayout(
            of: view,
            proposedSize: ProposedViewSize(100, height)
        )

        #expect(result.size.height == height)
    }

    @MainActor
    @Test("Fixed size stack redistributes space (#453)")
    func fixedSizeStackSpaceRedistribution() {
        let view = VStack(spacing: 0) {
            Text("Dummy")
            Color.blue
            Text("Dummy")
        }.fixedSize()

        let node = ViewGraphHelpers.committedNode(
            for: view,
            proposedSize: ProposedViewSize(200, 200)
        )

        let fixedSizeWidget = node.widget.getChildren()[0]
        let children = fixedSizeWidget.getChildren()
        let text1 = children[0]
        let color = children[1]
        let text2 = children[2]

        // Ensure #453 resolved
        #expect(text1.size.x == color.size.x)

        // Sanity checks
        #expect(text1.size == text2.size)
    }

    @MainActor
    @Test("Spacer layout priority")
    func spacerLayoutPriority() {
        let strings = ["AA", "AAAA"]
        let view = HStack(spacing: 0) {
            Text(strings[0])
            Spacer(minLength: 0)
            Text(strings[1])
        }

        let lineHeight = ViewGraphHelpers.environment.resolvedFont.lineHeight

        let textResults = strings.map(Text.init(_:)).map {
            ViewGraphHelpers.computeLayout(of: $0)
        }
        let minimumWidthWithoutWrapping = textResults.map(\.size.vector.x).reduce(0, +)
        let proposedSize = ProposedViewSize(
            Double(minimumWidthWithoutWrapping),
            lineHeight * 2
        )
        let result = ViewGraphHelpers.computeLayout(of: view, proposedSize: proposedSize)

        // No wrapping, and perfect fit
        #expect(result.size.height == ViewGraphHelpers.environment.resolvedFont.lineHeight)
        #expect(result.size.vector.x == minimumWidthWithoutWrapping)
    }

    @MainActor
    @Test("A row proposed its ideal width gives every child its ideal width")
    func rowProposedItsIdealWidthKeepsEveryChildIdeal() {
        // Three wrappable labels of different flexibility, like a row of
        // buttons. Each one must be offered its share of the whole row, not
        // its share minus every later sibling's minimum, or the least flexible
        // labels wrap although the row has all the space it asked for.
        let titles = ["Sign in to Avelio", "Connect a provider", "Explore a preview"]
        let view = HStack(spacing: 12) {
            Text(titles[0])
            Text(titles[1])
            Text(titles[2])
        }

        let ideal = ViewGraphHelpers.computeLayout(of: view)
        let node = ViewGraphHelpers.committedNode(
            for: view,
            proposedSize: ProposedViewSize(ideal.size.width, 600)
        )

        let children = node.widget.getChildren()
        for (child, title) in zip(children, titles) {
            let idealChild = ViewGraphHelpers.computeLayout(of: Text(title))
            #expect(Double(child.size.x) == idealChild.size.width)
            #expect(Double(child.size.y) == idealChild.size.height)
        }
    }
}
