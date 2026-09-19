import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing for grid layouts")
struct GridTests {
    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    @MainActor
    @Test("Cells in the same column share a width across rows")
    func columnsShareWidthAcrossRows() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("Diameter")
                Text("A")
            }
            GridRow {
                Text("W")
                Text("B")
            }
        }

        let node = committedNode(for: view)
        let rows = try container(node.widget).children
        let firstRow = try container(rows[0].widget)
        let secondRow = try container(rows[1].widget)

        // The second column starts at the same offset in both rows even though
        // the first row's first cell is much wider than the second row's.
        let firstColumnWidth = width(of: Text("Diameter"))
        #expect(firstRow.children[1].position.x == secondRow.children[1].position.x)
        #expect(Double(firstRow.children[1].position.x) == firstColumnWidth + 8)

        // Sanity check: the cells really are different widths, so the shared
        // offset can only come from the column negotiation.
        #expect(firstRow.children[0].widget.size.x != secondRow.children[0].widget.size.x)
    }

    @MainActor
    @Test("Grid sizes itself to its columns and spacing")
    func gridSizeMatchesColumns() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("Diameter")
                Text("A")
            }
            GridRow {
                Text("W")
                Text("B")
            }
        }

        let node = committedNode(for: view)
        let expectedWidth = width(of: Text("Diameter")) + 8 + width(of: Text("A"))
        #expect(Double(node.widget.size.x) == expectedWidth)

        let rowHeight = height(of: Text("A"))
        #expect(Double(node.widget.size.y) == rowHeight * 2 + 4)
    }

    @MainActor
    @Test("Rows are stacked vertically with the grid's vertical spacing")
    func rowsAreStackedVertically() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("A")
            }
            GridRow {
                Text("B")
            }
        }

        let node = committedNode(for: view)
        let rows = try container(node.widget).children
        let rowHeight = height(of: Text("A"))

        #expect(rows[0].position == SIMD2(0, 0))
        #expect(rows[1].position == SIMD2(0, Int(rowHeight) + 4))
    }

    @MainActor
    @Test("Cells honour the grid's alignment within their column")
    func cellsAreAlignedWithinTheirColumn() throws {
        let leadingGrid = Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Text("AAAA")
            }
            GridRow {
                Text("A")
            }
        }
        let trailingGrid = Grid(alignment: .trailing, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Text("AAAA")
            }
            GridRow {
                Text("A")
            }
        }

        let leadingRows = try container(committedNode(for: leadingGrid).widget).children
        let trailingRows = try container(committedNode(for: trailingGrid).widget).children
        let narrowCellWidth = width(of: Text("A"))
        let columnWidth = width(of: Text("AAAA"))

        #expect(try container(leadingRows[1].widget).children[0].position.x == 0)
        #expect(
            Double(try container(trailingRows[1].widget).children[0].position.x)
                == columnWidth - narrowCellWidth
        )
    }

    @MainActor
    @Test("gridCellColumns widens the columns that a cell spans")
    func spanningCellWidensColumns() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 0) {
            GridRow {
                Text("AAAAAAAAAA")
                    .gridCellColumns(2)
            }
            GridRow {
                Text("A")
                Text("A")
            }
        }

        let node = committedNode(for: view)
        let spanningWidth = width(of: Text("AAAAAAAAAA"))
        let narrowWidth = width(of: Text("A"))

        // The two narrow columns can't accommodate the spanning cell on their
        // own, so they're widened (evenly) until they can.
        #expect(Double(node.widget.size.x) == spanningWidth)

        let rows = try container(node.widget).children
        let secondRow = try container(rows[1].widget)
        let columnWidth = (spanningWidth - 8) / 2
        #expect(Double(secondRow.children[1].position.x) == columnWidth + 8)

        // The spanning cell itself gets the full width of both columns.
        #expect(Double(rows[0].widget.size.x) == spanningWidth)
        #expect(narrowWidth < columnWidth)
    }

    @MainActor
    @Test("gridCellColumns leaves wide enough columns alone")
    func spanningCellFitsWithinExistingColumns() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 0) {
            GridRow {
                Text("AA")
                    .gridCellColumns(2)
            }
            GridRow {
                Text("AAAA")
                Text("AAAA")
            }
        }

        let node = committedNode(for: view)
        let expectedWidth = width(of: Text("AAAA")) * 2 + 8
        #expect(Double(node.widget.size.x) == expectedWidth)
    }

    @MainActor
    @Test("Flexible columns absorb space that the grid is offered")
    func flexibleColumnsAbsorbExtraSpace() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Text("AA")
                Color.blue
            }
        }

        let proposedWidth = 400.0
        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(proposedWidth, 100)
        )

        // The text column can't grow, so all of the extra space goes to the
        // colour, which can.
        #expect(Double(node.widget.size.x) == proposedWidth)

        let rows = try container(node.widget).children
        let cells = try container(rows[0].widget).children
        #expect(Double(cells[0].widget.size.x) == width(of: Text("AA")))
        #expect(Double(cells[1].widget.size.x) == proposedWidth - width(of: Text("AA")))
    }

    @MainActor
    @Test("Columns shrink when the grid is offered less space than it wants")
    func columnsShrinkToFitProposal() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Text("AAAA")
                Text("AAAA")
            }
        }

        let idealWidth = width(of: Text("AAAA"))
        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(idealWidth, 100)
        )

        // Both columns can shrink by the same amount, so they each give up
        // half of the shortfall.
        #expect(Double(node.widget.size.x) == idealWidth)
    }

    @MainActor
    @Test("Columns still line up when the grid's parent probes it")
    func columnsLineUpInsideAStack() throws {
        // Stacks probe their children's minimum and maximum sizes before
        // laying them out, which means that the grid's layout gets computed
        // several times per update. Every one of those computations has to
        // negotiate its columns from scratch.
        let view = VStack(spacing: 0) {
            Text("Header")
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                GridRow {
                    Text("Diameter")
                    Text("A")
                }
                GridRow {
                    Text("W")
                    Text("B")
                }
            }
        }

        let node = committedNode(for: view, proposedSize: ProposedViewSize(400, 200))
        let stack = try container(node.widget)
        let grid = try container(stack.children[1].widget)
        let firstRow = try container(grid.children[0].widget)
        let secondRow = try container(grid.children[1].widget)

        #expect(firstRow.children[1].position.x == secondRow.children[1].position.x)
        #expect(Double(firstRow.children[1].position.x) == width(of: Text("Diameter")) + 8)

        // None of the columns can grow, so the grid stays at its ideal width
        // rather than filling the 400 points that it was offered.
        let expectedWidth = width(of: Text("Diameter")) + 8 + width(of: Text("A"))
        #expect(Double(grid.size.x) == expectedWidth)
    }

    @MainActor
    @Test("An inspector-style table lines its labels, fields and units up")
    func inspectorStyleTableLinesUp() throws {
        var values = ["10", "20"]
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("Diameter")
                TextField("", text: Binding(get: { values[0] }, set: { values[0] = $0 }))
                Text("mm")
            }
            GridRow {
                Text("Spacing")
                TextField("", text: Binding(get: { values[1] }, set: { values[1] = $0 }))
                Text("mm")
            }
        }

        let node = committedNode(for: view, proposedSize: ProposedViewSize(400, 200))
        let rows = try container(node.widget).children
        let firstRow = try container(rows[0].widget)
        let secondRow = try container(rows[1].widget)

        // All three columns start at the same offset in both rows, which is
        // the entire point of using a grid here.
        #expect(firstRow.children[1].position.x == secondRow.children[1].position.x)
        #expect(firstRow.children[2].position.x == secondRow.children[2].position.x)

        // The text fields are the flexible column, so they soak up the rest of
        // the 400 points that the grid was offered.
        #expect(Double(node.widget.size.x) == 400)
        #expect(firstRow.children[1].widget.size.x == secondRow.children[1].widget.size.x)
    }

    @MainActor
    @Test("A grid negotiates its columns on every layout, even while probing")
    func columnsAreNegotiatedWhileProbing() {
        // Stacks probe their children with layout caching enabled, and a
        // cached row never gets to report its cell measurements. The grid has
        // to opt its rows out of caching so that a repeated probe doesn't
        // leave it with no columns at all.
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("Diameter")
                Text("A")
            }
            GridRow {
                Text("W")
                Text("B")
            }
        }

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        let probingEnvironment = environment.with(\.allowLayoutCaching, true)
        _ = node.computeLayout(
            proposedSize: ProposedViewSize(400, 0),
            environment: probingEnvironment
        )
        let result = node.computeLayout(
            proposedSize: ProposedViewSize(400, Double.infinity),
            environment: probingEnvironment
        )

        let expectedWidth = width(of: Text("Diameter")) + 8 + width(of: Text("A"))
        #expect(result.size.width == expectedWidth)
    }

    @MainActor
    @Test("A grid with a flexible column is flexible itself")
    func gridWithFlexibleColumnIsFlexible() throws {
        let view = HStack(spacing: 0) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    Color.blue
                }
            }
            Text("AA")
        }

        let node = committedNode(for: view, proposedSize: ProposedViewSize(400, 100))
        let stack = try container(node.widget)

        #expect(Double(stack.children[0].widget.size.x) == 400 - width(of: Text("AA")))
    }

    @MainActor
    @Test("Rows produced by a ForEach take part in column negotiation")
    func forEachRowsParticipateInColumnNegotiation() throws {
        // Every row of the `ForEach` becomes a row of the grid in its own
        // right, with its own row index, rather than all of them collapsing
        // onto one row.
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            ForEach(["Diameter", "W"], id: \.self) { item in
                GridRow {
                    Text(item)
                    Text("A")
                }
            }
        }

        let node = committedNode(for: view)

        // Both rows negotiated the same two columns, so the grid is exactly as
        // wide as its widest first cell plus the second column, and two rows
        // tall.
        let firstColumnWidth = width(of: Text("Diameter"))
        let rowHeight = height(of: Text("A"))
        #expect(Double(node.widget.size.x) == firstColumnWidth + 8 + width(of: Text("A")))
        #expect(Double(node.widget.size.y) == rowHeight * 2 + 4)

        // The rows got distinct indices: they stack vertically instead of
        // collapsing onto one row, and their second cells share a column.
        let cells = cellPositions(in: node.widget)
        #expect(cells.count == 4)
        #expect(cells[0] == SIMD2(0, 0))
        #expect(Double(cells[1].x) == firstColumnWidth + 8)
        #expect(cells[2] == SIMD2(0, Int(rowHeight) + 4))
        #expect(cells[3] == SIMD2(cells[1].x, Int(rowHeight) + 4))
    }

    @MainActor
    @Test("Container-produced rows are indexed alongside direct rows")
    func containerProducedRowsGetDistinctIndices() throws {
        // A grid whose rows come from a mixture of sources still hands every
        // row its own index, in the order that the rows appear.
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("Diameter")
                Text("A")
            }
            Group {
                ForEach(["W", "X"], id: \.self) { item in
                    GridRow {
                        Text(item)
                        Text("A")
                    }
                }
            }
        }

        let node = committedNode(for: view)
        let rowHeight = height(of: Text("A"))
        let rowPitch = Int(rowHeight) + 4

        // Three rows in total, so the grid is three rows tall.
        #expect(Double(node.widget.size.y) == rowHeight * 3 + 4 * 2)

        // Row indices carry on across the boundary between the row written
        // directly inside the grid and the rows that the `Group` produced, and
        // all three rows share the column negotiated by the direct row's wide
        // first cell.
        let firstColumnWidth = width(of: Text("Diameter"))
        let cells = cellPositions(in: node.widget)
        let secondColumnOffset = Int(firstColumnWidth) + 8
        #expect(cells.count == 6)
        #expect(cells.map(\.y) == [0, 0, rowPitch, rowPitch, rowPitch * 2, rowPitch * 2])
        #expect(
            cells.map(\.x) == [
                0,
                secondColumnOffset,
                0,
                secondColumnOffset,
                0,
                secondColumnOffset,
            ]
        )
    }

    @MainActor
    @Test("A grid lays itself out the same way on a second update")
    func layoutIsStableAcrossUpdates() throws {
        // The layout context lives on the grid's children rather than being
        // recreated for every layout, so a second update has to start from a
        // clean row cursor and clean measurements.
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            ForEach(["Diameter", "W"], id: \.self) { item in
                GridRow {
                    Text(item)
                    Text("A")
                }
            }
        }

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        for _ in 0..<2 {
            _ = node.computeLayout(proposedSize: .unspecified, environment: environment)
            _ = node.commit()
        }

        let firstColumnWidth = width(of: Text("Diameter"))
        let rowHeight = height(of: Text("A"))
        #expect(Double(node.widget.size.x) == firstColumnWidth + 8 + width(of: Text("A")))
        #expect(Double(node.widget.size.y) == rowHeight * 2 + 4)

        let cells = cellPositions(in: node.widget)
        #expect(cells.count == 4)
        #expect(cells[2] == SIMD2(0, Int(rowHeight) + 4))
        #expect(cells[3] == SIMD2(Int(firstColumnWidth) + 8, Int(rowHeight) + 4))
    }

    @MainActor
    @Test("A child that isn't a grid row becomes a full width row")
    func nonRowChildBecomesItsOwnRow() throws {
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("Diameter")
                Text("A")
            }
            Text("Footnote")
        }

        let node = committedNode(for: view)
        let gridContainer = try container(node.widget)
        #expect(gridContainer.children.count == 2)

        // The lone view doesn't take part in column negotiation, so the grid
        // stays exactly as wide as the row's two columns.
        let firstColumnWidth = width(of: Text("Diameter"))
        #expect(Double(node.widget.size.x) == firstColumnWidth + 8 + width(of: Text("A")))

        // It becomes a row of its own, below the grid row.
        let rowHeight = height(of: Text("A"))
        #expect(gridContainer.children[1].position == SIMD2(0, Int(rowHeight) + 4))

        let firstRow = try container(gridContainer.children[0].widget)
        #expect(Double(firstRow.children[1].position.x) == firstColumnWidth + 8)
    }

    @MainActor
    @Test("A ForEach used as a cell doesn't add rows to the grid")
    func forEachInsideARowStaysInThatRow() throws {
        // The nesting most likely to produce a baffling bug: a `ForEach` that
        // is one cell of a row must stay inside that row rather than adding
        // rows of its own to the enclosing grid.
        let view = Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text("Diameter")
                ForEach(["A", "B"], id: \.self) { item in
                    Text(item)
                }
            }
            GridRow {
                Text("W")
                Text("AB")
            }
        }

        let node = committedNode(for: view)
        let gridContainer = try container(node.widget)
        #expect(gridContainer.children.count == 2)

        let firstRow = try container(gridContainer.children[0].widget)
        let secondRow = try container(gridContainer.children[1].widget)
        #expect(firstRow.children.count == 2)
        #expect(secondRow.children.count == 2)

        // Both rows still negotiate the same two columns.
        #expect(firstRow.children[1].position.x == secondRow.children[1].position.x)
        #expect(Double(firstRow.children[1].position.x) == width(of: Text("Diameter")) + 8)
    }

    @MainActor
    @Test("A row outside of a grid lays its cells out horizontally")
    func rowOutsideOfGridBehavesLikeAStack() throws {
        let view = GridRow {
            Text("AA")
            Text("AA")
        }

        let node = committedNode(for: view)
        let cells = try container(node.widget).children
        let cellWidth = width(of: Text("AA"))

        #expect(cells[0].position.x == 0)
        #expect(Double(cells[1].position.x) == cellWidth + GridRow<EmptyView>.defaultSpacing)
    }

    // MARK: Helpers

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = .unspecified
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        return node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }

    @MainActor
    func committedNode<V: View>(
        for view: V,
        proposedSize: ProposedViewSize = .unspecified
    ) -> ViewGraphNode<V, DummyBackend> {
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        _ = node.computeLayout(proposedSize: proposedSize, environment: environment)
        _ = node.commit()
        return node
    }

    /// The ideal width of a view, used to derive the widths that the grid
    /// should be negotiating.
    @MainActor
    func width<V: View>(of view: V) -> Double {
        Double(computeLayout(of: view).size.vector.x)
    }

    /// The ideal height of a view.
    @MainActor
    func height<V: View>(of view: V) -> Double {
        Double(computeLayout(of: view).size.vector.y)
    }

    @MainActor
    func container(_ widget: DummyBackend.Widget) throws -> DummyBackend.Container {
        try #require(widget as? DummyBackend.Container)
    }

    /// The position of every cell of a grid relative to the grid itself, in
    /// the order that the cells appear.
    ///
    /// Rows produced by a container live inside that container's widget rather
    /// than directly inside the grid's, so cell positions get read out of the
    /// whole widget tree instead of a fixed depth within it.
    ///
    /// - Parameters:
    ///   - widget: The widget to read cell positions out of.
    ///   - offset: The position of `widget` relative to the grid.
    /// - Returns: The position of every leaf widget beneath `widget`.
    @MainActor
    func cellPositions(
        in widget: DummyBackend.Widget,
        offset: SIMD2<Int> = .zero
    ) -> [SIMD2<Int>] {
        guard let container = widget as? DummyBackend.Container else {
            return [offset]
        }
        return container.children.flatMap { child in
            cellPositions(in: child.widget, offset: offset &+ child.position)
        }
    }
}
