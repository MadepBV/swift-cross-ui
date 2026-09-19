import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI
#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

@Suite("Subtree hit testing")
@MainActor
struct HitTestingTests {
    @Test("Unsupported backends preserve content, updates and layout")
    func unsupportedBackendPreservesContent() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend).with(
            \.window, backend.createWindow(withDefaultSize: nil, id: "hit-testing"))
        func content(_ label: String, allows: Bool) -> some View {
            Text(label).frame(width: 160, height: 90).allowsHitTesting(allows)
        }
        let graph = ViewGraph(for: content("Before", allows: true),
            backend: backend, environment: environment)
        let first = graph.computeLayout(proposedSize: ProposedViewSize(160, 90), environment: environment)
        graph.commit()
        let widget = graph.rootNode.concreteNode(for: DummyBackend.self).widget
        let second = graph.computeLayout(with: content("After", allows: false),
            proposedSize: ProposedViewSize(160, 90), environment: environment)
        graph.commit()
        #expect(first.size == ViewSize(160, 90))
        #expect(second.size == first.size)
        #expect(graph.rootNode.concreteNode(for: DummyBackend.self).widget === widget)
        #expect(widget.firstWidget(ofType: DummyBackend.TextView.self)?.content == "After")
    }

    #if canImport(AppKitBackend)
    @Test("A full-pane excluded overlay falls through to the underlying native control")
    func excludedOverlayFallsThroughAndCanBeReenabled() {
        let backend = AppKitBackend()
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let behind = NSButton(frame: root.bounds)
        let decoration = NSView(frame: root.bounds)
        let overlay = backend.createHitTestingContainer(wrapping: decoration)
        root.addSubview(behind)
        root.addSubview(overlay)
        overlay.frame = root.bounds
        decoration.frame = root.bounds
        let point = NSPoint(x: 100, y: 50)
        #expect(root.hitTest(point) === decoration)
        backend.setAllowsHitTesting(false, of: overlay)
        #expect(root.hitTest(point) === behind)
        #expect(overlay.frame == root.bounds)
        #expect(!overlay.isHidden)
        #expect(decoration.superview === overlay)
        #expect(behind.isEnabled)
        backend.setAllowsHitTesting(true, of: overlay)
        #expect(root.hitTest(point) === decoration)
        backend.setAllowsHitTesting(false, of: overlay)
        #expect(root.hitTest(point) === behind)
    }

    @Test("An allowed descendant cannot escape an excluded ancestor", arguments: [false, true])
    func nestedFalseWins(innerExcluded: Bool) {
        let backend = AppKitBackend()
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let behind = NSButton(frame: root.bounds)
        let child = NSButton(frame: root.bounds)
        let inner = backend.createHitTestingContainer(wrapping: child)
        let outer = backend.createHitTestingContainer(wrapping: inner)
        root.addSubview(behind)
        root.addSubview(outer)
        for widget in [outer, inner, child] { widget.frame = root.bounds }
        backend.setAllowsHitTesting(!innerExcluded, of: inner)
        backend.setAllowsHitTesting(innerExcluded, of: outer)
        let point = NSPoint(x: 100, y: 50)
        #expect(root.hitTest(point) === behind)
        backend.setAllowsHitTesting(true, of: inner)
        backend.setAllowsHitTesting(true, of: outer)
        #expect(root.hitTest(point) === child)
    }

    @Test("An allowed wrapper does not create a hit surface around empty layout content")
    func wrapperAddsNoEmptyHitArea() {
        let backend = AppKitBackend()
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let behind = NSButton(frame: root.bounds)
        let empty = backend.createContainer()
        let wrapper = backend.createHitTestingContainer(wrapping: empty)
        root.addSubview(behind)
        root.addSubview(wrapper)
        wrapper.frame = root.bounds
        empty.frame = root.bounds
        #expect(root.hitTest(NSPoint(x: 100, y: 50)) === behind)
    }

    @Test("Shared updates preserve the native child and refresh its action while excluded")
    func sharedModifierPreservesChildAndLatestAction() throws {
        let backend = AppKitBackend()
        // The view graph needs a window environment. This native window is
        // never ordered, activated or sent pointer events by this unit test.
        let window = backend.createWindow(withDefaultSize: SIMD2(200, 100), id: "hit-testing-graph")
        let environment = EnvironmentValues(backend: backend).with(\.window, window)
        var firstCalls = 0
        var latestCalls = 0
        func content(allows: Bool, label: String, action: @escaping @MainActor () -> Void)
            -> some View {
            HitTestingButtonLeaf(label: label, action: action).allowsHitTesting(allows)
        }
        let graph = ViewGraph(for: content(allows: true, label: "Before", action: { firstCalls += 1 }),
            backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: ProposedViewSize(160, 90), environment: environment)
        graph.commit()
        let wrapper = try #require(graph.rootNode.concreteNode(for: AppKitBackend.self).widget as? NSHitTestingContainer)
        let button = try #require(wrapper.subviews.first as? NSButton)
        button.performClick(nil)
        #expect(firstCalls == 1)
        _ = graph.computeLayout(with: content(allows: false, label: "After", action: { latestCalls += 1 }),
            proposedSize: ProposedViewSize(160, 90), environment: environment)
        graph.commit()
        #expect(!wrapper.allowsChildHitTesting)
        #expect(wrapper.subviews.first === button)
        #expect(button.attributedTitle.string == "After")
        #expect(button.isEnabled)
        _ = graph.computeLayout(with: content(allows: true, label: "After", action: { latestCalls += 1 }),
            proposedSize: ProposedViewSize(160, 90), environment: environment)
        graph.commit()
        #expect(wrapper.allowsChildHitTesting)
        #expect(wrapper.subviews.first === button)
        // Programmatic control activation checks retained action freshness;
        // native pointer admission is checked by the hitTest cases above.
        button.performClick(nil)
        #expect(firstCalls == 1)
        #expect(latestCalls == 1)
    }
    #endif
}

#if canImport(AppKitBackend)
/// A native leaf isolates the modifier's graph/identity behavior from unrelated
/// button-label layout. It uses the actual backend control update/action path.
@MainActor
private struct HitTestingButtonLeaf: ElementaryView {
    var label: String
    var action: @MainActor () -> Void

    func asWidget<Backend: BaseAppBackend>(backend: Backend) -> Backend.Widget {
        (backend as! AppKitBackend).createSimpleButton() as! Backend.Widget
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget, proposedSize: ProposedViewSize,
        environment: EnvironmentValues, backend: Backend
    ) -> ViewLayoutResult { .leafView(size: ViewSize(160, 90)) }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget, layout: ViewLayoutResult,
        environment: EnvironmentValues, backend: Backend
    ) {
        (backend as! AppKitBackend).updateSimpleButton(
            widget as! NSView, label: label, environment: environment, action: action)
        backend.setSize(of: widget, to: layout.size.vector)
    }
}
#endif
