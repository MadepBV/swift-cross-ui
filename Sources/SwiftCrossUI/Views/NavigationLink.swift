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
/// The value form doesn't have to be inside its ``NavigationStack``, unlike
/// Apple's SwiftUI API, as long as the two share the same ``NavigationPath``.
/// The destination form does have to be inside one, because that's how it finds
/// the stack to push onto.
public struct NavigationLink: View {
    /// How the link was built, which decides what clicking it does.
    enum Storage {
        /// A link that appends a value to a navigation path, labelled with a
        /// piece of text.
        case value(label: String, value: any Codable, path: Binding<NavigationPath>)
        /// A link that appends a value to a navigation path, labelled with a
        /// view of the author's choosing.
        case labelledValue(label: AnyView, value: any Codable, path: Binding<NavigationPath>)
        /// A link that pushes a view onto the enclosing navigation stack.
        case destination(label: AnyView, destination: () -> AnyView)
    }

    /// How the link was built.
    let storage: Storage

    /// Pushes a destination onto the enclosing navigation stack, if there is
    /// one.
    @Environment(\.pushNavigationDestination) private var push

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
