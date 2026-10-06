/// When a ``View/defaultFocus(_:_:priority:)`` takes effect.
public struct DefaultFocusEvaluationPriority: Hashable, Sendable {
    /// The priority's identity.
    private let rawValue: Int

    /// Only when the system moves focus on its own, such as when the view
    /// first appears.
    public static let automatic = DefaultFocusEvaluationPriority(rawValue: 0)
    /// Also when the user moves focus into the view. SwiftCrossUI has no
    /// focus regions to move into, so this behaves as ``automatic``.
    public static let userInitiated = DefaultFocusEvaluationPriority(rawValue: 1)
}

extension View {
    /// Focuses a value when this view appears, unless something else within
    /// it already has focus.
    ///
    /// ```swift
    /// @FocusState private var focusedField: Field?
    ///
    /// Form { ... }
    ///     .defaultFocus($focusedField, .name)
    /// ```
    ///
    /// - Parameters:
    ///   - binding: The focus state to set.
    ///   - value: The value to focus.
    ///   - priority: When the default takes effect.
    /// - Returns: A view that focuses `value` when it appears.
    public func defaultFocus<Value: Hashable>(
        _ binding: FocusState<Value>.Binding,
        _ value: Value,
        priority: DefaultFocusEvaluationPriority = .automatic
    ) -> some View {
        onAppear {
            if binding.wrappedValue == binding.unfocusedValue {
                binding.wrappedValue = value
            }
        }
    }
}
