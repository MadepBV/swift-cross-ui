/// A standard user interface item consisting of an icon paired with a title.
///
/// A label is the combination of an icon and a title that appears throughout
/// most user interfaces: in lists, in menus of action items, and on buttons.
///
/// ```swift
/// Label {
///     Text("Extrude")
/// } icon: {
///     Image(extrudeIconURL)
/// }
/// ```
///
/// Use ``View/labelStyle(_:)`` to control which parts of a label are shown.
/// For example, a toolbar that only has room for icons can hide every title
/// beneath it at once:
///
/// ```swift
/// HStack {
///     Label { Text("Extrude") } icon: { Image(extrudeIconURL) }
///     Label { Text("Revolve") } icon: { Image(revolveIconURL) }
/// }
/// .labelStyle(.iconOnly)
/// ```
///
/// ## System images
///
/// ``Label/init(_:systemImage:)`` takes an Apple SF Symbol name so that
/// SwiftUI source compiles unchanged:
///
/// ```swift
/// Label("Duplicate", systemImage: "square.on.square")
/// ```
///
/// SF Symbols are an Apple-only font, so the name is resolved through the
/// environment's ``EnvironmentValues/symbolProvider``, which by default draws
/// an equivalent bundled Lucide icon. The symbol is tinted with the current
/// foreground colour and sized from the current font, so it lines up with the
/// title beside it. See ``Image/init(systemName:)`` for the details.
///
/// ## Image resources
///
/// ``Label/init(_:image:)`` also exists for source compatibility, but
/// SwiftCrossUI has no asset catalog to resolve a resource name against, so
/// labels created that way render as title-only labels. The requested name is
/// recorded on the label so that a future asset mechanism can pick it up
/// without any call sites having to change. To show an image today, load it
/// yourself and use ``Label/init(title:icon:)``.
///
/// ## See Also
///
/// - ``LabelStyle``
/// - ``View/labelStyle(_:)``
/// - ``Image/init(systemName:)``
public struct Label<Title: View, Icon: View>: View {
    /// Creates a label with a custom title and icon.
    ///
    /// - Parameters:
    ///   - title: The view used as the label's title.
    ///   - icon: The view used as the label's icon.
    public init(
        @ViewBuilder title: () -> Title,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title()
        self.icon = icon()
    }

    /// The view used as the label's title.
    private var title: Title
    /// The view used as the label's icon.
    private var icon: Icon

    /// The name of the SF Symbol requested via ``Label/init(_:systemImage:)``,
    /// if the label was created that way.
    ///
    /// The symbol itself is rendered by the label's ``Image`` icon; this is
    /// kept so that a provider backed by a native symbol library can recover
    /// the original name.
    package private(set) var systemImageName: String?

    /// The name of the image asset requested via ``Label/init(_:image:)``, if
    /// the label was created that way.
    ///
    /// SwiftCrossUI has no asset catalog, so this name is currently only
    /// recorded, never rendered. See ``Label`` for the full explanation.
    package private(set) var imageName: String?

    /// The style to render with, taken from the environment.
    @Environment(\.labelStyle) private var labelStyle

    /// Whether `Icon` is a stand-in for an icon that couldn't be resolved.
    ///
    /// ``Label/init(_:image:)`` uses ``EmptyView`` as its icon because there's
    /// no asset catalog to resolve a resource name against. Such a label falls
    /// back to showing its title even under ``LabelStyle/iconOnly``, since a
    /// label that renders as nothing at all would leave the surrounding
    /// control unusable.
    private var iconIsUnavailable: Bool {
        Icon.self == EmptyView.self
    }

    /// Whether `Title` is a stand-in for a title that was never provided.
    private var titleIsUnavailable: Bool {
        Title.self == EmptyView.self
    }

    /// The label's parts, in the form that a ``LabelStyle`` consumes them.
    private var configuration: LabelStyleConfiguration {
        LabelStyleConfiguration(
            title: LabelStyleConfiguration.Title(title),
            icon: LabelStyleConfiguration.Icon(icon),
            titleIsAvailable: !titleIsUnavailable,
            iconIsAvailable: !iconIsUnavailable
        )
    }

    public var body: some View {
        AnyView(labelStyle.makeBody(configuration: configuration))
    }

    /// Menus can only display text, so a label contributes its title and
    /// discards its icon when used as menu content.
    public var _asMenuItems: [MenuItem] {
        title._asMenuItems
    }
}

extension Label: PickerContentContainer {
    /// A picker option shows a label's title, so that's what the label
    /// contributes; the icon carries no text.
    ///
    /// Handing the title over directly also means the label's `body` is never
    /// evaluated outside the view graph, where its `@Environment` read would
    /// trap.
    var pickerContentChildren: [any View] {
        [title]
    }
}

extension Label where Title == Text, Icon == Image {
    /// Creates a label with a system image (an SF Symbol) and a title
    /// generated from a string.
    ///
    /// The name is resolved through the environment's
    /// ``EnvironmentValues/symbolProvider``, which by default draws an
    /// equivalent bundled Lucide icon on every platform. See ``Label`` for
    /// details.
    ///
    /// - Parameters:
    ///   - titleKey: The title displayed by the label.
    ///   - name: The name of the SF Symbol to use as the label's icon.
    public init(_ titleKey: String, systemImage name: String) {
        // Assigns the stored properties directly instead of delegating to
        // `init(title:icon:)` because `ViewBuilder` would wrap each
        // child in a `TupleView1`, which doesn't match `Title` and `Icon`.
        title = Text(titleKey)
        icon = Image(systemName: name)
        systemImageName = name
    }
}

extension Label where Title == Text, Icon == EmptyView {
    /// Creates a label with an image resource and a title generated from a
    /// string.
    ///
    /// - Important: SwiftCrossUI has no asset catalog, so it can't resolve an
    ///   image name into an image. Labels created with this initializer render
    ///   as title-only labels regardless of the current ``LabelStyle``. See
    ///   ``Label`` for details. To display an icon, load it yourself with
    ///   ``Image/init(_:useFileExtension:)`` and use
    ///   ``Label/init(title:icon:)``.
    ///
    /// - Parameters:
    ///   - titleKey: The title displayed by the label.
    ///   - name: The name of the image resource to use as the label's icon.
    public init(_ titleKey: String, image name: String) {
        // See `init(_:systemImage:)` for why this doesn't delegate to
        // `init(title:icon:)`.
        title = Text(titleKey)
        icon = EmptyView()
        imageName = name
    }
}
