/// Where a view is relative to the visible region of the scroll view it's
/// in, as passed to a ``View/scrollTransition(_:axis:transition:)`` closure.
public enum ScrollTransitionPhase: Hashable, Sendable {
    /// The view is entering or leaving at the top or leading edge.
    case topLeading
    /// The view is fully inside the visible region.
    case identity
    /// The view is entering or leaving at the bottom or trailing edge.
    case bottomTrailing

    /// Whether the view is fully inside the visible region.
    public var isIdentity: Bool {
        self == .identity
    }

    /// The phase as a number: -1 at the top or leading edge, 0 inside the
    /// visible region and 1 at the bottom or trailing edge.
    public var value: Double {
        switch self {
            case .topLeading: -1
            case .identity: 0
            case .bottomTrailing: 1
        }
    }
}

/// How a ``View/scrollTransition(_:axis:transition:)`` moves between its
/// phases.
public struct ScrollTransitionConfiguration: Sendable {
    enum Kind: Sendable {
        case identity
        case interactive
        case animated(Animation)
    }

    let kind: Kind
    /// How far into the visible region the view must be to count as inside
    /// it, as a fraction of its size.
    var threshold: Double = 0

    /// The transition follows the scroll position exactly.
    public static let interactive = ScrollTransitionConfiguration(kind: .interactive)
    /// The transition animates between phases with the default animation.
    public static let animated = ScrollTransitionConfiguration(kind: .animated(.default))
    /// No transition: the view always draws in its identity phase.
    public static let identity = ScrollTransitionConfiguration(kind: .identity)

    /// The transition animates between phases with an animation.
    ///
    /// - Parameter animation: The animation to use.
    public static func animated(_ animation: Animation) -> ScrollTransitionConfiguration {
        ScrollTransitionConfiguration(kind: .animated(animation))
    }

    /// The transition follows the scroll position along a timing curve.
    ///
    /// - Parameter timingCurve: The curve; recorded, not applied.
    public static func interactive(timingCurve: Animation) -> ScrollTransitionConfiguration {
        .interactive
    }

    /// This configuration, counting a view as inside the visible region once
    /// it's past a threshold.
    ///
    /// - Parameter threshold: How far in, as a fraction of the view's size.
    public func threshold(_ threshold: Double) -> ScrollTransitionConfiguration {
        var configuration = self
        configuration.threshold = threshold
        return configuration
    }
}

extension View {
    /// Applies an effect to this view that depends on where it is relative to
    /// the visible region of the scroll view it's in.
    ///
    /// ```swift
    /// page.scrollTransition(.interactive, axis: .horizontal) { content, phase in
    ///     content.opacity(phase.isIdentity ? 1 : 0)
    /// }
    /// ```
    ///
    /// ## The phase is always identity
    ///
    /// The transition's in-between phases exist while a view crosses the
    /// edge of the visible region during a scroll. SwiftCrossUI has no
    /// per-view scroll position to compute them from, and no animation
    /// system to draw them (see ``VisualEffect``), so the closure is run with
    /// ``ScrollTransitionPhase/identity``: the view draws as it does at rest
    /// inside the visible region, which is how a paged carousel shows its
    /// current page. Effects the closure applies for that phase are drawn as
    /// ``View/visualEffect(_:)`` draws them.
    ///
    /// - Parameters:
    ///   - configuration: How the transition moves between phases.
    ///   - axis: The scroll axis to measure along, or `nil` for the scroll
    ///     view's own.
    ///   - transition: Computes the effect for a phase.
    /// - Returns: The view with the effect applied.
    public func scrollTransition<Effect: VisualEffect>(
        _ configuration: ScrollTransitionConfiguration = .interactive,
        axis: Axis? = nil,
        transition: @escaping @Sendable (EmptyVisualEffect, ScrollTransitionPhase) -> Effect
    ) -> some View {
        VisualEffectModifier(content: self) { _ in
            transition(EmptyVisualEffect(), .identity)._values
        }
    }

    /// Applies an effect that depends on where this view is relative to the
    /// visible region, with separate configurations for its top or leading
    /// and bottom or trailing edges. See
    /// ``View/scrollTransition(_:axis:transition:)``.
    ///
    /// - Parameters:
    ///   - topLeading: How the transition moves at the top or leading edge.
    ///   - bottomTrailing: How it moves at the bottom or trailing edge.
    ///   - axis: The scroll axis to measure along.
    ///   - transition: Computes the effect for a phase.
    /// - Returns: The view with the effect applied.
    public func scrollTransition<Effect: VisualEffect>(
        topLeading: ScrollTransitionConfiguration,
        bottomTrailing: ScrollTransitionConfiguration,
        axis: Axis? = nil,
        transition: @escaping @Sendable (EmptyVisualEffect, ScrollTransitionPhase) -> Effect
    ) -> some View {
        scrollTransition(topLeading, axis: axis, transition: transition)
    }
}
