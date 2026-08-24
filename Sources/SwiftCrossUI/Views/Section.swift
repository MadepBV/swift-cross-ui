/// A container view that groups related rows beneath an optional header and
/// above an optional footer.
///
/// Sections are the structural backbone of property inspectors and settings
/// panels. The most common form is a titled section, which renders its title
/// above its vertically stacked content.
///
/// ```swift
/// Section("Drafting parameters") {
///     LabeledContent("Diameter", value: diameter)
///     LabeledContent("Spacing", value: spacing)
/// }
/// ```
///
/// A section without a header simply groups its content, which is useful for
/// separating unlabelled groups of rows within a ``Form``.
///
/// ```swift
/// Section {
///     Text("Untitled group")
/// }
/// ```
///
/// The appearance of a section is controlled by the enclosing
/// ``EnvironmentValues/formStyle``, which is set with ``View/formStyle(_:)``.
/// Under ``FormStyle/grouped`` a section draws a subtle container behind its
/// content; under ``FormStyle/automatic`` it just stacks its rows. Beneath a
/// form style that SwiftCrossUI doesn't ship, a section stacks its rows too.
///
/// - Note: Unlike SwiftUI, sections don't currently collapse. Use
///   ``DisclosureGroup`` when you need collapsible content.
public struct Section<Parent: View, Content: View, Footer: View>: View {
    /// A view identifying the purpose of the section's content.
    private var header: Parent
    /// The section's rows.
    private var content: Content
    /// A view displayed beneath the section's content.
    private var footer: Footer

    /// The style of the enclosing form, if any.
    @Environment(\.formStyle) private var formStyle
    /// Whether this section is a row of a ``Form``.
    @Environment(\.isInsideForm) private var isInsideForm

    /// The metrics to lay the section out with.
    ///
    /// A style that SwiftCrossUI doesn't ship has no metrics of its own, so
    /// sections fall back to the plain layout beneath it.
    private var metrics: FormMetrics {
        guard let builtinStyle = formStyle as? any _BuiltinFormStyle else {
            return .automatic
        }
        return builtinStyle.formMetrics
    }

    /// Creates a section from its three constituent views.
    ///
    /// All of the public initializers funnel through this one.
    ///
    /// - Parameters:
    ///   - header: A view identifying the purpose of `content`.
    ///   - content: The section's rows.
    ///   - footer: A view displayed beneath `content`.
    private init(header: Parent, content: Content, footer: Footer) {
        self.header = header
        self.content = content
        self.footer = footer
    }

    /// In a menu a section is its content, set off by separators and headed
    /// by its title, as SwiftUI renders it.
    ///
    /// Spelled out so that the section's `body`, which reads the form style
    /// from the environment, is never evaluated for menu content. Redundant
    /// separators (at the menu's edges, or between adjacent sections) are
    /// removed when the menu is resolved.
    public var _asMenuItems: [MenuItem] {
        var items: [MenuItem] = [.separator(Divider())]
        items += header._asMenuItems
        items += content._asMenuItems
        items.append(.separator(Divider()))
        return items
    }

    /// Creates a section with no header and no footer.
    ///
    /// - Parameter content: The section's rows.
    public init(
        @ViewBuilder content: () -> Content
    ) where Parent == EmptyView, Footer == EmptyView {
        self.init(header: EmptyView(), content: content(), footer: EmptyView())
    }

    /// Creates a section with a title and no footer.
    ///
    /// SwiftUI takes a `LocalizedStringKey` here. SwiftCrossUI doesn't have
    /// string localization yet, so this takes a plain `String` instead, which
    /// keeps the vast majority of SwiftUI call sites source compatible.
    ///
    /// - Parameters:
    ///   - titleKey: The title of the section, displayed as its header.
    ///   - content: The section's rows.
    public init(
        _ titleKey: String,
        @ViewBuilder content: () -> Content
    ) where Parent == Text, Footer == EmptyView {
        self.init(header: Text(titleKey), content: content(), footer: EmptyView())
    }

    /// Creates a section with a custom header and no footer.
    ///
    /// - Parameters:
    ///   - content: The section's rows.
    ///   - header: A view identifying the purpose of `content`.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Parent
    ) where Footer == EmptyView {
        self.init(header: header(), content: content(), footer: EmptyView())
    }

    /// Creates a section with a custom footer and no header.
    ///
    /// - Parameters:
    ///   - content: The section's rows.
    ///   - footer: A view displayed beneath `content`.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) where Parent == EmptyView {
        self.init(header: EmptyView(), content: content(), footer: footer())
    }

    /// Creates a section with a custom header and footer.
    ///
    /// - Parameters:
    ///   - content: The section's rows.
    ///   - header: A view identifying the purpose of `content`.
    ///   - footer: A view displayed beneath `content`.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Parent,
        @ViewBuilder footer: () -> Footer
    ) {
        self.init(header: header(), content: content(), footer: footer())
    }

    /// Creates a section with a title and a custom footer.
    ///
    /// - Parameters:
    ///   - titleKey: The title of the section, displayed as its header.
    ///   - content: The section's rows.
    ///   - footer: A view displayed beneath `content`.
    public init(
        _ titleKey: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) where Parent == Text {
        self.init(header: Text(titleKey), content: content(), footer: footer())
    }

    /// Creates a section from an already constructed header view.
    ///
    /// Mirrors SwiftUI's older `Section(header:content:)` initializer.
    ///
    /// - Parameters:
    ///   - header: A view identifying the purpose of `content`.
    ///   - content: The section's rows.
    public init(
        header: Parent,
        @ViewBuilder content: () -> Content
    ) where Footer == EmptyView {
        self.init(header: header, content: content(), footer: EmptyView())
    }

    /// Creates a section from an already constructed footer view.
    ///
    /// Mirrors SwiftUI's older `Section(footer:content:)` initializer.
    ///
    /// - Parameters:
    ///   - footer: A view displayed beneath `content`.
    ///   - content: The section's rows.
    public init(
        footer: Footer,
        @ViewBuilder content: () -> Content
    ) where Parent == EmptyView {
        self.init(header: EmptyView(), content: content(), footer: footer)
    }

    /// Creates a section from already constructed header and footer views.
    ///
    /// Mirrors SwiftUI's older `Section(header:footer:content:)` initializer.
    ///
    /// - Parameters:
    ///   - header: A view identifying the purpose of `content`.
    ///   - footer: A view displayed beneath `content`.
    ///   - content: The section's rows.
    public init(
        header: Parent,
        footer: Footer,
        @ViewBuilder content: () -> Content
    ) {
        self.init(header: header, content: content(), footer: footer)
    }

    /// The container drawn behind a grouped section's content.
    ///
    /// Deliberately subtle so that it reads as a grouping cue rather than as a
    /// control, and adaptive so that it works in both color schemes.
    private var groupBackground: Color {
        Color.adaptive(light: .black, dark: .white).opacity(0.05)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: metrics.sectionHeaderSpacing) {
            header
                .font(.headline)

            VStack(alignment: .leading, spacing: metrics.sectionRowSpacing) {
                content
            }
            .if(isInsideForm) { rows in
                rows.frame(maxWidth: .infinity, alignment: .leading)
            }
            .if(metrics.groupsSectionContent) { rows in
                rows
                    .padding(metrics.sectionContentPadding)
                    .background(groupBackground)
                    .cornerRadius(metrics.sectionContentCornerRadius)
            }

            footer
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
}
