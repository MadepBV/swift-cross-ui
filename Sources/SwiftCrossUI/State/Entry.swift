/// Creates an ``EnvironmentValues``, ``FocusedValues`` or ``AppStorageValues`` entry.
///
/// In ``FocusedValues`` the property must have an optional type and no
/// initial value, as in SwiftUI: `@Entry var selection: Item?`.
///
/// You can create ``EnvironmentValues`` entries by extending the ``EnvironmentValues`` struct with `@Entry`-annotated properties:
/// ```swift
/// extension EnvironmentValues {
///     @Entry var myCustomValue: String = "Default value"
///     @Entry var anotherCustomValue = true
/// }
/// ```
///
/// You can create ``AppStorageValues`` entries by extending the ``AppStorageValues`` struct with `@Entry`-annotated properties:
/// ```swift
/// extension AppStorageValues {
///     @Entry var myCustomValue: String = "Default value"
///     @Entry var anotherCustomValue = true
/// }
/// ```
@attached(accessor) @attached(peer, names: prefixed(__Key_))
public macro Entry() =
    #externalMacro(
        module: "SwiftCrossUIMacrosPlugin",
        type: "EntryMacro"
    )
