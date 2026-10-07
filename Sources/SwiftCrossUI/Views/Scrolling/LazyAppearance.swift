import Foundation

/// Makes the views inside lazy containers appear as they're scrolled near,
/// as SwiftUI's lazy stacks and grids do.
///
/// SwiftCrossUI's lazy containers still create every child up front, but a
/// child's ``View/onAppear(perform:)`` (and so its ``View/task(priority:_:)``)
/// waits until the child comes within a screen's length of the visible region
/// of its scroll view, and of every scroll view around that one. Code that
/// loads a picture, or the next page of a feed, as a card appears then loads
/// what the viewer is about to see instead of everything at once.
///
/// Every ``ScrollView`` owns one and hands it to its content through the
/// environment; the views that wait register with it. It checks them after
/// each commit and whenever the user scrolls, on backends that can locate
/// widgets (``BackendFeatures/WidgetGeometry``) and report scrolling
/// (``BackendFeatures/ScrollObservation``). Elsewhere every view appears when
/// it's first committed, as before.
@MainActor
final class LazyAppearanceRegistry {
    /// A view waiting to appear. Its action is replaced on every commit, so
    /// that it runs with the view's latest values.
    final class Entry {
        var widget: AnyWidget
        var action: @MainActor () -> Void

        init(widget: AnyWidget, action: @escaping @MainActor () -> Void) {
            self.widget = widget
            self.action = action
        }
    }

    private struct WeakRegistry {
        weak var registry: LazyAppearanceRegistry?
    }

    /// The registry of the scroll view around this one's scroll view.
    private(set) weak var parent: LazyAppearanceRegistry?
    private var children: [ObjectIdentifier: WeakRegistry] = [:]
    private var pending: [Entry] = []
    private var isScheduled = false

    /// The scroll view's widget, the origin of the frames below.
    let anchor: CoordinateSpaceAnchor
    /// The size of the scroll view's visible region, as of its last commit.
    var viewportSize = SIMD2<Double>.zero
    /// Where a widget is relative to the scroll view's visible region; set by
    /// the scroll view's commit on backends that can locate widgets.
    var frame: (@MainActor (AnyWidget) -> CGRect?)?
    /// Runs work after the current commit; set by the scroll view's commit.
    var schedule: (@MainActor (@escaping @MainActor () -> Void) -> Void)?

    init(anchor: CoordinateSpaceAnchor) {
        self.anchor = anchor
    }

    /// Places this registry's scroll view inside another's.
    func setParent(_ parent: LazyAppearanceRegistry?) {
        guard parent !== self.parent else {
            return
        }
        self.parent = parent
        parent?.children[ObjectIdentifier(self)] = WeakRegistry(registry: self)
    }

    /// Whether views registering here can wait; without the backend support
    /// they appear at once.
    var canDefer: Bool {
        frame != nil && schedule != nil
    }

    /// Waits for `entry`'s widget to come near the visible region.
    func add(_ entry: Entry) {
        pending.append(entry)
        scheduleCheck()
    }

    /// Checks the waiting views after the current commit, at most once.
    func scheduleCheck() {
        guard !isScheduled, let schedule else {
            return
        }
        isScheduled = true
        schedule { [weak self] in
            self?.isScheduled = false
            self?.check()
        }
    }

    /// Where each waiting widget was at the last full measurement, relative
    /// to the visible region, and the commit generation it was taken at.
    ///
    /// While nothing has been committed, the only thing that can move the
    /// waiting widgets relative to this scroll view's visible region is the
    /// user scrolling it, which moves all of them by the same amount. So
    /// during a scroll one widget is measured and the others are shifted by
    /// its movement, instead of asking the backend to locate every waiting
    /// card on every frame of the scroll (a COM transform per card on WinUI,
    /// hundreds of them per frame on a long page of shelves).
    private var measuredFrames: [ObjectIdentifier: CGRect] = [:]
    private var measuredGeneration: UInt64?

    /// Makes every waiting view that's now near the visible region appear,
    /// then does the same for the scroll views inside this one.
    func check() {
        var appearing: [Entry] = []
        if !pending.isEmpty, isScrollViewNearVisibleRegion() {
            let frames = currentFrames()
            let reach = self.reach
            pending.removeAll { entry in
                guard let frame = frames[ObjectIdentifier(entry)],
                    frame.intersects(reach) || (frame.isEmpty && reach.contains(frame.origin))
                else {
                    return false
                }
                appearing.append(entry)
                return true
            }
        }
        for entry in appearing {
            measuredFrames[ObjectIdentifier(entry)] = nil
            entry.action()
        }
        children = children.filter { $0.value.registry != nil }
        for child in children.values {
            child.registry?.check()
        }
    }

    /// The region within a screen's length of the visible region.
    private var reach: CGRect {
        CGRect(
            x: -viewportSize.x,
            y: -viewportSize.y,
            width: viewportSize.x * 3,
            height: viewportSize.y * 3
        )
    }

    /// Whether this registry's scroll view is near the visible region of
    /// every scroll view around it. Checked once per check rather than once
    /// per waiting widget: a shelf far off screen skips all of its cards.
    private func isScrollViewNearVisibleRegion() -> Bool {
        guard let parent, let scrollWidget = anchor.widget else {
            return true
        }
        return parent.isNearVisibleRegion(scrollWidget)
    }

    /// The frames of the waiting widgets, measured or shifted (see
    /// ``measuredFrames``).
    private func currentFrames() -> [ObjectIdentifier: CGRect] {
        guard let frame else {
            return [:]
        }
        let generation = LayoutPass.commitGeneration
        if measuredGeneration == generation,
            let reference = pending.first(where: { measuredFrames[ObjectIdentifier($0)] != nil }),
            let then = measuredFrames[ObjectIdentifier(reference)],
            let now = frame(reference.widget),
            now.size == then.size
        {
            let dx = now.origin.x - then.origin.x
            let dy = now.origin.y - then.origin.y
            if dx != 0 || dy != 0 {
                for (key, value) in measuredFrames {
                    measuredFrames[key] = value.offsetBy(dx: dx, dy: dy)
                }
            }
            if pending.allSatisfy({ measuredFrames[ObjectIdentifier($0)] != nil }) {
                return measuredFrames
            }
        }
        measuredFrames.removeAll(keepingCapacity: true)
        for entry in pending {
            if let measured = frame(entry.widget) {
                measuredFrames[ObjectIdentifier(entry)] = measured
            }
        }
        measuredGeneration = generation
        return measuredFrames
    }

    /// Whether a widget is within a screen's length of the visible region of
    /// this scroll view and of every scroll view around it.
    func isNearVisibleRegion(_ widget: AnyWidget) -> Bool {
        guard let frame = frame?(widget) else {
            return false
        }
        let reach = self.reach
        guard frame.intersects(reach) || (frame.isEmpty && reach.contains(frame.origin)) else {
            return false
        }
        return isScrollViewNearVisibleRegion()
    }
}

extension EnvironmentValues {
    /// The registry of the nearest enclosing scroll view.
    @Entry var lazyAppearance: LazyAppearanceRegistry? = nil

    /// Whether the view is inside a lazy stack or grid, whose children appear
    /// as they're scrolled near.
    @Entry var appearsLazily = false
}
