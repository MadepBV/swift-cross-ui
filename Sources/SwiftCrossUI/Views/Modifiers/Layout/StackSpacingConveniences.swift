/// Fractional spacing for the eager stacks.
///
/// SwiftUI measures stack spacing in `CGFloat`; SwiftCrossUI's ``HStack`` and
/// ``VStack`` lay out in whole points and take `Int` spacing. These overloads
/// accept any floating-point spacing (`CGFloat`, `Double`) and round it up to
/// the nearest point, as ``LazyVStack`` does. Integer literals still pick the
/// `Int` initializers.
extension HStack {
    /// Creates a horizontal stack with fractional spacing.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the stack's children in the vertical
    ///     direction.
    ///   - spacing: The amount of spacing to apply between children, rounded
    ///     up to a whole point. `nil` uses the default spacing.
    ///   - content: The content of the stack.
    @_disfavoredOverload
    public init<Spacing: BinaryFloatingPoint>(
        alignment: VerticalAlignment = .center,
        spacing: Spacing?,
        @ViewBuilder _ content: () -> Content
    ) {
        self.init(
            alignment: alignment,
            spacing: spacing.map { LayoutSystem.roundSize(Double($0)) },
            content: content()
        )
    }
}

extension VStack {
    /// Creates a vertical stack with fractional spacing.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the stack's children in the horizontal
    ///     direction.
    ///   - spacing: The amount of spacing to apply between children, rounded
    ///     up to a whole point. `nil` uses the default spacing.
    ///   - content: The content of the stack.
    @_disfavoredOverload
    public init<Spacing: BinaryFloatingPoint>(
        alignment: HorizontalAlignment = .center,
        spacing: Spacing?,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            alignment: alignment,
            spacing: spacing.map { LayoutSystem.roundSize(Double($0)) },
            content: content()
        )
    }
}
