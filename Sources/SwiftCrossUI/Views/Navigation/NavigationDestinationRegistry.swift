/// The destinations declared inside a ``NavigationStack`` with
/// ``View/navigationDestination(for:destination:)-(_,_)``.
///
/// SwiftUI keeps a stack's root alive underneath the pages pushed onto it,
/// so the destinations its root declares stay declared. SwiftCrossUI only
/// keeps the top page, so the registry remembers each type's latest
/// destination for as long as the stack exists instead.
@MainActor
final class NavigationDestinationRegistry {
    /// Builds a destination for a path element, or returns `nil` if the
    /// element isn't of the destination's type.
    typealias Builder = @MainActor (Any) -> AnyView?

    /// Published when a type gets its first destination, which can make a
    /// page that had no destination resolvable.
    ///
    /// Read by ``NavigationChromeSubscription``-style subscriptions from
    /// outside the main actor; only ever sent from the main actor.
    nonisolated(unsafe) let didChange = Publisher()

    /// The latest destination of each type, keyed by the type.
    private var builders: [ObjectIdentifier: Builder] = [:]

    /// Creates an empty registry.
    init() {}

    /// Records the destination of a type, replacing any earlier one.
    ///
    /// - Parameters:
    ///   - type: The type of path element the destination presents.
    ///   - builder: Builds the destination.
    func register(_ type: Any.Type, builder: @escaping Builder) {
        let key = ObjectIdentifier(type)
        let isNew = builders[key] == nil
        builders[key] = builder
        if isNew {
            didChange.send()
        }
    }

    /// Builds the destination of a path element.
    ///
    /// - Parameter element: The element.
    /// - Returns: The destination, or `nil` if its type has none.
    func destination(for element: Any) -> AnyView? {
        builders[ObjectIdentifier(type(of: element))]?(element)
    }
}

/// Holds a ``NavigationDestinationRegistry`` in `@State`, which only fully
/// supports observable classes, while keeping its identity.
@MainActor
struct NavigationDestinationStorage {
    /// The registry.
    let registry = NavigationDestinationRegistry()
}

extension EnvironmentValues {
    /// The destination registry of the innermost enclosing
    /// ``NavigationStack``.
    @Entry var navigationDestinations: NavigationDestinationRegistry? = nil
}

extension View {
    /// Declares the view that the enclosing ``NavigationStack`` presents for
    /// path elements of a type, SwiftUI's spelling.
    ///
    /// Apply it to a view inside the stack, such as the stack's root. The
    /// destination stays declared for as long as the stack exists, even after
    /// the view that declared it has been navigated away from. Outside a
    /// stack it does nothing.
    ///
    /// - Parameters:
    ///   - data: The type of path element to present.
    ///   - destination: Builds the view for an element.
    /// - Returns: A view that declares the destination.
    public func navigationDestination<D: Hashable, C: View>(
        for data: D.Type,
        @ViewBuilder destination: @escaping (D) -> C
    ) -> some View {
        NavigationDestinationDeclaration(
            type: D.self,
            builder: { element in
                (element as? D).map { AnyView(destination($0)) }
            },
            content: self
        )
    }
}

/// Registers a destination with the enclosing stack whenever its body is
/// evaluated, so that the registry always holds the latest closure.
struct NavigationDestinationDeclaration<Content: View>: View {
    /// The type of path element the destination presents.
    var type: Any.Type
    /// Builds the destination.
    var builder: NavigationDestinationRegistry.Builder
    /// The modified view.
    var content: Content

    @Environment(\.navigationDestinations) private var registry

    var body: some View {
        let _ = registry?.register(type, builder: builder)
        content
    }
}

/// Subscribes a view to a ``NavigationDestinationRegistry``'s changes.
struct NavigationDestinationSubscription: ObservableProperty {
    let didChange: Publisher

    /// Subscribes to a registry.
    ///
    /// - Parameter registry: The registry to observe.
    @MainActor
    init(_ registry: NavigationDestinationRegistry) {
        didChange = registry.didChange
    }

    func update(with environment: EnvironmentValues, previousValue: Self?) {}
}

/// The page a ``NavigationStack`` shows: its top closure-pushed view, the
/// destination of its last path element, or its root.
///
/// A path element with no destination yet shows the root: the root is where
/// destinations are usually declared, and once it has declared one the
/// registry's change brings the element's page up. Each page is identified
/// by its depth and element, so pushing a page gives it fresh view state.
struct NavigationStackPage: View {
    /// The stack's declared destinations.
    var registry: NavigationDestinationRegistry
    /// The top closure-pushed view, if any.
    var viewDestination: AnyView?
    /// How many pages sit below this one.
    var depth: Int
    /// The last path element (the root marker for the root).
    var element: Any?
    /// Builds the root.
    var root: @MainActor () -> AnyView?
    /// Builds the destination of an element with the stack's own
    /// ``NavigationStack/navigationDestination(for:destination:)``s.
    var builtIn: @MainActor (Any) -> AnyView?

    /// Redraws the page when a destination is declared.
    private let subscription: NavigationDestinationSubscription

    init(
        registry: NavigationDestinationRegistry,
        viewDestination: AnyView?,
        depth: Int,
        element: Any?,
        root: @escaping @MainActor () -> AnyView?,
        builtIn: @escaping @MainActor (Any) -> AnyView?
    ) {
        self.registry = registry
        self.viewDestination = viewDestination
        self.depth = depth
        self.element = element
        self.root = root
        self.builtIn = builtIn
        subscription = NavigationDestinationSubscription(registry)
    }

    /// Identifies a page among the stack's pages.
    private struct PageIdentity: Hashable {
        var depth: Int
        var element: AnyHashable?
    }

    var body: some View {
        let page = resolvedPage
        page.view
            .id(PageIdentity(depth: page.depth, element: page.element))
    }

    /// The view to show, and what identifies it.
    private var resolvedPage: (view: AnyView, depth: Int, element: AnyHashable?) {
        if let viewDestination {
            return (viewDestination, depth, nil)
        }
        let identity = (element as? any Hashable).map { AnyHashable($0) }
        if let element, !(element is NavigationStackRootPath) {
            if let view = builtIn(element) ?? registry.destination(for: element) {
                return (view, depth, identity)
            }
        }
        return (root() ?? AnyView(EmptyView()), 0, nil)
    }
}
