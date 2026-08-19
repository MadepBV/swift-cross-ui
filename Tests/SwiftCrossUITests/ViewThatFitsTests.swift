import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing for ViewThatFits")
struct ViewThatFitsTests {
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
    @Test("The first candidate gets selected when it fits")
    func firstCandidateFits() {
        let view = ViewThatFits(in: .horizontal) {
            Color.blue.frame(width: 100, height: 20)
            Color.red.frame(width: 40, height: 60)
        }

        let result = computeLayout(of: view, proposedSize: ProposedViewSize(200, 200))

        #expect(result.size == ViewSize(100, 20))
    }

    @MainActor
    @Test("The last candidate gets selected when no candidate fits")
    func noCandidateFits() {
        let view = ViewThatFits(in: .horizontal) {
            Color.blue.frame(width: 100, height: 20)
            Color.red.frame(width: 40, height: 60)
        }

        let result = computeLayout(of: view, proposedSize: ProposedViewSize(30, 200))

        // Selected despite being 40 points wide within a 30 point proposal.
        #expect(result.size == ViewSize(40, 60))
    }

    @MainActor
    @Test("Intermediate candidates get selected when they're the first to fit")
    func intermediateCandidateFits() {
        let view = ViewThatFits(in: .horizontal) {
            Color.blue.frame(width: 300, height: 10)
            Color.red.frame(width: 150, height: 20)
            Color.green.frame(width: 50, height: 30)
        }

        let result = computeLayout(of: view, proposedSize: ProposedViewSize(200, 200))

        #expect(result.size == ViewSize(150, 20))
    }

    @MainActor
    @Test("A candidate that exactly fills the proposal counts as fitting")
    func exactFitCounts() {
        let view = ViewThatFits(in: .horizontal) {
            Color.blue.frame(width: 100, height: 20)
            Color.red.frame(width: 40, height: 60)
        }

        let result = computeLayout(of: view, proposedSize: ProposedViewSize(100, 200))

        #expect(result.size == ViewSize(100, 20))
    }

    @MainActor
    @Test("Horizontal fitting ignores the proposed height")
    func horizontalIgnoresHeight() {
        let view = ViewThatFits(in: .horizontal) {
            Color.blue.frame(width: 100, height: 500)
            Color.red.frame(width: 40, height: 30)
        }

        // The first candidate is five times taller than the proposal allows,
        // but height isn't part of the fit test.
        let result = computeLayout(of: view, proposedSize: ProposedViewSize(200, 100))

        #expect(result.size == ViewSize(100, 500))
    }

    @MainActor
    @Test("Vertical fitting ignores the proposed width")
    func verticalIgnoresWidth() {
        let view = ViewThatFits(in: .vertical) {
            Color.blue.frame(width: 500, height: 20)
            Color.red.frame(width: 40, height: 30)
        }

        let result = computeLayout(of: view, proposedSize: ProposedViewSize(100, 200))

        #expect(result.size == ViewSize(500, 20))
    }

    @MainActor
    @Test("Fitting on both axes rejects candidates that overflow either axis")
    func bothAxesGetTested() {
        let tooTall = ViewThatFits {
            Color.blue.frame(width: 100, height: 500)
            Color.red.frame(width: 40, height: 30)
        }
        let tooWide = ViewThatFits {
            Color.blue.frame(width: 500, height: 20)
            Color.red.frame(width: 40, height: 30)
        }

        let proposedSize = ProposedViewSize(200, 100)
        let tooTallResult = computeLayout(of: tooTall, proposedSize: proposedSize)
        let tooWideResult = computeLayout(of: tooWide, proposedSize: proposedSize)

        #expect(tooTallResult.size == ViewSize(40, 30))
        #expect(tooWideResult.size == ViewSize(40, 30))
    }

    @MainActor
    @Test("An unspecified proposal fits everything, selecting the first candidate")
    func unspecifiedProposalSelectsFirstCandidate() {
        let view = ViewThatFits {
            Color.blue.frame(width: 1000, height: 1000)
            Color.red.frame(width: 10, height: 10)
        }

        let result = computeLayout(of: view, proposedSize: .unspecified)

        #expect(result.size == ViewSize(1000, 1000))
    }

    @MainActor
    @Test("Candidates get measured at their ideal size, not their squished size")
    func candidatesGetMeasuredAtTheirIdealSize() {
        // Text squishes itself into whatever width it's proposed (by wrapping),
        // so a naive implementation would always consider it to fit.
        let longText = "This label is far too long to fit"
        let view = ViewThatFits(in: .horizontal) {
            Text(longText)
            Text("Short")
        }

        let idealWidth = computeLayout(of: Text(longText)).size.width
        let proposedSize = ProposedViewSize(idealWidth / 2, 1000)

        let result = computeLayout(of: view, proposedSize: proposedSize)
        let fallbackResult = computeLayout(of: Text("Short"), proposedSize: proposedSize)

        #expect(result.size == fallbackResult.size)
    }

    @MainActor
    @Test("Content with no candidates lays out as an empty view")
    func emptyContentIsEmpty() {
        let view = ViewThatFits {}

        let result = computeLayout(of: view, proposedSize: ProposedViewSize(200, 200))

        #expect(result.size == ViewSize.zero)
    }

    @MainActor
    @Test("Only the selected candidate's widget is in the widget hierarchy")
    func onlyTheSelectedCandidateIsRendered() {
        let view = ViewThatFits(in: .horizontal) {
            Text("Wide").frame(width: 300, height: 10)
            Color.blue.frame(width: 20, height: 10)
        }

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        update(node, proposedSize: ProposedViewSize(400, 400))

        let container = node.widget as! DummyBackend.Container
        #expect(container.children.count == 1)
        #expect(container.firstWidget(ofType: DummyBackend.TextView.self) != nil)
        #expect(container.firstWidget(ofType: DummyBackend.Rectangle.self) == nil)
    }

    @MainActor
    @Test("Shrinking the proposal swaps the rendered candidate without leaking widgets")
    func selectionSwapsWidgets() {
        let view = ViewThatFits(in: .horizontal) {
            Text("Wide").frame(width: 300, height: 10)
            Color.blue.frame(width: 20, height: 10)
        }

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        update(node, proposedSize: ProposedViewSize(400, 400))
        update(node, proposedSize: ProposedViewSize(100, 400))

        let container = node.widget as! DummyBackend.Container
        #expect(container.children.count == 1)
        #expect(container.firstWidget(ofType: DummyBackend.Rectangle.self) != nil)
        #expect(container.firstWidget(ofType: DummyBackend.TextView.self) == nil)
    }

    @MainActor
    @Test("Re-laying out a stable selection reuses the same widget")
    func stableSelectionReusesWidget() {
        let view = ViewThatFits(in: .horizontal) {
            Color.blue.frame(width: 100, height: 10)
            Color.red.frame(width: 20, height: 10)
        }

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        update(node, proposedSize: ProposedViewSize(400, 400))

        let container = node.widget as! DummyBackend.Container
        let originalWidget = container.children[0].widget

        update(node, proposedSize: ProposedViewSize(300, 400))

        #expect(container.children.count == 1)
        #expect(container.children[0].widget === originalWidget)
    }

    @MainActor
    @Test("Rejected candidates get re-measured after their content changes")
    func rejectedCandidatesGetRemeasured() {
        let proposedSize = ProposedViewSize(100, 100)

        let node = ViewGraphNode(
            for: adaptiveRow(firstCandidateWidth: 300),
            backend: backend,
            environment: environment
        )

        let initialResult = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        #expect(initialResult.size == ViewSize(20, 40))

        // The first candidate is now narrow enough to fit, so it must win even
        // though it was rejected (and therefore never committed) last time.
        let updatedResult = node.computeLayout(
            with: adaptiveRow(firstCandidateWidth: 50),
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()

        #expect(updatedResult.size == ViewSize(50, 10))
    }

    @MainActor
    @Test("The selection stays stable across repeated updates")
    func selectionIsStableAcrossUpdates() {
        let proposedSize = ProposedViewSize(100, 100)
        let node = ViewGraphNode(
            for: adaptiveRow(firstCandidateWidth: 300),
            backend: backend,
            environment: environment
        )

        for _ in 0..<3 {
            let result = node.computeLayout(
                with: adaptiveRow(firstCandidateWidth: 300),
                proposedSize: proposedSize,
                environment: environment
            )
            _ = node.commit()
            #expect(result.size == ViewSize(20, 40))
        }
    }

    @MainActor
    @Test("Candidates are selected correctly within a stack")
    func fitsWithinStack() {
        let view = HStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                Color.blue.frame(width: 100, height: 10)
                Color.red.frame(width: 20, height: 10)
            }
            Color.green.frame(width: 10, height: 10)
        }

        // 200 points is enough room for the wide candidate (100) alongside the
        // stack's other child (10).
        let roomyResult = computeLayout(of: view, proposedSize: ProposedViewSize(200, 100))
        #expect(roomyResult.size == ViewSize(110, 10))

        // 25 points isn't, so the narrow candidate (20) gets used instead.
        let crampedResult = computeLayout(of: view, proposedSize: ProposedViewSize(25, 100))
        #expect(crampedResult.size == ViewSize(30, 10))
    }

    @MainActor
    @Test("A row degrades into a column once its container gets too narrow")
    func rowDegradesIntoColumn() {
        let view = ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                Color.blue.frame(width: 60, height: 10)
                Color.red.frame(width: 60, height: 10)
            }
            VStack(spacing: 0) {
                Color.blue.frame(width: 60, height: 10)
                Color.red.frame(width: 60, height: 10)
            }
        }

        let roomyResult = computeLayout(of: view, proposedSize: ProposedViewSize(200, 200))
        #expect(roomyResult.size == ViewSize(120, 10))

        let crampedResult = computeLayout(of: view, proposedSize: ProposedViewSize(80, 200))
        #expect(crampedResult.size == ViewSize(60, 20))
    }

    // MARK: Helpers

    /// A view whose first candidate's width can be varied to simulate the
    /// candidate's content changing between updates.
    ///
    /// - Parameter firstCandidateWidth: The width of the first candidate.
    /// - Returns: The view.
    @MainActor
    func adaptiveRow(firstCandidateWidth: Double) -> some View {
        ViewThatFits(in: .horizontal) {
            Color.blue.frame(width: firstCandidateWidth, height: 10)
            Color.red.frame(width: 20, height: 40)
        }
    }

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = .unspecified
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        return node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }

    /// Computes and then commits a node's layout, mimicking a single update of
    /// the view graph.
    ///
    /// - Parameters:
    ///   - node: The node to update.
    ///   - proposedSize: The size to propose to the node.
    /// - Returns: The node's computed layout result.
    @MainActor
    @discardableResult
    func update<V: View>(
        _ node: ViewGraphNode<V, DummyBackend>,
        proposedSize: ProposedViewSize
    ) -> ViewLayoutResult {
        let result = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        return result
    }
}
