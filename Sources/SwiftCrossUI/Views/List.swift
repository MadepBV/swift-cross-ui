/// A view that displays a scrolling column of rows.
///
/// A list is built either from a collection of values, in which case it renders
/// one row per element and tracks which of them is selected:
///
/// ```swift
/// List(placements, selection: $selectedPlacement) { placement in
///     Text(placement.name)
/// }
/// ```
///
/// ...or from a collection whose rows drive themselves, in which case the
/// selection can be left out entirely:
///
/// ```swift
/// List(definitions) { definition in
///     Button(definition.name) { choose(definition) }
/// }
/// ```
///
/// ...or from a view builder, in which case its rows are written out the same
/// way the rows of a ``Form`` are:
///
/// ```swift
/// List {
///     Section("Drafting layers") {
///         ForEach(layers) { layer in
///             Toggle(layer.name, isOn: visibility(of: layer))
///         }
///     }
/// }
/// ```
///
/// The two forms are laid out differently. The collection form is backed by the
/// platform's own selectable list widget, so its rows highlight and respond to
/// the keyboard the way that platform expects. The view builder form stacks its
/// rows in a ``ScrollView``, exactly like a form, because its rows are
/// arbitrary views rather than a homogeneous collection.
///
/// - Note: The view builder form accepts a `selection` binding for source
///   compatibility, but doesn't drive it. SwiftUI resolves the selection of a
///   row-built list from `tag(_:)` and value-form ``NavigationLink``s attached
///   to individual rows, which the row builder can't see.
public struct List<SelectionValue: Hashable, RowView: View>: View {
    /// How the list was built, which decides how it's laid out.
    enum Storage {
        /// A list of a collection's elements, backed by the platform's
        /// selectable list widget.
        case items(SelectableListView<SelectionValue, RowView>)
        /// A list of arbitrary rows written out in a view builder.
        case rows(RowView)
    }

    /// How the list was built.
    var storage: Storage

    @ViewBuilder
    public var body: some View {
        switch storage {
            case .items(let list):
                list
            case .rows(let rows):
                ListRowsView(content: rows)
        }
    }

    /// Creates a list view.
    ///
    /// - Parameters:
    ///   - data: A collection of `Identifiable` values to construct the list
    ///     from.
    ///   - selection: A binding to the ID of the value that is currently
    ///     selected.
    ///   - rowContent: A view builder that renders a single row of the list.
    ///     Receives an element of `data`.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        selection: Binding<SelectionValue?>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowView
    ) where Data.Element: Identifiable, Data.Element.ID == SelectionValue, Data.Index == Int {
        self.init(data, id: \.id, selection: selection, rowContent: rowContent)
    }

    /// Creates a list view that renders `Text` views based on the elements of
    /// `data`.
    ///
    /// - Parameters:
    ///   - data: A collection of `Identifiable` values to construct the list
    ///     from.
    ///   - selection: A binding to the ID of the value that is currently
    ///     selected.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        selection: Binding<SelectionValue?>
    )
        where
        Data.Element: CustomStringConvertible & Identifiable,
        Data.Element.ID == SelectionValue,
        Data.Index == Int,
        RowView == Text
    {
        self.init(data, selection: selection) { item in
            return Text(item.description)
        }
    }

    /// Creates a list view that renders `Text` views based on the elements of
    /// `data`.
    ///
    /// - Parameters:
    ///   - data: A collection of values to construct the list from.
    ///   - id: A closure that returns the ID to use for a given element of
    ///     `data`.
    ///   - selection: A binding to the ID of the value that is currently
    ///     selected.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        id: @escaping (Data.Element) -> SelectionValue,
        selection: Binding<SelectionValue?>
    ) where Data.Element: CustomStringConvertible, RowView == Text, Data.Index == Int {
        self.init(data, id: id, selection: selection) { item in
            return Text(item.description)
        }
    }

    /// Creates a list view that renders `Text` views based on the elements of
    /// `data`.
    ///
    /// - Parameters:
    ///   - data: A collection of values to construct the list from.
    ///   - id: A key path to the ID to use for an element of `data`.
    ///   - selection: A binding to the ID of the value that is currently
    ///     selected.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        id: KeyPath<Data.Element, SelectionValue>,
        selection: Binding<SelectionValue?>
    ) where Data.Element: CustomStringConvertible, RowView == Text, Data.Index == Int {
        self.init(data, id: id, selection: selection) { item in
            return Text(item.description)
        }
    }

    /// Creates a list view.
    ///
    /// - Parameters:
    ///   - data: A collection of values to construct the list from.
    ///   - id: A key path to the ID to use for an element of `data`.
    ///   - selection: A binding to the ID of the value that is currently
    ///     selected.
    ///   - rowContent: A view builder that renders a single row of the list.
    ///     Receives an element of `data`.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        id: KeyPath<Data.Element, SelectionValue>,
        selection: Binding<SelectionValue?>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowView
    ) where Data.Index == Int {
        self.init(
            data,
            id: { element in element[keyPath: id] },
            selection: selection,
            rowContent: rowContent
        )
    }

    /// Creates a list view.
    ///
    /// - Parameters:
    ///   - data: A collection of values to construct the list from.
    ///   - id: A closure that returns the ID to use for a given element of
    ///     `data`.
    ///   - selection: A binding to the ID of the value that is currently
    ///     selected.
    ///   - rowContent: A view builder that renders a single row of the list.
    ///     Receives an element of `data`.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        id: @escaping (Data.Element) -> SelectionValue,
        selection: Binding<SelectionValue?>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowView
    ) where Data.Index == Int {
        storage = .items(
            SelectableListView(
                data,
                id: id,
                selection: selection,
                rowContent: rowContent
            )
        )
    }

    /// Creates a list whose rows are written out in a view builder, tracking a
    /// selection.
    ///
    /// - Parameters:
    ///   - selection: A binding to the currently selected value. See the note
    ///     on ``List`` for what a row-built list does with it.
    ///   - content: The list's rows.
    public init(
        selection: Binding<SelectionValue?>,
        @ViewBuilder content: () -> RowView
    ) {
        storage = .rows(content())
    }
}

extension List where SelectionValue == Never {
    /// Creates a list whose rows are written out in a view builder.
    ///
    /// - Parameter content: The list's rows.
    public init(@ViewBuilder content: () -> RowView) {
        storage = .rows(content())
    }

    /// Creates a list of a collection's elements, without tracking a
    /// selection.
    ///
    /// This is the form to reach for when the rows drive themselves — a row of
    /// buttons, or of ``NavigationLink``s — and nothing outside the list needs
    /// to know which of them is current:
    ///
    /// ```swift
    /// List(definitions) { definition in
    ///     Button(definition.name) { choose(definition) }
    /// }
    /// ```
    ///
    /// The list is still backed by the platform's own list widget, exactly as
    /// ``init(_:selection:rowContent:)`` is; it simply never reports a
    /// selection.
    ///
    /// - Parameters:
    ///   - data: A collection of `Identifiable` values to construct the list
    ///     from.
    ///   - rowContent: A view builder that renders a single row of the list.
    ///     Receives an element of `data`.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowView
    ) where Data.Element: Identifiable, Data.Index == Int {
        storage = .items(
            SelectableListView(unselectable: data, rowContent: rowContent)
        )
    }

    /// Creates a list of a collection's elements identified by a key path,
    /// without tracking a selection.
    ///
    /// ```swift
    /// List(families, id: \.self) { family in
    ///     familyRow(family)
    /// }
    /// ```
    ///
    /// - Note: `id` is accepted for source compatibility with SwiftUI, whose
    ///   lists use it as the identity of each row. SwiftCrossUI's list matches
    ///   rows up by position instead, so the identifier is not read. It's still
    ///   required, because it's what distinguishes this initializer from
    ///   ``init(_:rowContent:)`` for collections whose elements aren't
    ///   `Identifiable`.
    ///
    /// - Parameters:
    ///   - data: A collection of values to construct the list from.
    ///   - id: A key path to the identity of an element of `data`.
    ///   - rowContent: A view builder that renders a single row of the list.
    ///     Receives an element of `data`.
    public init<Data: RandomAccessCollection, ID: Hashable>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowView
    ) where Data.Index == Int {
        storage = .items(
            SelectableListView(unselectable: data, rowContent: rowContent)
        )
    }
}

/// A list of a collection's elements, backed by the platform's own selectable
/// list widget.
///
/// This is the implementation of every collection-based ``List`` initializer.
struct SelectableListView<SelectionValue: Hashable, RowView: View>: TypeSafeView, View {
    typealias Children = ListViewChildren<PaddingModifierView<RowView>>

    var body = EmptyView()

    /// The current selection, if any.
    var selection: Binding<SelectionValue?>
    /// The selection value identifying the row at a given index.
    ///
    /// `nil` for a list that doesn't track a selection, whose rows stand for no
    /// selection value at all.
    var associatedSelectionValue: (Int) -> SelectionValue?
    /// Renders the row at a given index.
    var rowContent: (Int) -> RowView
    /// The index of the row with a given selection value, if any.
    var find: (SelectionValue) -> Int?
    /// How many rows the list has.
    var rowCount: Int

    /// Creates a selectable list over a collection.
    ///
    /// - Parameters:
    ///   - data: A collection of values to construct the list from.
    ///   - id: A closure that returns the ID to use for a given element of
    ///     `data`.
    ///   - selection: A binding to the ID of the value that is currently
    ///     selected.
    ///   - rowContent: A view builder that renders a single row of the list.
    init<Data: RandomAccessCollection>(
        _ data: Data,
        id: @escaping (Data.Element) -> SelectionValue,
        selection: Binding<SelectionValue?>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowView
    ) where Data.Index == Int {
        self.selection = selection
        self.rowContent = { index in
            rowContent(data[index])
        }
        associatedSelectionValue = { index in
            id(data[index])
        }
        find = { selection in
            data.firstIndex { item in
                id(item) == selection
            }
        }
        rowCount = data.count
    }

    /// Creates a list over a collection that doesn't track a selection.
    ///
    /// The selection binding reads as `nil` and swallows writes, and no row
    /// stands for a selection value, so the platform's list widget is never
    /// told to select anything and never reports a selection back.
    ///
    /// - Parameters:
    ///   - data: A collection of values to construct the list from.
    ///   - rowContent: A view builder that renders a single row of the list.
    init<Data: RandomAccessCollection>(
        unselectable data: Data,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowView
    ) where Data.Index == Int {
        selection = Binding(get: { nil }, set: { _ in })
        associatedSelectionValue = { _ in nil }
        self.rowContent = { index in
            rowContent(data[index])
        }
        find = { _ in nil }
        rowCount = data.count
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        // TODO: Implement snapshotting
        Children()
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        backend.createSelectableListView()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // Padding that the backend could not remove (some frameworks have a small
        // constant amount of required padding within each row).
        let baseRowPadding = backend.baseItemPadding(ofSelectableListView: widget)
        let minimumRowSize = backend.minimumRowSize(ofSelectableListView: widget)
        let horizontalBasePadding = baseRowPadding.axisTotals.x
        let verticalBasePadding = baseRowPadding.axisTotals.y

        let rowViews = (0..<rowCount).map(rowContent).map { rowView in
            PaddingModifierView(
                body: TupleView1(rowView),
                insets: EdgeInsets.Internal(
                    top: max(6 - baseRowPadding.top, 0),
                    bottom: max(6 - baseRowPadding.bottom, 0),
                    leading: max(8 - baseRowPadding.leading, 0),
                    trailing: max(8 - baseRowPadding.trailing, 0)
                )
            )
        }

        if rowCount > children.nodes.count {
            for rowView in rowViews.dropFirst(children.nodes.count) {
                let node = AnyViewGraphNode(
                    for: rowView,
                    backend: backend,
                    environment: environment
                )
                children.nodes.append(node)
            }
        } else if children.nodes.count > rowCount {
            children.nodes.removeLast(children.nodes.count - rowCount)
        }

        var childResults: [ViewLayoutResult] = []
        for (rowView, node) in zip(rowViews, children.nodes) {
            let proposedWidth: Double?
            if let width = proposedSize.width {
                proposedWidth = max(
                    Double(minimumRowSize.x),
                    width - Double(baseRowPadding.axisTotals.x)
                )
            } else {
                proposedWidth = nil
            }

            let childResult = node.computeLayout(
                with: rowView,
                proposedSize: ProposedViewSize(
                    proposedWidth,
                    nil
                ),
                environment: environment
            )
            childResults.append(childResult)
        }

        let height = childResults.map(\.size.height).map { rowHeight in
            max(
                rowHeight + Double(verticalBasePadding),
                Double(minimumRowSize.y)
            )
        }.reduce(0, +)
        let minimumWidth =
            (childResults.map(\.size.width).max() ?? 0) + Double(horizontalBasePadding)
        let size = ViewSize(
            max(proposedSize.width ?? minimumWidth, minimumWidth),
            height
        )

        return ViewLayoutResult(
            size: size,
            childResults: childResults
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let baseRowPadding = backend.baseItemPadding(ofSelectableListView: widget)
        let verticalBasePadding = baseRowPadding.axisTotals.y

        let childResults = children.nodes.map { node in node.commit() }
        backend.setItems(
            ofSelectableListView: widget,
            to: children.widgets.map { widget in widget.into() },
            withRowHeights: childResults.map(\.size.height).map { height in
                LayoutSystem.roundSize(height) + verticalBasePadding
            }
        )

        backend.setSize(of: widget, to: layout.size.vector)
        backend.setSelectionHandler(forSelectableListView: widget) { selectedIndex in
            guard let value = associatedSelectionValue(selectedIndex) else {
                return
            }
            selection.wrappedValue = value
        }

        let selectedIndex: Int?
        if let selectedItem = selection.wrappedValue {
            selectedIndex = find(selectedItem)
        } else {
            selectedIndex = nil
        }

        backend.updateSelectableListView(widget, environment: environment)
        backend.setSelectedItem(ofSelectableListView: widget, toItemAt: selectedIndex)
    }
}

/// A list whose rows were written out in a view builder.
///
/// Its rows are arbitrary views rather than a homogeneous collection, so it
/// stacks them in a ``ScrollView`` the way a ``Form`` does rather than handing
/// them to the platform's selectable list widget.
struct ListRowsView<Content: View>: View {
    /// The vertical spacing between rows.
    private static var rowSpacing: Int { 8 }

    /// The padding above and below the list's rows.
    private static var verticalPadding: Int { 6 }

    /// The list's rows.
    var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Self.rowSpacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.verticalPadding)
        }
        // Rows of a list fill their container's width, just like rows of a
        // form, and `Section` reads this to know that.
        .environment(\.isInsideForm, true)
    }
}

class ListViewChildren<RowView: View>: ViewGraphNodeChildren {
    var nodes: [AnyViewGraphNode<RowView>]

    init() {
        nodes = []
    }

    var erasedNodes: [ErasedViewGraphNode] {
        nodes.map(ErasedViewGraphNode.init)
    }

    var widgets: [AnyWidget] {
        nodes.map(\.widget)
    }
}
