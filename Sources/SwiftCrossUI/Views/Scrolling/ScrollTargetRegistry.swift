import Foundation

/// Something inside a scroll view that can find the widget of a view by its
/// identity: a ``ForEach`` with identified elements, or a view with
/// ``View/id(_:)`` (which is one).
@MainActor
protocol ScrollTargetProvider: AnyObject {
    /// The widget of the view with the given identity, if this provider has
    /// one.
    ///
    /// - Parameter id: The identity, as given to ``ForEach`` or
    ///   ``View/id(_:)``.
    /// - Returns: The view's widget.
    func scrollTargetWidget(for id: AnyHashable) -> AnyWidget?

    /// The identities of every view this provider has, in order.
    var scrollTargetIdentifiers: [AnyHashable] { get }
}

/// The views a ``ScrollView`` can scroll to, and the means to scroll it.
///
/// Every scroll view owns one and hands it to its content through the
/// environment (``EnvironmentValues/scrollTargets``); identified ``ForEach``es
/// inside register with it, and the scroll view gives it a
/// ``ScrollController`` whenever it commits. ``ScrollViewReader``,
/// ``ScrollPosition`` and ``View/scrollPosition(id:anchor:)`` all scroll
/// through it.
@MainActor
final class ScrollTargetRegistry {
    /// A provider, held weakly so that a ``ForEach`` that goes away takes its
    /// targets with it.
    private struct WeakProvider {
        weak var provider: (any ScrollTargetProvider)?
    }

    /// The registered providers.
    private var providers: [ObjectIdentifier: WeakProvider] = [:]

    /// Scrolls the scroll view, once it has committed on a backend that can
    /// scroll programmatically.
    var controller: ScrollController?

    /// Creates an empty registry.
    init() {}

    /// Registers a provider of scroll targets.
    ///
    /// Registering the same provider again does nothing.
    ///
    /// - Parameter provider: The provider.
    func register(_ provider: any ScrollTargetProvider) {
        let key = ObjectIdentifier(provider)
        if providers[key]?.provider == nil {
            providers[key] = WeakProvider(provider: provider)
        }
    }

    /// The widget of the view with the given identity.
    ///
    /// - Parameter id: The identity.
    /// - Returns: The widget, or `nil` if no registered view has the identity.
    func widget(for id: AnyHashable) -> AnyWidget? {
        providers = providers.filter { $0.value.provider != nil }
        for entry in providers.values {
            if let widget = entry.provider?.scrollTargetWidget(for: id) {
                return widget
            }
        }
        return nil
    }

    /// Every registered view, with its identity, in registration order.
    var targets: [(id: AnyHashable, widget: AnyWidget)] {
        providers.values.compactMap(\.provider).flatMap { provider in
            provider.scrollTargetIdentifiers.compactMap { id in
                provider.scrollTargetWidget(for: id).map { (id, $0) }
            }
        }
    }

    /// Scrolls so that the view with the given identity is visible.
    ///
    /// - Parameters:
    ///   - id: The view's identity.
    ///   - anchor: The point of the view to align with the same point of the
    ///     visible region, or `nil` to scroll as little as possible.
    /// - Returns: Whether the registry knew the view and could scroll.
    @discardableResult
    func scrollTo(id: AnyHashable, anchor: UnitPoint?) -> Bool {
        guard let controller, let widget = widget(for: id),
              let frame = controller.frame(widget)
        else {
            return false
        }
        controller.scroll(to: controller.offset(revealing: frame, anchor: anchor))
        return true
    }
}

/// Scrolls one committed ``ScrollView``.
@MainActor
struct ScrollController {
    /// The size of the scroll view's visible region.
    var viewportSize: SIMD2<Double>
    /// The size of the scroll view's content.
    var contentSize: SIMD2<Double>
    /// Gets how far the scroll view is scrolled.
    var currentOffset: @MainActor () -> SIMD2<Double>
    /// Scrolls the scroll view to an offset.
    var setOffset: @MainActor (SIMD2<Double>) -> Void
    /// Gets where a widget is in the scroll view's content.
    var frame: @MainActor (AnyWidget) -> (origin: SIMD2<Double>, size: SIMD2<Double>)?

    /// The largest offset the content can be scrolled to.
    var maximumOffset: SIMD2<Double> {
        SIMD2(
            max(0, contentSize.x - viewportSize.x),
            max(0, contentSize.y - viewportSize.y)
        )
    }

    /// Scrolls to an offset, clamped to the scrollable range.
    ///
    /// - Parameter offset: The offset.
    func scroll(to offset: SIMD2<Double>) {
        let maximum = maximumOffset
        setOffset(
            SIMD2(
                min(max(0, offset.x), maximum.x),
                min(max(0, offset.y), maximum.y)
            )
        )
    }

    /// Scrolls to one of the content's edges, keeping the other axis where it
    /// is.
    ///
    /// - Parameter edge: The edge.
    func scroll(to edge: Edge) {
        var offset = currentOffset()
        switch edge {
            case .top: offset.y = 0
            case .bottom: offset.y = maximumOffset.y
            case .leading: offset.x = 0
            case .trailing: offset.x = maximumOffset.x
        }
        scroll(to: offset)
    }

    /// The offset that reveals a region of the content.
    ///
    /// With an anchor, the anchor point of the region lines up with the same
    /// point of the visible region, as in SwiftUI's
    /// `ScrollViewProxy.scrollTo(_:anchor:)`. Without one, each axis scrolls
    /// as little as it takes to show the region, and not at all if it's
    /// already visible.
    ///
    /// - Parameters:
    ///   - frame: The region, in content coordinates.
    ///   - anchor: The point to line up, or `nil`.
    /// - Returns: The offset, before clamping.
    func offset(
        revealing frame: (origin: SIMD2<Double>, size: SIMD2<Double>),
        anchor: UnitPoint?
    ) -> SIMD2<Double> {
        if let anchor {
            let unit = SIMD2(anchor.x, anchor.y)
            return frame.origin + unit * frame.size - unit * viewportSize
        }
        var offset = currentOffset()
        for axis in 0..<2 {
            let start = frame.origin[axis]
            let end = start + frame.size[axis]
            if start < offset[axis] {
                offset[axis] = start
            } else if end > offset[axis] + viewportSize[axis] {
                offset[axis] = min(start, end - viewportSize[axis])
            }
        }
        return offset
    }
}

extension ScrollController {
    /// Creates a controller for a committed scroll view, if its backend can
    /// scroll programmatically.
    ///
    /// - Parameters:
    ///   - backend: The scroll view's backend.
    ///   - widget: The scroll view's widget.
    ///   - viewportSize: The size of the visible region.
    ///   - contentSize: The size of the content.
    /// - Returns: The controller, or `nil` if the backend can't scroll.
    static func make<Backend: BaseAppBackend>(
        backend: Backend,
        widget: Backend.Widget,
        viewportSize: SIMD2<Double>,
        contentSize: SIMD2<Double>
    ) -> ScrollController? {
        guard let scrolling = backend as? any BackendFeatures.ScrollOffsets else {
            return nil
        }
        return make(
            scrolling: scrolling,
            widget: AnyWidget(widget),
            viewportSize: viewportSize,
            contentSize: contentSize
        )
    }

    /// Creates a controller once the backend has been opened as a scrolling
    /// one.
    private static func make<Backend: BackendFeatures.ScrollOffsets>(
        scrolling backend: Backend,
        widget: AnyWidget,
        viewportSize: SIMD2<Double>,
        contentSize: SIMD2<Double>
    ) -> ScrollController {
        let container: Backend.Widget = widget.into()
        return ScrollController(
            viewportSize: viewportSize,
            contentSize: contentSize,
            currentOffset: { backend.scrollOffset(of: container) },
            setOffset: { offset in
                backend.setScrollOffset(of: container, to: offset, animated: false)
            },
            frame: { target in
                backend.frame(of: target.into(), inContentOf: container)
            }
        )
    }
}

extension EnvironmentValues {
    /// The scroll targets of the innermost enclosing ``ScrollView``.
    @Entry var scrollTargets: ScrollTargetRegistry? = nil
}
