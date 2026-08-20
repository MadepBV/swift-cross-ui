import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Guards the ``ViewBuilder`` arity ceiling against a regeneration that silently
/// lowers it.
///
/// The ceiling lives in three coupled gyb templates - `TupleView.swift.gyb`,
/// `TupleViewChildren.swift.gyb` and `ViewBuilder.swift.gyb` - and raising one
/// without the others produces a framework that still fails to compile a block
/// at the new arity. Every test here is therefore two guards at once:
///
/// - A **compile-time** guard. Each body below is a literal view-builder block
///   of a fixed width. If a future regeneration drops the ceiling, or bumps only
///   two of the three templates, this test target stops compiling.
/// - A **runtime** guard. Each test walks the resulting `TupleViewN` through the
///   view graph and asserts that every child is actually there, so a generator
///   that emits a well-typed but under-populated tuple is caught too.
@Suite("Testing for ViewBuilder arity")
struct ViewBuilderArityTests {
    /// The current ceiling: the widest block ``ViewBuilder`` accepts.
    static let maximumArity = 48

    /// The ceiling before the most recent bump. Held here so that a regeneration
    /// which lowers the ceiling back towards it fails loudly rather than only
    /// breaking whichever application first exceeds it.
    static let previousArity = 32

    /// The arity of the densest inspector block in the application that drove the
    /// bump to 48. Sits between ``previousArity`` and ``maximumArity``, and is the
    /// width that actually regressed when the ceiling was last outgrown.
    static let applicationArity = 34

    /// The height of each child in the layout tests, chosen so that the expected
    /// stack height is exactly `arity * rowHeight`.
    static let rowHeight = 10.0

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
    @Test("A block at the maximum arity compiles and lays out every child")
    func maximumArityBlockLaysOutEveryChild() {
        let view = VStack(spacing: 0) {
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
        }

        let result = computeLayout(of: view)
        let expectedHeight = Double(Self.maximumArity) * Self.rowHeight

        #expect(result.size.height == expectedHeight)
    }

    @MainActor
    @Test("A block at the previous ceiling still compiles and lays out every child")
    func previousCeilingBlockLaysOutEveryChild() {
        let view = VStack(spacing: 0) {
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
        }

        let result = computeLayout(of: view)
        let expectedHeight = Double(Self.previousArity) * Self.rowHeight

        #expect(result.size.height == expectedHeight)
    }

    @MainActor
    @Test("A block one past the previous ceiling compiles and lays out every child")
    func applicationArityBlockLaysOutEveryChild() {
        let view = VStack(spacing: 0) {
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
            Color.blue.frame(width: 10, height: Self.rowHeight)
        }

        let result = computeLayout(of: view)
        let expectedHeight = Double(Self.applicationArity) * Self.rowHeight

        #expect(result.size.height == expectedHeight)
    }

    @MainActor
    @Test("The tuple view at the maximum arity carries a node per child")
    func maximumArityTupleViewHasEveryChildNode() {
        let view = ViewBuilder.buildBlock(
            Text("row 0"),
            Text("row 1"),
            Text("row 2"),
            Text("row 3"),
            Text("row 4"),
            Text("row 5"),
            Text("row 6"),
            Text("row 7"),
            Text("row 8"),
            Text("row 9"),
            Text("row 10"),
            Text("row 11"),
            Text("row 12"),
            Text("row 13"),
            Text("row 14"),
            Text("row 15"),
            Text("row 16"),
            Text("row 17"),
            Text("row 18"),
            Text("row 19"),
            Text("row 20"),
            Text("row 21"),
            Text("row 22"),
            Text("row 23"),
            Text("row 24"),
            Text("row 25"),
            Text("row 26"),
            Text("row 27"),
            Text("row 28"),
            Text("row 29"),
            Text("row 30"),
            Text("row 31"),
            Text("row 32"),
            Text("row 33"),
            Text("row 34"),
            Text("row 35"),
            Text("row 36"),
            Text("row 37"),
            Text("row 38"),
            Text("row 39"),
            Text("row 40"),
            Text("row 41"),
            Text("row 42"),
            Text("row 43"),
            Text("row 44"),
            Text("row 45"),
            Text("row 46"),
            Text("row 47")
        )

        let children = view.children(
            backend: backend,
            snapshots: nil,
            environment: environment
        )

        #expect(children.erasedNodes.count == Self.maximumArity)
        #expect(children.widgets.count == Self.maximumArity)
    }

    @MainActor
    @Test("The tuple view at the previous ceiling carries a node per child")
    func previousCeilingTupleViewHasEveryChildNode() {
        let view = ViewBuilder.buildBlock(
            Text("row 0"),
            Text("row 1"),
            Text("row 2"),
            Text("row 3"),
            Text("row 4"),
            Text("row 5"),
            Text("row 6"),
            Text("row 7"),
            Text("row 8"),
            Text("row 9"),
            Text("row 10"),
            Text("row 11"),
            Text("row 12"),
            Text("row 13"),
            Text("row 14"),
            Text("row 15"),
            Text("row 16"),
            Text("row 17"),
            Text("row 18"),
            Text("row 19"),
            Text("row 20"),
            Text("row 21"),
            Text("row 22"),
            Text("row 23"),
            Text("row 24"),
            Text("row 25"),
            Text("row 26"),
            Text("row 27"),
            Text("row 28"),
            Text("row 29"),
            Text("row 30"),
            Text("row 31")
        )

        let children = view.children(
            backend: backend,
            snapshots: nil,
            environment: environment
        )

        #expect(children.erasedNodes.count == Self.previousArity)
        #expect(children.widgets.count == Self.previousArity)
    }

    // MARK: Helpers

    @MainActor
    func computeLayout(
        of view: some View,
        proposedSize: ProposedViewSize = ProposedViewSize(200, 10_000)
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        return node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }
}
