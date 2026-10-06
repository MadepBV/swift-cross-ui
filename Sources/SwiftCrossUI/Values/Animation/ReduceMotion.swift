extension EnvironmentValues {
    /// Whether the user has asked for less motion.
    ///
    /// Apps read this to pick a calmer alternative to a motion effect, such
    /// as `withAnimation(reduceMotion ? nil : .smooth)`.
    ///
    /// - Note: Backends don't report the system setting yet, so this is the
    ///   platform default, `false`. SwiftCrossUI plays no animations (see
    ///   ``Animation``), so motion is already reduced either way; the value
    ///   matters for app behaviour that keys off it, such as auto-advancing
    ///   carousels. Set it with ``View/environment(_:_:)`` to test that.
    @Entry public var accessibilityReduceMotion = false
}
