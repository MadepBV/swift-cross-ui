/// The scroll views inside one ``ScrollViewReader``.
@MainActor
final class ScrollViewReaderScope {
    /// A registry, held weakly so that a scroll view that goes away drops out.
    private struct WeakRegistry {
        weak var registry: ScrollTargetRegistry?
    }

    /// The scroll views' registries, in the order they first laid out.
    private var registries: [WeakRegistry] = []

    /// Creates an empty scope.
    init() {}

    /// Adds a scroll view's registry to the scope.
    ///
    /// Adding the same registry again does nothing.
    ///
    /// - Parameter registry: The registry.
    func add(_ registry: ScrollTargetRegistry) {
        registries.removeAll { $0.registry == nil }
        if !registries.contains(where: { $0.registry === registry }) {
            registries.append(WeakRegistry(registry: registry))
        }
    }

    /// Scrolls the first scroll view that holds a view with the given
    /// identity.
    ///
    /// - Parameters:
    ///   - id: The view's identity.
    ///   - anchor: The point of the view to line up with the same point of
    ///     the visible region, or `nil` to scroll as little as possible.
    func scrollTo(id: AnyHashable, anchor: UnitPoint?) {
        for entry in registries {
            if entry.registry?.scrollTo(id: id, anchor: anchor) == true {
                return
            }
        }
    }
}

/// Holds a ``ScrollViewReaderScope`` in `@State`, which only fully supports
/// observable classes, while keeping its identity.
@MainActor
struct ScrollViewReaderScopeStorage {
    /// The scope.
    let scope = ScrollViewReaderScope()
}

extension EnvironmentValues {
    /// The scope of the innermost enclosing ``ScrollViewReader``, which the
    /// scroll views inside join.
    @Entry var scrollViewReaderScope: ScrollViewReaderScope? = nil
}

/// Scrolls the scroll views inside a ``ScrollViewReader``.
///
/// Call ``scrollTo(_:anchor:)`` from an action or a task, never from a view's
/// body.
public struct ScrollViewProxy {
    /// The reader's scroll views.
    let scope: ScrollViewReaderScope

    /// Scrolls to the view with the given identity, in whichever of the
    /// reader's scroll views holds it.
    ///
    /// A view's identity is the value given to ``View/id(_:)`` or its element
    /// identifier in a ``ForEach``. An identity no scroll view holds does
    /// nothing, as does a backend that can't scroll programmatically (see
    /// ``BackendFeatures/ScrollOffsets``).
    ///
    /// - Parameters:
    ///   - id: The view's identity.
    ///   - anchor: The point of the view to line up with the same point of the
    ///     visible region, such as ``UnitPoint/top`` to bring the view to the
    ///     top. `nil` scrolls as little as it takes to show the view.
    @MainActor
    public func scrollTo<ID: Hashable>(_ id: ID, anchor: UnitPoint? = nil) {
        scope.scrollTo(id: AnyHashable(id), anchor: anchor)
    }
}

/// A view that lets its content scroll the scroll views inside it.
///
/// ```swift
/// ScrollViewReader { proxy in
///     ScrollView {
///         ForEach(messages) { message in
///             MessageRow(message)
///         }
///     }
///     .onChange(of: messages.count) {
///         proxy.scrollTo(messages.last?.id, anchor: .bottom)
///     }
/// }
/// ```
public struct ScrollViewReader<Content: View>: View {
    /// Builds the content.
    var content: (ScrollViewProxy) -> Content

    @State private var storage = ScrollViewReaderScopeStorage()

    /// Creates a reader.
    ///
    /// - Parameter content: The content, given a proxy that scrolls the
    ///   scroll views inside it.
    public init(@ViewBuilder content: @escaping (ScrollViewProxy) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(ScrollViewProxy(scope: storage.scope))
            .environment(\.scrollViewReaderScope, storage.scope)
    }
}
