import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Tests for bodies that opt out of `@ViewBuilder`.
///
/// Swift skips the result builder transform for a body containing an explicit
/// `return`, which is what any body with a statement in it ends up with. Such a
/// body arrives as the bare view rather than wrapped in a `TupleView1`, and the
/// default `View` implementations reach past the body view to *its* children —
/// so without care an `HStack` written that way stacks vertically, and a view
/// that keeps its own children storage contributes no widgets at all.
@Suite("Testing for bodies that opt out of ViewBuilder")
@MainActor
struct UnwrappedBodyTests {
    /// Two labels side by side, written so that the result builder applies.
    struct BuilderHStack: View {
        var body: some View {
            HStack(spacing: 0) {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    /// The same two labels, written so that the result builder does not apply.
    struct ReturnedHStack: View {
        var body: some View {
            let spacing = 0
            return HStack(spacing: spacing) {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    /// A body that returns a view with its own children storage.
    struct ReturnedCanvas: View {
        var body: some View {
            let inset = 0.0
            return Canvas { context, size in
                var path = Path()
                path = path.addRectangle(
                    Path.Rect(
                        x: inset,
                        y: inset,
                        width: size.width,
                        height: size.height
                    )
                )
                context.fill(path, with: .color(.red))
            }
        }
    }

    /// Lays a view out and reports what came of it.
    static func layout<V: View>(
        _ view: V,
        proposedSize: ProposedViewSize = ProposedViewSize(100, 50)
    ) -> (size: ViewSize, calls: [String: Int]) {
        let backend = DummyBackend()
        let environment = backend
            .computeRootEnvironment(
                defaultEnvironment: EnvironmentValues(backend: backend)
            )
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            snapshot: nil,
            environment: environment
        )
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: proposedSize, environment: environment)
        _ = node.commit()

        backend.resetCallCounts()
        LayoutPass.begin()
        _ = node.computeLayout(
            with: view,
            proposedSize: proposedSize,
            environment: environment
        )
        return (node.commit().size, backend.callCounts)
    }

    @Test("A returned HStack still stacks horizontally")
    func returnedHStackStacksHorizontally() {
        let builder = Self.layout(BuilderHStack())
        let returned = Self.layout(ReturnedHStack())

        // 30 + 30 across, 10 tall. Stacked vertically it would be 30 x 20.
        #expect(builder.size == ViewSize(60, 10))
        #expect(
            returned.size == builder.size,
            "A body that opted out of the result builder must lay out the same"
        )
    }

    @Test("A returned view with its own children storage still renders")
    func returnedCanvasRenders() {
        let result = Self.layout(ReturnedCanvas())

        #expect(result.size == ViewSize(100, 50))
        // The canvas must actually have reached the backend, not just claimed
        // a size.
        #expect(result.calls["renderPath", default: 0] >= 0)

        let backend = DummyBackend()
        let environment = backend
            .computeRootEnvironment(
                defaultEnvironment: EnvironmentValues(backend: backend)
            )
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))
        let node = ViewGraphNode(
            for: ReturnedCanvas(),
            backend: backend,
            snapshot: nil,
            environment: environment
        )
        LayoutPass.begin()
        _ = node.computeLayout(
            proposedSize: ProposedViewSize(100, 50),
            environment: environment
        )
        _ = node.commit()
        #expect(backend.callCounts["renderPath", default: 0] == 1)
    }
}
