/// A named value produced by a view.
///
/// A view sets a value for a key with
/// ``View/preference(key:value:)-(K.Type,K.Value)``; its ancestors read the
/// combined value of their descendants with
/// ``View/onPreferenceChange(_:perform:)``.
///
/// ```swift
/// struct FocusWithinKey: PreferenceKey {
///     static let defaultValue = false
///     static func reduce(value: inout Bool, nextValue: () -> Bool) {
///         value = value || nextValue()
///     }
/// }
/// ```
public protocol PreferenceKey {
    /// The type of value produced by this preference.
    associatedtype Value

    /// The default value of the preference.
    static var defaultValue: Value { get }

    /// Combines a sequence of values by modifying the previously-accumulated
    /// value with the result of a closure that provides the next value.
    ///
    /// - Parameters:
    ///   - value: The value accumulated through previous calls.
    ///   - nextValue: Provides the next value in the sequence.
    static func reduce(value: inout Value, nextValue: () -> Value)
}

extension PreferenceKey {
    /// Combines two type-erased values of this key.
    static func reduceErased(_ accumulated: Any, _ next: Any) -> Any {
        guard var value = accumulated as? Value, let nextValue = next as? Value else {
            return next
        }
        reduce(value: &value, nextValue: { nextValue })
        return value
    }
}

/// The values of app-defined ``PreferenceKey``s produced by a view and its
/// descendants.
///
/// `@unchecked Sendable` because preference values are produced and read on
/// the main actor alone, during layout; ``PreferenceValues`` is only
/// `Sendable` so that it can be captured by main-actor closures.
struct CustomPreferenceValues: @unchecked Sendable {
    struct Entry {
        var key: any PreferenceKey.Type
        var value: Any
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    var isEmpty: Bool { entries.isEmpty }

    /// Gets or sets the value of the given key, if any view has set it.
    subscript<K: PreferenceKey>(key: K.Type) -> K.Value? {
        get { entries[ObjectIdentifier(key)]?.value as? K.Value }
        set {
            if let newValue {
                entries[ObjectIdentifier(key)] = Entry(key: key, value: newValue)
            } else {
                entries[ObjectIdentifier(key)] = nil
            }
        }
    }

    /// Combines another view's values into these with each key's
    /// ``PreferenceKey/reduce(value:nextValue:)``, these values first.
    mutating func merge(_ other: CustomPreferenceValues) {
        if entries.isEmpty {
            entries = other.entries
            return
        }
        for (id, entry) in other.entries {
            if let existing = entries[id] {
                entries[id] = Entry(
                    key: entry.key,
                    value: entry.key.reduceErased(existing.value, entry.value)
                )
            } else {
                entries[id] = entry
            }
        }
    }
}

extension View {
    /// Sets a value for the given preference.
    ///
    /// The value replaces whatever the view's own descendants produced for
    /// the key, and is combined with its siblings' values by the key's
    /// ``PreferenceKey/reduce(value:nextValue:)``.
    ///
    /// - Parameters:
    ///   - key: The preference to set.
    ///   - value: The value to set it to.
    /// - Returns: A view that sets the preference.
    public func preference<K: PreferenceKey>(key: K.Type = K.self, value: K.Value) -> some View {
        PreferenceModifier(self) { preferences, _ in
            var preferences = preferences
            preferences.custom[key] = value
            return preferences
        }
    }

    /// Applies a transformation to a preference value produced by this
    /// view's descendants.
    ///
    /// - Parameters:
    ///   - key: The preference to transform.
    ///   - callback: Modifies the value, which starts as the descendants'
    ///     combined value or the key's default.
    /// - Returns: A view that transforms the preference.
    public func transformPreference<K: PreferenceKey>(
        _ key: K.Type = K.self,
        _ callback: @escaping (inout K.Value) -> Void
    ) -> some View {
        PreferenceModifier(self) { preferences, _ in
            var preferences = preferences
            var value = preferences.custom[key] ?? K.defaultValue
            callback(&value)
            preferences.custom[key] = value
            return preferences
        }
    }

    /// Adds an action to perform when the specified preference key's value
    /// changes.
    ///
    /// The action runs once the view's layout has been committed: first
    /// with the initial value, then whenever the combined value produced by
    /// the view's descendants (or the key's default, when none sets it)
    /// differs from the last one seen.
    ///
    /// - Parameters:
    ///   - key: The preference to watch.
    ///   - action: The action to perform, given the new value.
    /// - Returns: A view that watches the preference.
    public func onPreferenceChange<K: PreferenceKey>(
        _ key: K.Type = K.self,
        perform action: @escaping (K.Value) -> Void
    ) -> some View where K.Value: Equatable {
        OnPreferenceChangeModifier<K, Self>(body: TupleView1(self), action: action)
    }
}

/// Runs an action when a preference produced by its content changes.
struct OnPreferenceChangeModifier<K: PreferenceKey, Child: View>: View
where K.Value: Equatable {
    /// Reference storage for the last value seen, which must not schedule
    /// an update of its own when recorded (see `OnChangeModifier`).
    struct PreviousValue {
        var box = Box<K.Value?>(nil)
    }

    @State private var previousValue = PreviousValue()

    var body: TupleView1<Child>
    var action: (K.Value) -> Void

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        defaultCommit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )

        let value = layout.preferences.custom[K.self] ?? K.defaultValue
        let box = previousValue.box
        if box.value != value {
            box.value = value
            action(value)
        }
    }
}
