extension View {
    /// Runs an action when a value changes.
    ///
    /// This is SwiftUI's original spelling, whose action receives nothing.
    ///
    /// - Parameters:
    ///   - value: The value to watch. The action runs on every update in
    ///     which it differs from the value seen on the previous update.
    ///   - initial: Whether to also run the action on the first update.
    ///   - action: The action to run.
    /// - Returns: A view that runs `action` when `value` changes.
    public func onChange<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        perform action: @escaping () -> Void
    ) -> some View {
        OnChangeModifier(
            body: TupleView1(self),
            value: value,
            action: { _, _ in action() },
            initial: initial
        )
    }

    /// Runs an action, handed the old and new values, when a value changes.
    ///
    /// This is SwiftUI's macOS 14 / iOS 17 spelling. On the initial run (when
    /// `initial` is `true`) both arguments are the current value, as in
    /// SwiftUI.
    ///
    /// ```swift
    /// .onChange(of: selection) { oldValue, newValue in
    ///     reseed(from: newValue, previous: oldValue)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value to watch. The action runs on every update in
    ///     which it differs from the value seen on the previous update.
    ///   - initial: Whether to also run the action on the first update.
    ///   - action: The action to run, given the previous and the new value.
    /// - Returns: A view that runs `action` when `value` changes.
    public func onChange<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        _ action: @escaping (_ oldValue: Value, _ newValue: Value) -> Void
    ) -> some View {
        OnChangeModifier(
            body: TupleView1(self),
            value: value,
            action: action,
            initial: initial
        )
    }

    /// Runs an action, handed the new value, when a value changes.
    ///
    /// This is SwiftUI's macOS 14 / iOS 17 spelling with a single argument.
    ///
    /// - Parameters:
    ///   - value: The value to watch.
    ///   - initial: Whether to also run the action on the first update.
    ///   - action: The action to run, given the new value.
    /// - Returns: A view that runs `action` when `value` changes.
    public func onChange<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        _ action: @escaping (_ newValue: Value) -> Void
    ) -> some View {
        OnChangeModifier(
            body: TupleView1(self),
            value: value,
            action: { _, newValue in action(newValue) },
            initial: initial
        )
    }

    /// Runs an action, handed the new value, when a value changes.
    ///
    /// This is the spelling SwiftUI deprecated in favour of
    /// ``View/onChange(of:initial:_:)-(Value,Value)``.
    ///
    /// - Parameters:
    ///   - value: The value to watch.
    ///   - action: The action to run, given the new value.
    /// - Returns: A view that runs `action` when `value` changes.
    @available(*, deprecated, message: "Use `onChange(of:initial:_:)` instead")
    public func onChange<Value: Equatable>(
        of value: Value,
        perform action: @escaping (_ newValue: Value) -> Void
    ) -> some View {
        OnChangeModifier(
            body: TupleView1(self),
            value: value,
            action: { _, newValue in action(newValue) },
            initial: false
        )
    }
}

/// Runs an action whenever the watched value differs from the value seen on
/// the previous update.
///
/// The previous value lives in the node's state, so it survives every
/// re-evaluation of the enclosing body: the comparison is always against the
/// value from the last update, never against the value the modifier was
/// created with (which would make the old and new values identical).
struct OnChangeModifier<Value: Equatable, Content: View>: View {
    /// Reference storage for the previous value.
    ///
    /// Recording the previous value must not itself schedule another update
    /// (it happens in the middle of layout), so it lives in a box held by the
    /// node's state rather than directly in `@State`.
    struct PreviousValue {
        var box = Box<Value?>(nil)
    }

    /// The value seen on the previous update, or `nil` before the first.
    @State private var previousValue = PreviousValue()

    var body: TupleView1<Content>

    var value: Value
    var action: (Value, Value) -> Void
    var initial: Bool

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // Layout can run several times per update (probing passes with
        // caching, then the final pass), so the previous value is recorded
        // before the action runs: a second pass then sees no change and the
        // action runs exactly once per change.
        let box = previousValue.box
        if let previous = box.value {
            if previous != value {
                box.value = value
                action(previous, value)
            }
        } else {
            box.value = value
            if initial {
                action(value, value)
            }
        }

        return defaultComputeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
    }
}
