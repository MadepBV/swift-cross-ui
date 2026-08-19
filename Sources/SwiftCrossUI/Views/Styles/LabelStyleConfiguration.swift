/// The properties of a label, handed to a ``LabelStyle`` so that it can
/// arrange them.
///
/// A style never constructs a configuration itself; ``Label`` builds one and
/// passes it to ``LabelStyle/makeBody(configuration:)``.
///
/// ## See Also
///
/// - ``LabelStyle``
/// - ``Label``
public struct LabelStyleConfiguration {
    /// A type-erased view of a label's title.
    public struct Title: View {
        /// The label's title, with its type erased.
        private var erasedTitle: AnyView

        @ViewBuilder
        public var body: some View {
            erasedTitle
        }

        /// Erases a label's title.
        ///
        /// - Parameter title: The view used as the label's title.
        package init(_ title: some View) {
            erasedTitle = AnyView(title)
        }
    }

    /// A type-erased view of a label's icon.
    public struct Icon: View {
        /// The label's icon, with its type erased.
        private var erasedIcon: AnyView

        @ViewBuilder
        public var body: some View {
            erasedIcon
        }

        /// Erases a label's icon.
        ///
        /// - Parameter icon: The view used as the label's icon.
        package init(_ icon: some View) {
            erasedIcon = AnyView(icon)
        }
    }

    /// A view that describes the purpose of the label.
    public var title: Title

    /// A symbolic representation of the label's purpose.
    public var icon: Icon

    /// Whether the label's title can actually be rendered.
    ///
    /// `false` for a label that was created without a title. The built-in
    /// styles fall back to the icon rather than rendering nothing at all,
    /// since an empty label would leave an enclosing control unusable.
    package var titleIsAvailable: Bool

    /// Whether the label's icon can actually be rendered.
    ///
    /// `false` for a label created with ``Label/init(_:image:)``, since
    /// SwiftCrossUI has no asset catalog to resolve a resource name against.
    /// The built-in styles fall back to the title in that case, for the same
    /// reason as ``LabelStyleConfiguration/titleIsAvailable``.
    package var iconIsAvailable: Bool

    /// Creates a configuration describing a label.
    ///
    /// - Parameters:
    ///   - title: A view that describes the purpose of the label.
    ///   - icon: A symbolic representation of the label's purpose.
    ///   - titleIsAvailable: Whether `title` can actually be rendered.
    ///   - iconIsAvailable: Whether `icon` can actually be rendered.
    package init(
        title: Title,
        icon: Icon,
        titleIsAvailable: Bool,
        iconIsAvailable: Bool
    ) {
        self.title = title
        self.icon = icon
        self.titleIsAvailable = titleIsAvailable
        self.iconIsAvailable = iconIsAvailable
    }
}
