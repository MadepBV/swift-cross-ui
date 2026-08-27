/// A container view that arranges its children in a two-dimensional grid.
///
/// Unlike nested stacks, a grid measures every cell of every row before it
/// lays anything out, and then gives all cells that share a column the same
/// width. That column-wide negotiation is what makes grids the right tool for
/// tables of labelled values, where nested stacks would let each row choose
/// its own column widths.
///
/// ```swift
/// Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
///     GridRow {
///         Text("Width")
///         TextField("", text: $width)
///         Text("mm")
///     }
///     GridRow {
///         Text("Height")
///         TextField("", text: $height)
///         Text("mm")
///     }
/// }
/// ```
///
/// A cell can be made to span multiple columns with
/// ``View/gridCellColumns(_:)``.
///
/// Grouping containers are transparent to the grid: each row produced by a
/// ``ForEach`` (or held by a ``Group``, including a ``ForEach`` nested within
/// one) becomes a row of the grid in its own right and takes part in column
/// negotiation just like a row written directly inside the grid. Containers
/// that impose a layout of their own, such as ``VStack``, stay a single row,
/// and so does a ``ForEach`` used as a cell of a row. See
/// ``ContainerChildLayout`` for how that works.
///
/// A row produced by a container keeps living inside that container's widget,
/// which the grid sizes to its own bounds and places at its own origin, so
/// such a row still ends up exactly where it would have been had it been
/// written out directly.
///
/// - Important: A child of a grid that isn't a ``GridRow`` becomes a row of
///   its own, spanning the grid's full width.
public struct Grid<Content: View>: View {
    /// The spacing used when the developer doesn't specify any.
    ///
    /// Matches ``VStack``'s default spacing so that grids look at home
    /// alongside the framework's other containers.
    static var defaultSpacing: Double {
        Double(VStack<EmptyView>.defaultSpacing)
    }

    public var body: Content

    /// How cells are aligned within the space allotted to them.
    private var alignment: Alignment
    /// The amount of spacing between neighbouring columns.
    private var horizontalSpacing: Double
    /// The amount of spacing between neighbouring rows.
    private var verticalSpacing: Double

    /// Creates a grid with the given spacing and alignment.
    ///
    /// - Parameters:
    ///   - alignment: How each cell is aligned within the space allotted to it
    ///     by the grid. A row can override the vertical component of this
    ///     alignment via ``GridRow/init(alignment:content:)``.
    ///   - horizontalSpacing: The amount of spacing between columns. `nil`
    ///     uses ``Grid/defaultSpacing``.
    ///   - verticalSpacing: The amount of spacing between rows. `nil` uses
    ///     ``Grid/defaultSpacing``.
    ///   - content: The rows of the grid.
    public init(
        alignment: Alignment = .center,
        horizontalSpacing: Double? = nil,
        verticalSpacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) {
        body = content()
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing ?? Self.defaultSpacing
        self.verticalSpacing = verticalSpacing ?? Self.defaultSpacing
    }

    public func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        GridChildren(
            wrapping: defaultChildren(
                backend: backend,
                snapshots: snapshots,
                environment: environment
            )
        )
    }

    public func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: any ViewGraphNodeChildren
    ) -> [LayoutSystem.LayoutableChild] {
        guard let children = children as? GridChildren else {
            logUnexpectedChildren(children)
            return []
        }
        var layoutableChildren = body.layoutableChildren(
            backend: backend,
            children: children.wrapped
        )
        LayoutSystem.markGroupingContainers(&layoutableChildren, using: children.wrapped)
        return layoutableChildren
    }

    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        for (index, child) in children.widgets(for: backend).enumerated() {
            backend.insert(child, into: container, at: index)
        }
        return container
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        guard let gridChildren = children as? GridChildren else {
            logUnexpectedChildren(children)
            return .leafView(size: .zero)
        }

        let rows = layoutableChildren(backend: backend, children: children)
        let context = gridChildren.context
        context.beginLayoutPass(
            alignment: alignment,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )

        // Measurement pass. Every row reports the minimum, ideal and maximum
        // width of each of its cells (along with the cell's column span) so
        // that we can negotiate a width for each column.
        //
        // The two passes deliberately propose differently shaped sizes because
        // the view graph reuses a node's layout whenever it gets proposed the
        // same size twice in a row, and a reused row never reports its
        // measurements. It's the same reason ``LazyVGrid`` measures before it
        // places.
        context.beginPhase(.measuring)
        for row in rows {
            context.addParticipant(row, environment: environment)
        }

        // Negotiate the column widths.
        context.resolveColumnWidths(proposedWidth: proposedSize.width)

        // Placement pass. Rows now know how wide each of their cells may be.
        context.beginPhase(.placing)
        var rowResults: [ViewLayoutResult] = []
        rowResults.reserveCapacity(rows.count)
        for row in rows {
            rowResults.append(context.addParticipant(row, environment: environment))
        }
        context.finishLayoutPass()

        return ViewLayoutResult(
            size: context.participantAreaSize,
            childResults: rowResults,
            participateInStackLayoutsWhenEmpty: context.participateInStackLayoutsWhenEmpty
        )
    }

    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.setSize(of: widget, to: layout.size.vector)

        guard let gridChildren = children as? GridChildren else {
            logUnexpectedChildren(children)
            return
        }

        let context = gridChildren.context
        context.beginCommitPass()

        let rows = layoutableChildren(backend: backend, children: children)
        for (index, row) in rows.enumerated() {
            let placement = context.commitNextParticipant(row)
            backend.setPosition(
                ofChildAt: index,
                in: widget,
                to: placement.position
            )
        }
    }

    /// Warns that the grid received children that it didn't create.
    ///
    /// - Parameter children: The unexpected children.
    private func logUnexpectedChildren(_ children: any ViewGraphNodeChildren) {
        logger.warning(
            "Grid received children that it didn't create; layout skipped",
            metadata: [
                "childrenType": "\(type(of: children))",
                "contentType": "\(Content.self)",
            ]
        )
    }
}

/// The children of a ``Grid``.
///
/// Wraps the content's own children so that the grid has somewhere to persist
/// its ``GridLayoutContext`` between the layout phase and the commit phase (the
/// same role that `stackLayoutCache` plays for stack layouts).
class GridChildren: ViewGraphNodeChildren {
    /// The content's own children.
    let wrapped: any ViewGraphNodeChildren

    /// The grid's row layout, shared with the grid's rows and with any
    /// grouping containers nested inside the grid.
    let context = GridLayoutContext()

    var widgets: [AnyWidget] {
        wrapped.widgets
    }

    var erasedNodes: [ErasedViewGraphNode] {
        wrapped.erasedNodes
    }

    /// Wraps a grid's content's children.
    ///
    /// - Parameter wrapped: The content's own children.
    init(wrapping wrapped: any ViewGraphNodeChildren) {
        self.wrapped = wrapped
    }
}

/// The row layout of a single ``Grid``.
///
/// Every view that becomes a row of the grid is handed to this by either the
/// grid itself or by a grouping container nested inside the grid (see
/// ``ContainerChildLayout``), which is what lets the rows of a ``ForEach``
/// take part in column negotiation.
///
/// Rows report their cell measurements during the
/// ``GridLayoutContext/Phase/measuring`` phase and read back the negotiated
/// column widths during the ``GridLayoutContext/Phase/placing`` phase. The
/// placements recorded during the placing phase are then consumed when the
/// rows commit their layouts.
///
/// This is an internal helper type; it lives alongside ``Grid`` because both
/// ``Grid`` and ``GridRow`` need it.
final class GridLayoutContext: ContainerChildLayout {
    /// The stage of the grid's layout algorithm that's currently running.
    enum Phase {
        /// Rows are reporting the sizing behaviour of their cells.
        case measuring
        /// Rows are laying their cells out within the negotiated columns.
        case placing
    }

    /// How a single cell of a row behaves when laid out.
    struct CellMeasurement {
        /// The number of columns that the cell spans.
        var span: Int
        /// The cell's width when proposed a width of zero.
        var minimumWidth: Double
        /// The cell's width when proposed an unspecified width.
        var idealWidth: Double
        /// The cell's width when proposed an infinite width.
        var maximumWidth: Double
    }

    /// Where a row's cells sit within the grid's columns.
    struct RowPlacement {
        /// The x offset of each cell relative to the row.
        var offsets: [Double]
        /// The width allotted to each cell.
        var widths: [Double]
    }

    /// How each cell is aligned within the space allotted to it.
    private(set) var alignment: Alignment = .center
    /// The amount of spacing between neighbouring columns.
    private(set) var horizontalSpacing: Double = 0
    /// The amount of spacing between neighbouring rows.
    private(set) var verticalSpacing: Double = 0

    /// The stage of the layout algorithm that's currently running.
    private(set) var phase: Phase = .measuring
    /// The negotiated width of each column.
    private(set) var columnWidths: [Double] = []
    /// The measurements of each row's cells, keyed by row index.
    private var measurements: [Int: [CellMeasurement]] = [:]
    /// The placements of each row's cells, keyed by row index.
    private var placements: [Int: RowPlacement] = [:]
    /// The index that the next row to take part will be given.
    private var rowCursor = 0
    /// The index of the row that the participant currently being laid out (or
    /// committed) may act as, until a ``GridRow`` claims it.
    private var openRow: Int?
    /// The layout reported by each row of the most recent placing phase, in
    /// row order.
    private var rowResults: [ViewLayoutResult] = []
    /// How many rows have been committed during the current commit pass.
    private var commitCursor = 0
    /// The y offset that the next committed row is placed at.
    private var commitOffset = 0.0

    private(set) var participantAreaSize: ViewSize = .zero

    /// The total width of the grid's columns, including the spacing between
    /// them.
    var totalWidth: Double {
        let content = columnWidths.reduce(0, +)
        let spacing = horizontalSpacing * Double(max(columnWidths.count - 1, 0))
        return content + spacing
    }

    /// Whether the grid should take part in stack layouts even when it has no
    /// size of its own.
    var participateInStackLayoutsWhenEmpty: Bool {
        rowResults.contains(where: \.participateInStackLayoutsWhenEmpty)
    }

    /// Prepares the context for a fresh layout computation.
    ///
    /// - Parameters:
    ///   - alignment: How each cell is aligned within the space allotted to it.
    ///   - horizontalSpacing: The amount of spacing between columns.
    ///   - verticalSpacing: The amount of spacing between rows.
    func beginLayoutPass(
        alignment: Alignment,
        horizontalSpacing: Double,
        verticalSpacing: Double
    ) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        measurements = [:]
        placements = [:]
    }

    /// Moves the context on to the given phase, ready to receive every row
    /// once more.
    ///
    /// - Parameter phase: The phase that's about to run.
    func beginPhase(_ phase: Phase) {
        self.phase = phase
        rowCursor = 0
        openRow = nil
        rowResults = []
    }

    /// Claims the row that the grid is currently laying out or committing.
    ///
    /// Only the outermost ``GridRow`` of a participant may act as a row of the
    /// grid; a row nested within one of that row's cells gets `nil` and lays
    /// itself out like an ``HStack`` instead.
    ///
    /// - Returns: The index of the row within the grid, or `nil` if the grid
    ///   isn't currently expecting a row.
    func claimOpenRow() -> Int? {
        guard let openRow else {
            return nil
        }
        self.openRow = nil
        return openRow
    }

    @discardableResult
    func addParticipant(
        _ participant: LayoutSystem.LayoutableChild,
        environment: EnvironmentValues
    ) -> ViewLayoutResult {
        let index = rowCursor
        openRow = index

        let proposedSize: ProposedViewSize =
            switch phase {
                case .measuring:
                    .unspecified
                case .placing:
                    ProposedViewSize(totalWidth, nil)
            }

        // Layout caching has to be off for every participant, not just for the
        // grouping containers among them the way ``LazyVGrid`` does it. A row
        // reports its cell measurements as a side effect of computing its
        // layout, and the grid needs every row's measurements to negotiate its
        // columns, so a row that answers from its layout cache leaves the grid
        // believing that it has no columns at all. Enabling caching for
        // ordinary participants fails `columnsAreNegotiatedWhileProbing` (the
        // grid comes out of probing zero points wide) and enabling it for
        // grouping containers too additionally stops them registering their
        // rows. Turning caching off is safe because the last proposal that
        // every row receives is always the placing pass's.
        let result = participant.computeLayout(
            proposedSize: proposedSize,
            environment: environment
                .with(\.containerChildLayout, self)
                .with(\.allowLayoutCaching, false)
        )
        openRow = nil

        guard !participant.isGroupingContainer, rowCursor == index else {
            // A nested grouping container took over and registered its own
            // rows, so it isn't a row of its own.
            return result
        }
        rowCursor += 1
        rowResults.append(result)
        return result
    }

    /// Resolves the grid's overall size once every row has been placed.
    func finishLayoutPass() {
        var width = totalWidth
        var height = 0.0
        var visibleRowCount = 0
        for result in rowResults where result.participatesInStackLayouts {
            width = max(width, result.size.width)
            height += result.size.height
            visibleRowCount += 1
        }
        height += verticalSpacing * Double(max(visibleRowCount - 1, 0))
        participantAreaSize = ViewSize(width, height)
    }

    /// Prepares the context to hand out the positions it resolved.
    func beginCommitPass() {
        commitCursor = 0
        commitOffset = 0
        openRow = nil
    }

    func commitNextParticipant(
        _ participant: LayoutSystem.LayoutableChild
    ) -> (position: SIMD2<Int>, result: ViewLayoutResult) {
        let index = commitCursor
        openRow = index
        let result = participant.commit()
        openRow = nil

        guard !participant.isGroupingContainer, commitCursor == index else {
            // A nested grouping container committed its own rows, so it covers
            // the whole participant area.
            return (.zero, result)
        }
        commitCursor += 1

        guard result.participatesInStackLayouts else {
            return (Position(0, commitOffset).vector, result)
        }

        // Rows generally take up the grid's full width, but views that aren't
        // grid rows get aligned like any other cell would.
        let x = alignment.horizontal.position(
            ofChild: result.size.width,
            in: participantAreaSize.width
        )
        let position = Position(x, commitOffset).vector
        commitOffset += result.size.height + verticalSpacing
        return (position, result)
    }

    /// Records the measurements of a row's cells.
    ///
    /// - Parameters:
    ///   - measurements: The measurement of each of the row's cells, in order.
    ///   - row: The index of the row within the grid.
    func setMeasurements(_ measurements: [CellMeasurement], forRow row: Int) {
        self.measurements[row] = measurements
    }

    /// Gets the measurements recorded for a row's cells.
    ///
    /// - Parameter row: The index of the row within the grid.
    /// - Returns: The row's measurements, or `nil` if the row wasn't measured.
    func measurements(forRow row: Int) -> [CellMeasurement]? {
        measurements[row]
    }

    /// Records where a row's cells ended up.
    ///
    /// - Parameters:
    ///   - placement: The offset and allotted width of each of the row's cells.
    ///   - row: The index of the row within the grid.
    func setPlacement(_ placement: RowPlacement, forRow row: Int) {
        placements[row] = placement
    }

    /// Gets the placement recorded for a row's cells.
    ///
    /// - Parameter row: The index of the row within the grid.
    /// - Returns: The row's placement, or `nil` if the row wasn't placed.
    func placement(forRow row: Int) -> RowPlacement? {
        placements[row]
    }

    /// Computes the geometry of a run of columns.
    ///
    /// - Parameters:
    ///   - column: The index of the first column of the run.
    ///   - span: The number of columns in the run.
    /// - Returns: The x offset of the run relative to the row, and the width
    ///   available to a cell occupying the whole run (which includes the
    ///   spacing between the spanned columns).
    func geometry(
        ofColumnsStartingAt column: Int,
        span: Int
    ) -> (offset: Double, width: Double) {
        var offset = 0.0
        for index in 0..<min(column, columnWidths.count) {
            offset += columnWidths[index] + horizontalSpacing
        }

        let end = min(column + max(span, 1), columnWidths.count)
        guard column < end else {
            return (offset, 0)
        }

        var width = 0.0
        for index in column..<end {
            width += columnWidths[index]
        }
        width += horizontalSpacing * Double(end - column - 1)
        return (offset, width)
    }

    /// Negotiates a width for every column from the measurements reported by
    /// the grid's rows.
    ///
    /// Every column is first given the largest ideal width of the cells that
    /// occupy it alone, and cells spanning multiple columns then widen the
    /// columns that they span if they don't fit. The resulting content width
    /// is grown or shrunk to match `proposedWidth` if one was given.
    ///
    /// - Parameter proposedWidth: The width proposed to the grid, if any.
    func resolveColumnWidths(proposedWidth: Double?) {
        let rows = Array(measurements.values)
        var columnCount = 0
        for cells in rows {
            let spanned = cells.reduce(0) { total, cell in
                total + cell.span
            }
            columnCount = max(columnCount, spanned)
        }

        guard columnCount > 0 else {
            columnWidths = []
            return
        }

        var minimums = [Double](repeating: 0, count: columnCount)
        var ideals = [Double](repeating: 0, count: columnCount)
        var maximums = [Double](repeating: 0, count: columnCount)

        // Cells that occupy a single column define the baseline widths, and
        // this is where a column's width becomes shared across all rows.
        var spanningCells: [(column: Int, cell: CellMeasurement)] = []
        for cells in rows {
            var column = 0
            for cell in cells {
                if column >= columnCount {
                    break
                } else if cell.span > 1 {
                    spanningCells.append((column, cell))
                } else {
                    minimums[column] = max(minimums[column], cell.minimumWidth)
                    ideals[column] = max(ideals[column], cell.idealWidth)
                    maximums[column] = max(maximums[column], cell.maximumWidth)
                }
                column += cell.span
            }
        }

        // Cells that span multiple columns only widen columns when the columns
        // that they span can't already accommodate them. Narrower spans are
        // applied first so that wider spans see their effect.
        spanningCells.sort { first, second in
            first.cell.span < second.cell.span
        }
        for entry in spanningCells {
            let end = min(entry.column + entry.cell.span, columnCount)
            let range = entry.column..<end
            let spacing = horizontalSpacing * Double(max(range.count - 1, 0))
            distribute(entry.cell.minimumWidth - spacing, over: range, in: &minimums)
            distribute(entry.cell.idealWidth - spacing, over: range, in: &ideals)
            distribute(entry.cell.maximumWidth - spacing, over: range, in: &maximums)
        }

        var widths = ideals
        for index in widths.indices {
            minimums[index] = min(minimums[index], widths[index])
            maximums[index] = max(maximums[index], widths[index])
        }

        guard let proposedWidth else {
            columnWidths = widths
            return
        }

        let spacing = horizontalSpacing * Double(columnCount - 1)
        let available = proposedWidth - spacing
        let content = widths.reduce(0, +)
        if available > content {
            grow(&widths, upTo: maximums, by: available - content)
        } else if available < content {
            shrink(&widths, downTo: minimums, by: content - available)
        }
        columnWidths = widths
    }

    /// Widens a run of columns until they can jointly accommodate a width.
    ///
    /// - Parameters:
    ///   - required: The width that the columns need to accommodate.
    ///   - range: The columns to widen.
    ///   - widths: The widths to update.
    private func distribute(
        _ required: Double,
        over range: Range<Int>,
        in widths: inout [Double]
    ) {
        guard !range.isEmpty else {
            return
        }

        guard required.isFinite else {
            for index in range {
                widths[index] = .infinity
            }
            return
        }

        var total = 0.0
        for index in range {
            total += widths[index]
        }

        let deficit = required - total
        guard deficit > 0, deficit.isFinite else {
            return
        }

        let share = deficit / Double(range.count)
        for index in range {
            widths[index] += share
        }
    }

    /// Distributes surplus space evenly between the columns that can use it,
    /// never taking a column past its maximum width.
    ///
    /// - Parameters:
    ///   - widths: The widths to grow.
    ///   - maximums: The maximum width of each column.
    ///   - amount: The amount of surplus space to distribute. May be infinite,
    ///     in which case every flexible column takes its maximum width (which
    ///     is how a grid reports that it's flexible to its parent).
    private func grow(
        _ widths: inout [Double],
        upTo maximums: [Double],
        by amount: Double
    ) {
        var remaining = amount
        var flexible = widths.indices.filter { index in
            maximums[index] > widths[index]
        }

        guard amount.isFinite else {
            for index in flexible {
                widths[index] = maximums[index]
            }
            return
        }

        while remaining > 0.0001 && !flexible.isEmpty {
            let share = remaining / Double(flexible.count)
            var stillFlexible: [Int] = []
            for index in flexible {
                let capacity = maximums[index] - widths[index]
                let granted = min(share, capacity)
                widths[index] += granted
                remaining -= granted
                if capacity > granted {
                    stillFlexible.append(index)
                }
            }

            // Either every column took its full share (so there's nothing
            // left to distribute) or we'd loop forever.
            if stillFlexible.count == flexible.count {
                break
            }
            flexible = stillFlexible
        }
    }

    /// Removes excess width from the columns in proportion to how much each of
    /// them can shrink, never taking a column past its minimum width.
    ///
    /// - Parameters:
    ///   - widths: The widths to shrink.
    ///   - minimums: The minimum width of each column.
    ///   - amount: The amount of space to reclaim.
    private func shrink(
        _ widths: inout [Double],
        downTo minimums: [Double],
        by amount: Double
    ) {
        let shrinkable = widths.indices.map { index in
            max(widths[index] - minimums[index], 0)
        }
        let total = shrinkable.reduce(0, +)
        guard total > 0 else {
            return
        }

        let fraction = min(amount / total, 1)
        for index in widths.indices {
            widths[index] -= shrinkable[index] * fraction
        }
    }
}
