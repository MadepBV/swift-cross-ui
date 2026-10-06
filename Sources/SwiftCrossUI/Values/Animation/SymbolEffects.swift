/// An animation that plays on an SF Symbol, applied with
/// ``View/symbolEffect(_:options:isActive:)`` or
/// ``View/symbolEffect(_:options:value:)``.
///
/// ## Symbol effects are inert
///
/// SwiftCrossUI draws a symbol as a single path (see ``SymbolProvider``),
/// without the layers that variable color, breathe and pulse animate, and has
/// no animation system to play a bounce or a wiggle (see ``Animation``). The
/// symbol is therefore drawn still, in its final state, which is what SwiftUI
/// shows with Reduce Motion on. The effects are recorded so that SwiftUI
/// source compiles unchanged and keeps its intent for when an animation
/// system lands. Don't rely on an effect alone to convey state: SwiftUI's
/// guidance is the same, since Reduce Motion stops them too.
public protocol SymbolEffect: Sendable {
    /// What the effect is, for inspection.
    var _symbolEffectDescription: String { get }
}

/// A symbol effect that plays continuously while it's active.
public protocol IndefiniteSymbolEffect {}

/// A symbol effect that plays once each time a value changes.
public protocol DiscreteSymbolEffect {}

/// Options for how a symbol effect plays: its speed and how often it
/// repeats.
public struct SymbolEffectOptions: Hashable, Sendable {
    /// The playback speed multiplier.
    public var speedMultiplier: Double = 1
    /// How many times the effect repeats, or `nil` for the effect's default.
    public var repetitions: Int?

    /// The effect's own speed and repetition.
    public static let `default` = SymbolEffectOptions()
    /// Repeats the effect indefinitely.
    public static let repeating = SymbolEffectOptions(repetitions: .max)
    /// Plays the effect once.
    public static let nonRepeating = SymbolEffectOptions(repetitions: 1)

    /// Repeats the effect a number of times.
    public static func `repeat`(_ count: Int) -> SymbolEffectOptions {
        SymbolEffectOptions(repetitions: count)
    }

    /// Plays the effect at a multiple of its normal speed.
    public static func speed(_ multiplier: Double) -> SymbolEffectOptions {
        SymbolEffectOptions(speedMultiplier: multiplier)
    }

    /// These options, repeated a number of times.
    public func `repeat`(_ count: Int) -> SymbolEffectOptions {
        var options = self
        options.repetitions = count
        return options
    }

    /// These options, at a multiple of their speed.
    public func speed(_ multiplier: Double) -> SymbolEffectOptions {
        var options = self
        options.speedMultiplier *= multiplier
        return options
    }
}

/// The modifiers shared by every symbol effect: which layers move, and in
/// which variation.
public struct SymbolEffectVariation: Hashable, Sendable {
    var name: String
    var modifiers: [String] = []

    func adding(_ modifier: String) -> SymbolEffectVariation {
        var variation = self
        variation.modifiers.append(modifier)
        return variation
    }

    var description: String {
        ([name] + modifiers).joined(separator: ".")
    }
}

/// Lights a symbol's layers in turn. See ``SymbolEffect``.
public struct VariableColorSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    var variation = SymbolEffectVariation(name: "variableColor")
    public var _symbolEffectDescription: String { variation.description }

    /// One layer at a time.
    public var iterative: Self { Self(variation: variation.adding("iterative")) }
    /// Each layer stays lit as the next one lights.
    public var cumulative: Self { Self(variation: variation.adding("cumulative")) }
    /// Plays forwards then backwards.
    public var reversing: Self { Self(variation: variation.adding("reversing")) }
    /// Plays forwards only.
    public var nonReversing: Self { Self(variation: variation.adding("nonReversing")) }
    /// Hides the layers that aren't lit.
    public var hideInactiveLayers: Self { Self(variation: variation.adding("hideInactiveLayers")) }
    /// Dims the layers that aren't lit.
    public var dimInactiveLayers: Self { Self(variation: variation.adding("dimInactiveLayers")) }
}

/// Makes a symbol breathe, growing and fading gently. See ``SymbolEffect``.
public struct BreatheSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    var variation = SymbolEffectVariation(name: "breathe")
    public var _symbolEffectDescription: String { variation.description }

    /// Breathes by scaling only.
    public var plain: Self { Self(variation: variation.adding("plain")) }
    /// Breathes by scaling and fading.
    public var pulse: Self { Self(variation: variation.adding("pulse")) }
    /// Animates each layer separately.
    public var byLayer: Self { Self(variation: variation.adding("byLayer")) }
    /// Animates the whole symbol at once.
    public var wholeSymbol: Self { Self(variation: variation.adding("wholeSymbol")) }
}

/// Fades a symbol's opacity in and out. See ``SymbolEffect``.
public struct PulseSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    var variation = SymbolEffectVariation(name: "pulse")
    public var _symbolEffectDescription: String { variation.description }

    /// Animates each layer separately.
    public var byLayer: Self { Self(variation: variation.adding("byLayer")) }
    /// Animates the whole symbol at once.
    public var wholeSymbol: Self { Self(variation: variation.adding("wholeSymbol")) }
}

/// Bounces a symbol. See ``SymbolEffect``.
public struct BounceSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    var variation = SymbolEffectVariation(name: "bounce")
    public var _symbolEffectDescription: String { variation.description }

    /// Bounces upwards.
    public var up: Self { Self(variation: variation.adding("up")) }
    /// Bounces downwards.
    public var down: Self { Self(variation: variation.adding("down")) }
    /// Animates each layer separately.
    public var byLayer: Self { Self(variation: variation.adding("byLayer")) }
    /// Animates the whole symbol at once.
    public var wholeSymbol: Self { Self(variation: variation.adding("wholeSymbol")) }
}

/// Scales a symbol up or down while it's active. See ``SymbolEffect``.
public struct ScaleSymbolEffect: SymbolEffect, IndefiniteSymbolEffect {
    var variation = SymbolEffectVariation(name: "scale")
    public var _symbolEffectDescription: String { variation.description }

    /// Scales up.
    public var up: Self { Self(variation: variation.adding("up")) }
    /// Scales down.
    public var down: Self { Self(variation: variation.adding("down")) }
    /// Animates each layer separately.
    public var byLayer: Self { Self(variation: variation.adding("byLayer")) }
    /// Animates the whole symbol at once.
    public var wholeSymbol: Self { Self(variation: variation.adding("wholeSymbol")) }
}

/// Wiggles a symbol. See ``SymbolEffect``.
public struct WiggleSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    var variation = SymbolEffectVariation(name: "wiggle")
    public var _symbolEffectDescription: String { variation.description }

    /// Animates each layer separately.
    public var byLayer: Self { Self(variation: variation.adding("byLayer")) }
    /// Animates the whole symbol at once.
    public var wholeSymbol: Self { Self(variation: variation.adding("wholeSymbol")) }
}

/// Rotates a symbol. See ``SymbolEffect``.
public struct RotateSymbolEffect: SymbolEffect, IndefiniteSymbolEffect, DiscreteSymbolEffect {
    var variation = SymbolEffectVariation(name: "rotate")
    public var _symbolEffectDescription: String { variation.description }

    /// Rotates clockwise.
    public var clockwise: Self { Self(variation: variation.adding("clockwise")) }
    /// Rotates counter-clockwise.
    public var counterClockwise: Self { Self(variation: variation.adding("counterClockwise")) }
    /// Animates each layer separately.
    public var byLayer: Self { Self(variation: variation.adding("byLayer")) }
    /// Animates the whole symbol at once.
    public var wholeSymbol: Self { Self(variation: variation.adding("wholeSymbol")) }
}

extension SymbolEffect where Self == VariableColorSymbolEffect {
    /// Lights a symbol's layers in turn.
    public static var variableColor: VariableColorSymbolEffect { VariableColorSymbolEffect() }
}

extension SymbolEffect where Self == BreatheSymbolEffect {
    /// Makes a symbol breathe.
    public static var breathe: BreatheSymbolEffect { BreatheSymbolEffect() }
}

extension SymbolEffect where Self == PulseSymbolEffect {
    /// Fades a symbol in and out.
    public static var pulse: PulseSymbolEffect { PulseSymbolEffect() }
}

extension SymbolEffect where Self == BounceSymbolEffect {
    /// Bounces a symbol.
    public static var bounce: BounceSymbolEffect { BounceSymbolEffect() }
}

extension SymbolEffect where Self == ScaleSymbolEffect {
    /// Scales a symbol while active.
    public static var scale: ScaleSymbolEffect { ScaleSymbolEffect() }
}

extension SymbolEffect where Self == WiggleSymbolEffect {
    /// Wiggles a symbol.
    public static var wiggle: WiggleSymbolEffect { WiggleSymbolEffect() }
}

extension SymbolEffect where Self == RotateSymbolEffect {
    /// Rotates a symbol.
    public static var rotate: RotateSymbolEffect { RotateSymbolEffect() }
}

extension View {
    /// Plays a symbol effect continuously while `isActive` is `true`.
    ///
    /// Inert: the symbol is drawn still. See ``SymbolEffect``.
    ///
    /// - Parameters:
    ///   - effect: The effect to play.
    ///   - options: How it plays.
    ///   - isActive: Whether it plays.
    /// - Returns: The view, drawn unchanged.
    public func symbolEffect<T: IndefiniteSymbolEffect & SymbolEffect>(
        _ effect: T,
        options: SymbolEffectOptions = .default,
        isActive: Bool = true
    ) -> some View {
        self
    }

    /// Plays a symbol effect once each time `value` changes.
    ///
    /// Inert: the symbol is drawn still. See ``SymbolEffect``.
    ///
    /// - Parameters:
    ///   - effect: The effect to play.
    ///   - options: How it plays.
    ///   - value: The value whose changes trigger the effect.
    /// - Returns: The view, drawn unchanged.
    public func symbolEffect<T: DiscreteSymbolEffect & SymbolEffect, U: Equatable>(
        _ effect: T,
        options: SymbolEffectOptions = .default,
        value: U
    ) -> some View {
        self
    }

    /// Removes the symbol effects from this view and its descendants.
    ///
    /// Symbol effects are inert, so there's nothing to remove. See
    /// ``SymbolEffect``.
    ///
    /// - Parameter isEnabled: Whether to remove them.
    /// - Returns: The view, unchanged.
    public func symbolEffectsRemoved(_ isEnabled: Bool = true) -> some View {
        self
    }
}
