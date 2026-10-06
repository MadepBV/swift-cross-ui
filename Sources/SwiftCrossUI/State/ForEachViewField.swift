/// Calls the given closure on every field of a view, including the fields of
/// any ``ViewModifier`` stored inline in it.
///
/// A ``ModifiedContent`` stores its modifier as a plain field, so the
/// modifier's own dynamic properties (`@State`, `@Environment` and friends)
/// sit inside the view's memory at the modifier's offset plus their own. This
/// walks into such fields so that the view graph updates and observes them
/// exactly as it would a view's own properties, which is what makes a
/// modifier's state behave as it does in SwiftUI.
///
/// Only value-type modifiers are walked into: a class instance isn't stored
/// inline, so its fields have no offset within the view.
///
/// - Parameters:
///   - value: The view (or other value) to inspect.
///   - body: Called with the name of each field, its offset from the start of
///     `value`, and its value.
func forEachViewField<Value>(
    of value: Value,
    body: (_ name: String?, _ offset: Int, _ fieldValue: Any) -> Void
) {
    forEachViewField(of: value, baseOffset: 0, body: body)
}

private func forEachViewField<Value>(
    of value: Value,
    baseOffset: Int,
    body: (_ name: String?, _ offset: Int, _ fieldValue: Any) -> Void
) {
    forEachField(of: value) { name, offset, fieldValue in
        if fieldValue is any DynamicProperty {
            body(name, baseOffset + offset, fieldValue)
        } else if let modifier = fieldValue as? any ViewModifier,
            !(type(of: modifier) is AnyClass)
        {
            visitModifier(modifier, baseOffset: baseOffset + offset, body: body)
        } else {
            body(name, baseOffset + offset, fieldValue)
        }
    }
}

private func visitModifier<Modifier: ViewModifier>(
    _ modifier: Modifier,
    baseOffset: Int,
    body: (_ name: String?, _ offset: Int, _ fieldValue: Any) -> Void
) {
    forEachViewField(of: modifier, baseOffset: baseOffset, body: body)
}
