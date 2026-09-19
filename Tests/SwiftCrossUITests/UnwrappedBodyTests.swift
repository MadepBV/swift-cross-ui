import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    @testable import AppKitBackend
#endif

/// Tests for bodies that opt out of `@ViewBuilder`.
///
/// Swift skips the result builder transform for a body containing an explicit
/// `return`, which is what any body with a statement in it ends up with. Such a
/// body arrives as the bare view rather than wrapped in a `TupleView1`, and the
/// `View` default implementations reach past the body view to *its* children —
/// so the body view's own `computeLayout` never runs.
///
/// Every test here spells the same view twice, once so that the result builder
/// applies and once so that it doesn't, and requires the two to render
/// identically. That is the invariant: how a body is spelled must not change
/// what it draws.
///
/// The shapes are separated because the pre-fix symptoms differed. Containers
/// kept a size but got the wrong geometry; everything else collapsed to nothing
/// and drew no pixels at all, with no diagnostic.
@Suite("Testing for bodies that opt out of ViewBuilder")
@MainActor
struct UnwrappedBodyTests {
    /// What a view rendered.
    struct Render: Equatable {
        var size: ViewSize
        var texts: [String]
    }

    /// Lays a view out through `DummyBackend` and reports what came of it.
    ///
    /// Two passes, so that the reported state is a steady-state one rather
    /// than whatever the first pass happened to build.
    static func render<V: View>(
        _ view: V,
        _ proposal: ProposedViewSize = ProposedViewSize(100, 60)
    ) -> Render {
        let backend = DummyBackend()
        let environment = backend
            .computeRootEnvironment(defaultEnvironment: EnvironmentValues(backend: backend))
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            snapshot: nil,
            environment: environment
        )
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: proposal, environment: environment)
        _ = node.commit()

        LayoutPass.begin()
        _ = node.computeLayout(
            with: view,
            proposedSize: proposal,
            environment: environment
        )
        let size = node.commit().size

        func texts(of widget: DummyBackend.Widget) -> [String] {
            var found: [String] = []
            if let text = widget as? DummyBackend.TextView {
                found.append(text.content)
            }
            for child in widget.getChildren() {
                found += texts(of: child)
            }
            return found
        }
        return Render(size: size, texts: texts(of: node.widget))
    }

    /// Requires two spellings of the same view to render identically.
    static func expectSameRendering<Builder: View, Returned: View>(
        _ builderSpelled: Builder,
        _ returnSpelled: Returned,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let builder = render(builderSpelled)
        let returned = render(returnSpelled)
        #expect(
            builder == returned,
            """
            A body that opted out of the result builder rendered differently: \
            builder-spelled \(builder), return-spelled \(returned)
            """,
            sourceLocation: sourceLocation
        )
    }

    // MARK: Containers — pre-fix these kept a size but lost their geometry

    struct BuilderHStack: View {
        var body: some View {
            HStack(spacing: 0) {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    struct ReturnedHStack: View {
        var body: some View {
            let spacing = 0
            return HStack(spacing: spacing) {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    @Test("A returned HStack still stacks horizontally")
    func returnedHStackStacksHorizontally() {
        // Pre-fix: 30x30, the children stacked vertically with VStack's
        // default spacing, instead of 60x10.
        Self.expectSameRendering(BuilderHStack(), ReturnedHStack())
        #expect(Self.render(BuilderHStack()).size == ViewSize(60, 10))
    }

    struct BuilderZStack: View {
        var body: some View {
            ZStack {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 20, height: 40)
            }
        }
    }

    struct ReturnedZStack: View {
        var body: some View {
            let _ = 0
            return ZStack {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 20, height: 40)
            }
        }
    }

    @Test("A returned ZStack still overlays its children")
    func returnedZStackOverlays() {
        // Pre-fix: 30x60, the overlay flattened into a vertical stack.
        Self.expectSameRendering(BuilderZStack(), ReturnedZStack())
        #expect(Self.render(BuilderZStack()).size == ViewSize(30, 40))
    }

    struct BuilderTightVStack: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Color.red.frame(width: 10, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    struct ReturnedTightVStack: View {
        var body: some View {
            let spacing = 0
            return VStack(alignment: .leading, spacing: spacing) {
                Color.red.frame(width: 10, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    @Test("A returned VStack keeps its own spacing and alignment")
    func returnedVStackKeepsSpacing() {
        // Pre-fix: 30x30 — the stack's own spacing of 0 was replaced by the
        // default 10, which is the quietest symptom of the lot.
        Self.expectSameRendering(BuilderTightVStack(), ReturnedTightVStack())
        #expect(Self.render(BuilderTightVStack()).size == ViewSize(30, 20))
    }

    // MARK: Modifiers — pre-fix these collapsed to nothing

    struct BuilderPadding: View {
        var body: some View { Text("x").padding(20) }
    }

    struct ReturnedPadding: View {
        var body: some View {
            let amount = 20
            return Text("x").padding(amount)
        }
    }

    @Test("A returned padding modifier is still applied")
    func returnedPaddingApplies() {
        // Pre-fix: 0x0.
        Self.expectSameRendering(BuilderPadding(), ReturnedPadding())
        #expect(Self.render(BuilderPadding()).size != .zero)
    }

    struct BuilderFrame: View {
        var body: some View { Text("x").frame(width: 77, height: 33) }
    }

    struct ReturnedFrame: View {
        var body: some View {
            let width = 77.0
            return Text("x").frame(width: width, height: 33)
        }
    }

    @Test("A returned frame modifier is still applied")
    func returnedFrameApplies() {
        // Pre-fix: 0x0.
        Self.expectSameRendering(BuilderFrame(), ReturnedFrame())
        #expect(Self.render(BuilderFrame()).size == ViewSize(77, 33))
    }

    struct BuilderChain: View {
        var body: some View {
            VStack { Text("a") }
                .padding(8)
                .background(Color.red)
                .frame(width: 90, height: 40)
        }
    }

    struct ReturnedChain: View {
        var body: some View {
            let padding = 8
            return VStack { Text("a") }
                .padding(padding)
                .background(Color.red)
                .frame(width: 90, height: 40)
        }
    }

    @Test("A returned modifier chain is still applied")
    func returnedModifierChainApplies() {
        // The shape a real body ends with, and pre-fix it was 0x0: an
        // invisible view with no diagnostic.
        Self.expectSameRendering(BuilderChain(), ReturnedChain())
        #expect(Self.render(BuilderChain()).size == ViewSize(90, 40))
    }

    // MARK: Views with their own children storage — pre-fix these drew nothing

    struct BuilderCanvas: View {
        var body: some View {
            Canvas { context, size in
                var path = Path()
                path = path.addRectangle(
                    Path.Rect(x: 0, y: 0, width: size.width, height: size.height)
                )
                context.fill(path, with: .color(.red))
            }
        }
    }

    struct ReturnedCanvas: View {
        var body: some View {
            let _ = 0
            return Canvas { context, size in
                var path = Path()
                path = path.addRectangle(
                    Path.Rect(x: 0, y: 0, width: size.width, height: size.height)
                )
                context.fill(path, with: .color(.red))
            }
        }
    }

    @Test("A returned Canvas still draws")
    func returnedCanvasDraws() {
        // Pre-fix: 0x0 and not a single drawing call.
        Self.expectSameRendering(BuilderCanvas(), ReturnedCanvas())

        let backend = DummyBackend()
        let environment = backend
            .computeRootEnvironment(defaultEnvironment: EnvironmentValues(backend: backend))
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))
        let node = ViewGraphNode(
            for: ReturnedCanvas(),
            backend: backend,
            snapshot: nil,
            environment: environment
        )
        LayoutPass.begin()
        _ = node.computeLayout(
            proposedSize: ProposedViewSize(100, 60),
            environment: environment
        )
        _ = node.commit()
        #expect(backend.callCounts["renderPath", default: 0] == 1)
    }

    struct BuilderScrollView: View {
        var body: some View {
            ScrollView { VStack { Text("a")
                Text("b") } }
        }
    }

    struct ReturnedScrollView: View {
        var body: some View {
            let _ = 0
            return ScrollView { VStack { Text("a")
                Text("b") } }
        }
    }

    @Test("A returned ScrollView still renders")
    func returnedScrollViewRenders() {
        // Pre-fix: 0x0.
        Self.expectSameRendering(BuilderScrollView(), ReturnedScrollView())
        #expect(Self.render(BuilderScrollView()).size != .zero)
    }

    struct BuilderForEach: View {
        var body: some View {
            ForEach(Array(0..<3)) { index in Text("row \(index)") }
        }
    }

    struct ReturnedForEach: View {
        var body: some View {
            let _ = 0
            return ForEach(Array(0..<3)) { index in Text("row \(index)") }
        }
    }

    @Test("A returned ForEach still renders")
    func returnedForEachRenders() {
        // Pre-fix: 0x0.
        Self.expectSameRendering(BuilderForEach(), ReturnedForEach())
        #expect(Self.render(BuilderForEach()).size != .zero)
    }

    struct BuilderConditional: View {
        var flag = true
        var body: some View {
            if flag { Text("yes") } else { Text("no") }
        }
    }

    struct ReturnedConditional: View {
        var flag = true
        var body: some View {
            let flag = flag
            return flag ? AnyView(Text("yes")) : AnyView(Text("no"))
        }
    }

    @Test("A returned conditional still renders")
    func returnedConditionalRenders() {
        // Pre-fix: 0x0.
        Self.expectSameRendering(BuilderConditional(), ReturnedConditional())
        #expect(Self.render(BuilderConditional()).size != .zero)
    }

    // MARK: The failure is per view, not per root

    struct NestedReturnedHStack: View {
        var body: some View {
            let spacing = 0
            return HStack(spacing: spacing) {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    struct BuilderNested: View {
        var body: some View {
            VStack {
                Text("header")
                HStack(spacing: 0) {
                    Color.red.frame(width: 30, height: 10)
                    Color.blue.frame(width: 30, height: 10)
                }
            }
        }
    }

    struct ReturnedNested: View {
        var body: some View {
            VStack {
                Text("header")
                NestedReturnedHStack()
            }
        }
    }

    @Test("The shape matters wherever it appears, not just at the root")
    func nestedUnwrappedBodyIsAlsoCorrect() {
        // Pre-fix: 30x56 instead of 60x36 — a view deep in a tree breaks its
        // own subtree, which is why this is hard to spot in a large app.
        Self.expectSameRendering(BuilderNested(), ReturnedNested())
    }

    // MARK: The failure is in the core, not in any backend

    #if canImport(AppKitBackend)
        /// Lays a view out through a real backend.
        static func appKitSize<V: View>(_ view: V) -> ViewSize {
            let backend = AppKitBackend()
            let environment = backend
                .computeRootEnvironment(
                    defaultEnvironment: EnvironmentValues(backend: backend)
                )
                .with(
                    \.window,
                    backend.createWindow(withDefaultSize: SIMD2(200, 200), id: "window")
                )
            let node = ViewGraphNode(
                for: view,
                backend: backend,
                snapshot: nil,
                environment: environment
            )
            LayoutPass.begin()
            _ = node.computeLayout(
                proposedSize: ProposedViewSize(100, 60),
                environment: environment
            )
            return node.commit().size
        }

        @Test("A real backend agrees, because the decision is made in the core")
        func appKitBackendAgrees() {
            // Pre-fix, AppKitBackend reproduced every symptom exactly, so
            // nothing about a backend masks or causes this.
            #expect(Self.appKitSize(BuilderHStack()) == Self.appKitSize(ReturnedHStack()))
            #expect(Self.appKitSize(BuilderPadding()) == Self.appKitSize(ReturnedPadding()))
            #expect(Self.appKitSize(BuilderCanvas()) == Self.appKitSize(ReturnedCanvas()))
            #expect(Self.appKitSize(BuilderChain()) == Self.appKitSize(ReturnedChain()))
        }
    #endif
}
