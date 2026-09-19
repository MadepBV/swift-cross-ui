/// A key for a value published by the focused scene.
///
/// Focused values answer the app-level question "what does the focused window
/// own?", which is how a document app drives its menu bar and inspector
/// without every command having to reach into every window.
///
/// Declare a key, expose it as a property on ``FocusedValues``, publish it
/// from a scene with ``View/focusedSceneValue(_:_:)``, and read it anywhere
/// with ``FocusedValue``:
///
/// ```swift
/// struct SelectedBarKey: FocusedValueKey {
///     typealias Value = Bar
/// }
///
/// extension FocusedValues {
///     var selectedBar: Bar? {
///         get { self[SelectedBarKey.self] }
///         set { self[SelectedBarKey.self] = newValue }
///     }
/// }
/// ```
public protocol FocusedValueKey {
    /// The type of value published under this key.
    associatedtype Value
}

/// The collection of values published by the focused scene.
///
/// Extend this type with a computed property per ``FocusedValueKey`` so that
/// values can be published and read through key paths; see
/// ``FocusedValueKey`` for an example.
public struct FocusedValues {
    /// The published values, keyed by the metatype of their
    /// ``FocusedValueKey``.
    private var storage: [ObjectIdentifier: Any]

    /// Creates an empty set of focused values.
    public init() {
        storage = [:]
    }

    /// Accesses the value published under a given key.
    ///
    /// - Parameter key: The type of the key.
    /// - Returns: The published value, or `nil` if no focused scene publishes
    ///   one.
    public subscript<Key: FocusedValueKey>(key: Key.Type) -> Key.Value? {
        get {
            storage[ObjectIdentifier(Key.self)] as? Key.Value
        }
        set {
            storage[ObjectIdentifier(Key.self)] = newValue
        }
    }
}

/// The app-wide store backing ``FocusedValues``.
///
/// SwiftCrossUI resolves focused values at *scene* granularity: the modifiers
/// in ``View/focusedSceneValue(_:_:)`` only publish while their scene's
/// ``EnvironmentValues/scenePhase`` is ``ScenePhase/active``, so in a
/// multi-window app the frontmost window is the one whose values win. When
/// that window goes inactive another active scene takes over on its next
/// update.
///
/// - Note: The store is only ever touched from the main thread, during view
///   graph updates.
final class FocusedValuesStore {
    /// The shared store.
    nonisolated(unsafe) static let shared = FocusedValuesStore()

    /// Published whenever a focused value actually changes.
    let didChange = Publisher()

    /// The currently published values.
    private(set) var values = FocusedValues()

    private init() {}

    /// The publisher that last published each key path, and whether the value
    /// it published could be compared with its successor.
    ///
    /// Used to break the republish loop described on ``publish(_:for:from:)``.
    private var lastPublishers: [PartialKeyPath<FocusedValues>: ObjectIdentifier] = [:]

    /// Key paths that have already warned about an incomparable value, so that
    /// the warning is logged once rather than once per commit.
    private var warnedKeyPaths: Set<PartialKeyPath<FocusedValues>> = []

    /// Publishes a value for a key path, notifying observers if it changed.
    ///
    /// Values that compare equal are dropped so that a view which both
    /// publishes and reads a focused value can't drive an endless update loop.
    /// Equality is established by `Equatable` where the value has it, and by
    /// reference identity where the value is an object.
    ///
    /// ## Values that can't be compared
    ///
    /// A value that is neither `Equatable` nor an object — a struct of
    /// closures, say — can't be told apart from the one published a moment
    /// ago. Treating it as changed every time is what makes the loop: the
    /// modifier publishes on every commit, publishing notifies observers, an
    /// observer re-resolves the scene, re-resolving commits the window, and
    /// the window's commit publishes again.
    ///
    /// So an incomparable value republished by the *same* publisher is stored
    /// but doesn't notify. Anyone reading it still sees the newest value; they
    /// just aren't woken by a change nobody can detect. A different publisher
    /// taking over the key path, or a value that can be compared, notifies as
    /// usual. Making the value `Equatable` restores change notifications, and
    /// the first incomparable publish logs a warning saying so.
    ///
    /// - Parameters:
    ///   - value: The new value, or `nil` to withdraw the current one.
    ///   - keyPath: A key path to the ``FocusedValues`` property to publish
    ///     under.
    ///   - publisher: The object identifying the view that is publishing,
    ///     if known. Views publishing an incomparable value must pass one to
    ///     get the loop-breaking behaviour.
    func publish<T>(
        _ value: T?,
        for keyPath: WritableKeyPath<FocusedValues, T?>,
        from publisher: AnyObject? = nil
    ) {
        let old = values[keyPath: keyPath]
        guard !areEquivalent(old, value) else {
            return
        }

        let publisherIdentity = publisher.map(ObjectIdentifier.init)
        let isRepublishByTheSamePublisher =
            publisherIdentity != nil
                && lastPublishers[keyPath] == publisherIdentity
        let isIncomparable = value.map { !isComparable($0) } ?? false

        values[keyPath: keyPath] = value
        lastPublishers[keyPath] = publisherIdentity

        if isIncomparable {
            warnAboutIncomparableValue(of: T.self, for: keyPath)
            if isRepublishByTheSamePublisher {
                return
            }
        }

        didChange.send()
    }

    /// Logs, once per key path, that a focused value can't be compared.
    private func warnAboutIncomparableValue<T>(
        of type: T.Type,
        for keyPath: PartialKeyPath<FocusedValues>
    ) {
        guard warnedKeyPaths.insert(keyPath).inserted else {
            return
        }
        logger.warning(
            """
            focused value is neither Equatable nor an object, so changes to it             can't be detected; it will be published but won't notify readers a             second time. Conform it to Equatable to restore change             notifications
            """,
            metadata: ["type": "\(T.self)"]
        )
    }

    /// Reads the value currently published for a key path.
    ///
    /// - Parameter keyPath: A key path to the ``FocusedValues`` property.
    /// - Returns: The published value, if any.
    func value<T>(for keyPath: KeyPath<FocusedValues, T?>) -> T? {
        values[keyPath: keyPath]
    }
}

/// Compares two optional values of unknown conformance.
///
/// - Returns: `true` only when both values are absent, or both are present,
///   `Equatable`, and equal. Non-`Equatable` values are reported as different
///   so that publishing them always takes effect.
private func areEquivalent<T>(_ lhs: T?, _ rhs: T?) -> Bool {
    switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (.some(let lhs), .some(let rhs)):
            if let equatableLHS = lhs as? any Equatable {
                return areEqual(equatableLHS, rhs)
            }
            // Two references to one object are the same value whatever the
            // object's type has to say about equality, and publishing a model
            // object is the common case. Without this, publishing the same
            // object on every commit reports a change every time.
            if isClassInstance(lhs), isClassInstance(rhs) {
                return (lhs as AnyObject) === (rhs as AnyObject)
            }
            return false
        default:
            return false
    }
}

/// Whether a value's changes can be detected at all.
///
/// - Parameter value: The value to check.
/// - Returns: Whether the value is `Equatable` or an object.
private func isComparable(_ value: Any) -> Bool {
    value is any Equatable || isClassInstance(value)
}

/// Whether a value is an instance of a class.
///
/// Checks the value's type rather than casting it: `value as? AnyObject`
/// succeeds for a struct too on Darwin, by boxing it in a fresh object, which
/// would make every struct look like a distinct instance.
///
/// - Parameter value: The value to check.
/// - Returns: Whether `value` is a class instance.
private func isClassInstance(_ value: Any) -> Bool {
    type(of: value) is AnyClass
}

/// Compares an opened `Equatable` existential against an arbitrary value.
private func areEqual<T: Equatable>(_ lhs: T, _ rhs: Any) -> Bool {
    guard let rhs = rhs as? T else {
        return false
    }
    return lhs == rhs
}

/// A property wrapper that reads a value published by the focused scene.
///
/// ```swift
/// struct BarCommands: View {
///     @FocusedValue(\.selectedBar) private var selectedBar
///
///     var body: some View {
///         Button("Mirror bar") { selectedBar?.mirror() }
///             .disabled(selectedBar == nil)
///     }
/// }
/// ```
///
/// The value is `nil` when no focused scene publishes one, which is the usual
/// way to disable a command that has nothing to act on.
@propertyWrapper
public struct FocusedValue<Value>: ObservableProperty {
    /// A key path to the published value.
    private let keyPath: KeyPath<FocusedValues, Value?>
    /// The value as of the last update.
    private let box: Box<Value?>

    public var didChange: Publisher { FocusedValuesStore.shared.didChange }

    /// The value published by the focused scene, if any.
    public var wrappedValue: Value? { box.value }

    /// Creates a property that reads a focused value.
    ///
    /// - Parameter keyPath: A key path to the ``FocusedValues`` property to
    ///   read.
    public init(_ keyPath: KeyPath<FocusedValues, Value?>) {
        self.keyPath = keyPath
        self.box = Box(FocusedValuesStore.shared.value(for: keyPath))
    }

    public func update(
        with environment: EnvironmentValues,
        previousValue: FocusedValue<Value>?
    ) {
        box.value = FocusedValuesStore.shared.value(for: keyPath)
    }
}
