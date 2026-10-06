/// An interface, consisting of a label and additional content,
/// that you display when the content of your app is unavailable to users.
public struct ContentUnavailableView<Label: View, Description: View, Actions: View>: View {
    /// Creates an interface, consisting of a label and additional content,
    /// that you display when the content of your app is unavailable to users.
    ///
    /// - Parameters:
    ///   - label: The label that describes the view.
    ///   - description: The view giving more information about the reason
    ///     for the content being unavailable.
    ///   - actions: The view containing actions related to the content being unavailable.
    ///     For example "Back to Home", "Login" or "Refresh".
    public init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder description: () -> Description = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }

    private var label: Label
    private var description: Description
    private var actions: Actions

    @Environment(\.backend) var backend
    @Environment(\.foregroundColor) var environmentForegroundColor

    var labelFont: Font {
        switch backend.deviceClass.kind {
            case .phone, .tablet, .watch: .title2
            case .tv: .headline
            case .desktop: .largeTitle
        }
    }

    var descriptionFont: Font {
        switch backend.deviceClass.kind {
            case .phone, .tablet, .tv, .watch: .subheadline
            case .desktop: .body
        }
    }

    var labelColor: Color {
        if let environmentForegroundColor { return environmentForegroundColor }
        if backend.deviceClass == .desktop { return .gray }
        return .adaptive(light: .black, dark: .white)
    }

    public var body: some View {
        VStack {
            label
                .font(labelFont)
                .foregroundColor(labelColor)
            description
                .font(descriptionFont)
                .foregroundColor(environmentForegroundColor ?? .gray)

            if backend.deviceClass == .desktop {
                HStack {
                    actions
                        .font(.body)
                        .foregroundColor(
                            environmentForegroundColor
                                ?? .adaptive(light: .black, dark: .white)
                        )
                }
            } else {
                VStack {
                    actions
                        .font(.body)
                }
            }
        }
        .if(backend.deviceClass != .desktop) { view in
            view.padding(30)
        }
        .if(backend.deviceClass == .desktop) { view in
            view.frame(maxWidth: 360)
        }
    }
}

/// SwiftUI's standard "no search results" presentations.
///
/// The constraints pin every generic argument to a concrete type, which is
/// what lets a caller write `ContentUnavailableView.search(text:)` without
/// naming any of them. ``ViewBuilder`` wraps even a single view in a
/// ``TupleView1``, so these are the types the view's initializer infers for a
/// label, a description and no actions.
extension ContentUnavailableView
    where
    Label == TupleView1<Text>,
    Description == TupleView1<Text>,
    Actions == TupleView1<EmptyView>
{
    /// A view that indicates that a search returned no results.
    ///
    /// Use this when the search term isn't worth repeating back to the user,
    /// or isn't available where the view is built. Use
    /// ``ContentUnavailableView/search(text:)`` when it is, because quoting
    /// the term makes it obvious which search came up empty.
    ///
    /// ```swift
    /// if results.isEmpty {
    ///     ContentUnavailableView.search
    /// }
    /// ```
    public static var search: Self {
        ContentUnavailableView {
            Text("No Results")
        } description: {
            Text(Self.searchDescription)
        } actions: {
            EmptyView()
        }
    }

    /// A view that indicates that a search for `text` returned no results.
    ///
    /// The search term is quoted in the label so that the user can see exactly
    /// which search came up empty:
    ///
    /// ```swift
    /// if results.isEmpty {
    ///     ContentUnavailableView.search(text: query)
    /// }
    /// ```
    ///
    /// - Parameter text: The search term that returned no results.
    /// - Returns: A standard "No Results" presentation naming `text`.
    public static func search(text: String) -> Self {
        ContentUnavailableView {
            Text("No Results for \u{201C}\(text)\u{201D}")
        } description: {
            Text(Self.searchDescription)
        } actions: {
            EmptyView()
        }
    }

    /// The description shown beneath both empty search presentations.
    private static var searchDescription: String {
        "Check the spelling or try a new search."
    }
}

/// SwiftUI's title-and-symbol presentation.
extension ContentUnavailableView
    where
    Label == TupleView1<AnyView>,
    Description == TupleView1<AnyView>,
    Actions == TupleView1<EmptyView>
{
    /// Creates a presentation from a title, a symbol and an optional
    /// description.
    ///
    /// ```swift
    /// ContentUnavailableView(
    ///     "No downloads",
    ///     systemImage: "arrow.down.circle",
    ///     description: Text("Downloaded titles play without a connection.")
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - title: The title.
    ///   - systemImage: The name of the symbol shown with the title.
    ///   - description: More about why the content is unavailable, if
    ///     anything.
    public init(_ title: String, systemImage: String, description: Text? = nil) {
        self.init {
            AnyView(SwiftCrossUI.Label(title, systemImage: systemImage))
        } description: {
            description.map { AnyView($0) } ?? AnyView(EmptyView())
        } actions: {
            EmptyView()
        }
    }
}
