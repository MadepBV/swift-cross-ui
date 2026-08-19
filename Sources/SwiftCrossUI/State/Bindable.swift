/// A property wrapper that hands out ``Binding``s to the properties of an
/// observable reference type.
///
/// Use it when a view needs to write into an object it doesn't own, most
/// commonly one declared with the standard library's `@Observable` macro:
///
/// ```swift
/// @Observable
/// final class Settings {
///     var name = "Untitled"
///     var isEnabled = true
/// }
///
/// struct SettingsView: View {
///     @Bindable var settings: Settings
///
///     var body: some View {
///         VStack {
///             TextField("Name", text: $settings.name)
///             Toggle("Enabled", isOn: $settings.isEnabled)
///         }
///     }
/// }
/// ```
///
/// `$settings.name` projects a ``Binding`` straight into the object, so writes
/// go to the object itself rather than to a copy. Because the write happens
/// through the object's own setter, an `@Observable` object publishes it like
/// any other mutation and every view that read the property re-renders.
///
/// - Note: `Bindable` doesn't make an object observable, it only projects
///   bindings into one. Wrapping a plain class produces working bindings, but
///   writing through them won't invalidate any views, exactly as in SwiftUI.
///   Use `@Observable` (or ``ObservableObject`` with ``Published``) for the
///   object itself.
///
/// - Note: Unlike a ``State`` property, a `Bindable` property holds no state
///   of its own and doesn't persist across view updates. It's a lens onto an
///   object that lives somewhere else.
@dynamicMemberLookup
@propertyWrapper
public struct Bindable<Value> {
    /// The object being projected.
    public var wrappedValue: Value

    /// The bindable itself, so that `$object.property` reaches
    /// ``subscript(dynamicMember:)``.
    public var projectedValue: Bindable<Value> {
        self
    }

    /// Creates a bindable projection of an object.
    ///
    /// - Parameter wrappedValue: The object to project bindings into.
    public init(wrappedValue: Value) where Value: AnyObject {
        self.wrappedValue = wrappedValue
    }

    /// Creates a bindable projection of an object.
    ///
    /// - Parameter wrappedValue: The object to project bindings into.
    public init(_ wrappedValue: Value) where Value: AnyObject {
        self.wrappedValue = wrappedValue
    }

    /// Creates a bindable from another bindable's projected value.
    ///
    /// This exists so that a `Bindable` property can be initialised from
    /// `$someOtherBindable`.
    ///
    /// - Parameter projectedValue: The bindable to copy.
    public init(projectedValue: Bindable<Value>) where Value: AnyObject {
        self = projectedValue
    }

    /// Projects a binding to one of the object's properties.
    ///
    /// - Parameter keyPath: A key path to a mutable property of the object.
    /// - Returns: A binding that reads and writes the property in place.
    public subscript<Subject>(
        dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>
    ) -> Binding<Subject> where Value: AnyObject {
        let object = wrappedValue
        return Binding(
            get: { object[keyPath: keyPath] },
            set: { newValue in object[keyPath: keyPath] = newValue }
        )
    }
}

extension Bindable: Sendable where Value: Sendable {}
