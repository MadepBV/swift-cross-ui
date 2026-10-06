/// How a change of state is animated.
///
/// ```swift
/// withAnimation(.easeInOut(duration: 0.25)) {
///     isExpanded.toggle()
/// }
/// ```
///
/// ## Animations complete instantly
///
/// SwiftCrossUI has no animation system: a view redraws in its new state as
/// soon as the state changes, as if every animation had a duration of zero.
/// ``Animation`` records the curve, timing and repetition an author asked
/// for, with SwiftUI's spellings, so that SwiftUI source compiles unchanged
/// and the intent is kept for a future animation engine. The same holds for
/// ``AnyTransition`` and ``View/transition(_:)``.
public struct Animation: Hashable, Sendable {
    /// The shape of an animation's progress over time.
    enum Curve: Hashable, Sendable {
        case linear
        case easeIn
        case easeOut
        case easeInOut
        case spring(response: Double, dampingFraction: Double)
    }

    var curve: Curve
    /// The duration of one repetition, in seconds.
    var duration: Double
    var delay: Double = 0
    var speed: Double = 1
    /// How many times the animation runs; `nil` repeats it forever.
    var repeatCount: Int? = 1
    var autoreverses = false

    /// The default animation: a smooth spring.
    public static let `default` = Animation.spring(response: 0.55, dampingFraction: 1)

    /// A constant-speed animation of the default duration.
    public static let linear = Animation(curve: .linear, duration: 0.35)
    /// An animation that starts slowly.
    public static let easeIn = Animation(curve: .easeIn, duration: 0.35)
    /// An animation that ends slowly.
    public static let easeOut = Animation(curve: .easeOut, duration: 0.35)
    /// An animation that starts and ends slowly.
    public static let easeInOut = Animation(curve: .easeInOut, duration: 0.35)
    /// A spring with no bounce.
    public static let smooth = Animation.smooth(duration: 0.5)
    /// A quick spring with a little bounce.
    public static let snappy = Animation.snappy(duration: 0.5)
    /// A spring with a noticeable bounce.
    public static let bouncy = Animation.bouncy(duration: 0.5)
    /// The default spring.
    public static let spring = Animation.spring(response: 0.5, dampingFraction: 0.825)
    /// A spring tuned for following the pointer.
    public static let interactiveSpring = Animation.spring(
        response: 0.15,
        dampingFraction: 0.86
    )

    /// A constant-speed animation.
    public static func linear(duration: Double) -> Animation {
        Animation(curve: .linear, duration: duration)
    }

    /// An animation that starts slowly.
    public static func easeIn(duration: Double) -> Animation {
        Animation(curve: .easeIn, duration: duration)
    }

    /// An animation that ends slowly.
    public static func easeOut(duration: Double) -> Animation {
        Animation(curve: .easeOut, duration: duration)
    }

    /// An animation that starts and ends slowly.
    public static func easeInOut(duration: Double) -> Animation {
        Animation(curve: .easeInOut, duration: duration)
    }

    /// A spring described by its response and damping.
    public static func spring(
        response: Double = 0.5,
        dampingFraction: Double = 0.825,
        blendDuration: Double = 0
    ) -> Animation {
        Animation(
            curve: .spring(response: response, dampingFraction: dampingFraction),
            duration: response
        )
    }

    /// A spring described by its duration and bounce.
    public static func spring(
        duration: Double = 0.5,
        bounce: Double = 0,
        blendDuration: Double = 0
    ) -> Animation {
        spring(response: duration, dampingFraction: 1 - bounce)
    }

    /// A spring with no bounce.
    public static func smooth(duration: Double = 0.5, extraBounce: Double = 0) -> Animation {
        spring(duration: duration, bounce: extraBounce)
    }

    /// A quick spring with a little bounce.
    public static func snappy(duration: Double = 0.5, extraBounce: Double = 0) -> Animation {
        spring(duration: duration, bounce: 0.15 + extraBounce)
    }

    /// A spring with a noticeable bounce.
    public static func bouncy(duration: Double = 0.5, extraBounce: Double = 0) -> Animation {
        spring(duration: duration, bounce: 0.3 + extraBounce)
    }

    /// This animation, starting after a delay.
    ///
    /// - Parameter delay: The delay, in seconds.
    public func delay(_ delay: Double) -> Animation {
        var animation = self
        animation.delay += delay
        return animation
    }

    /// This animation, played faster or slower.
    ///
    /// - Parameter speed: The speed multiplier.
    public func speed(_ speed: Double) -> Animation {
        var animation = self
        animation.speed *= speed
        return animation
    }

    /// This animation, repeated.
    ///
    /// - Parameters:
    ///   - repeatCount: How many times to play it.
    ///   - autoreverses: Whether every other repetition plays backwards.
    public func repeatCount(_ repeatCount: Int, autoreverses: Bool = true) -> Animation {
        var animation = self
        animation.repeatCount = repeatCount
        animation.autoreverses = autoreverses
        return animation
    }

    /// This animation, repeated forever.
    ///
    /// Because animations complete instantly (see ``Animation``), a repeating
    /// animation shows its final state, which is the state the author set.
    ///
    /// - Parameter autoreverses: Whether every other repetition plays
    ///   backwards.
    public func repeatForever(autoreverses: Bool = true) -> Animation {
        var animation = self
        animation.repeatCount = nil
        animation.autoreverses = autoreverses
        return animation
    }
}

/// Changes state, animating the views that change as a result.
///
/// Runs `body` immediately and returns its result. SwiftCrossUI has no
/// animation system, so the views redraw in their new state at once; see
/// ``Animation``.
///
/// - Parameters:
///   - animation: The animation to use. `nil` changes state without
///     animating, as it would anyway.
///   - body: The state change.
/// - Returns: What `body` returns.
public func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    try body()
}

/// Changes state, animating the views that change as a result, and calls
/// `completion` once the animation has finished.
///
/// The animation finishes as soon as it starts (see ``Animation``), so
/// `completion` runs on the main actor right after `body`.
///
/// - Parameters:
///   - animation: The animation to use.
///   - body: The state change.
///   - completion: Called when the animation has finished.
/// - Returns: What `body` returns.
@MainActor
public func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result,
    completion: @escaping @MainActor () -> Void
) rethrows -> Result {
    let result = try body()
    completion()
    return result
}

extension View {
    /// Animates the changes to this view that happen when `value` changes.
    ///
    /// The view changes instantly; see ``Animation``.
    ///
    /// - Parameters:
    ///   - animation: The animation to use.
    ///   - value: The value whose changes are animated.
    /// - Returns: The view.
    public func animation<Value: Equatable>(
        _ animation: Animation?,
        value: Value
    ) -> some View {
        self
    }

    /// Animates every change to this view.
    ///
    /// The view changes instantly; see ``Animation``.
    ///
    /// - Parameter animation: The animation to use.
    /// - Returns: The view.
    @available(*, deprecated, message: "Use animation(_:value:) instead.")
    public func animation(_ animation: Animation?) -> some View {
        self
    }
}
