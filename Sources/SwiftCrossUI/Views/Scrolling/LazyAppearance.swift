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

    /// Makes every waiting view that's now near the visible region appear,
    /// then does the same for the scroll views inside this one.
    func check() {
        var appearing: [Entry] = []
        pending.removeAll { entry in
            guard isNearVisibleRegion(entry.widget) else {
                return false
            }
            appearing.append(entry)
            return true
        }
        for entry in appearing {
            entry.action()
        }
        children = children.filter { $0.value.registry != nil }
        for child in children.values {
            child.registry?.check()
        }
    }

    /// Whether a widget is within a screen's length of the visible region of
    /// this scroll view and of every scroll view around it.
    func isNearVisibleRegion(_ widget: AnyWidget) -> Bool {
        guard let frame = frame?(widget) else {
            return false
        }
        let reach = CGRect(
            x: -viewportSize.x,
            y: -viewportSize.y,
            width: viewportSize.x * 3,
            height: viewportSize.y * 3
        )
        guard frame.intersects(reach) || (frame.isEmpty && reach.contains(frame.origin)) else {
            return false
        }
        guard let parent, let scrollWidget = anchor.widget else {
            return true
        }
        return parent.isNearVisibleRegion(scrollWidget)
    }
}

extension EnvironmentValues {
    /// The registry of the nearest enclosing scroll view.
    @Entry var lazyAppearance: LazyAppearanceRegistry? = nil

    /// Whether the view is inside a lazy stack or grid, whose children appear
    /// as they're scrolled near.
    @Entry var appearsLazily = false
}
