/// A stylized view, with an optional label, that visually collects a logical
/// grouping of content.
///
/// Group boxes are handy for breaking dense interfaces (such as property
/// inspectors) into visually distinct sections.
///
/// ```swift
/// GroupBox("Region") {
///     Text("Width")
///     Text("Height")
/// }
/// ```
///
/// The content of a group box is implicitly stacked vertically, exactly like
/// the content of a ``VStack``. A group box takes up as much width as its
/// parent offers it, and only as much height as its label and content require.
///
/// If you don't need a label, use ``init(content:)``.
///
/// ```swift
/// GroupBox {
///     Text("Ungrouped, but boxed")
/// }
/// ```
public struct GroupBox<Label: View, Content: View>: View {
    /// The corner radius of the box drawn around the content.
    private static var cornerRadius: Int { 8 }

    /// The thickness of the border drawn around the content.
    private static var borderWidth: Int { 1 }

    /// The padding between the box's border and its content.
    private static var contentPadding: Int { 12 }

    /// The spacing between the label and the box drawn around the content.
    private static var labelSpacing: Int { 4 }

    /// The color of the border drawn around the content.
    private static var borderColor: Color {
        Color.adaptive(
            light: Color(white: 0, opacity: 0.14),
            dark: Color(white: 1, opacity: 0.18)
        )
    }

    /// The color used to fill the box drawn around the content.
    private static var fillColor: Color {
        Color.adaptive(
            light: Color(white: 0, opacity: 0.04),
            dark: Color(white: 1, opacity: 0.06)
        )
    }

    /// The view describing the content of the group box.
    private var label: Label

    /// The content of the group box.
    private var content: Content

    /// Creates a group box from an already built label and content.
    ///
    /// Exists because ``ViewBuilder`` would otherwise wrap the labels of the
    /// convenience initializers in a ``TupleView1``.
    ///
    /// - Parameters:
    ///   - label: A view describing the content of the group box.
    ///   - content: The content of the group box.
    private init(label: Label, content: Content) {
        self.label = label
        self.content = content
    }

    /// Creates a group box with a custom label.
    ///
    /// - Parameters:
    ///   - content: The content of the group box. Implicitly stacked
    ///     vertically.
    ///   - label: A view describing the content of the group box.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.init(label: label(), content: content())
    }

    /// The label stacked above the bordered box that holds the content.
    public var body: some View {
        VStack(alignment: .leading, spacing: Self.labelSpacing) {
            label
                .font(.headline)

            VStack(alignment: .leading, content: content)
                .padding(Self.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    Self.borderColor
                        .cornerRadius(Self.cornerRadius)

                    Self.fillColor
                        .cornerRadius(Self.cornerRadius - Self.borderWidth)
                        .padding(Self.borderWidth)
                }
        }
    }
}

extension GroupBox where Label == Text {
    /// Creates a group box with a text label.
    ///
    /// - Parameters:
    ///   - titleKey: The title of the group box, displayed above its content.
    ///   - content: The content of the group box. Implicitly stacked
    ///     vertically.
    public init(
        _ titleKey: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init(label: Text(titleKey), content: content())
    }
}

extension GroupBox where Label == EmptyView {
    /// Creates a group box without a label.
    ///
    /// - Parameter content: The content of the group box. Implicitly stacked
    ///   vertically.
    public init(@ViewBuilder content: () -> Content) {
        self.init(label: EmptyView(), content: content())
    }
}
