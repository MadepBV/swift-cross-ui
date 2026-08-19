/// A view that shows or hides another view based on the state of a disclosure
/// control.
///
/// Clicking (or tapping) the disclosure group's label toggles its expansion
/// state. While collapsed, the group's content is completely removed from the
/// view hierarchy and therefore contributes no size to the surrounding layout.
///
/// ```swift
/// DisclosureGroup("Layout") {
///     Text("Margin")
///     Text("Padding")
/// }
/// ```
///
/// Pass a binding to control (and observe) the expansion state yourself.
/// Changes made to the binding by the surrounding view are reflected by the
/// disclosure group, and interacting with the disclosure group writes the new
/// expansion state back through the binding.
///
/// ```swift
/// @State var isExpanded = true
///
/// var body: some View {
///     DisclosureGroup(isExpanded: $isExpanded) {
///         Text("Margin")
///     } label: {
///         Text("Layout")
///     }
/// }
/// ```
///
/// The content of a disclosure group is implicitly stacked vertically, exactly
/// like the content of a ``VStack``.
public struct DisclosureGroup<Label: View, Content: View>: View {
    /// The spacing between the disclosure indicator and the label.
    private static var indicatorSpacing: Int { 4 }

    /// The spacing between the label row and the content.
    private static var contentSpacing: Int { 6 }

    /// The amount that the content is indented relative to the label.
    private static var contentIndent: Int { 16 }

    /// The indicator shown while the group is collapsed (a right pointing
    /// triangle).
    private static var collapsedIndicator: String { "\u{25B8}" }

    /// The indicator shown while the group is expanded (a downwards pointing
    /// triangle).
    private static var expandedIndicator: String { "\u{25BE}" }

    /// The expansion state used when the group manages its own state (i.e.
    /// when no binding was supplied at initialization).
    @State private var internalExpansion = false

    /// The expansion state supplied by the surrounding view, if any.
    private var externalExpansion: Binding<Bool>?

    /// A view describing the content of the disclosure group.
    private var label: Label

    /// The content revealed when the disclosure group is expanded.
    private var content: Content

    /// The binding that the disclosure group reads from and writes to.
    ///
    /// This is the binding supplied at initialization if there was one, and a
    /// binding to the group's own state otherwise.
    private var expansion: Binding<Bool> {
        externalExpansion ?? $internalExpansion
    }

    /// Creates a disclosure group from an already built label and content.
    ///
    /// Exists because ``ViewBuilder`` would otherwise wrap the labels of the
    /// convenience initializers in a ``TupleView1``.
    ///
    /// - Parameters:
    ///   - isExpanded: A binding to whether the group is expanded, or `nil` to
    ///     let the group manage its own expansion state.
    ///   - label: A view describing the content of the disclosure group.
    ///   - content: The content shown while the group is expanded.
    private init(
        isExpanded: Binding<Bool>?,
        label: Label,
        content: Content
    ) {
        self.externalExpansion = isExpanded
        self.label = label
        self.content = content
    }

    /// Creates a disclosure group with a custom label, managing its own
    /// expansion state.
    ///
    /// The group starts out collapsed.
    ///
    /// - Parameters:
    ///   - content: The content shown while the group is expanded. Implicitly
    ///     stacked vertically.
    ///   - label: A view describing the content of the disclosure group.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.init(isExpanded: nil, label: label(), content: content())
    }

    /// Creates a disclosure group with a custom label and an externally
    /// managed expansion state.
    ///
    /// - Parameters:
    ///   - isExpanded: A binding to whether the group is expanded. Written to
    ///     whenever the user toggles the group.
    ///   - content: The content shown while the group is expanded. Implicitly
    ///     stacked vertically.
    ///   - label: A view describing the content of the disclosure group.
    public init(
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.init(isExpanded: isExpanded, label: label(), content: content())
    }

    /// A clickable label row, followed by the content while expanded.
    public var body: some View {
        // Resolved once so that the button's action captures just the binding
        // rather than the whole view (including its label and content).
        let expansion = self.expansion
        let isExpanded = expansion.wrappedValue

        VStack(alignment: .leading, spacing: Self.contentSpacing) {
            Button {
                expansion.wrappedValue = !expansion.wrappedValue
            } label: {
                HStack(spacing: Self.indicatorSpacing) {
                    Text(
                        isExpanded
                            ? Self.expandedIndicator
                            : Self.collapsedIndicator
                    )

                    label
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, content: content)
                    .padding(.leading, Self.contentIndent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

extension DisclosureGroup where Label == Text {
    /// Creates a disclosure group with a text label, managing its own
    /// expansion state.
    ///
    /// The group starts out collapsed.
    ///
    /// - Parameters:
    ///   - titleKey: The title of the disclosure group.
    ///   - content: The content shown while the group is expanded. Implicitly
    ///     stacked vertically.
    public init(
        _ titleKey: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            isExpanded: nil,
            label: Text(titleKey),
            content: content()
        )
    }

    /// Creates a disclosure group with a text label and an externally managed
    /// expansion state.
    ///
    /// - Parameters:
    ///   - titleKey: The title of the disclosure group.
    ///   - isExpanded: A binding to whether the group is expanded. Written to
    ///     whenever the user toggles the group.
    ///   - content: The content shown while the group is expanded. Implicitly
    ///     stacked vertically.
    public init(
        _ titleKey: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            isExpanded: isExpanded,
            label: Text(titleKey),
            content: content()
        )
    }
}
