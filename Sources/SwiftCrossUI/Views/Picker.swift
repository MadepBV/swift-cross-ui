/// A control for selecting from a set of mutually exclusive values.
///
/// Describe the picker's options with tagged views, and give it a binding to
/// the value that the selected option stands for.
///
/// ```swift
/// Picker("Kind", selection: $kind) {
///     Text("Alpha").tag(Kind.alpha)
///     Text("Beta").tag(Kind.beta)
/// }
/// ```
///
/// The content is an ordinary view builder, so ``ForEach`` and ``Group`` work
/// as well as literal children:
///
/// ```swift
/// Picker("Kind", selection: $kind) {
///     ForEach(Kind.allCases, id: \.self) { kind in
///         Text(kind.name).tag(kind)
///     }
/// }
/// ```
///
/// A selection binding of optional type accepts tags of its wrapped type too,
/// so `.tag(Kind.alpha)` selects a `Binding<Kind?>` without having to spell
/// the optional out. An option whose view carries no tag is tagged with the
/// text that it displays, which lets a picker over strings skip tags entirely.
///
/// Use ``SwiftCrossUI/View/pickerStyle(_:)`` to choose how the picker
/// presents itself.
public struct Picker<Label: View, SelectedValue: Hashable, Content: View>: View {
    /// A view describing the picker's purpose, shown before the control.
    private var label: Label
    /// The view builder content that describes the picker's options.
    private var content: Content
    /// A binding to the value that the picker's selected option stands for.
    ///
    /// Held as an optional binding because a picker can be in a state where
    /// none of its options match the selection.
    private var selection: Binding<SelectedValue?>
    /// Options handed to the picker directly instead of through tagged
    /// content, by ``init(of:selection:)``.
    private var directOptions: [SelectedValue]?
    /// Whether the picker has a label worth showing.
    private var showsLabel: Bool

    @Environment(\.self) var environment

    /// Creates a picker from its already-resolved parts.
    ///
    /// - Parameters:
    ///   - label: A view describing the picker's purpose.
    ///   - showsLabel: Whether the label is worth showing.
    ///   - content: The view builder content describing the picker's options.
    ///   - selection: A binding to the value that the selected option stands
    ///     for.
    ///   - directOptions: Options handed to the picker directly instead of
    ///     through tagged content.
    private init(
        label: Label,
        showsLabel: Bool,
        content: Content,
        selection: Binding<SelectedValue?>,
        directOptions: [SelectedValue]?
    ) {
        self.label = label
        self.showsLabel = showsLabel
        self.content = content
        self.selection = selection
        self.directOptions = directOptions
    }

    /// Creates a picker with a custom label.
    ///
    /// - Parameters:
    ///   - selection: A binding to the value that the selected option stands
    ///     for.
    ///   - content: The picker's options, as views carrying tags applied with
    ///     ``SwiftCrossUI/View/tag(_:)``.
    ///   - label: A view describing the picker's purpose.
    public init(
        selection: Binding<SelectedValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            label: label(),
            showsLabel: Label.self != EmptyView.self,
            content: content(),
            selection: Self.acceptingNoSelection(selection),
            directOptions: nil
        )
    }

    /// Widens a selection binding so that the picker can represent having no
    /// option selected.
    ///
    /// Writing `nil` back is ignored; a picker only ever writes the tag of an
    /// option that the user chose.
    ///
    /// - Parameter selection: The binding to widen.
    /// - Returns: An optional binding onto the same value.
    private static func acceptingNoSelection(
        _ selection: Binding<SelectedValue>
    ) -> Binding<SelectedValue?> {
        Binding {
            selection.wrappedValue
        } set: { newValue in
            guard let newValue else {
                return
            }
            selection.wrappedValue = newValue
        }
    }

    public var body: some View {
        AnyView(labelledControl)
    }

    /// The picker's control, preceded by its label if it has one worth
    /// showing.
    private var labelledControl: any View {
        let options = resolvedOptions
        let control = environment.pickerStyle.makeView(
            options: options,
            selection: optionBinding(for: options),
            environment: environment
        )

        guard showsLabel else {
            return control
        }
        return HStack {
            label
            AnyView(control)
        }
    }

    /// The options that the picker offers.
    private var resolvedOptions: [PickerOption] {
        guard let directOptions else {
            return PickerOptionCollector.options(of: content, environment: environment)
        }
        return directOptions.enumerated().map { index, value in
            PickerOption(title: "\(value)", tag: AnyHashable(value), index: index)
        }
    }

    /// Bridges the picker's selection to the option that it corresponds to.
    ///
    /// This is the whole of the picker's backend bridging: styles and backends
    /// only ever deal in options and indices, and the mapping between an option
    /// and the selected value happens here.
    ///
    /// - Parameter options: The picker's options.
    /// - Returns: A binding to the currently selected option.
    private func optionBinding(for options: [PickerOption]) -> Binding<PickerOption?> {
        let selection = self.selection
        return Binding {
            guard let value = selection.wrappedValue else {
                return nil
            }
            let selectedTag = AnyHashable(value)
            return options.first { option in
                PickerOption.tag(option.tag, matches: selectedTag)
            }
        } set: { newOption in
            guard let newOption else {
                return
            }
            guard let value = newOption.tag.base as? SelectedValue else {
                logger.warning(
                    "Picker option tag doesn't match the selection's type; ignoring",
                    metadata: [
                        "tagType": "\(type(of: newOption.tag.base))",
                        "selectionType": "\(SelectedValue.self)",
                    ]
                )
                return
            }
            selection.wrappedValue = value
        }
    }
}

extension Picker where Label == Text {
    /// Creates a picker with a text label.
    ///
    /// - Parameters:
    ///   - titleKey: The text describing the picker's purpose.
    ///   - selection: A binding to the value that the selected option stands
    ///     for.
    ///   - content: The picker's options, as views carrying tags applied with
    ///     ``SwiftCrossUI/View/tag(_:)``.
    public init(
        _ titleKey: String,
        selection: Binding<SelectedValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            label: Text(titleKey),
            showsLabel: !titleKey.isEmpty,
            content: content(),
            selection: Self.acceptingNoSelection(selection),
            directOptions: nil
        )
    }
}

extension Picker where Label == EmptyView, Content == EmptyView {
    /// Creates an unlabelled picker over a fixed list of values.
    ///
    /// Each option is displayed as its string interpolation. Prefer
    /// ``init(_:selection:content:)``, which follows SwiftUI's shape and lets
    /// each option carry its own display text.
    ///
    /// - Parameters:
    ///   - options: The options to be offered by the picker.
    ///   - selection: A binding to the picker's selected option.
    public init(of options: [SelectedValue], selection: Binding<SelectedValue?>) {
        self.init(
            label: EmptyView(),
            showsLabel: false,
            content: EmptyView(),
            selection: selection,
            directOptions: options
        )
    }
}

/// One of the options offered by a ``Picker``.
///
/// This is the value type that a ``PickerStyle`` receives; a style displays an
/// option's ``title`` (which is also what interpolating an option into a
/// string gives) and never has to look at its ``tag``.
public struct PickerOption: Equatable, CustomStringConvertible {
    /// The text shown for the option.
    public var title: String
    /// The value that identifies the option, either applied with
    /// ``SwiftCrossUI/View/tag(_:)`` or, for untagged text, the text itself.
    public var tag: AnyHashable
    /// The option's position within the picker's options.
    ///
    /// Part of the option's identity, so that two options which happen to
    /// share a title and a tag stay distinguishable from one another.
    public var index: Int

    /// The option's ``title``, so that a style can interpolate an option
    /// straight into the string that it displays.
    public var description: String {
        title
    }

    /// Creates an option.
    ///
    /// - Parameters:
    ///   - title: The text to show for the option.
    ///   - tag: The value identifying the option.
    ///   - index: The option's position within the picker's options.
    public init(title: String, tag: AnyHashable, index: Int) {
        self.title = title
        self.tag = tag
        self.index = index
    }

    /// Whether a tag identifies the given selection value.
    ///
    /// An optional and its wrapped value are treated as the same value, so
    /// that `.tag(Kind.alpha)` matches a `Binding<Kind?>` holding
    /// `Kind.alpha`. SwiftUI is stricter here, and requiring the optional to
    /// be spelled out is a well known way to end up with a picker that never
    /// shows a selection.
    ///
    /// - Parameters:
    ///   - tag: The tag of one of a picker's options.
    ///   - selection: The picker's current selection.
    /// - Returns: Whether the option is the selected one.
    static func tag(_ tag: AnyHashable, matches selection: AnyHashable) -> Bool {
        if tag == selection {
            return true
        }
        return unwrappingOptionals(tag) == unwrappingOptionals(selection)
    }

    /// Strips any optional layers from a hashable value.
    ///
    /// - Parameter value: The value to unwrap.
    /// - Returns: The innermost wrapped value, or `nil` if any layer was
    ///   `nil`.
    private static func unwrappingOptionals(_ value: AnyHashable) -> AnyHashable? {
        var base: Any = value.base
        while true {
            let mirror = Mirror(reflecting: base)
            guard mirror.displayStyle == .optional else {
                break
            }
            guard let wrapped = mirror.children.first else {
                return nil
            }
            base = wrapped.value
        }
        return base as? AnyHashable
    }
}
