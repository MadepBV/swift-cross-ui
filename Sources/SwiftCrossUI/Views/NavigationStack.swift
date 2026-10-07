/// Type to indicate the root of the NavigationStack. This is internal to prevent root accidentally showing instead
/// of a detail view.
struct NavigationStackRootPath: Codable {}

/// A view that displays a root view and enables you to present additional views
/// over the root view.
///
/// A stack can drive its navigation from a ``NavigationPath`` that you own:
///
/// ```swift
/// NavigationStack(path: $path) {
///     NavigationLink("Science", value: SubjectArea.science, path: $path)
/// }
/// .navigationDestination(for: SubjectArea.self) { area in
///     SubjectAreaView(area)
/// }
/// ```
///
/// ...or manage its own, which is what the path-less initializer is for. A
/// stack that owns its path is navigated with the closure form of
/// ``NavigationLink``, which pushes a view rather than a value:
///
/// ```swift
/// NavigationStack {
///     Form {
///         NavigationLink {
///             DrawingStyleSettingsView(model: model)
///         } label: {
///             Text("Drawing style")
///         }
///     }
/// }
/// ```
///
/// Destinations can be declared either way: with
/// ``navigationDestination(for:destination:)`` on the stack itself, or, as in
/// SwiftUI, with ``View/navigationDestination(for:destination:)-(_,_)`` on a
/// view inside it. A destination declared inside the stack is remembered for
/// as long as the stack exists, so it keeps resolving after the view that
/// declared it has been navigated away from.
///
/// A path can also be a plain collection of `Hashable` values, as in SwiftUI:
///
/// ```swift
/// @State private var path: [Destination] = []
///
/// NavigationStack(path: $path) {
///     HomeView()
///         .navigationDestination(for: Destination.self) { destination in
///             DestinationView(destination)
///         }
/// }
/// ```
///
/// The stack draws a navigation bar above its content (see
/// ``View/navigationTitle(_:)-(String)``, ``View/toolbar(content:)`` and
/// ``View/searchable(text:placement:prompt:)-(_,_,String)``). While there's
/// anything to return to — a closure-pushed destination or a non-empty path —
/// the bar starts with a Back button, which pops the top view. The bar takes
/// no room when it has nothing to show.
public struct NavigationStack<Detail: View>: View {
    /// The navigation path supplied by the surrounding view, if any.
    var externalPath: Binding<NavigationPath>?

    /// A typed navigation path supplied by the surrounding view, if any: a
    /// collection of `Hashable` values (see ``init(path:_:)-(Binding<Data>,_)``).
    var typedPath: NavigationStackPath?

    /// The navigation path used when the stack manages its own navigation state
    /// (i.e. when no path was supplied at initialization).
    @State private var internalPath = NavigationPath()

    /// The destinations pushed by closure-form ``NavigationLink``s, innermost
    /// last.
    ///
    /// These are kept separately from ``path`` because a view isn't `Codable`
    /// and therefore can't live in a ``NavigationPath``. They sit on top of the
    /// path: while there's a view destination, it's what the stack displays.
    @State private var viewDestinations: [AnyView] = []

    /// What the stack's pages ask its bar to show.
    @State private var chrome = NavigationChromeStorage()

    /// The destinations declared inside the stack.
    @State private var registeredDestinations = NavigationDestinationStorage()

    /// A binding to the current navigation path.
    ///
    /// This is the path supplied at initialization if there was one, and a
    /// binding to the stack's own state otherwise.
    var path: Binding<NavigationPath> {
        externalPath ?? $internalPath
    }

    /// The types handled by each destination (in the same order as their
    /// corresponding views in the stack).
    var destinationTypes: [any Codable.Type]
    /// Gets a recursive ``EitherView`` structure which will have a single view
    /// visible suitable for displaying the given path element (based on its
    /// type).
    ///
    /// It's implemented as a recursive structure because that's the best way to keep this
    /// typesafe without introducing some crazy generated pseudo-variadic storage types of
    /// some sort. This way we can easily have unlimited navigation destinations and there's
    /// just a single simple method for adding a navigation destination.
    var child: (Any) -> Detail?

    /// The stack's path, whichever kind it is.
    var resolvedPath: NavigationStackPath {
        typedPath ?? NavigationStackPath(path, destinationTypes: destinationTypes)
    }

    /// The elements of the navigation path. The result can depend on
    /// ``NavigationStack/destinationTypes`` which determines how the keys are
    /// decoded if they haven't yet been decoded (this happens if they're loaded
    /// from disk for persistence).
    var elements: [Any] {
        [NavigationStackRootPath()] + resolvedPath.elements()
    }

    public var body: some View {
        // Resolved once so that the environment values capture just the
        // bindings rather than the whole stack.
        let destinations = $viewDestinations
        let path = resolvedPath
        let elements = self.elements
        let child = self.child

        NavigationChromeHost(
            chrome: chrome.ownChrome,
            back: backAction,
            content: NavigationStackPage(
                registry: registeredDestinations.registry,
                viewDestinations: viewDestinations,
                elements: elements,
                root: { child(NavigationStackRootPath()).map { AnyView($0) } },
                builtIn: { element in child(element).map { AnyView($0) } }
            )
        )
            .environment(\.navigationDestinations, registeredDestinations.registry)
            .environment(
                \.pushNavigationDestination,
                NavigationDestinationPusher { destination in
                    destinations.wrappedValue.append(destination)
                }
            )
            .environment(
                \.appendToNavigationPath,
                NavigationPathAppender { value in
                    path.append(value)
                }
            )
    }

    /// Pops the top view: the last closure-pushed destination if there is
    /// one, and the last path element otherwise; `nil` when the stack shows
    /// its root.
    private var backAction: (@MainActor () -> Void)? {
        let destinations = $viewDestinations
        let path = resolvedPath
        if !viewDestinations.isEmpty {
            return { destinations.wrappedValue.removeLast() }
        } else if !path.isEmpty() {
            return { path.removeLast() }
        } else {
            return nil
        }
    }

    /// Creates a navigation stack with heterogeneous navigation state that you
    /// can control.
    ///
    /// - Parameters:
    ///   - path: A ``Binding`` to the navigation state for this stack.
    ///   - root: The view to display when the stack is empty.
    public init(
        path: Binding<NavigationPath>,
        @ViewBuilder _ root: @escaping () -> Detail
    ) {
        self.init(externalPath: path, typedPath: nil, root: root)
    }

    /// Creates a navigation stack with homogeneous navigation state that you
    /// can control: a collection of `Hashable` values, SwiftUI's spelling.
    ///
    /// Declare the values' destination with
    /// ``View/navigationDestination(for:destination:)-(_,_)`` inside the stack.
    /// A ``NavigationLink`` whose value isn't of the collection's element type
    /// does nothing.
    ///
    /// - Parameters:
    ///   - path: A ``Binding`` to the navigation state for this stack.
    ///   - root: The view to display when the stack is empty.
    public init<Data>(
        path: Binding<Data>,
        @ViewBuilder _ root: @escaping () -> Detail
    )
    where
        Data: MutableCollection & RandomAccessCollection & RangeReplaceableCollection,
        Data.Element: Hashable
    {
        self.init(externalPath: nil, typedPath: NavigationStackPath(path), root: root)
    }

    /// Creates a navigation stack that manages its own navigation state.
    ///
    /// Navigate such a stack with the closure form of ``NavigationLink``, which
    /// pushes a view onto the stack rather than a value onto a path.
    ///
    /// - Parameter root: The view to display when the stack is empty.
    public init(@ViewBuilder _ root: @escaping () -> Detail) {
        self.init(externalPath: nil, typedPath: nil, root: root)
    }

    /// Creates a navigation stack, with or without an externally managed path.
    ///
    /// All public initializers funnel through this one.
    ///
    /// - Parameters:
    ///   - externalPath: A binding to the navigation state for this stack, or
    ///     `nil` to let the stack manage its own.
    ///   - typedPath: A typed path for this stack, if it has one instead.
    ///   - root: The view to display when the stack is empty.
    private init(
        externalPath: Binding<NavigationPath>?,
        typedPath: NavigationStackPath?,
        root: @escaping () -> Detail
    ) {
        self.externalPath = externalPath
        self.typedPath = typedPath
        destinationTypes = []
        child = { element in
            if element is NavigationStackRootPath {
                return root()
            } else {
                return nil
            }
        }
    }

    /// Associates a destination view with a presented data type for use within
    /// a navigation stack.
    ///
    /// Add this view modifer to describe the view that the stack displays when
    /// presenting a particular kind of data. Use a ``NavigationLink`` to
    /// present the data. You can add more than one navigation destination
    /// modifier to the stack if it needs to present more than one kind of data.
    ///
    /// - Parameters:
    ///   - data: The type of data that this destination matches.
    ///   - destination: A view builder that defines a view to display when the
    ///     stack's navigation state contains a value of type data. The closure
    ///     takes one argument, which is the value of the data to present.
    public func navigationDestination<D: Codable, C: View>(
        for data: D.Type,
        @ViewBuilder destination: @escaping (D) -> C
    ) -> NavigationStack<EitherView<Detail, C>> {
        // Adds another detail view by adding to the recursive structure of either views created
        // to display details in a type-safe manner. See NavigationStack.child for details.
        return NavigationStack<EitherView<Detail, C>>(
            previous: self,
            destination: destination
        )
    }

    /// Add a destination for a specific path element (by adding another layer of ``EitherView``).
    private init<PreviousDetail: View, NewDetail: View, Component: Codable>(
        previous: NavigationStack<PreviousDetail>,
        destination: @escaping (Component) -> NewDetail?
    ) where Detail == EitherView<PreviousDetail, NewDetail> {
        externalPath = previous.externalPath
        typedPath = previous.typedPath
        destinationTypes = previous.destinationTypes + [Component.self]
        child = { element in
            if let previous = previous.child(element) {
                // Either root or previously defined destination returned a view
                return EitherView(previous)
            } else if let component = element as? Component,
                      let new = destination(component)
            {
                // This destination returned a detail view for the current element
                return EitherView(new)
            } else {
                // Possibly a future .navigationDestination will handle this path element
                return nil
            }
        }
    }
}

/// Pushes a view onto the ``NavigationStack`` that published it.
///
/// A closure-form ``NavigationLink`` has no navigation path to append to, so it
/// finds the stack to navigate through the environment instead. This wraps the
/// closure that does the pushing in a type of its own so that the environment
/// value is `Sendable`; a bare closure isn't.
@MainActor
struct NavigationDestinationPusher {
    /// Appends a destination to the stack's view destinations.
    var push: (AnyView) -> Void

    /// Pushes a destination onto the stack.
    ///
    /// - Parameter destination: The view to display on top of the stack.
    func callAsFunction(_ destination: AnyView) {
        push(destination)
    }
}

/// Appends a value to the path of the ``NavigationStack`` that published it.
///
/// This is how a ``NavigationLink`` written without a `path:` argument finds
/// the path to append to — SwiftUI's spelling, where the stack and the link
/// agree through the view hierarchy rather than through a binding that the
/// author threads between them. Wrapped in a type of its own for the same
/// reason ``NavigationDestinationPusher`` is: the environment's values have to
/// be `Sendable`, and a bare closure isn't.
@MainActor
struct NavigationPathAppender {
    /// Appends a value to the stack's path.
    var appendValue: (Any) -> Void

    /// Appends a value to the stack's path.
    ///
    /// - Parameter value: The value to append.
    func callAsFunction(_ value: Any) {
        appendValue(value)
    }
}

extension EnvironmentValues {
    /// Pushes a view onto the innermost enclosing ``NavigationStack``.
    ///
    /// `nil` when there's no enclosing stack, in which case a closure-form
    /// ``NavigationLink`` has nowhere to navigate to and says so.
    @Entry var pushNavigationDestination: NavigationDestinationPusher? = nil

    /// Appends a value to the path of the innermost enclosing
    /// ``NavigationStack``.
    ///
    /// `nil` when there's no enclosing stack, in which case a path-less
    /// value-form ``NavigationLink`` has nowhere to navigate to and says so.
    @Entry var appendToNavigationPath: NavigationPathAppender? = nil
}
