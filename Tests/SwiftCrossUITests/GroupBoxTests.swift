import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing for GroupBox")
struct GroupBoxTests {
    /// The width proposed to every group box under test. The height is left
    /// unspecified so that the group boxes report their ideal heights.
    static let proposal = ProposedViewSize(400, nil)

    /// The total vertical padding that ``GroupBox`` adds around its content.
    static let verticalContentPadding = 24.0

    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    @MainActor
    @Test("GroupBox takes up the width that it's proposed")
    func groupBoxFillsProposedWidth() {
        let view = GroupBox("Region") {
            Text("Width")
        }

        let result = computeLayout(of: view)

        #expect(result.size.width == GroupBoxTests.proposal.width)
    }

    @MainActor
    @Test("GroupBox grows exactly as much as its content does")
    func groupBoxGrowsWithContent() {
        let short = GroupBox {
            Color.blue.frame(height: 50)
        }
        let tall = GroupBox {
            Color.blue.frame(height: 150)
        }

        let shortHeight = computeLayout(of: short).size.height
        let tallHeight = computeLayout(of: tall).size.height

        #expect(tallHeight - shortHeight == 100)
    }

    @MainActor
    @Test("GroupBox pads its content")
    func groupBoxPadsItsContent() {
        let contentHeight = 50.0
        let view = GroupBox {
            Color.blue.frame(height: contentHeight)
        }

        let result = computeLayout(of: view)

        #expect(
            result.size.height
                == contentHeight + GroupBoxTests.verticalContentPadding
        )
    }

    @MainActor
    @Test("GroupBox's label adds height, and an absent label doesn't")
    func groupBoxLabelAffectsHeight() {
        let contentHeight = 50.0
        let unlabelled = GroupBox {
            Color.blue.frame(height: contentHeight)
        }
        let labelled = GroupBox("Region") {
            Color.blue.frame(height: contentHeight)
        }

        let unlabelledHeight = computeLayout(of: unlabelled).size.height
        let labelledHeight = computeLayout(of: labelled).size.height

        // An `EmptyView` label must contribute neither height nor spacing.
        #expect(
            unlabelledHeight
                == contentHeight + GroupBoxTests.verticalContentPadding
        )
        #expect(labelledHeight > unlabelledHeight)
    }

    @MainActor
    @Test("GroupBox renders both its label and its content")
    func groupBoxRendersLabelAndContent() {
        let view = GroupBox("Region") {
            Text("Width")
            Text("Height")
        }

        let node = committedNode(for: view)
        let renderedText = texts(in: node.widget)

        #expect(renderedText.contains("Region"))
        #expect(renderedText.contains("Width"))
        #expect(renderedText.contains("Height"))
    }

    @MainActor
    @Test("GroupBox stacks its content vertically")
    func groupBoxStacksContentVertically() {
        let single = GroupBox {
            Color.blue.frame(height: 40)
        }
        let double = GroupBox {
            Color.blue.frame(height: 40)
            Color.blue.frame(height: 40)
        }

        let singleHeight = computeLayout(of: single).size.height
        let doubleHeight = computeLayout(of: double).size.height

        // The second child must add its own height plus the stack's spacing.
        #expect(doubleHeight >= singleHeight + 40)
    }

    @MainActor
    @Test("GroupBox provides SwiftUI's initializers")
    func groupBoxProvidesSwiftUIInitializers() {
        let unlabelled = GroupBox {
            Text("Width")
        }
        let titled = GroupBox("Region") {
            Text("Width")
        }
        let customLabel = GroupBox {
            Text("Width")
        } label: {
            Text("Region")
        }

        #expect(computeLayout(of: unlabelled).size.height > 0)
        #expect(computeLayout(of: titled).size.height > 0)
        #expect(computeLayout(of: customLabel).size.height > 0)
    }

    // MARK: Helpers

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = GroupBoxTests.proposal
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        return node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }

    @MainActor
    func committedNode<V: View>(
        for view: V,
        proposedSize: ProposedViewSize = GroupBoxTests.proposal
    ) -> ViewGraphNode<V, DummyBackend> {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        _ = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        return node
    }

    /// Collects the content of every text widget in a widget hierarchy.
    @MainActor
    func texts(in widget: DummyBackend.Widget) -> [String] {
        var result: [String] = []
        if let textView = widget as? DummyBackend.TextView {
            result.append(textView.content)
        }
        for child in widget.getChildren() {
            result += texts(in: child)
        }
        return result
    }
}
