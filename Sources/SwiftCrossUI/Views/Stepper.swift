/// A control that nudges a value up or down.
///
/// ```swift
/// Stepper("Bar count", value: $barCount, in: 1...64)
/// Stepper("Cover", value: $cover, in: 20.0...80.0, step: 5)
/// ```
///
/// Steppers created with a range disable the button that would take the value
/// out of that range, and clamp the value to the range regardless. Steppers
/// created with custom `onIncrement` and `onDecrement` actions disable
/// whichever of their two buttons was given a `nil` action.
///
/// - Note: SwiftCrossUI composes steppers out of a label and two buttons
///   rather than using a native stepper widget, so a stepper looks the same
///   on every backend.
public struct Stepper<Label: View>: View {
    /// The minimum amount of space to leave between the label and the
    /// buttons.
    private static var labelSpacing: Int { 8 }

    /// The amount of space between the decrement and increment buttons.
    private static var buttonSpacing: Int { 2 }

    /// The label of the button that decrements the value (a minus sign).
    private static var decrementSymbol: String { "\u{2212}" }

    /// The label of the button that increments the value.
    private static var incrementSymbol: String { "+" }

    /// A view describing the value that the stepper nudges.
    private var label: Label

    /// Nudges the value up. Does nothing when incrementing isn't possible.
    private var increment: () -> Void

    /// Nudges the value down. Does nothing when decrementing isn't possible.
    private var decrement: () -> Void

    /// Whether the increment button is enabled. Re-evaluated on every update
    /// so that the buttons respond to the value reaching a bound.
    private var isIncrementEnabled: () -> Bool

    /// Whether the decrement button is enabled.
    private var isDecrementEnabled: () -> Bool

    /// Creates a stepper from an already built label.
    ///
    /// Exists because ``ViewBuilder`` would otherwise wrap the labels of the
    /// convenience initializers in a ``TupleView1``, which would conflict
    /// with their `Label == Text` requirement.
    ///
    /// - Parameters:
    ///   - label: A view describing the value that the stepper nudges.
    ///   - increment: Nudges the value up.
    ///   - decrement: Nudges the value down.
    ///   - isIncrementEnabled: Whether the increment button is enabled.
    ///   - isDecrementEnabled: Whether the decrement button is enabled.
    private init(
        label: Label,
        increment: @escaping () -> Void,
        decrement: @escaping () -> Void,
        isIncrementEnabled: @escaping () -> Bool,
        isDecrementEnabled: @escaping () -> Bool
    ) {
        self.label = label
        self.increment = increment
        self.decrement = decrement
        self.isIncrementEnabled = isIncrementEnabled
        self.isDecrementEnabled = isDecrementEnabled
    }

    /// Creates a stepper that nudges a value within a range.
    ///
    /// - Parameters:
    ///   - value: A binding to the value that the stepper nudges.
    ///   - bounds: The range that `value` is kept within.
    ///   - step: The amount that each nudge changes `value` by.
    ///   - onEditingChanged: Called with `true` when a nudge begins and
    ///     `false` when it ends.
    ///   - label: A view describing the value that the stepper nudges.
    public init<Value: Strideable>(
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            label: label(),
            increment: Self.nudge(
                value,
                by: step,
                in: bounds,
                onEditingChanged: onEditingChanged
            ),
            decrement: Self.nudge(
                value,
                by: -step,
                in: bounds,
                onEditingChanged: onEditingChanged
            ),
            isIncrementEnabled: { value.wrappedValue < bounds.upperBound },
            isDecrementEnabled: { value.wrappedValue > bounds.lowerBound }
        )
    }

    /// Creates a stepper that nudges an unbounded value.
    ///
    /// - Parameters:
    ///   - value: A binding to the value that the stepper nudges.
    ///   - step: The amount that each nudge changes `value` by.
    ///   - onEditingChanged: Called with `true` when a nudge begins and
    ///     `false` when it ends.
    ///   - label: A view describing the value that the stepper nudges.
    public init<Value: Strideable>(
        value: Binding<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            label: label(),
            increment: Self.nudge(
                value,
                by: step,
                in: nil,
                onEditingChanged: onEditingChanged
            ),
            decrement: Self.nudge(
                value,
                by: -step,
                in: nil,
                onEditingChanged: onEditingChanged
            ),
            isIncrementEnabled: { true },
            isDecrementEnabled: { true }
        )
    }

    /// Creates a stepper that performs custom increment and decrement
    /// actions.
    ///
    /// - Parameters:
    ///   - onIncrement: The action performed when the user nudges upwards, or
    ///     `nil` to disable the increment button.
    ///   - onDecrement: The action performed when the user nudges downwards,
    ///     or `nil` to disable the decrement button.
    ///   - onEditingChanged: Called with `true` when a nudge begins and
    ///     `false` when it ends.
    ///   - label: A view describing the value that the stepper nudges.
    public init(
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            label: label(),
            increment: Self.perform(onIncrement, onEditingChanged: onEditingChanged),
            decrement: Self.perform(onDecrement, onEditingChanged: onEditingChanged),
            isIncrementEnabled: { onIncrement != nil },
            isDecrementEnabled: { onDecrement != nil }
        )
    }

    /// Builds an action that moves a value by a stride, clamping it to a
    /// range if there is one.
    ///
    /// - Parameters:
    ///   - value: A binding to the value to nudge.
    ///   - stride: The amount to move the value by.
    ///   - bounds: The range to keep the value within, if any.
    ///   - onEditingChanged: Called around the nudge.
    /// - Returns: The action to attach to a stepper button.
    private static func nudge<Value: Strideable>(
        _ value: Binding<Value>,
        by stride: Value.Stride,
        in bounds: ClosedRange<Value>?,
        onEditingChanged: @escaping (Bool) -> Void
    ) -> () -> Void {
        return {
            onEditingChanged(true)
            var newValue = value.wrappedValue.advanced(by: stride)
            if let bounds {
                newValue = min(max(newValue, bounds.lowerBound), bounds.upperBound)
            }
            if newValue != value.wrappedValue {
                value.wrappedValue = newValue
            }
            onEditingChanged(false)
        }
    }

    /// Builds an action that runs a user supplied nudge action, if there is
    /// one.
    ///
    /// - Parameters:
    ///   - action: The user supplied action, or `nil` if the corresponding
    ///     button is disabled.
    ///   - onEditingChanged: Called around the nudge.
    /// - Returns: The action to attach to a stepper button.
    private static func perform(
        _ action: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void
    ) -> () -> Void {
        return {
            guard let action else {
                return
            }
            onEditingChanged(true)
            action()
            onEditingChanged(false)
        }
    }

    public var body: some View {
        // Resolved once so that the buttons' actions capture just the nudge
        // actions rather than the whole stepper (including its label).
        let increment = self.increment
        let decrement = self.decrement

        HStack(spacing: Self.labelSpacing) {
            label

            Spacer(minLength: Self.labelSpacing)

            HStack(spacing: Self.buttonSpacing) {
                Button(Self.decrementSymbol) {
                    decrement()
                }
                .disabled(!isDecrementEnabled())

                Button(Self.incrementSymbol) {
                    increment()
                }
                .disabled(!isIncrementEnabled())
            }
        }
    }
}

extension Stepper where Label == Text {
    /// Creates a stepper with a text label that nudges a value within a
    /// range.
    ///
    /// - Parameters:
    ///   - titleKey: Text describing the value that the stepper nudges.
    ///   - value: A binding to the value that the stepper nudges.
    ///   - bounds: The range that `value` is kept within.
    ///   - step: The amount that each nudge changes `value` by.
    ///   - onEditingChanged: Called with `true` when a nudge begins and
    ///     `false` when it ends.
    public init<Value: Strideable>(
        _ titleKey: String,
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.init(
            label: Text(titleKey),
            increment: Self.nudge(
                value,
                by: step,
                in: bounds,
                onEditingChanged: onEditingChanged
            ),
            decrement: Self.nudge(
                value,
                by: -step,
                in: bounds,
                onEditingChanged: onEditingChanged
            ),
            isIncrementEnabled: { value.wrappedValue < bounds.upperBound },
            isDecrementEnabled: { value.wrappedValue > bounds.lowerBound }
        )
    }

    /// Creates a stepper with a text label that nudges an unbounded value.
    ///
    /// - Parameters:
    ///   - titleKey: Text describing the value that the stepper nudges.
    ///   - value: A binding to the value that the stepper nudges.
    ///   - step: The amount that each nudge changes `value` by.
    ///   - onEditingChanged: Called with `true` when a nudge begins and
    ///     `false` when it ends.
    public init<Value: Strideable>(
        _ titleKey: String,
        value: Binding<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.init(
            label: Text(titleKey),
            increment: Self.nudge(
                value,
                by: step,
                in: nil,
                onEditingChanged: onEditingChanged
            ),
            decrement: Self.nudge(
                value,
                by: -step,
                in: nil,
                onEditingChanged: onEditingChanged
            ),
            isIncrementEnabled: { true },
            isDecrementEnabled: { true }
        )
    }

    /// Creates a stepper with a text label that performs custom increment and
    /// decrement actions.
    ///
    /// - Parameters:
    ///   - titleKey: Text describing the value that the stepper nudges.
    ///   - onIncrement: The action performed when the user nudges upwards, or
    ///     `nil` to disable the increment button.
    ///   - onDecrement: The action performed when the user nudges downwards,
    ///     or `nil` to disable the decrement button.
    ///   - onEditingChanged: Called with `true` when a nudge begins and
    ///     `false` when it ends.
    public init(
        _ titleKey: String,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.init(
            label: Text(titleKey),
            increment: Self.perform(onIncrement, onEditingChanged: onEditingChanged),
            decrement: Self.perform(onDecrement, onEditingChanged: onEditingChanged),
            isIncrementEnabled: { onIncrement != nil },
            isDecrementEnabled: { onDecrement != nil }
        )
    }
}
