import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Switching an `if`/`else` must take the old branch's widget out of the
/// tree. A branch that lingers after a switch shows on screen as chrome from
/// a pane that is no longer there.
@Suite("EitherView branch switching")
struct EitherViewSwitchTests {
    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    struct Pane: View {
        var showsBar: Bool
        var body: some View {
            if showsBar {
                Color.red.frame(width: 40, height: 10)
                Color.red.frame(width: 40, height: 10)
            } else {
                Color.blue.frame(width: 20, height: 20)
            }
        }
    }

    @MainActor
    @Test("Switching branches removes the old branch's widget")
    func switchingRemovesTheOldBranch() throws {
        let node = ViewGraphNode(for: Pane(showsBar: true), backend: backend, environment: environment)
        _ = node.computeLayout(proposedSize: ProposedViewSize(200, 200), environment: environment)
        _ = node.commit()
        let either = try #require(eitherContainer(under: node.widget))
        #expect(either.children.count == 1)
        let before = either.children[0].widget

        _ = node.computeLayout(
            with: Pane(showsBar: false), proposedSize: ProposedViewSize(200, 200), environment: environment)
        _ = node.commit()
        #expect(either.children.count == 1, "old branch lingered: \(either.children.count) children")
        #expect(either.children[0].widget !== before, "the widget shown is still the old branch's")
        #expect(Double(node.widget.size.y) == 20, "the pane did not take the new branch's size")
    }

    /// The `EitherView`'s own container: the first container whose single
    /// child is not itself a wrapper of the same view.
    @MainActor
    private func eitherContainer(under widget: DummyBackend.Widget) -> DummyBackend.Container? {
        var current: DummyBackend.Widget? = widget
        var last: DummyBackend.Container?
        while let container = current as? DummyBackend.Container, container.children.count == 1 {
            last = container
            current = container.children[0].widget
        }
        return last
    }
}
