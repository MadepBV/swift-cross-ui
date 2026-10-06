/// How a scroll view settles once the user stops scrolling.
///
/// Snapping needs the backend to adjust a scroll's resting place as it
/// decelerates, which no SwiftCrossUI backend exposes yet, so every behaviour
/// lets the content come to rest where the user's scroll ends; see
/// ``View/scrollTargetBehavior(_:)``.
public protocol ScrollTargetBehavior: Sendable {}

/// Snapping to the scroll view's own size, a page at a time.
public struct PagingScrollTargetBehavior: ScrollTargetBehavior {
    public init() {}
}

/// Snapping to the views marked with ``View/scrollTargetLayout(isEnabled:)``.
public struct ViewAlignedScrollTargetBehavior: ScrollTargetBehavior {
    /// How far one scroll may travel before it settles.
    public struct LimitBehavior: Hashable, Sendable {
        /// The behaviour's identity.
        private let rawValue: Int

        /// The platform's choice.
        public static let automatic = LimitBehavior(rawValue: 0)
        /// At most one view per scroll.
        public static let always = LimitBehavior(rawValue: 1)
        /// As far as the scroll goes.
        public static let never = LimitBehavior(rawValue: 2)
        /// At most one view per scroll, on compact layouts.
        public static let alwaysByFew = LimitBehavior(rawValue: 3)
        /// At most one view per scroll, when one view fills the scroll view.
        public static let alwaysByOne = LimitBehavior(rawValue: 4)
    }

    /// How far one scroll may travel.
    public var limitBehavior: LimitBehavior

    /// Creates the behaviour.
    ///
    /// - Parameter limitBehavior: How far one scroll may travel.
    public init(limitBehavior: LimitBehavior = .automatic) {
        self.limitBehavior = limitBehavior
    }
}

extension ScrollTargetBehavior where Self == PagingScrollTargetBehavior {
    /// Snapping a page at a time.
    public static var paging: PagingScrollTargetBehavior { PagingScrollTargetBehavior() }
}

extension ScrollTargetBehavior where Self == ViewAlignedScrollTargetBehavior {
    /// Snapping to the views of the scroll target layout.
    public static var viewAligned: ViewAlignedScrollTargetBehavior {
        ViewAlignedScrollTargetBehavior()
    }

    /// Snapping to the views of the scroll target layout, limited per scroll.
    ///
    /// - Parameter limitBehavior: How far one scroll may travel.
    /// - Returns: The behaviour.
    public static func viewAligned(
        limitBehavior: ViewAlignedScrollTargetBehavior.LimitBehavior
    ) -> ViewAlignedScrollTargetBehavior {
        ViewAlignedScrollTargetBehavior(limitBehavior: limitBehavior)
    }
}

/// The phases a scroll goes through, reported by
/// ``View/onScrollPhaseChange(_:)``.
public enum ScrollPhase: Hashable, Sendable {
    /// Not scrolling.
    case idle
    /// The user is about to scroll.
    case tracking
    /// The user is scrolling.
    case interacting
    /// The content is decelerating after the user let go.
    case decelerating
    /// The content is scrolling programmatically.
    case animating

    /// Whether the content is moving.
    public var isScrolling: Bool {
        self != .idle
    }
}

/// The soft or hard edge a scroll view draws where its content meets a bar.
public struct ScrollEdgeEffectStyle: Hashable, Sendable {
    /// The style's identity.
    private let rawValue: Int

    /// The platform's choice.
    public static let automatic = ScrollEdgeEffectStyle(rawValue: 0)
    /// A soft, blurred edge.
    public static let soft = ScrollEdgeEffectStyle(rawValue: 1)
    /// A hard, opaque edge.
    public static let hard = ScrollEdgeEffectStyle(rawValue: 2)
}

extension View {
    /// Sets how the scroll views within this view settle once the user stops
    /// scrolling.
    ///
    /// Without effect so far: no backend exposes a scroll's resting place, so
    /// content rests wherever the user's scroll ends. Programmatic scrolling
    /// (``ScrollViewReader``, ``ScrollPosition``) still lands exactly on its
    /// target.
    ///
    /// - Parameter behavior: How to settle.
    /// - Returns: This view, unchanged.
    public func scrollTargetBehavior(_ behavior: some ScrollTargetBehavior) -> some View {
        self
    }

    /// Marks the views of this layout as the places a view-aligned scroll
    /// target behaviour settles on.
    ///
    /// Without effect so far, for the reason
    /// ``View/scrollTargetBehavior(_:)`` gives. Every identified view inside a
    /// scroll view is already a target of ``ScrollViewProxy/scrollTo(_:anchor:)``.
    ///
    /// - Parameter isEnabled: Whether the views are targets.
    /// - Returns: This view, unchanged.
    public func scrollTargetLayout(isEnabled: Bool = true) -> some View {
        self
    }

    /// Adds an action to perform when the scroll views within this view move
    /// between scroll phases.
    ///
    /// Never called so far: no backend reports when the user starts or stops
    /// scrolling. Don't rely on it for anything but polish.
    ///
    /// - Parameter action: The action, given the old and new phases.
    /// - Returns: This view, unchanged.
    public func onScrollPhaseChange(
        _ action: @escaping (_ oldPhase: ScrollPhase, _ newPhase: ScrollPhase) -> Void
    ) -> some View {
        self
    }

    /// Sets the edge effect the scroll views within this view draw where
    /// their content meets a bar.
    ///
    /// Purely cosmetic: SwiftCrossUI's scroll views draw no edge effect.
    ///
    /// - Parameters:
    ///   - style: The style, or `nil` for the default.
    ///   - edges: The edges the style applies to.
    /// - Returns: This view, unchanged.
    public func scrollEdgeEffectStyle(
        _ style: ScrollEdgeEffectStyle?,
        for edges: Edge.Set
    ) -> some View {
        self
    }
}
