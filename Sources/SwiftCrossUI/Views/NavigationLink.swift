// TODO: This documentation could probably be clarified a bit more (potentially with
//   some practical examples).
/// A navigation primitive that presents another view when clicked.
///
/// A link either appends a value to a navigation path, in which case the
/// enclosing ``NavigationStack`` decides what to display for that value:
///
/// ```swift
/// NavigationLink("Science", value: SubjectArea.science, path: $path)
/// ```
///
/// ...with a label of its own, if a line of text isn't enough:
///
/// ```swift
/// NavigationLink(value: SubjectArea.science, path: $path) {
///     Label("Science", systemImage: "flask")
/// }
/// ```
///
/// ...or names its destination directly, in which case the destination is
/// pushed onto the enclosing stack as-is:
///
/// ```swift
/// NavigationLink {
///     DrawingStyleSettingsView(model: model)
/// } label: {
///     Text("Drawing style")
/// }
/// ```
///
/// A value link can also leave the path out, in which case it appends to the
/// path of the ``NavigationStack`` it's inside, exactly as SwiftUI's does:
///
/// ```swift
/// NavigationLink(value: SubjectArea.science) {
///     Label("Science", systemImage: "flask")
/// }
/// ```
///
/// The `path:` forms don't have to be inside their ``NavigationStack``, unlike
/// Apple's SwiftUI API, as long as the two share the same ``NavigationPath``.
/// The path-less and destination forms do have to be inside one, because that's
/// how they find the stack to navigate. Outside a stack they're inert: clicking
/// one logs a warning and navigates nowhere.
public struct NavigationLink: View {
    /// How the link was built, which decides what clicking it does.
    enum Storage {
        /// A link that appends a value to a navigation path, labelled with a
        /// piece of text.
        case value(label: String, value: any Codable, path: Binding<NavigationPath>)
        /// A link that appends a value to a navigation path, labelled with a
        /// view of the author's choosing.
        case labelledValue(label: AnyView, value: any Codable, path: Binding<NavigationPath>)
        /// A link that appends a value to the path of the enclosing navigation
        /// stack, which it finds through the environment.
        case stackValue(label: AnyView, value: any Codable)
        /// A link that pushes a view onto the enclosing navigation stack.
        case destination(label: AnyView, destination: () -> AnyView)
    }

    /// How the link was built.
    let storage: Storage

    /// Pushes a destination onto the enclosing navigation stack, if there is
    /// one.
    @Environment(\.pushNavigationDestination) private var push

    /// Appends a value to the path of the enclosing navigation stack, if there
    /// is one.
    @Environment(\.appendToNavigationPath) private var appendToPath

    @ViewBuilder
    public var body: some View {
        switch storage {
            case .value(let label, let value, let path):
                Button(label) {
                    path.wrappedValue.append(value)
                }
            case .labelledValue(let label, let value, let path):
                Button {
                    path.wrappedValue.append(value)
                } label: {
                    label
                }
            case .stackValue(let label, let value):
                // Resolved here so that the button's action captures just the
                // appender and the value rather than the whole link.
                let appendToPath = self.appendToPath

                Button {
                    guard let appendToPath else {
                        logger.warning(
                            """
                            a 'NavigationLink' with a value and no path was \
                            clicked outside of a 'NavigationStack'; there's \
                            nowhere to navigate to
                            """
                        )
                        return
                    }
                    appendToPath(value)
                } label: {
                    label
                }
            case .destination(let label, let destination):
                // Resolved here so that the button's action captures just the
                // two closures rather than the whole link.
                let push = self.push

                Button {
                    guard let push else {
                        logger.warning(
                            """
                            a 'NavigationLink' with a destination was clicked \
                            outside of a 'NavigationStack'; there's nowhere to \
                            navigate to
                            """
                        )
                        return
                    }
                    push(destination())
                } label: {
                    label
                }
        }
    }

    /// Creates a navigation link that presents the view corresponding to a value.
    /// The link is handled by whatever ``NavigationStack`` is sharing the same
    /// navigation path.
    ///
    /// - Parameters:
    ///   - label: The label to display on the button.
    ///   - value: The value to append to the navigation path when clicked.
    ///   - path: The navigation path to append to when clicked.
    public init(_ label: String, value: some Codable, path: Binding<NavigationPath>) {
        storage = .value(label: label, value: value, path: path)
    }

    /// Creates a navigation link that presents the view corresponding to a
    /// value, labelled with a view rather than a piece of text.
    ///
    /// This is the value counterpart of ``init(destination:label:)``: the label
    /// can be any view, so a link can show an icon, a subtitle, or a whole row
    /// instead of a single line of text.
    ///
    /// ```swift
    /// NavigationLink(value: definition.id, path: $path) {
    ///     definitionRow(definition)
    /// }
    /// ```
    ///
    /// The link is handled by whatever ``NavigationStack`` is sharing the same
    /// navigation path.
    ///
    /// - Parameters:
    ///   - value: The value to append to the navigation path when clicked.
    ///   - path: The navigation path to append to when clicked.
    ///   - label: The label to display on the link.
    @MainActor
    public init<Label: View>(
        value: some Codable,
        path: Binding<NavigationPath>,
        @ViewBuilder label: () -> Label
    ) {
        storage = .labelledValue(
            label: AnyView(label()),
            value: value,
            path: path
        )
    }

    /// Creates a navigation link that presents the view corresponding to a
    /// value, appending it to the path of the enclosing ``NavigationStack``.
    ///
    /// This is SwiftUI's spelling, where the link and the stack agree through
    /// the view hierarchy instead of through a path binding that the author
    /// threads between them:
    ///
    /// ```swift
    /// NavigationStack(path: $path) {
    ///     List(definitions) { definition in
    ///         NavigationLink(value: definition.id) {
    ///             definitionRow(definition)
    ///         }
    ///     }
    /// }
    /// .navigationDestination(for: String.self) { id in
    ///     definitionView(id)
    /// }
    /// ```
    ///
    /// A link like this has to be inside its stack, which is how it finds the
    /// path to append to. Outside of one it's inert: clicking it logs a warning
    /// and navigates nowhere. Use ``init(value:path:label:)`` to place a link
    /// outside its stack.
    ///
    /// - Parameters:
    ///   - value: The value to append to the stack's path when clicked.
    ///   - label: The label to display on the link.
    @MainActor
    public init<Label: View>(
        value: some Codable,
        @ViewBuilder label: () -> Label
    ) {
        storage = .stackValue(label: AnyView(label()), value: value)
    }

    /// Creates a navigation link that presents the view corresponding to a
    /// value, appending it to the path of the enclosing ``NavigationStack``.
    ///
    /// The text counterpart of ``init(value:label:)``, and inert outside a
    /// stack for the same reason.
    ///
    /// - Parameters:
    ///   - label: The label to display on the link.
    ///   - value: The value to append to the stack's path when clicked.
    @MainActor
    public init(_ label: String, value: some Codable) {
        storage = .stackValue(label: AnyView(Text(label)), value: value)
    }

    /// Creates a navigation link that presents a destination view.
    ///
    /// The destination is pushed onto the innermost enclosing
    /// ``NavigationStack`` when the link is clicked, and is only built at that
    /// point.
    ///
    /// - Parameters:
    ///   - destination: The view to present when the link is clicked.
    ///   - label: The label to display on the link.
    @MainActor
    public init<Destination: View, Label: View>(
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        storage = .destination(
            label: AnyView(label()),
            destination: { AnyView(destination()) }
        )
    }
}
