import Foundation
import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI
#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

@Suite("Horizontal split resizing")
@MainActor
struct HorizontalSplitLayoutTests {
    typealias Bounds = HorizontalSplitLayout.Bounds
    let workspace = Bounds(minimum: 480, ideal: 480, maximum: .infinity)
    let inspector = Bounds(minimum: 220, ideal: 260, maximum: 340)

    @Test("Unspecified, minimum, maximum and constrained proposals retain their meaning")
    func widthProbesAndNarrowWindow() {
        let bounds = [workspace, inspector]
        #expect(HorizontalSplitLayout.widths(bounds: bounds, preferred: [:], available: nil) == [480, 260])
        #expect(HorizontalSplitLayout.widths(bounds: bounds, preferred: [:], available: 0) == [480, 220])
        #expect(HorizontalSplitLayout.widths(bounds: bounds, preferred: [:], available: .infinity) == [.infinity, 340])
        #expect(HorizontalSplitLayout.widths(bounds: bounds, preferred: [:], available: 650) == [480, 220])
        #expect(HorizontalSplitLayout.widths(bounds: bounds, preferred: [:], available: 1000) == [740, 260])
    }

    @Test("Divider movement conserves pair width and honours both panes' bounds")
    func dragClampsBothSides() {
        let bounds = [workspace, inspector]
        #expect(HorizontalSplitLayout.movedWidths([740, 260], bounds: bounds, left: 0, right: 1, delta: 1000) == [780, 220])
        #expect(HorizontalSplitLayout.movedWidths([740, 260], bounds: bounds, left: 0, right: 1, delta: -1000) == [660, 340])
        #expect(HorizontalSplitLayout.movedWidths([740, 260], bounds: bounds, left: 0, right: 1, delta: .nan) == nil)
        #expect(HorizontalSplitLayout.widths(bounds: bounds, preferred: [0: 680, 1: 320], available: 1200) == [880, 320])
    }

    @Test("Bounded peer growth saturates, and explicit zero panes cannot resize")
    func boundedPeersAndHiddenMiddle() {
        let bound = Bounds(minimum: 100, ideal: 150, maximum: 200)
        #expect(HorizontalSplitLayout.widths(bounds: [bound, bound], preferred: [:], available: 350) == [175, 175])
        #expect(HorizontalSplitLayout.widths(bounds: [bound, bound], preferred: [:], available: 600) == [200, 200])
        let zero = Bounds(minimum: 0, ideal: 0, maximum: 0)
        let bounds = [inspector, zero, workspace]
        #expect(HorizontalSplitLayout.widths(bounds: bounds, preferred: [1: 300], available: 1000) == [260, 0, 740])
        #expect(HorizontalSplitLayout.movedWidths([260, 0, 740], bounds: bounds, left: 0, right: 2, delta: 20) == [280, 0, 720])
        #expect(HorizontalSplitLayout.movedWidths([260, 0, 740], bounds: bounds, left: 0, right: 1, delta: 20) == nil)
    }

    @Test("A real split remembers user width across hide, show and window resize")
    func graphRemembersWidth() throws {
        let backend = DummyBackend()
        let environment = context(backend)
        func content(hidden: Bool, modelOnly: Bool = false) -> HSplitView<some View> {
            HSplitView {
                HSplitView {
                    Color.red.frame(minWidth: modelOnly ? CGFloat(0) : CGFloat(220),
                        idealWidth: modelOnly ? CGFloat(0) : nil, maxWidth: modelOnly ? CGFloat(0) : .infinity)
                    Color.green.frame(minWidth: CGFloat(220), maxWidth: .infinity)
                }.frame(minWidth: CGFloat(480), idealWidth: CGFloat(480), maxWidth: .infinity)
                Color.blue.frame(minWidth: hidden ? CGFloat(0) : CGFloat(220),
                    idealWidth: hidden ? CGFloat(0) : CGFloat(260), maxWidth: hidden ? CGFloat(0) : CGFloat(340))
            }
        }
        let graph = ViewGraph(for: content(hidden: false), backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        let children = try #require(graph.rootNode.concreteNode(for: DummyBackend.self).children as? HorizontalSplitChildren)
        let original = children.widgets.map { $0.into() as DummyBackend.Widget }
        let nested = try #require(original[0].firstWidget(ofType: DummyBackend.Rectangle.self))
        children.receiveDrag(dragEvent(delta: -60, id: 1), left: 0, right: 1, ended: false)
        #expect(children.committedWidths == [680, 320])
        _ = graph.computeLayout(with: content(hidden: true, modelOnly: true), proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        #expect(children.committedWidths == [1000, 0])
        #expect(nested.size.x == 0)
        children.receiveDrag(dragEvent(delta: -100, id: 1), left: 0, right: 1, ended: false) // stale hidden callback
        #expect(children.preferredWidths[1] == 320)
        _ = graph.computeLayout(with: content(hidden: false), proposedSize: .init(1200, 300), environment: environment)
        graph.commit()
        #expect(children.committedWidths == [880, 320])
        #expect(original[0].firstWidget(ofType: DummyBackend.Rectangle.self) === nested)
        #expect(nested.size.x == 440)
        #expect(children.widgets.enumerated().allSatisfy { index, widget in
            (widget.into() as DummyBackend.Widget) === original[index]
        })
    }

    @Test("Dragging one divider leaves a third flexible peer at its current width")
    func thirdPeerDoesNotRedistribute() throws {
        let backend = DummyBackend()
        let environment = context(backend)
        let graph = ViewGraph(for: HSplitView {
            Color.red.frame(minWidth: CGFloat(100), maxWidth: .infinity)
            Color.green.frame(minWidth: CGFloat(100), maxWidth: .infinity)
            Color.blue.frame(minWidth: CGFloat(100), maxWidth: .infinity)
        }, backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: .init(900, 300), environment: environment)
        graph.commit()
        let children = try #require(graph.rootNode.concreteNode(for: DummyBackend.self).children as? HorizontalSplitChildren)
        #expect(children.committedWidths == [300, 300, 300])
        children.receiveDrag(dragEvent(delta: 30, id: 1), left: 0, right: 1, ended: false)
        #expect(children.committedWidths == [330, 270, 300])
    }

    @Test("Conditional and ForEach content updates stay inside stable pane nodes")
    func groupedDynamicContentKeepsPaneIndices() throws {
        let backend = DummyBackend()
        let environment = context(backend)
        func content(items: [Int], footer: Bool) -> HSplitView<some View> {
            HSplitView {
                ForEach(items, id: \.self) { value in
                    Text("Item \(value)").frame(width: CGFloat(30), height: CGFloat(20))
                }
                if footer { Color.blue.frame(width: CGFloat(40), height: CGFloat(20)) }
                Color.red.frame(minWidth: CGFloat(100), maxWidth: .infinity)
            }
        }
        let graph = ViewGraph(for: content(items: [1, 2], footer: true), backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: .init(500, 100), environment: environment)
        graph.commit()
        let children = try #require(graph.rootNode.concreteNode(for: DummyBackend.self).children as? HorizontalSplitChildren)
        let original = children.widgets.map { $0.into() as DummyBackend.Widget }
        #expect(original.count == 3)
        _ = graph.computeLayout(with: content(items: [1, 2, 3, 4], footer: false), proposedSize: .init(500, 100), environment: environment)
        graph.commit()
        #expect(children.widgets.count == 3)
        #expect(children.committedWidths.count == 3)
        #expect(children.committedWidths[1] == 0)
        #expect(children.widgets.enumerated().allSatisfy { index, widget in
            (widget.into() as DummyBackend.Widget) === original[index]
        })
    }

    #if canImport(AppKitBackend)
    @Test("Native divider handlers occupy only the boundary and disappear with a hidden pane")
    func nativeTargetsAndCallbacks() throws {
        let backend = AppKitBackend()
        let window = backend.createWindow(withDefaultSize: SIMD2(1000, 300), id: "split-native")
        let environment = EnvironmentValues(backend: backend).with(\.window, window)
        func content(hidden: Bool) -> HSplitView<some View> {
            HSplitView {
                Color.red.frame(minWidth: CGFloat(480), idealWidth: CGFloat(480), maxWidth: .infinity)
                Color.blue.frame(minWidth: hidden ? CGFloat(0) : CGFloat(220),
                    idealWidth: hidden ? CGFloat(0) : CGFloat(260), maxWidth: hidden ? CGFloat(0) : CGFloat(340))
            }
        }
        let graph = ViewGraph(for: content(hidden: false), backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        let children = try #require(graph.rootNode.concreteNode(for: AppKitBackend.self).children as? HorizontalSplitChildren)
        #expect(children.dividers.count == 1)
        let divider: NSView = children.dividers[0].target.into()
        let target = try #require(pointerTarget(divider))
        let action = try #require(target.dragChangedHandler)
        // These unmounted native views receive explicit size constraints;
        // an ordered window's Auto Layout pass is outside this unit test.
        let width = try #require(divider.constraints.first {
            $0.firstAnchor === divider.widthAnchor && $0.isActive
        })
        let height = try #require(divider.constraints.first {
            $0.firstAnchor === divider.heightAnchor && $0.isActive
        })
        #expect(width.constant == 6)
        #expect(height.constant == 300)
        #expect(target.reportsWindowCoordinates)
        #expect(target.scrollHandler == nil)
        #expect(target.tapHandler == nil)
        #expect(!children.widgets.contains { ( $0.into() as NSView).isDescendant(of: divider) })
        action(dragEvent(delta: -60, id: 1))
        #expect(children.committedWidths == [680, 320])
        // A later raw sample may have been queued before the first callback
        // moved the target. Its total window-space translation must replace,
        // not be added to, the first resize.
        action(dragEvent(delta: -80, id: 1))
        #expect(children.committedWidths == [660, 340])
        action(dragEvent(delta: -80, id: 1))
        #expect(children.committedWidths == [660, 340])
        // A cancelled drag has no ended callback. A new press at the exact
        // same point still gets its own initial widths via a distinct id.
        action(dragEvent(delta: 20, id: 2))
        #expect(children.committedWidths == [680, 320])
        _ = graph.computeLayout(with: content(hidden: true), proposedSize: .init(1000, 300), environment: environment)
        graph.commit()
        #expect(width.constant == 0 && height.constant == 0)
        #expect(target.dragChangedHandler == nil)
        action(dragEvent(delta: -200, id: 2))
        #expect(children.preferredWidths[1] == 320)
    }

    @Test("AppKit drag identity survives samples and changes after cancelled same-point press")
    func nativePerPressIdentity() throws {
        let backend = AppKitBackend()
        let wrapper = backend.createPointerGestureTarget(wrapping: NSView(frame: .zero))
        let target = try #require(pointerTarget(wrapper))
        let recognizer = SplitTestPanRecognizer()
        var ids: [UInt64?] = []
        target.dragChangedHandler = { ids.append($0.interactionID) }
        target.minimumDragDistance = 0
        let phases: [NSGestureRecognizer.State] = [.began, .changed, .changed, .cancelled, .began, .changed]
        for phase in phases {
            recognizer.testState = phase
            target.pan(sender: recognizer, button: .primary)
        }
        #expect(ids.count == 3)
        #expect(ids[0] != nil)
        #expect(ids[0] == ids[1])
        #expect(ids[2] != ids[1])
    }

    private final class SplitTestPanRecognizer: NSPanGestureRecognizer {
        var testState: NSGestureRecognizer.State = .began
        override var state: NSGestureRecognizer.State {
            get { testState }
            set { testState = newValue }
        }
        override func location(in view: NSView?) -> NSPoint { CGPoint(x: 3, y: 10) }
        override func velocity(in view: NSView?) -> NSPoint { .zero }
    }

    private func pointerTarget(_ view: NSView) -> NSCustomPointerGestureTarget? {
        if let target = view as? NSCustomPointerGestureTarget { return target }
        return view.subviews.compactMap { self.pointerTarget($0) }.first
    }
    #endif

    private func dragEvent(delta: Double, id: UInt64) -> PointerGestureEvent {
        .init(startLocation: CGPoint(x: 1000, y: 20), location: CGPoint(x: 1000 + delta, y: 20),
            interactionID: id)
    }

    private func context(_ backend: DummyBackend) -> EnvironmentValues {
        EnvironmentValues(backend: backend).with(\.window,
            backend.createWindow(withDefaultSize: nil, id: "split-layout"))
    }
}
