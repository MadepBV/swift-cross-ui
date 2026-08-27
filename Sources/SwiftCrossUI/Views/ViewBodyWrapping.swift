/// Decides, once per view type, whether a body has to be wrapped in a
/// ``TupleView1``.
///
/// See ``View/bodyNeedsWrapping``. The answer is a property of the body's type,
/// and a protocol conformance check goes through the runtime's conformance
/// cache every time, so it is memoised: the default implementations ask on
/// every layout computation and every commit of every composite view.
@MainActor
enum ViewBodyWrapping {
    private static var cache: [ObjectIdentifier: Bool] = [:]

    /// Whether a body of the given type needs wrapping.
    ///
    /// - Parameter type: The body's type.
    /// - Returns: Whether it needs wrapping.
    static func isNeeded(for type: any View.Type) -> Bool {
        let key = ObjectIdentifier(type)
        if let cached = cache[key] {
            return cached
        }
        // An empty body has nothing to lay out and no widgets to contribute,
        // which is exactly what the unwrapped path already does for it.
        // Wrapping it would give every elementary view — `Text`, `TextField`
        // and friends, whose `Content` is `EmptyView` — a spurious child node.
        let isNeeded = !(type is any TupleView.Type) && type != EmptyView.self
        cache[key] = isNeeded
        return isNeeded
    }
}
