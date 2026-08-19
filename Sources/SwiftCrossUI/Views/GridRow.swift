/// A horizontal row of cells within a ``Grid``.
///
/// Each child of a grid row becomes a cell, and cells that share a position
/// across rows share a column (and therefore a width). A cell can be made to
/// occupy more than one column with ``View/gridCellColumns(_:)``.
///
/// ```swift
/// Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
///     GridRow {
///         Text("Diameter")
///         TextField("", text: $diameter)
///         Text("mm")
///     }
/// }
/// ```
///
/// A row that isn't part of a ``Grid`` can't take part in column negotiation,
/// and lays its cells out like an ``HStack`` would instead. So does a row
/// nested within a cell of an enclosing grid, which belongs to that cell
/// rather than to the grid.
///
/// - Note: A row imposes a layout of its own, so it deliberately isn't a
///   ``GroupingContainer``; a row of an enclosing grid is a row of that grid
///   rather than a set of cells belonging to it.
public struct GridRow<Content: View>: View {
    /// The spacing used by rows that lay themselves out like an ``HStack``
    /// because they aren't part of a grid.
    static var defaultSpacing: Double {
        Grid<EmptyView>.defaultSpacing
    }

    public var body: Content

    /// How the row's cells are aligned vertically. `nil` inherits the vertical
    /// component of the grid's alignment.
    private var alignment: VerticalAlignment?

    /// Creates a row of grid cells.
    ///
    /// - Parameters:
    ///   - alignment: How the row's cells are aligned vertically within the
    ///     row. `nil` inherits the vertical component of the enclosing
    ///     ``Grid``'s alignment.
    ///   - content: The cells of the row.
    public init(
        alignment: VerticalAlignment? = nil,
        @ViewBuilder content: () -> Content
    ) {
        body = content()
        self.alignment = alignment
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
        let cells = layoutableChildren(backend: backend, children: children)
        guard
            let context = environment.containerChildLayout as? GridLayoutContext,
            let rowIndex = context.claimOpenRow()
        else {
            return computeStackLayout(
                widget,
                children: children,
                cells: cells,
                proposedSize: proposedSize,
                environment: environment,
                backend: backend
            )
        }

        switch context.phase {
            case .measuring:
                return measure(
                    cells: cells,
                    rowIndex: rowIndex,
                    context: context,
                    environment: cellEnvironment(environment)
                )
            case .placing:
                return place(
                    cells: cells,
                    rowIndex: rowIndex,
                    context: context,
                    environment: cellEnvironment(environment)
                )
        }
    }

    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let cells = layoutableChildren(backend: backend, children: children)
        guard
            let context = environment.containerChildLayout as? GridLayoutContext,
            let rowIndex = context.claimOpenRow(),
            let placement = context.placement(forRow: rowIndex),
            placement.widths.count == cells.count
        else {
            commitStackLayout(
                widget,
                children: children,
                cells: cells,
                layout: layout,
                environment: environment,
                backend: backend
            )
            return
        }

        backend.setSize(of: widget, to: layout.size.vector)

        let cellResults = cells.map { cell in
            cell.commit()
        }

        let horizontalAlignment = context.alignment.horizontal
        let verticalAlignment = alignment ?? context.alignment.vertical
        for (index, result) in cellResults.enumerated() {
            let x =
                placement.offsets[index]
                + horizontalAlignment.position(
                    ofChild: result.size.width,
                    in: placement.widths[index]
                )
            let y = verticalAlignment.position(
                ofChild: result.size.height,
                in: layout.size.height
            )
            backend.setPosition(
                ofChildAt: index,
                in: widget,
                to: Position(x, y).vector
            )
        }
    }

    /// The environment that a row hands on to its cells.
    ///
    /// A row imposes a layout of its own, so it clears the enclosing grid's
    /// ``ContainerChildLayout`` before proposing to its cells. That's what
    /// stops a ``ForEach`` used as a cell from adding rows to the grid, and
    /// what makes a ``GridRow`` nested within a cell lay itself out like an
    /// ``HStack`` instead of claiming a row of the enclosing grid.
    ///
    /// - Parameter environment: The environment that the row was given.
    /// - Returns: The environment to lay the row's cells out in.
    private func cellEnvironment(
        _ environment: EnvironmentValues
    ) -> EnvironmentValues {
        environment.with(\.containerChildLayout, nil)
    }

    /// Measures each of the row's cells and reports the results to the grid.
    ///
    /// Cells are probed with a zero, unspecified and infinite width so that the
    /// grid knows how much each column can shrink and grow. A cell's column
    /// span comes back through the cell's preferences, which every probe
    /// carries, so it doesn't matter which of the probes a cell answers from
    /// its layout cache.
    ///
    /// - Parameters:
    ///   - cells: The row's cells.
    ///   - rowIndex: The index of the row within the grid.
    ///   - context: The enclosing grid's layout context.
    ///   - environment: The environment to lay the cells out in.
    /// - Returns: The row's ideal layout.
    @MainActor
    private func measure(
        cells: [LayoutSystem.LayoutableChild],
        rowIndex: Int,
        context: GridLayoutContext,
        environment: EnvironmentValues
    ) -> ViewLayoutResult {
        let probingEnvironment = environment.with(\.allowLayoutCaching, true)

        var measurements: [GridLayoutContext.CellMeasurement] = []
        var cellResults: [ViewLayoutResult] = []
        var width = 0.0
        var height = 0.0
        for cell in cells {
            let ideal = cell.computeLayout(
                proposedSize: .unspecified,
                environment: environment
            )
            let minimum = cell.computeLayout(
                proposedSize: ProposedViewSize(0, nil),
                environment: probingEnvironment
            )
            let maximum = cell.computeLayout(
                proposedSize: ProposedViewSize(Double.infinity, nil),
                environment: probingEnvironment
            )

            measurements.append(
                GridLayoutContext.CellMeasurement(
                    span: max(ideal.preferences.gridCellColumns ?? 1, 1),
                    minimumWidth: min(minimum.size.width, ideal.size.width),
                    idealWidth: ideal.size.width,
                    maximumWidth: max(maximum.size.width, ideal.size.width)
                )
            )
            cellResults.append(ideal)
            width += ideal.size.width
            height = max(height, ideal.size.height)
        }

        context.setMeasurements(measurements, forRow: rowIndex)
        width += context.horizontalSpacing * Double(max(cells.count - 1, 0))

        return ViewLayoutResult(
            size: ViewSize(width, height),
            participateInStackLayoutsWhenEmpty: cellResults
                .contains(where: \.participateInStackLayoutsWhenEmpty),
            preferences: Self.preferences(ofCells: cellResults)
        )
    }

    /// Lays the row's cells out within the grid's negotiated columns.
    ///
    /// - Parameters:
    ///   - cells: The row's cells.
    ///   - rowIndex: The index of the row within the grid.
    ///   - context: The enclosing grid's layout context.
    ///   - environment: The environment to lay the cells out in.
    /// - Returns: The row's layout.
    @MainActor
    private func place(
        cells: [LayoutSystem.LayoutableChild],
        rowIndex: Int,
        context: GridLayoutContext,
        environment: EnvironmentValues
    ) -> ViewLayoutResult {
        guard
            let measurements = context.measurements(forRow: rowIndex),
            measurements.count == cells.count
        else {
            // The row somehow didn't get measured, so there's nothing sensible
            // that we can lay out against.
            return ViewLayoutResult(size: .zero, childResults: [])
        }

        var offsets: [Double] = []
        var widths: [Double] = []
        var column = 0
        for measurement in measurements {
            let geometry = context.geometry(
                ofColumnsStartingAt: column,
                span: measurement.span
            )
            offsets.append(geometry.offset)
            widths.append(geometry.width)
            column += measurement.span
        }

        // Work out how tall the row needs to be before proposing a final size,
        // so that cells which fill the space available to them fill the whole
        // row rather than just their own ideal height.
        var height = 0.0
        for (index, cell) in cells.enumerated() {
            let result = cell.computeLayout(
                proposedSize: ProposedViewSize(widths[index], nil),
                environment: environment.with(\.allowLayoutCaching, true)
            )
            height = max(height, result.size.height)
        }

        var cellResults: [ViewLayoutResult] = []
        var finalHeight = height
        for (index, cell) in cells.enumerated() {
            let result = cell.computeLayout(
                proposedSize: ProposedViewSize(widths[index], height),
                environment: environment
            )
            cellResults.append(result)
            finalHeight = max(finalHeight, result.size.height)
        }

        context.setPlacement(
            GridLayoutContext.RowPlacement(offsets: offsets, widths: widths),
            forRow: rowIndex
        )

        return ViewLayoutResult(
            size: ViewSize(context.totalWidth, finalHeight),
            participateInStackLayoutsWhenEmpty: cellResults
                .contains(where: \.participateInStackLayoutsWhenEmpty),
            preferences: Self.preferences(ofCells: cellResults)
        )
    }

    /// Merges the preferences of a row's cells.
    ///
    /// A cell's column span is a message to the row that contains it, so the
    /// row consumes it rather than passing it on to the grid (which would
    /// otherwise hand it to whatever contains the grid).
    ///
    /// - Parameter cellResults: The layouts of the row's cells.
    /// - Returns: The preferences that the row reports.
    private static func preferences(
        ofCells cellResults: [ViewLayoutResult]
    ) -> PreferenceValues {
        PreferenceValues(merging: cellResults.map(\.preferences))
            .with(\.gridCellColumns, nil)
    }

    /// The environment used by rows that aren't part of a grid, which lay
    /// themselves out like an ``HStack``.
    ///
    /// - Parameter environment: The environment that the row was given.
    /// - Returns: An environment describing a horizontal stack layout.
    private func stackEnvironment(
        _ environment: EnvironmentValues
    ) -> EnvironmentValues {
        let context = environment.containerChildLayout as? GridLayoutContext
        let spacing = context?.horizontalSpacing ?? Self.defaultSpacing
        return environment
            .with(\.layoutOrientation, .horizontal)
            .with(\.layoutAlignment, (alignment ?? .center).asStackAlignment)
            .with(\.layoutSpacing, Int(spacing.rounded()))
    }

    /// Lays the row out like an ``HStack`` for when it isn't part of a grid.
    ///
    /// - Parameters:
    ///   - widget: The row's widget.
    ///   - children: The row's child nodes.
    ///   - cells: The row's cells.
    ///   - proposedSize: The size proposed by the row's parent.
    ///   - environment: The environment to lay the cells out in.
    ///   - backend: The app's backend.
    /// - Returns: The row's layout.
    @MainActor
    private func computeStackLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        cells: [LayoutSystem.LayoutableChild],
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        var cache = (children as? TupleViewChildren)?.stackLayoutCache ?? StackLayoutCache.initial
        let result = LayoutSystem.computeStackLayout(
            container: widget,
            children: cells,
            cache: &cache,
            proposedSize: proposedSize,
            environment: stackEnvironment(environment),
            backend: backend
        )
        (children as? TupleViewChildren)?.stackLayoutCache = cache
        return result
    }

    /// Commits a layout produced by
    /// ``computeStackLayout(_:children:cells:proposedSize:environment:backend:)``.
    ///
    /// - Parameters:
    ///   - widget: The row's widget.
    ///   - children: The row's child nodes.
    ///   - cells: The row's cells.
    ///   - layout: The layout to commit.
    ///   - environment: The environment that the cells were laid out in.
    ///   - backend: The app's backend.
    @MainActor
    private func commitStackLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        cells: [LayoutSystem.LayoutableChild],
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        var cache = (children as? TupleViewChildren)?.stackLayoutCache ?? StackLayoutCache.initial
        LayoutSystem.commitStackLayout(
            container: widget,
            children: cells,
            cache: &cache,
            layout: layout,
            environment: stackEnvironment(environment),
            backend: backend
        )
        (children as? TupleViewChildren)?.stackLayoutCache = cache
    }
}
