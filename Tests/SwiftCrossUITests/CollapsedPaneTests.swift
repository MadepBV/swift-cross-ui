import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// The shape a window uses to hide one of two panes without dismantling it:
/// the hidden pane is clamped to zero width and its peer takes the rest.
@Suite("A pane clamped to zero width")
struct CollapsedPaneTests {
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
    @Test("The peer of a zero-width pane gets the whole width", arguments: [true, false])
    func peerTakesTheWidth(collapseSecond: Bool) throws {
        let view = HStack(spacing: 0) {
            Color.red
                .frame(minWidth: collapseSecond ? 260 : 0, maxWidth: collapseSecond ? .infinity : 0)
            Color.blue
                .frame(minWidth: collapseSecond ? 0 : 260, maxWidth: collapseSecond ? 0 : .infinity)
        }
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        _ = node.computeLayout(proposedSize: ProposedViewSize(1292, 1031), environment: environment)
        _ = node.commit()
        let stack = try #require(node.widget as? DummyBackend.Container)
        let widths = stack.children.map { Double($0.widget.size.x) }
        let expected: [Double] = collapseSecond ? [1292, 0] : [0, 1292]
        #expect(widths == expected, "pane widths \(widths), expected \(expected)")
    }

    /// The real panes are `GeometryReader` surfaces that size themselves to
    /// the proposal and answer an unbounded proposal with a point (the
    /// canvas cannot paint an infinite raster). The collapsing frames must
    /// still hand the shown pane the whole width.
    struct Surface: View {
        var body: some View {
            GeometryReader { proxy in
                Color.green.frame(
                    width: proxy.size.width.isFinite ? max(proxy.size.width, 1) : 1,
                    height: proxy.size.height.isFinite ? max(proxy.size.height, 1) : 1)
            }
        }
    }

    @MainActor
    @Test("A GeometryReader surface beside a zero-width pane gets the whole width", arguments: [true, false])
    func surfaceTakesTheWidth(collapseSecond: Bool) throws {
        let view = HStack(spacing: 0) {
            ZStack(alignment: .topLeading) { Surface() }
                .frame(minWidth: collapseSecond ? 260 : 0, maxWidth: collapseSecond ? .infinity : 0)
            ZStack(alignment: .topLeading) { Surface() }
                .frame(minWidth: collapseSecond ? 0 : 260, maxWidth: collapseSecond ? 0 : .infinity)
        }
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        _ = node.computeLayout(proposedSize: ProposedViewSize(1292, 1031), environment: environment)
        _ = node.commit()
        let stack = try #require(node.widget as? DummyBackend.Container)
        let widths = stack.children.map { Double($0.widget.size.x) }
        let expected: [Double] = collapseSecond ? [1292, 0] : [0, 1292]
        #expect(widths == expected, "pane widths \(widths), expected \(expected)")
    }

    struct Panes: View {
        var collapseSecond: Bool
        var body: some View {
            HStack(spacing: 0) {
                ZStack(alignment: .topLeading) { Surface() }
                    .frame(minWidth: collapseSecond ? 260 : 0, maxWidth: collapseSecond ? .infinity : 0)
                ZStack(alignment: .topLeading) { Surface() }
                    .frame(minWidth: collapseSecond ? 0 : 260, maxWidth: collapseSecond ? 0 : .infinity)
            }
        }
    }

    /// The transition, not the two end states: a body re-run hands the frame
    /// nodes new constraints under the same proposal, and the widths must
    /// follow. A node that reuses its previous layout here leaves a window
    /// showing the old pane after a layout switch.
    @MainActor
    @Test("Changing which pane is collapsed re-lays-out the panes")
    func togglingTheCollapsedPaneRelaysOut() throws {
        let node = ViewGraphNode(for: Panes(collapseSecond: true), backend: backend, environment: environment)
        let proposal = ProposedViewSize(1292, 1031)
        _ = node.computeLayout(proposedSize: proposal, environment: environment)
        _ = node.commit()
        func widths() throws -> [Double] {
            var current: DummyBackend.Widget? = node.widget
            while let c = current as? DummyBackend.Container, c.children.count == 1 { current = c.children[0].widget }
            let stack = try #require(current as? DummyBackend.Container)
            return stack.children.map { Double($0.widget.size.x) }
        }
        #expect(try widths() == [1292, 0])

        _ = node.computeLayout(with: Panes(collapseSecond: false), proposedSize: proposal, environment: environment)
        _ = node.commit()
        let afterToggle = try widths()
        #expect(afterToggle == [0, 1292], "after the toggle the widths are \(afterToggle)")

        _ = node.computeLayout(with: Panes(collapseSecond: true), proposedSize: proposal, environment: environment)
        _ = node.commit()
        let afterToggleBack = try widths()
        #expect(afterToggleBack == [1292, 0], "after toggling back the widths are \(afterToggleBack)")
    }

    /// The switch as the window performs it: a `@State` flip inside the view
    /// that owns the panes, reaching the frames bottom-up rather than as a
    /// new value handed down by a parent.
    struct PanesHost: View {
        @State var collapseSecond = true
        var body: some View {
            Panes(collapseSecond: collapseSecond)
        }
    }

    @MainActor
    @Test("A @State flip inside the owner re-lays-out the panes")
    func stateFlipRelaysOutThePanes() throws {
        let host = PanesHost()
        let backend = DummyBackend()
        let environment = backend
            .computeRootEnvironment(defaultEnvironment: EnvironmentValues(backend: backend))
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))
        let graph = ViewGraph(for: host, backend: backend, environment: environment)
        let proposal = ProposedViewSize(1292, 1031)
        func pass() {
            _ = graph.computeLayout(proposedSize: proposal, environment: environment)
            _ = graph.rootNode.concreteNode(for: DummyBackend.self).commit()
        }
        func widths() throws -> [Double] {
            var current: DummyBackend.Widget? = graph.rootNode.concreteNode(for: DummyBackend.self).widget
            while let c = current as? DummyBackend.Container, c.children.count == 1 { current = c.children[0].widget }
            let stack = try #require(current as? DummyBackend.Container)
            return stack.children.map { Double($0.widget.size.x) }
        }
        pass(); pass()
        #expect(try widths() == [1292, 0])
        host.collapseSecond = false
        pass()
        let flipped = try widths()
        #expect(flipped == [0, 1292], "after the state flip the widths are \(flipped)")
    }
}
