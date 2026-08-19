/// A property wrapper used to access environment values within a ``View`` or
/// ``App``.
///
/// Must not be used before the view graph accesses the view or app's `body`
/// (so, don't access it from an initializer).
///
/// ```swift
/// struct ContentView: View {
///     @Environment(\.colorScheme) var colorScheme
///
///     var body: some View {
///         Text("Current color scheme: \(colorScheme)")
///             .background(colorScheme == .light ? Color.black : Color.white)
///     }
/// }
/// ```
///
/// The environment also contains UI-related actions, such as the
/// ``EnvironmentValues/chooseFile`` action used to present 'Open file' dialogs.
///
/// ```swift
/// struct ContentView: View {
///     @Environment(\.chooseFile) var chooseFile
///
///     var body: some View {
///         Button("Open") {
///             Task {
///                 guard let file = await chooseFile() else {
///                     print("No file chosen")
///                     return
///                 }
///
///                 print("The user chose: \(file.path)")
///             }
///         }
///     }
/// }
/// ```
@propertyWrapper
public struct Environment<Value>: DynamicProperty {
    private var mode: Mode
    /// The underlying value.
    ///
    /// `nil` if ``update(with:previousValue:)`` has not yet been called.
    private var value: Box<Value?>

    public func update(
        with environment: EnvironmentValues,
        previousValue: Self?
    ) {
        switch mode {
            case .keyPath(let keyPath):
                value.value = environment[keyPath: keyPath]
            case .observableObject:
                value.value =
                    environment.observableObject(ofType: Value.self) as? Value
        }
    }

    /// The environment value that this property refers to.
    public var wrappedValue: Value {
        guard let value = value.value else {
            fatalError(mode.missingValueMessage)
        }
        return value
    }

    /// Initializes an ``Environment`` property wrapper.
    ///
    /// - Parameter keyPath: A key path to the enviornment value to access.
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.value = Box(nil)
        self.mode = .keyPath(keyPath)
    }

    /// Initializes an ``Environment`` property wrapper that reads an object
    /// placed in the environment by ``View/environment(_:)``.
    ///
    /// ```swift
    /// @Observable
    /// final class Preferences {
    ///     var language = "en"
    /// }
    ///
    /// struct ContentView: View {
    ///     @Environment(Preferences.self) private var preferences
    ///
    ///     var body: some View {
    ///         Text(preferences.language)
    ///     }
    /// }
    /// ```
    ///
    /// The object can be a class declared with the standard library's
    /// `@Observable` macro, a ``ObservableObject``, or a plain class. Only the
    /// first two invalidate the views that read them:
    ///
    /// - An `@Observable` object invalidates whichever views read the mutated
    ///   property, because a view's body is evaluated under
    ///   ``ViewObservationTracking`` and this property wrapper hands back the
    ///   object itself, so reads through it are tracked like any other.
    /// - An ``ObservableObject`` publishes through
    ///   ``ObservableObject/didChange``, which the view that owns it (via
    ///   ``State``) subscribes to. ``View/environment(_:)`` performs no
    ///   observation of its own, so an ``ObservableObject`` must still be
    ///   owned by some ancestor.
    ///
    /// - Parameter type: The type of the object to read from the environment.
    ///   Objects are keyed by their exact type.
    public init(_ type: Value.Type) where Value: AnyObject {
        self.value = Box(nil)
        self.mode = .observableObject
    }

    private enum Mode {
        /// A key path to the enviornment value to access.
        case keyPath(KeyPath<EnvironmentValues, Value>)
        /// An observable object.
        case observableObject

        var pathDescription: String {
            switch self {
                case .keyPath(let keyPath):
                    "\(keyPath)"
                case .observableObject:
                    "\(Value.self).self"
            }
        }

        /// The message to trap with when the property is read but has no
        /// value.
        ///
        /// A key path always resolves to something, so the only way to get
        /// here is to read the property too early. An object has to have been
        /// put in the environment first, which is much easier to forget, so
        /// that case names the modifier that puts it there.
        var missingValueMessage: String {
            switch self {
                case .keyPath:
                    """
                    Environment value at \(pathDescription) used before \
                    initialization. Don't use @Environment properties before \
                    SwiftCrossUI requests the view's body.
                    """
                case .observableObject:
                    """
                    No \(Value.self) found in the environment. Put one there \
                    with .environment(_:) on an ancestor view, and don't read \
                    an @Environment property before SwiftCrossUI requests the \
                    view's body.
                    """
            }
        }
    }
}

extension View {
    /// Adds an object to the environment of the enclosed view, to be read back
    /// with ``Environment/init(_:)``.
    ///
    /// ```swift
    /// ContentView()
    ///     .environment(preferences)
    /// ```
    ///
    /// This is the general form of the `environment(_:)` overload that only
    /// accepts an ``ObservableObject``. It accepts any class, so a model
    /// declared with the standard library's `@Observable` macro can be placed
    /// in the environment too. Swift picks the more specialised
    /// ``ObservableObject`` overload whenever it applies, so existing code
    /// keeps resolving exactly as it did.
    ///
    /// - Important: This modifier performs no observation of its own. An
    ///   `@Observable` object needs none — the views that read its properties
    ///   track those reads themselves — but an ``ObservableObject`` must be
    ///   owned by an ancestor view (typically through ``State``) for its
    ///   changes to redraw anything.
    ///
    /// - Parameter object: The object to add to the environment. It's keyed by
    ///   its exact type, so reading it back requires naming that same type.
    /// - Returns: A view with `object` in its environment.
    public func environment<T: AnyObject>(_ object: T) -> some View {
        EnvironmentModifier(self) { environment in
            var environment = environment
            environment[observable: T.self] = object
            return environment
        }
    }
}
