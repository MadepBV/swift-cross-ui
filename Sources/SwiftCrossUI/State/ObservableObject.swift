/// An object that can be observed for changes.
///
/// The default implementation only publishes changes made to properties that
/// have been wrapped with the ``Published`` property wrapper. Even properties
/// that themselves conform to ``ObservableObject`` must be wrapped with the
/// ``Published`` property wrapper for clarity.
///
/// ```swift
/// class NestedState: ObservableObject {
///     // Both `startIndex` and `endIndex` will have their changes published to `NestedState`'s
///     // `didChange` publisher.
///     @Published
///     var startIndex = 0
///
///     @Published
///     var endIndex = 0
/// }
///
/// class CounterState: ObservableObject {
///     // Only changes to `count` will be published (it is the only property with `@Published`)
///     @Published
///     var count = 0
///
///     var otherCount = 0
///
///     // Even though `nested` is `ObservableObject`, its changes won't be
///     // published because if you could have observed properties without
///     // `@Published` things would get pretty messy and you'd always have to
///     // check the definition of the type of each property to know exactly
///     // what would and wouldn't cause updates.
///     var nested = NestedState()
/// }
/// ```
///
/// To use an observable object as part of a view's state, use the ``State`` property
/// wrapper. It'll detect that it's been given an observable and will forward any
/// observations published by the object's ``ObservableObject/didChange`` publisher.
///
/// ```swift
/// class CounterState: ObservableObject {
///     @Published var count = 0
/// }
///
/// struct CounterView: View {
///     @State var state = CounterState()
///
///     var body: some View {
///         HStack {
///             Button("-") {
///                 state.count -= 1
///             }
///             Text("Count: \(state.count)")
///             Button("+") {
///                 state.count += 1
///             }
///         }
///     }
/// }
/// ```
public protocol ObservableObject: AnyObject {
    /// A publisher which publishes changes made to the object. Only publishes changes made to
    /// ``Published`` properties by default.
    var didChange: Publisher { get }
}

extension ObservableObject {
    public var didChange: Publisher {
        let publisher = Publisher()
            .tag(with: String(describing: type(of: self)))

        var mirror: Mirror? = Mirror(reflecting: self)
        while let aClass = mirror {
            for (_, property) in aClass.children {
                guard
                    property is PublishedMarkerProtocol,
                    let property = property as? ObservableObject
                else {
                    continue
                }

                let cancellable = publisher.link(toUpstream: property.didChange)
                cancellable.defuse()
            }
            mirror = aClass.superclassMirror
        }
        return publisher
    }
}

protocol OptionalObservableObject {
    var didChange: Publisher? { get }
}

extension Optional: OptionalObservableObject where Wrapped: ObservableObject {
    var didChange: SwiftCrossUI.Publisher? {
        switch self {
            case .some(let object):
                object.didChange
            case .none:
                nil
        }
    }
}

@available(*, deprecated, message: "Replace Observable with ObservableObject")
public typealias Observable = ObservableObject

/// Automatically observes all public noncomputed variables with public getter and setter
@attached(memberAttribute)
@attached(extension, conformances: ObservableObject)
public macro ObservableObject() =
    #externalMacro(
        module: "SwiftCrossUIMacrosPlugin",
        type: "ObservableObjectMacro"
    )

/// Applies to a member of an ``ObservableObject()`` class to opt the member
/// out of automatic publishing.
///
/// ``ObservableObject()`` wraps every eligible stored property of a class in
/// ``Published``. Mark a property with this macro to leave it alone, either
/// because its changes shouldn't redraw anything or because it's storage that
/// happens to be a `var` for reasons of its own.
///
/// ```swift
/// @ObservableObject
/// class CounterState {
///     // Wrapped in `@Published`, so changes redraw views that read it.
///     var count = 0
///
///     // Left alone, so changes redraw nothing.
///     @ObservableObjectIgnored
///     var lastInteraction = Date()
/// }
/// ```
///
/// The expansion is deliberately empty: the macro exists only as a marker
/// that ``ObservableObject()`` looks for while walking a class's members.
/// `names: named(willSet)` is what keeps the marked property stored — an
/// accessor macro that declares no names is assumed to turn the property into
/// a computed one, and the compiler then rejects the empty expansion with
/// "did not produce a non-observing accessor". Declaring an observing
/// accessor instead lets the property stay exactly as written, which is the
/// same trick `Observation`'s own opt-out macro uses.
///
/// - Note: This macro used to be spelled `ObservationIgnored`, which clashed
///   with the declaration of the same name in the standard library's
///   `Observation` module and made that module's `@Observable` macro
///   impossible to expand in any file that imported both. Use
///   `Observation`'s `@ObservationIgnored` for `@Observable` classes and this
///   macro for ``ObservableObject()`` classes.
@attached(accessor, names: named(willSet))
public macro ObservableObjectIgnored() =
    #externalMacro(
        module: "SwiftCrossUIMacrosPlugin",
        type: "ObservableObjectIgnoredMacro"
    )

/// The former spelling of ``ObservableObjectIgnored()``.
///
/// This declaration exists only so that code written against the old name
/// fails with "has been renamed to 'ObservableObjectIgnored'" and a fix-it,
/// rather than with a bare "cannot find 'ObservationIgnored' in scope".
///
/// - Important: It is `unavailable` rather than `deprecated` on purpose. A
///   deprecated declaration still takes part in name lookup, and having *any*
///   usable `ObservationIgnored` in this module is exactly what used to break
///   the standard library's `@Observable`: its expansion applies
///   `@ObservationIgnored` unqualified, and two visible candidates make that
///   expansion fail with "ambiguous use of 'ObservationIgnored()'" — an error
///   inside generated code that the user cannot qualify their way out of.
///   Unavailable declarations are dropped from that lookup, so this alias can
///   guide migration without resurrecting the clash. Working `@Observable`
///   matters more than a warning-only migration.
@available(*, unavailable, renamed: "ObservableObjectIgnored")
@attached(accessor, names: named(willSet))
public macro ObservationIgnored() =
    #externalMacro(
        module: "SwiftCrossUIMacrosPlugin",
        type: "ObservableObjectIgnoredMacro"
    )
