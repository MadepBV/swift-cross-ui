import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing for lazy stacks and grids")
struct LazyGridTests {
    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    // MARK: Column resolution

    @Test("Fixed columns get exactly the width that they ask for")
    func fixedColumnResolution() {
        let tracks = GridItem.resolveTracks(
            columns: [GridItem(.fixed(50)), GridItem(.fixed(70))],
            availableWidth: 500
        )

        #expect(tracks.map(\.width) == [50, 70])
        #expect(tracks.map(\.spacingAfter) == [GridItem.defaultSpacing, 0])
        #expect(GridItem.totalWidth(of: tracks) == 130)
    }

    @Test("Flexible columns share the space left over by fixed columns")
    func flexibleColumnResolution() {
        let tracks = GridItem.resolveTracks(
            columns: [
                GridItem(.fixed(100)),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ],
            availableWidth: 320
        )

        // 320 - 100 (fixed) - 20 (two gaps of default spacing) = 200, split
        // evenly between the two flexible columns.
        #expect(tracks.map(\.width) == [100, 100, 100])
        #expect(GridItem.totalWidth(of: tracks) == 320)
    }

    @Test("Flexible columns respect their bounds")
    func flexibleColumnBounds() {
        let tracks = GridItem.resolveTracks(
            columns: [
                GridItem(.flexible(minimum: 10, maximum: 60), spacing: 0),
                GridItem(.flexible()),
            ],
            availableWidth: 200
        )

        // The first column's even share is 100, which gets clamped to its
        // maximum of 60. The 40 points that it gave up go to the second column.
        #expect(tracks.map(\.width) == [60, 140])
    }

    @Test("Non-fixed columns fall back to their minimum width")
    func columnResolutionWithoutAvailableWidth() {
        let columns = [GridItem(.flexible(minimum: 80)), GridItem(.adaptive(minimum: 120))]

        let unspecified = GridItem.resolveTracks(columns: columns, availableWidth: nil)
        let infinite = GridItem.resolveTracks(columns: columns, availableWidth: .infinity)

        #expect(unspecified.map(\.width) == [80, 120])
        #expect(infinite.map(\.width) == [80, 120])
    }

    @Test("Adaptive columns fit as many tracks as they can")
    func adaptiveColumnResolution() {
        let tracks = GridItem.resolveTracks(
            columns: [GridItem(.adaptive(minimum: 120))],
            availableWidth: 500
        )

        // Three 120 point tracks plus two default gaps fit in 500 points, and
        // the leftover space gets shared between the three tracks.
        #expect(tracks.count == 3)
        #expect(tracks.map(\.width) == [160, 160, 160])
        #expect(tracks.map(\.spacingAfter) == [GridItem.defaultSpacing, GridItem.defaultSpacing, 0])
        #expect(GridItem.totalWidth(of: tracks) == 500)
    }

    @Test("Adaptive tracks respect their spacing and maximum width")
    func adaptiveColumnBounds() {
        let unspaced = GridItem.resolveTracks(
            columns: [GridItem(.adaptive(minimum: 100), spacing: 0)],
            availableWidth: 500
        )
        #expect(unspaced.count == 5)
        #expect(unspaced.map(\.width) == [100, 100, 100, 100, 100])

        let bounded = GridItem.resolveTracks(
            columns: [GridItem(.adaptive(minimum: 200, maximum: 220), spacing: 0)],
            availableWidth: 500
        )
        // Only two 200 point tracks fit, and neither is allowed to grow past
        // 220 points to soak up the leftover space.
        #expect(bounded.count == 2)
        #expect(bounded.map(\.width) == [220, 220])
    }

    @Test("Adaptive columns resolve the shapes used by the app being ported")
    func productionAdaptiveColumnShapes() {
        // `LazyVGrid(columns: [GridItem(.adaptive(minimum: 126), spacing: 8)],
        // spacing: 8)`, as used by the line pattern picker, in a 500 point
        // wide panel. Three 126 point tracks plus two 8 point gaps fit, and
        // the leftover space gets shared between the three tracks.
        let patterns = GridItem.resolveTracks(
            columns: [GridItem(.adaptive(minimum: 126), spacing: 8)],
            availableWidth: 500
        )
        #expect(patterns.count == 3)
        #expect(patterns.map(\.spacingAfter) == [8, 8, 0])
        #expect(patterns.allSatisfy { track in abs(track.width - 484 / 3) < 0.001 })
        #expect(abs(GridItem.totalWidth(of: patterns) - 500) < 0.001)

        // The hatch preset picker's slightly wider cells only fit three times
        // in a wider panel.
        let hatches = GridItem.resolveTracks(
            columns: [GridItem(.adaptive(minimum: 132), spacing: 8)],
            availableWidth: 420
        )
        #expect(hatches.count == 3)
        #expect(hatches.allSatisfy { track in abs(track.width - 404 / 3) < 0.001 })
    }

    @Test("An adaptive column always resolves to at least one track")
    func adaptiveColumnWithoutEnoughSpace() {
        let tracks = GridItem.resolveTracks(
            columns: [GridItem(.adaptive(minimum: 400))],
            availableWidth: 100
        )

        // A column's minimum width is a hard floor, so the single track
        // overflows the space available to the grid rather than shrinking.
        #expect(tracks.count == 1)
        #expect(tracks[0].width == 400)
    }

    // MARK: Row wrapping

    @MainActor
    @Test("Items wrap onto a new row once the columns are full")
    func rowWrapping() {
        let view = LazyVGrid(
            columns: [GridItem(.fixed(50)), GridItem(.fixed(50))],
            spacing: 5
        ) {
            cell(width: 40, height: 20)
            cell(width: 40, height: 30)
            cell(width: 40, height: 20)
        }

        let node = committedNode(for: view, proposedSize: ProposedViewSize(200, 200))
        let container = node.widget as! DummyBackend.Container

        // The grid fills the proposed width, and is 30 (the tallest item of
        // the first row) + 5 (spacing) + 20 (the second row) tall.
        #expect(node.currentLayout?.size == ViewSize(200, 55))

        // The columns occupy 110 points, centered within the grid's 200
        // points, and each item is centered within its own cell.
        #expect(container.children.map(\.position) == [SIMD2(50, 5), SIMD2(110, 0), SIMD2(50, 35)])
    }

    @MainActor
    @Test("Columns honour the grid's alignment")
    func gridAlignment() {
        func grid(alignment: HorizontalAlignment) -> some View {
            LazyVGrid(columns: [GridItem(.fixed(40))], alignment: alignment) {
                cell(width: 40, height: 10)
            }
        }

        let proposedSize = ProposedViewSize(100, 100)
        let leading = committedNode(for: grid(alignment: .leading), proposedSize: proposedSize)
        let center = committedNode(for: grid(alignment: .center), proposedSize: proposedSize)
        let trailing = committedNode(for: grid(alignment: .trailing), proposedSize: proposedSize)

        #expect((leading.widget as! DummyBackend.Container).children[0].position.x == 0)
        #expect((center.widget as! DummyBackend.Container).children[0].position.x == 30)
        #expect((trailing.widget as! DummyBackend.Container).children[0].position.x == 60)
    }

    @MainActor
    @Test("ForEach items each occupy their own wrapping grid cell")
    func foreachItemsBecomeSeparateCells() {
        // The exact shape used by the app's line pattern picker.
        let view = LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 126), spacing: 8)],
            spacing: 8
        ) {
            ForEach(Array(0..<4), id: \.self) { _ in
                cell(width: 40, height: 20)
            }
        }

        let node = committedNode(for: view, proposedSize: ProposedViewSize(500, 500))

        // Three 161.33 point columns, so four items make two rows of 20 points
        // separated by 8 points of spacing.
        #expect(node.currentLayout?.size == ViewSize(500, 48))

        // The items live inside the `ForEach`'s own container, which the grid
        // sizes to the whole cell area and places at its origin.
        let gridContainer = node.widget as! DummyBackend.Container
        #expect(gridContainer.children.count == 1)
        #expect(gridContainer.children[0].position == SIMD2(0, 0))

        let items = gridContainer.children[0].widget as! DummyBackend.Container
        #expect(items.size == SIMD2(500, 48))
        #expect(
            items.children.map(\.position) == [
                SIMD2(61, 0), SIMD2(231, 0), SIMD2(400, 0), SIMD2(61, 28),
            ]
        )
    }

    @MainActor
    @Test("ForEach items nested in a Group also become separate cells")
    func groupedForEachItemsBecomeSeparateCells() {
        let view = LazyVGrid(
            columns: [GridItem(.fixed(50)), GridItem(.fixed(50))],
            spacing: 0
        ) {
            Group {
                ForEach(Array(0..<3), id: \.self) { _ in
                    cell(width: 50, height: 10)
                }
            }
        }

        let node = committedNode(for: view, proposedSize: ProposedViewSize(110, 200))
        #expect(node.currentLayout?.size == ViewSize(110, 20))

        // Both the `Group` and the `ForEach` are transparent, so they nest
        // without either of them consuming a cell.
        let gridContainer = node.widget as! DummyBackend.Container
        let group = gridContainer.children[0].widget as! DummyBackend.Container
        let items = group.children[0].widget as! DummyBackend.Container
        #expect(
            items.children.map(\.position) == [
                SIMD2(0, 0), SIMD2(60, 0), SIMD2(0, 10),
            ]
        )
    }

    @MainActor
    @Test("A ForEach inside a real container doesn't join the enclosing grid")
    func foreachInsideAStackStaysInThatStack() {
        // The nesting most likely to produce a baffling bug: the `HStack` is
        // one cell of the grid, and its own `ForEach` must lay out inside it
        // rather than spilling into the grid's cells.
        let view = LazyVGrid(
            columns: [GridItem(.fixed(100)), GridItem(.fixed(100))],
            spacing: 4
        ) {
            HStack(spacing: 0) {
                ForEach(Array(0..<3), id: \.self) { _ in
                    cell(width: 10, height: 10)
                }
            }
            cell(width: 20, height: 20)
        }

        let node = committedNode(for: view, proposedSize: ProposedViewSize(300, 300))

        // Two cells on one row, whose height is that of the taller cell.
        #expect(node.currentLayout?.size == ViewSize(300, 20))

        let gridContainer = node.widget as! DummyBackend.Container
        #expect(gridContainer.children.count == 2)
        #expect(gridContainer.children.map(\.position) == [SIMD2(80, 5), SIMD2(195, 0)])

        // The nested items are still laid out horizontally by the `HStack`.
        let stack = gridContainer.children[0].widget as! DummyBackend.Container
        let items = stack.children[0].widget as! DummyBackend.Container
        #expect(
            items.children.map(\.position) == [
                SIMD2(0, 0), SIMD2(10, 0), SIMD2(20, 0),
            ]
        )
    }

    @MainActor
    @Test("Cells are still resolved while an enclosing stack probes the grid")
    func cellsSurviveProbing() {
        // A stack probes its children at a minimum and a maximum length before
        // laying them out, which proposes the grid several sizes that share a
        // width. A grouping container only registers its participants while
        // it's actually computing a layout, and the view graph skips computing
        // one whenever a node is proposed the same size twice in a row, so the
        // grid would otherwise come out of probing believing that it has no
        // cells at all. Delete the measuring pass in `LazyVGrid.computeLayout`
        // and this collapses to a height of 10.
        // Two children and a concrete length are what push the stack onto its
        // probing path.
        let view = VStack(spacing: 0) {
            cell(width: 10, height: 10)
            LazyVGrid(
                columns: [GridItem(.fixed(50)), GridItem(.fixed(50))],
                spacing: 0
            ) {
                ForEach(Array(0..<4), id: \.self) { _ in
                    cell(width: 50, height: 10)
                }
            }
        }

        let result = computeLayout(of: view, proposedSize: ProposedViewSize(110, 200))

        // The lone cell, then four items in two columns making two rows of 10
        // points.
        #expect(result.size.height == 30)
    }

    // MARK: Lazy stacks

    @MainActor
    @Test("LazyVStack lays out like a VStack")
    func lazyVStackMatchesVStack() {
        let proposedSize = ProposedViewSize(100, 100)

        let lazyResult = computeLayout(
            of: LazyVStack(alignment: .leading, spacing: 2) {
                cell(width: 30, height: 10)
                cell(width: 50, height: 20)
            },
            proposedSize: proposedSize
        )
        let eagerResult = computeLayout(
            of: VStack(alignment: .leading, spacing: 2) {
                cell(width: 30, height: 10)
                cell(width: 50, height: 20)
            },
            proposedSize: proposedSize
        )

        #expect(lazyResult.size == ViewSize(50, 32))
        #expect(lazyResult.size == eagerResult.size)
    }

    // MARK: Helpers

    /// A grid item of a known size.
    @MainActor
    func cell(width: Double, height: Double) -> some View {
        Color.blue.frame(width: width, height: height)
    }

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
}

