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
/// Use ``navigationDestination(for:destination:)`` on this view instead of its
/// children, unlike Apple's SwiftUI API.
///
/// - Note: SwiftUI puts the button that returns to the previous view in a
///   navigation bar. SwiftCrossUI has no navigation bar, so a stack that has a
///   closure-pushed destination on top draws a plain back button above it.
///   Value-driven navigation is unchanged: pop it yourself with
///   ``NavigationPath/removeLast(_:)``.
public struct NavigationStack<Detail: View>: View {
    /// The label of the button that returns to the previous view.
    private static var backButtonLabel: String { "Back" }

    /// The spacing between the back button and the view it returns from.
    private static var backButtonSpacing: Int { 8 }

    /// The navigation path supplied by the surrounding view, if any.
    var externalPath: Binding<NavigationPath>?

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
    var child: (any Codable) -> Detail?
    /// The elements of the navigation path. The result can depend on
    /// ``NavigationStack/destinationTypes`` which determines how the keys are
    /// decoded if they haven't yet been decoded (this happens if they're loaded
    /// from disk for persistence).
    var elements: [any Codable] {
        let resolvedPath = path.wrappedValue.path(
            destinationTypes: destinationTypes
        )
        return [NavigationStackRootPath()] + resolvedPath
    }

    public var body: some View {
        // Resolved once so that the environment value captures just the
        // binding rather than the whole stack.
        let destinations = $viewDestinations

        visibleContent
            .environment(
                \.pushNavigationDestination,
                NavigationDestinationPusher { destination in
                    destinations.wrappedValue.append(destination)
                }
            )
    }

    /// The top of the stack: a closure-pushed destination if there is one, and
    /// the detail view for the current path element otherwise.
    @ViewBuilder
    private var visibleContent: some View {
        if let destination = viewDestinations.last {
            let destinations = $viewDestinations

            VStack(alignment: .leading, spacing: Self.backButtonSpacing) {
                Button(Self.backButtonLabel) {
                    destinations.wrappedValue.removeLast()
                }

                destination
            }
        } else if let element = elements.last {
            childOrCrash(for: element)
        } else {
            Text("Empty navigation path")
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
        self.init(externalPath: path, root: root)
    }

    /// Creates a navigation stack that manages its own navigation state.
    ///
    /// Navigate such a stack with the closure form of ``NavigationLink``, which
    /// pushes a view onto the stack rather than a value onto a path.
    ///
    /// - Parameter root: The view to display when the stack is empty.
    public init(@ViewBuilder _ root: @escaping () -> Detail) {
        self.init(externalPath: nil, root: root)
    }

    /// Creates a navigation stack, with or without an externally managed path.
    ///
    /// Both public initializers funnel through this one.
    ///
    /// - Parameters:
    ///   - externalPath: A binding to the navigation state for this stack, or
    ///     `nil` to let the stack manage its own.
    ///   - root: The view to display when the stack is empty.
    private init(
        externalPath: Binding<NavigationPath>?,
        root: @escaping () -> Detail
    ) {
        self.externalPath = externalPath
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

    /// Attempts to compute the detail view for the given element (the type of
    /// the element decides which detail is shown). Crashes if no suitable detail
    /// view is found.
    func childOrCrash(for element: some Codable) -> Detail {
        guard let child = child(element) else {
            fatalError(
                "Failed to find detail view for \"\(element)\", make sure you have called .navigationDestination for this type."
            )
        }

        return child
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

extension EnvironmentValues {
    /// Pushes a view onto the innermost enclosing ``NavigationStack``.
    ///
    /// `nil` when there's no enclosing stack, in which case a closure-form
    /// ``NavigationLink`` has nowhere to navigate to and says so.
    @Entry var pushNavigationDestination: NavigationDestinationPusher? = nil
}
