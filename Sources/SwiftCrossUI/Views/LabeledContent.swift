import Foundation

/// A view that pairs a label with some associated content.
///
/// ``LabeledContent`` lays its label out along the leading edge of the
/// available space and its content along the trailing edge, which makes it
/// well suited to dense property inspectors where many labelled controls get
/// stacked on top of each other.
///
/// ```swift
/// LabeledContent("Diameter") {
///     TextField("", text: $diameter)
/// }
/// ```
///
/// If the content is just a value to display, you can use the
/// ``LabeledContent/init(_:value:)`` convenience initializer instead.
///
/// ```swift
/// LabeledContent("Profile", value: profileName)
/// ```
///
/// By default each ``LabeledContent`` sizes its label to fit, which means
/// that the labels of sibling views don't necessarily line up with each
/// other. Set ``EnvironmentValues/labeledContentLabelWidth`` on a common
/// ancestor to give every label beneath that ancestor the same width, and
/// therefore line the contents up in a column.
public struct LabeledContent<Label: View, Content: View>: View {
    /// The minimum amount of space to leave between the label and the
    /// content.
    ///
    /// The label and the content are pushed apart by a ``Spacer``, so this is
    /// only ever the actual gap when there isn't enough space to spare.
    private static var minimumSpacing: Int { 8 }

    /// A view describing the purpose of the content.
    private var label: Label
    /// The content that the label describes.
    private var content: Content

    /// The width to give the label, or `nil` to let the label size itself.
    @Environment(\.labeledContentLabelWidth) private var labelWidth
    @Environment(\.labelsHidden) private var labelsHidden

    /// Creates a labelled view from a content view and a label view.
    ///
    /// - Parameters:
    ///   - content: The content to label. Usually a control such as a
    ///     ``TextField`` or a ``Picker``, or a read-only value displayed with
    ///     ``Text``.
    ///   - label: A view describing the purpose of `content`.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
    }

    /// Creates a labelled view from views that have already been built.
    ///
    /// The convenience initializers can't use
    /// ``LabeledContent/init(content:label:)`` because ``ViewBuilder`` wraps
    /// its result in a ``TupleView1``, which would conflict with their
    /// `Label == Text` and `Content == Text` requirements.
    ///
    /// - Parameters:
    ///   - label: A view describing the purpose of `content`.
    ///   - content: The content that `label` describes.
    private init(label: Label, content: Content) {
        self.label = label
        self.content = content
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if !labelsHidden {
                label
                    // `frame(width:height:alignment:)` takes `CGFloat?` (as
                    // SwiftUI's does), and the implicit `Double`/`CGFloat`
                    // conversion doesn't reach inside an optional.
                    .frame(
                        width: labelWidth.map { width in CGFloat(width) },
                        alignment: .leading
                    )
            }
            if !labelsHidden {
                Spacer(minLength: Self.minimumSpacing)
            }
            content
        }
        .retainingHiddenControlLabel(label, hidden: labelsHidden)
    }
}

extension LabeledContent where Label == Text {
    /// Creates a labelled view with a textual label.
    ///
    /// - Parameters:
    ///   - title: Text describing the purpose of `content`.
    ///   - content: The content to label.
    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(label: Text(title), content: content())
    }
}

extension LabeledContent where Label == Text, Content == Text {
    /// Creates a labelled view displaying a textual value.
    ///
    /// - Parameters:
    ///   - title: Text describing the purpose of `value`.
    ///   - value: The value to display alongside the label.
    public init(_ title: String, value: String) {
        self.init(label: Text(title), content: Text(value))
    }
}

extension EnvironmentValues {
    /// The width to give the labels of ``LabeledContent`` views.
    ///
    /// ``LabeledContent`` sizes its label to fit when this is `nil` (the
    /// default). Set it on a common ancestor of a group of labelled views to
    /// line their contents up in a column, in the same way that SwiftUI's
    /// `Form` aligns the labels of its rows.
    ///
    /// ```swift
    /// VStack {
    ///     LabeledContent("Diameter", value: "16 mm")
    ///     LabeledContent("Spacing", value: "150 mm")
    /// }
    /// .environment(\.labeledContentLabelWidth, 100)
    /// ```
    ///
    /// - Note: Containers that want to derive the column width from their
    ///   rows have to measure those rows themselves before setting this value;
    ///   ``LabeledContent`` doesn't report its label's width back up the view
    ///   hierarchy.
    @Entry public var labeledContentLabelWidth: Double?
}
