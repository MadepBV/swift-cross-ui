/// A property wrapper that reads and writes which view currently has keyboard
/// focus.
///
/// Declare a `FocusState` property in a view, bind views to it with
/// ``View/focused(_:equals:)``, and the property tracks (and controls) focus:
///
/// ```swift
/// struct DetailForm: View {
///     enum Field: Hashable {
///         case name
///         case diameter
///     }
///
///     @FocusState private var focusedField: Field?
///     @State private var name = ""
///     @State private var diameter = ""
///
///     var body: some View {
///         VStack {
///             TextField("Name", text: $name)
///                 .focused($focusedField, equals: .name)
///             TextField("Diameter", text: $diameter)
///                 .focused($focusedField, equals: .diameter)
///             Button("Start over") {
///                 // Writing to the property moves focus.
///                 focusedField = .name
///             }
///         }
///     }
/// }
/// ```
///
/// The binding is genuinely two-way: assigning to the property moves platform
/// focus, and focus changes driven by the user (clicking, tabbing) write back
/// to the property. How completely each direction is implemented depends on
/// the backend; see ``BackendFeatures/Focus``.
///
/// `Value` is normally either `Bool` (with ``View/focused(_:)``) or an optional
/// `Hashable` type, usually an enum naming each focusable field. Those are the
/// only two shapes that can express "nothing is focused", which is why they're
/// the only two shapes ``init()`` supports.
///
/// - Note: On backends that don't implement ``BackendFeatures/Focus``, the
///   property still stores and publishes values, but nothing observes or
///   drives platform focus.
@propertyWrapper
public struct FocusState<Value: Hashable>: ObservableProperty {
    private final class Storage: StateStorageProtocol {
        var value: Value
        var didChange = Publisher()
        var downstreamObservation: Cancellable?

        init(_ value: Value) {
            self.value = value
        }
    }

    private let implementation: StateImpl<Storage>

    /// The value representing "no view in this group has focus".
    ///
    /// `false` for `Bool` focus states and `nil` for optional ones. Used to
    /// clear the state when the focused view resigns focus.
    private let unfocusedValue: Value

    public var didChange: Publisher { implementation.storage.didChange }

    /// Whether (or which) view bound to this property currently has focus.
    public var wrappedValue: Value {
        get { implementation.wrappedValue }
        nonmutating set { implementation.wrappedValue = newValue }
    }

    /// A binding used with ``View/focused(_:equals:)`` and ``View/focused(_:)``.
    public var projectedValue: FocusState<Value>.Binding {
        FocusState<Value>.Binding(
            base: implementation.projectedValue,
            unfocusedValue: unfocusedValue
        )
    }

    /// Creates a focus state that tracks whether a single view has focus.
    public init() where Value == Bool {
        implementation = StateImpl(initialStorage: Storage(false))
        unfocusedValue = false
    }

    /// Creates a focus state that tracks which of several views has focus.
    ///
    /// The state starts out `nil`, meaning nothing is focused.
    public init() where Value: ExpressibleByNilLiteral {
        implementation = StateImpl(initialStorage: Storage(nil))
        unfocusedValue = nil
    }

    public func update(
        with environment: EnvironmentValues,
        previousValue: FocusState<Value>?
    ) {
        implementation.update(
            with: environment,
            previousValue: previousValue?.implementation
        )
    }
}

extension FocusState {
    /// A binding to a ``FocusState``, produced by its `$` projection.
    @propertyWrapper
    public struct Binding {
        /// The underlying binding to the focus state's storage.
        let base: SwiftCrossUI.Binding<Value>
        /// The value representing "nothing is focused".
        let unfocusedValue: Value

        /// The focus state's current value.
        public var wrappedValue: Value {
            get { base.wrappedValue }
            nonmutating set { base.wrappedValue = newValue }
        }

        /// The binding itself, so that focus bindings can be passed on with
        /// `$` syntax just like ``SwiftCrossUI/Binding``.
        public var projectedValue: FocusState<Value>.Binding { self }

        /// Erases this binding to the form consumed by
        /// ``View/focused(_:equals:)``.
        ///
        /// - Parameter value: The value that means "the modified view has
        ///   focus".
        /// - Returns: A type-erased two-way focus binding.
        func erased(matching value: Value) -> AnyFocusBinding {
            let base = base
            let unfocusedValue = unfocusedValue
            return AnyFocusBinding(
                isFocused: {
                    base.wrappedValue == value
                },
                setFocused: { shouldFocus in
                    if shouldFocus {
                        guard base.wrappedValue != value else { return }
                        base.wrappedValue = value
                    } else {
                        guard base.wrappedValue == value else { return }
                        base.wrappedValue = unfocusedValue
                    }
                }
            )
        }
    }
}

/// A type-erased two-way binding between a ``FocusState`` and a single
/// focusable view.
///
/// Erasing the focus state's `Value` lets ``FocusModifier`` stay non-generic
/// over it, which keeps the view graph's type explosion in check.
struct AnyFocusBinding {
    /// Whether the bound view should currently have focus.
    var isFocused: () -> Bool
    /// Records that the bound view gained or lost focus.
    ///
    /// Setting `false` only clears the focus state if the bound view is the
    /// one it currently names, so that a view resigning focus can't clobber
    /// the view that just took it.
    var setFocused: (Bool) -> Void
}
