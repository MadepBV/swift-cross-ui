import Foundation

/// Where a ``ScrollView`` is scrolled to, as a value you can set.
///
/// Bind one to a scroll view with ``View/scrollPosition(_:)`` and call one of
/// its `scrollTo` methods to scroll:
///
/// ```swift
/// @State private var position = ScrollPosition(edge: .top)
///
/// ScrollView { ... }
///     .scrollPosition($position)
///
/// Button("Back to top") { position.scrollTo(edge: .top) }
/// ```
///
/// ## Differences from SwiftUI
///
/// The position only travels one way: setting it scrolls the scroll view,
/// but the user's own scrolling isn't written back, so ``edge``, ``point``
/// and ``viewID`` describe the last request rather than where the content
/// is now, and ``isPositionedByUser`` is always `false`.
public struct ScrollPosition: Equatable {
    /// A request to scroll.
    enum Target: Equatable {
        case edge(Edge)
        case point(x: Double?, y: Double?)
        case view(AnyHashable, anchor: UnitPoint?)
    }

    /// The last request, if any.
    var target: Target?

    /// Distinguishes requests, so that asking for the same place twice
    /// scrolls twice (the user may have scrolled away in between).
    var request = UUID()

    /// Creates a position at one of the content's edges.
    ///
    /// - Parameter edge: The edge, or `nil` for the scroll view's initial
    ///   position.
    public init(edge: Edge? = nil) {
        target = edge.map(Target.edge)
    }

    /// Creates a position at a point of the content.
    ///
    /// - Parameter point: The point, from the content's top-leading corner.
    public init(point: CGPoint) {
        target = .point(x: Double(point.x), y: Double(point.y))
    }

    /// Creates a position at an offset along either axis.
    ///
    /// - Parameters:
    ///   - x: The horizontal offset, or `nil` to leave that axis alone.
    ///   - y: The vertical offset, or `nil` to leave that axis alone.
    public init(x: CGFloat? = nil, y: CGFloat? = nil) {
        target = .point(x: x.map(Double.init), y: y.map(Double.init))
    }

    /// Creates a position that will be set to views of a given identity type.
    ///
    /// - Parameters:
    ///   - type: The type of the views' identities.
    ///   - edge: The edge to start at, if any.
    public init<ID: Hashable>(idType: ID.Type, edge: Edge? = nil) {
        self.init(edge: edge)
    }

    /// The edge last scrolled to, if the last request was for an edge.
    public var edge: Edge? {
        if case .edge(let edge) = target { edge } else { nil }
    }

    /// The point last scrolled to, if the last request was for a point.
    public var point: CGPoint? {
        if case .point(let x, let y) = target {
            CGPoint(x: x ?? 0, y: y ?? 0)
        } else {
            nil
        }
    }

    /// The identity of the view last scrolled to, if the last request was
    /// for a view.
    public var viewID: (any Hashable)? {
        if case .view(let id, _) = target { id.base as? any Hashable } else { nil }
    }

    /// The identity of the view last scrolled to, if it has the given type.
    ///
    /// - Parameter type: The identity's type.
    /// - Returns: The identity.
    public func viewID<ID: Hashable>(type: ID.Type) -> ID? {
        if case .view(let id, _) = target { id.base as? ID } else { nil }
    }

    /// Whether the user scrolled the content since the last request.
    /// SwiftCrossUI doesn't observe the user's scrolling, so this is always
    /// `false`.
    public var isPositionedByUser: Bool {
        false
    }

    /// Scrolls to one of the content's edges.
    ///
    /// - Parameter edge: The edge.
    public mutating func scrollTo(edge: Edge) {
        request(.edge(edge))
    }

    /// Scrolls to a point of the content.
    ///
    /// - Parameter point: The point, from the content's top-leading corner.
    public mutating func scrollTo(point: CGPoint) {
        request(.point(x: Double(point.x), y: Double(point.y)))
    }

    /// Scrolls horizontally, leaving the vertical offset alone.
    ///
    /// - Parameter x: The horizontal offset.
    public mutating func scrollTo(x: CGFloat) {
        request(.point(x: Double(x), y: nil))
    }

    /// Scrolls vertically, leaving the horizontal offset alone.
    ///
    /// - Parameter y: The vertical offset.
    public mutating func scrollTo(y: CGFloat) {
        request(.point(x: nil, y: Double(y)))
    }

    /// Scrolls to an offset along both axes.
    ///
    /// - Parameters:
    ///   - x: The horizontal offset.
    ///   - y: The vertical offset.
    public mutating func scrollTo(x: CGFloat, y: CGFloat) {
        request(.point(x: Double(x), y: Double(y)))
    }

    /// Scrolls to the view with the given identity.
    ///
    /// - Parameters:
    ///   - id: The view's identity, as given to ``View/id(_:)`` or
    ///     ``ForEach``.
    ///   - anchor: The point of the view to line up with the same point of
    ///     the visible region, or `nil` to scroll as little as possible.
    public mutating func scrollTo<ID: Hashable>(id: ID, anchor: UnitPoint? = nil) {
        request(.view(AnyHashable(id), anchor: anchor))
    }

    /// Records a new request.
    ///
    /// - Parameter target: Where to scroll.
    private mutating func request(_ target: Target) {
        self.target = target
        request = UUID()
    }

    /// Scrolls a scroll view to this position.
    ///
    /// - Parameters:
    ///   - controller: The scroll view's controller.
    ///   - targets: The scroll view's targets.
    @MainActor
    func apply(with controller: ScrollController, targets: ScrollTargetRegistry) {
        switch target {
            case .edge(let edge):
                controller.scroll(to: edge)
            case .point(let x, let y):
                let current = controller.currentOffset()
                controller.scroll(to: SIMD2(x ?? current.x, y ?? current.y))
            case .view(let id, let anchor):
                targets.scrollTo(id: id, anchor: anchor)
            case nil:
                break
        }
    }
}

/// A scroll request that a ``ScrollView`` takes from its environment, set by
/// ``View/scrollPosition(_:)`` or ``View/scrollPosition(id:anchor:)``.
struct ScrollRequest {
    /// Identifies the request, so that a scroll view carries it out once.
    var identity: AnyHashable
    /// Carries the request out.
    var apply: @MainActor (ScrollController, ScrollTargetRegistry) -> Void
}

extension EnvironmentValues {
    /// The request of the innermost ``View/scrollPosition(_:)`` or
    /// ``View/scrollPosition(id:anchor:)`` around a scroll view. Scroll views
    /// take it out of their content's environment, so it only reaches the
    /// scroll view it was applied to.
    @Entry var scrollRequest: ScrollRequest? = nil
}

extension View {
    /// Scrolls the scroll view inside this view whenever `position` asks to.
    ///
    /// See ``ScrollPosition`` for how to ask.
    ///
    /// - Parameter position: The scroll view's position.
    /// - Returns: A view whose scroll view follows `position`.
    public func scrollPosition(_ position: Binding<ScrollPosition>) -> some View {
        let position = position.wrappedValue
        return environment(
            \.scrollRequest,
            ScrollRequest(identity: AnyHashable(position.request)) { controller, targets in
                position.apply(with: controller, targets: targets)
            }
        )
    }

    /// Scrolls the scroll view inside this view to the view whose identity
    /// `id` holds, whenever `id` changes.
    ///
    /// - Note: The binding is only read: the user's scrolling doesn't write
    ///   the identity of the view now in place back to it.
    ///
    /// - Parameters:
    ///   - id: The identity of the view to scroll to, as given to
    ///     ``View/id(_:)`` or ``ForEach``; `nil` leaves the scroll view alone.
    ///   - anchor: The point of the view to line up with the same point of the
    ///     visible region, or `nil` to scroll as little as possible.
    /// - Returns: A view whose scroll view follows `id`.
    public func scrollPosition<ID: Hashable>(
        id: Binding<ID?>,
        anchor: UnitPoint? = nil
    ) -> some View {
        let target = id.wrappedValue
        return environment(
            \.scrollRequest,
            target.map { target in
                ScrollRequest(identity: AnyHashable(target)) { _, targets in
                    targets.scrollTo(id: AnyHashable(target), anchor: anchor)
                }
            }
        )
    }
}
