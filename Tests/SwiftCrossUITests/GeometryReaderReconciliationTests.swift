import Foundation
import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("GeometryReader content reconciliation")
@MainActor
struct GeometryReaderReconciliationTests {
    final class RecordedSizes {
        var committed: [CGSize] = []
        var all: [CGSize] = []
        var identities: [UUID] = []
    }

    struct SizeLeaf: View {
        let size: CGSize
        let records: RecordedSizes
        @Environment(\.isProbingLayout) private var isProbing

        var body: some View {
            records.all.append(size)
            if !isProbing { records.committed.append(size) }
            return Color.blue.frame(width: Double(size.width), height: Double(size.height))
        }
    }

    struct FixedSlot: View {
        let size: CGSize
        let records: RecordedSizes
        var body: some View {
            SizeLeaf(size: size, records: records)
                .frame(width: 80, height: 40)
        }
    }

    struct PhaseReportingLeaf: View {
        let size: CGSize
        let records: RecordedSizes
        @Environment(\.isProbingLayout) private var isProbing

        var body: some View {
            Color.blue.onChange(of: isProbing) { _, probing in
                if !probing { records.committed.append(size) }
            }
        }
    }

    struct StatefulLeaf: View {
        let size: CGSize
        let records: RecordedSizes
        @State private var identity = UUID()

        var body: some View {
            records.identities.append(identity)
            return Text("Width: \(size.width)")
        }
    }

    @Test("Nested content receives the final size and non-probing environment")
    func nestedContentCommitsFinalSize() {
        let records = RecordedSizes()
        let view = GeometryReader { proxy in
            ZStack {
                SizeLeaf(size: proxy.size, records: records)
            }
        }
        let (backend, environment) = context()
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: ProposedViewSize(1, 1),
            environment: environment.with(\.allowLayoutCaching, true))
        _ = node.computeLayout(proposedSize: ProposedViewSize(640, 480), environment: environment)
        _ = node.commit()
        #expect(records.committed.last == CGSize(width: 640, height: 480))
    }

    @Test("Fixed-size descendants still receive changed geometry content")
    func identicalChildProposalCannotKeepEarlierGeometry() {
        let records = RecordedSizes()
        let view = GeometryReader { proxy in
            VStack { FixedSlot(size: proxy.size, records: records) }
        }
        let (backend, environment) = context()
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: ProposedViewSize(320, 240),
            environment: environment.with(\.allowLayoutCaching, true))
        _ = node.computeLayout(proposedSize: ProposedViewSize(640, 480), environment: environment)
        _ = node.commit()
        #expect(records.all.last == CGSize(width: 640, height: 480))
        #expect(records.committed.last == CGSize(width: 640, height: 480))
    }

    @Test("A persistent split pane receives its expanded committed size")
    func expandingSplitPaneReconcilesGeometry() {
        let records = RecordedSizes()
        func workspace(collapsed: Bool) -> some View {
            HSplitView {
                Color.red.frame(minWidth: collapsed ? 0 : 100,
                    idealWidth: collapsed ? 0 : nil,
                    maxWidth: collapsed ? 0 : .infinity)
                GeometryReader { proxy in
                    ZStack { SizeLeaf(size: proxy.size, records: records) }
                }.frame(minWidth: 100, maxWidth: .infinity)
            }
        }
        let (backend, environment) = context()
        let node = ViewGraphNode(for: workspace(collapsed: false), backend: backend, environment: environment)
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: ProposedViewSize(800, 600), environment: environment)
        _ = node.commit()
        records.committed.removeAll()
        LayoutPass.begin()
        _ = node.computeLayout(with: workspace(collapsed: true),
            proposedSize: ProposedViewSize(800, 600), environment: environment)
        _ = node.commit()
        #expect(records.committed.last == CGSize(width: 800, height: 600))
    }

    @Test("A nested onChange observes the final layout phase with current geometry")
    func nestedPhaseChangeReceivesCurrentGeometry() {
        let records = RecordedSizes()
        let view = GeometryReader { proxy in
            ZStack { PhaseReportingLeaf(size: proxy.size, records: records) }
        }
        let (backend, environment) = context()
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: ProposedViewSize(1, 1),
            environment: environment.with(\.allowLayoutCaching, true))
        _ = node.computeLayout(proposedSize: ProposedViewSize(640, 480), environment: environment)
        _ = node.commit()
        #expect(records.committed == [CGSize(width: 640, height: 480)])
    }

    @Test("Recomputing geometry retains descendant state and widgets")
    func geometryChangesPreserveStateAndWidgets() throws {
        let records = RecordedSizes()
        let view = GeometryReader { proxy in
            ZStack { StatefulLeaf(size: proxy.size, records: records) }
        }
        let (backend, environment) = context()
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: ProposedViewSize(320, 240), environment: environment)
        _ = node.commit()
        let firstText = try #require(node.widget.firstWidget(ofType: DummyBackend.TextView.self))

        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: ProposedViewSize(1, 1),
            environment: environment.with(\.allowLayoutCaching, true))
        _ = node.computeLayout(proposedSize: ProposedViewSize(640, 480), environment: environment)
        _ = node.commit()
        let finalText = try #require(node.widget.firstWidget(ofType: DummyBackend.TextView.self))
        #expect(firstText === finalText)
        #expect(finalText.content == "Width: 640.0")
        #expect(Set(records.identities).count == 1)
    }

    private func context() -> (DummyBackend, EnvironmentValues) {
        let backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "geometry-reconcile")
        let environment = EnvironmentValues(backend: backend).with(\.window, window)
        return (backend, environment)
    }
}
