import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// The tool palette's shape: two fixed 30-pt columns with a 4-pt gutter,
/// inside a 64-pt frame — exactly the width the columns and their one
/// interior gutter need. SwiftUI lays that out as two columns; the palette's
/// height is what its number of rows makes it. A grid that falls back to one
/// column here doubles the palette's height and pushes tools off the bottom
/// of the window, which is what was observed on Windows.
@Suite("LazyVGrid with fixed columns in an exact-fit frame")
struct LazyVGridFixedColumnsTests {
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
    @Test("Two fixed columns fit exactly in columns + one gutter")
    func twoFixedColumnsFitAnExactFrame() throws {
        let columns = [
            GridItem(.fixed(30), spacing: 4),
            GridItem(.fixed(30), spacing: 4),
        ]
        let view = LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<6, id: \.self) { _ in
                Color.red.frame(width: 30, height: 30)
            }
        }
        .frame(width: 64)

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        _ = node.computeLayout(
            proposedSize: ProposedViewSize(64, 600), environment: environment)
        _ = node.commit()

        #expect(Double(node.widget.size.x) == 64)
        // Six 30-pt cells in two columns are three rows: 3 × 30 + 2 × 4.
        #expect(Double(node.widget.size.y) == 98, "expected 3 rows of 2, got height \(node.widget.size.y)")
    }

    /// The palette does not use `ForEach`: each section's buttons come out
    /// of a `@ViewBuilder`, i.e. a `TupleView`. SwiftUI flattens a tuple's
    /// elements into grid cells exactly as it flattens `ForEach` output. A
    /// grid that instead treats the tuple as one cell stacks every button in
    /// column one and leaves column two empty — one column of buttons at
    /// double the height, which is the Windows palette as observed.
    @MainActor
    @Test("A @ViewBuilder tuple's elements are individual cells")
    func tupleElementsAreIndividualCells() throws {
        let columns = [
            GridItem(.fixed(30), spacing: 4),
            GridItem(.fixed(30), spacing: 4),
        ]
        let view = LazyVGrid(columns: columns, spacing: 4) {
            Color.red.frame(width: 30, height: 30)
            Color.red.frame(width: 30, height: 30)
            Color.red.frame(width: 30, height: 30)
            Color.red.frame(width: 30, height: 30)
            Color.red.frame(width: 30, height: 30)
            Color.red.frame(width: 30, height: 30)
        }
        .frame(width: 64)

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        _ = node.computeLayout(
            proposedSize: ProposedViewSize(64, 600), environment: environment)
        _ = node.commit()

        #expect(Double(node.widget.size.x) == 64)
        #expect(Double(node.widget.size.y) == 98, "expected 3 rows of 2, got height \(node.widget.size.y)")
    }

    private enum Section { case a, b }

    /// The palette's real shape: each section's buttons come out of a
    /// `switch` inside the builder, so the grid's content is conditional
    /// content wrapping a tuple, not a bare tuple. SwiftUI flattens through
    /// the conditional exactly as through the tuple.
    @MainActor
    @Test("Elements behind a switch in the builder are individual cells")
    func conditionalTupleElementsAreIndividualCells() throws {
        let columns = [
            GridItem(.fixed(30), spacing: 4),
            GridItem(.fixed(30), spacing: 4),
        ]
        @ViewBuilder func cells(_ section: Section) -> some View {
            switch section {
            case .a:
                Color.red.frame(width: 30, height: 30)
                Color.red.frame(width: 30, height: 30)
                Color.red.frame(width: 30, height: 30)
                Color.red.frame(width: 30, height: 30)
                Color.red.frame(width: 30, height: 30)
                Color.red.frame(width: 30, height: 30)
            case .b:
                Color.blue.frame(width: 30, height: 30)
            }
        }
        let view = LazyVGrid(columns: columns, spacing: 4) {
            cells(.a)
        }
        .frame(width: 64)

        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        _ = node.computeLayout(
            proposedSize: ProposedViewSize(64, 600), environment: environment)
        _ = node.commit()

        #expect(Double(node.widget.size.x) == 64)
        #expect(Double(node.widget.size.y) == 98, "expected 3 rows of 2, got height \(node.widget.size.y)")
    }
}
