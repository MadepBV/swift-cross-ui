import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Tests that a ``Canvas`` still repaints when it has to.
///
/// A canvas re-applies every one of its drawing commands on every commit, and a
/// commit happens whenever anything in the window updates, not only when the
/// drawing changed. Each of those applications is a backend call — a COM
/// crossing on Windows — so the canvas skips the ones whose inputs are
/// unchanged, and a canvas that declares its inputs skips the renderer as well.
/// These tests pin the other half of that bargain: every kind of change must
/// still reach the backend.
@Suite("Testing for Canvas repainting")
@MainActor
struct CanvasRepaintTests {
    /// A mutable value that a renderer or a view builder can capture.
    final class Box<Value> {
        var value: Value

        init(_ value: Value) {
            self.value = value
        }
    }

    /// Drives a canvas through ``DummyBackend`` so that its backend calls can
    /// be counted.
    @MainActor
    final class Harness {
        let backend: DummyBackend
        let environment: EnvironmentValues
        let node: ViewGraphNode<VStack<TupleView1<Canvas>>, DummyBackend>
        /// How many times the canvas' renderer has run.
        let rendererRuns = Box(0)

        /// Rebuilds the canvas for each pass, so that a test can change what
        /// the view value carries between passes.
        private let makeCanvas: () -> Canvas

        /// Creates a harness for a canvas with the given renderer.
        ///
        /// - Parameter renderer: The canvas' drawing closure.
        convenience init(renderer: @escaping Canvas.Renderer) {
            self.init(makeCanvas: { Canvas(renderer: $0) }, renderer: renderer)
        }

        /// Creates a harness whose canvas is rebuilt by `makeCanvas` on every
        /// pass, so that a test can pick which `Canvas` initialiser is under
        /// test and vary what it carries.
        ///
        /// The canvas is wrapped in a stack because a view's body is laid out
        /// as if it were a `VStack`, which needs `TupleView` content.
        ///
        /// - Parameters:
        ///   - makeCanvas: Builds the canvas from a renderer.
        ///   - renderer: The canvas' drawing closure.
        init(
            makeCanvas: @escaping (@escaping Canvas.Renderer) -> Canvas,
            renderer: @escaping Canvas.Renderer
        ) {
            let runs = rendererRuns
            let countingRenderer: Canvas.Renderer = { context, size in
                runs.value += 1
                renderer(&context, size)
            }
            self.makeCanvas = { makeCanvas(countingRenderer) }

            backend = DummyBackend()
            environment = backend
                .computeRootEnvironment(
                    defaultEnvironment: EnvironmentValues(backend: backend)
                )
                .with(
                    \.window,
                    backend.createWindow(withDefaultSize: nil, id: "window")
                )
            node = ViewGraphNode(
                for: VStack(content: TupleView1(makeCanvas(countingRenderer))),
                backend: backend,
                snapshot: nil,
                environment: environment
            )
        }

        /// Runs one layout and commit pass and returns the backend calls it
        /// made.
        ///
        /// - Returns: The number of times each backend method was called.
        @discardableResult
        func pass() -> [String: Int] {
            backend.resetCallCounts()
            _ = node.computeLayout(
                with: VStack(content: TupleView1(makeCanvas())),
                proposedSize: ProposedViewSize(100, 50),
                environment: environment
            )
            _ = node.commit()
            return backend.callCounts
        }
    }

    static func rectangle(x: Double) -> Path {
        Path().addRectangle(Path.Rect(x: x, y: 0, width: 10, height: 10))
    }

    @Test("An unchanged drawing doesn't touch the backend a second time")
    func unchangedDrawingIsNotReapplied() {
        let harness = Harness { context, _ in
            context.fill(Self.rectangle(x: 0), with: .color(.red))
        }

        let first = harness.pass()
        #expect(first["updatePath", default: 0] == 1)
        #expect(first["renderPath", default: 0] == 1)

        let second = harness.pass()
        #expect(second["updatePath", default: 0] == 0)
        #expect(second["renderPath", default: 0] == 0)
    }

    @Test("Changed geometry is uploaded again")
    func changedGeometryIsUploaded() {
        let offset = Box(0.0)
        let harness = Harness { context, _ in
            context.fill(Self.rectangle(x: offset.value), with: .color(.red))
        }

        harness.pass()
        offset.value = 20.0
        let afterChange = harness.pass()
        #expect(afterChange["updatePath", default: 0] == 1)
    }

    @Test("A changed fill colour is rendered again")
    func changedColorIsRendered() {
        let color = Box(Color.red)
        let harness = Harness { context, _ in
            context.fill(Self.rectangle(x: 0), with: .color(color.value))
        }

        harness.pass()
        color.value = .blue
        let afterChange = harness.pass()
        #expect(afterChange["renderPath", default: 0] == 1)
    }

    @Test("A changed stroke style is rendered again")
    func changedStrokeStyleIsRendered() {
        let width = Box(1.0)
        let harness = Harness { context, _ in
            context.stroke(
                Self.rectangle(x: 0),
                with: .color(.black),
                lineWidth: width.value
            )
        }

        harness.pass()
        width.value = 4.0
        let afterChange = harness.pass()
        #expect(afterChange["renderPath", default: 0] == 1)
        #expect(afterChange["updatePath", default: 0] == 1)
    }

    @Test("Changed text is written to its widget again")
    func changedTextIsWritten() {
        let label = Box("first")
        let harness = Harness { context, _ in
            context.draw(Text(label.value), at: CGPoint(x: 0, y: 0))
        }

        let first = harness.pass()
        #expect(first["updateTextView", default: 0] >= 1)

        let unchanged = harness.pass()
        #expect(unchanged["updateTextView", default: 0] == 0)

        label.value = "second"
        let afterChange = harness.pass()
        #expect(afterChange["updateTextView", default: 0] >= 1)
    }

    @Test("A canvas that declares its inputs skips an unchanged drawing entirely")
    func declaredInputsSkipTheRenderer() {
        let inputs = Box(0.0)
        let harness = Harness(
            makeCanvas: { renderer in
                Canvas(inputs: inputs.value, renderer: renderer)
            },
            renderer: { context, _ in
                context.fill(Self.rectangle(x: inputs.value), with: .color(.red))
            }
        )

        harness.pass()
        let runsAfterFirstPass = harness.rendererRuns.value
        #expect(runsAfterFirstPass >= 1)

        harness.pass()
        let third = harness.pass()

        // Nothing the drawing depends on moved, so the renderer must not run
        // again and no drawing widget may be touched.
        #expect(harness.rendererRuns.value == runsAfterFirstPass)
        #expect(third["updatePath", default: 0] == 0)
        #expect(third["renderPath", default: 0] == 0)
    }

    @Test("A canvas redraws when its declared inputs change")
    func declaredInputsRedrawOnChange() {
        let inputs = Box(0.0)
        let harness = Harness(
            makeCanvas: { renderer in
                Canvas(inputs: inputs.value, renderer: renderer)
            },
            renderer: { context, _ in
                context.fill(Self.rectangle(x: inputs.value), with: .color(.red))
            }
        )

        harness.pass()
        harness.pass()
        let runsWhileUnchanged = harness.rendererRuns.value

        inputs.value = 30.0
        let afterChange = harness.pass()
        #expect(harness.rendererRuns.value > runsWhileUnchanged)
        #expect(afterChange["updatePath", default: 0] == 1)
    }
}
