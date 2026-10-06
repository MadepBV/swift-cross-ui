/// A ``NavigationStack``'s path, whichever kind it is: a ``NavigationPath``
/// or a typed collection of `Hashable` values.
@MainActor
struct NavigationStackPath {
    /// The path's elements, root excluded.
    let elements: () -> [Any]
    /// Whether the path is empty.
    let isEmpty: () -> Bool
    /// Appends a value, if the path can hold it.
    let appendValue: (Any) -> Void
    /// Removes the last element.
    let removeLast: () -> Void

    /// Appends a value, if the path can hold it.
    ///
    /// - Parameter value: The value.
    func append(_ value: Any) {
        appendValue(value)
    }

    /// Wraps a ``NavigationPath``.
    ///
    /// - Parameters:
    ///   - path: The path.
    ///   - destinationTypes: The types that encoded entries may decode to.
    init(_ path: Binding<NavigationPath>, destinationTypes: [any Codable.Type]) {
        elements = { path.wrappedValue.path(destinationTypes: destinationTypes) }
        isEmpty = { path.wrappedValue.isEmpty }
        appendValue = { value in path.wrappedValue.appendAny(value) }
        removeLast = { path.wrappedValue.removeLast() }
    }

    /// Wraps a typed collection of values.
    ///
    /// - Parameter path: The collection.
    init<Data>(_ path: Binding<Data>)
    where
        Data: MutableCollection & RandomAccessCollection & RangeReplaceableCollection,
        Data.Element: Hashable
    {
        elements = { path.wrappedValue.map { $0 as Any } }
        isEmpty = { path.wrappedValue.isEmpty }
        appendValue = { value in
            guard let element = value as? Data.Element else {
                logger.warning(
                    """
                    a 'NavigationLink' value of type \\(type(of: value)) can't go \\
                    in a navigation path of \\(Data.Element.self) values
                    """
                )
                return
            }
            path.wrappedValue.append(element)
        }
        removeLast = {
            guard !path.wrappedValue.isEmpty else {
                return
            }
            path.wrappedValue.removeLast()
        }
    }
}
