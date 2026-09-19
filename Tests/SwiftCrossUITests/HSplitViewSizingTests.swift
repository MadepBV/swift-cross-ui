import Foundation
import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Baseline-compatible regressions: copy this file first for the existing
/// HStack facade's bounded-sidebar ideal-width failure.
@Suite("Horizontal split pane sizing")
@MainActor
struct HSplitViewSizingTests {
    @Test("A bounded inspector starts at its ideal beside a flexible workspace")
    func boundedInspectorUsesIdeal() throws {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend).with(\.window,
            backend.createWindow(withDefaultSize: nil, id: "split-sizing"))
        let graph = ViewGraph(for: HSplitView {
            Color.red.frame(minWidth: CGFloat(480), idealWidth: CGFloat(480), maxWidth: .infinity)
            Color.blue.frame(minWidth: CGFloat(220), idealWidth: CGFloat(260), maxWidth: CGFloat(340))
        }, backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        let root = graph.rootNode.concreteNode(for: DummyBackend.self).widget
        let inspector = try #require(rectangles(in: root).first { $0.color == Color.blue.resolve(in: environment) })
        let workspace = try #require(rectangles(in: root).first { $0.color == Color.red.resolve(in: environment) })
        #expect(inspector.size == SIMD2(260, 300))
        #expect(workspace.size == SIMD2(740, 300))
    }

    @Test("Hidden panes preserve their widget while the visible pane fills the split")
    func hiddenPaneKeepsIdentity() throws {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend).with(\.window,
            backend.createWindow(withDefaultSize: nil, id: "split-hide"))
        func content(hidden: Bool) -> some View {
            HSplitView {
                Color.red.frame(minWidth: CGFloat(260), maxWidth: .infinity)
                Color.blue.frame(minWidth: hidden ? CGFloat(0) : CGFloat(220),
                    idealWidth: hidden ? CGFloat(0) : CGFloat(260), maxWidth: hidden ? CGFloat(0) : CGFloat(340))
            }
        }
        let graph = ViewGraph(for: content(hidden: false), backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        let root = graph.rootNode.concreteNode(for: DummyBackend.self).widget
        let first = try #require(rectangles(in: root).first { $0.color == Color.blue.resolve(in: environment) })
        _ = graph.computeLayout(with: content(hidden: true), proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        let hidden = try #require(rectangles(in: root).first { $0.color == Color.blue.resolve(in: environment) })
        #expect(hidden === first)
        #expect(hidden.size.x == 0)
        #expect(rectangles(in: root).first { $0.color == Color.red.resolve(in: environment) }?.size.x == 1000)
        _ = graph.computeLayout(with: content(hidden: false), proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        #expect(rectangles(in: root).first { $0.color == Color.blue.resolve(in: environment) } === first)
        #expect(first.size.x == 260)
    }

    @Test("A collapsed inspector cannot impose its wrapping content's minimum height")
    func collapsedPaneDoesNotSetSplitHeight() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend).with(\.window,
            backend.createWindow(withDefaultSize: nil, id: "split-hidden-height"))
        let graph = ViewGraph(for: HSplitView {
            Color.red.frame(minWidth: CGFloat(220), maxWidth: .infinity)
            Color.blue.frame(width: CGFloat(220), height: CGFloat(800))
                .frame(minWidth: CGFloat(0), idealWidth: CGFloat(0), maxWidth: CGFloat(0))
        }, backend: backend, environment: environment)
        let result = graph.computeLayout(proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        #expect(result.size == ViewSize(1000, 300))
    }

    private func rectangles(in widget: DummyBackend.Widget) -> [DummyBackend.Rectangle] {
        (widget as? DummyBackend.Rectangle).map { [$0] } ?? widget.getChildren().flatMap { rectangles(in: $0) }
    }
}
