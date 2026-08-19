extension View {
    /// Tells a view that acts as a cell in a ``Grid`` to span the specified
    /// number of columns.
    ///
    /// ```swift
    /// Grid(alignment: .leading) {
    ///     GridRow {
    ///         Text("Reinforcement")
    ///             .gridCellColumns(2)
    ///     }
    ///     GridRow {
    ///         Text("Diameter")
    ///         TextField("", text: $diameter)
    ///     }
    /// }
    /// ```
    ///
    /// A spanning cell only widens the columns that it spans when they can't
    /// already accommodate it, and any extra width it needs is shared evenly
    /// between them.
    ///
    /// Has no effect on views that aren't cells of a grid.
    ///
    /// - Parameter count: The number of columns that the cell spans. Values
    ///   below one are treated as one.
    /// - Returns: A view that spans `count` columns when used as a grid cell.
    public func gridCellColumns(_ count: Int) -> some View {
        GridCellColumnsModifier(self, count: count)
    }
}

/// A view that reports its child's column span to the enclosing ``GridRow``.
///
/// The span travels up through the cell's preferences, so a row learns it from
/// the same probe that tells the row how wide the cell wants to be, and the
/// outermost modifier of a cell wins.
struct GridCellColumnsModifier<Child: View>: View {
    var body: TupleView1<Child>
    /// The number of columns that the child spans.
    var count: Int

    /// Creates a view that spans multiple grid columns.
    ///
    /// - Parameters:
    ///   - child: The cell's content.
    ///   - count: The number of columns that the cell spans.
    init(_ child: Child, count: Int) {
        body = TupleView1(child)
        self.count = count
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        var result = body.computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
        result.preferences = result.preferences.with(
            \.gridCellColumns,
            max(count, 1)
        )
        return result
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        body.commit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )
    }
}
