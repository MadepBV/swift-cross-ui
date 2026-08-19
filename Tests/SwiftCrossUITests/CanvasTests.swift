import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend

    /// Drives a ``Canvas`` through a real backend so that the widget side of
    /// canvas rendering can be inspected.
    ///
    /// `DummyBackend` doesn't implement `BackendFeatures.Paths`, so
    /// `AppKitBackend` is the only backend available to the test suite that a
    /// canvas can actually render through.
    @MainActor
    final class AppKitCanvasHarness {
        /// The backend under test.
        let backend: AppKitBackend
        /// The view graph holding the canvas.
        let viewGraph: ViewGraph<Canvas>
        /// The environment that layout runs in.
        let environment: EnvironmentValues

        /// The canvas' container widget.
        var container: NSView {
            viewGraph.rootNode.widget.into()
        }

        /// Creates a harness for the given canvas.
        ///
        /// - Parameter canvas: The canvas to render.
        init(canvas: Canvas) {
            backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(200, 200),
                id: "window"
            )
            environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            viewGraph = ViewGraph(
                for: canvas,
                backend: backend,
                environment: environment
            )
            backend.setChild(
                ofWindow: window,
                to: viewGraph.rootNode.widget.into()
            )
        }

        /// Runs one layout and commit pass.
        func render() {
            _ = viewGraph.computeLayout(
                proposedSize: ProposedViewSize(100.0, 50.0),
                environment: environment
            )
            viewGraph.commit()
        }
    }
#endif

/// A mutable command count that a renderer closure can capture.
///
/// Stands in for the `@State` property that an app would drive a canvas with.
final class CommandCountBox {
    /// The number of commands that the renderer should issue.
    var value: Int

    /// Creates a box.
    ///
    /// - Parameter value: The initial command count.
    init(_ value: Int) {
        self.value = value
    }
}

/// Tests for ``Canvas``, ``GraphicsContext`` and the path construction that
/// canvas drawing relies on.
///
/// `DummyBackend` doesn't implement `BackendFeatures.Paths`, so a canvas can't
/// be rendered through it. These tests therefore assert on the command list
/// that a renderer produces and on the resolved path geometry, not on pixels.
@Suite("Testing for Canvas")
struct CanvasTests {
    /// The size handed to every renderer under test.
    static let size = CGSize(width: 100.0, height: 50.0)

    /// A horizontal line from (0, 0) to (10, 0).
    static let line = Path()
        .move(to: SIMD2(x: 0.0, y: 0.0))
        .addLine(to: SIMD2(x: 10.0, y: 0.0))

    /// Builds an axis-aligned rectangle path.
    ///
    /// - Parameters:
    ///   - x: The rectangle's leading edge.
    ///   - y: The rectangle's top edge.
    ///   - width: The rectangle's width.
    ///   - height: The rectangle's height.
    /// - Returns: The rectangle as a path.
    static func rectangle(
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) -> Path {
        Path().addRectangle(
            Path.Rect(x: x, y: y, width: width, height: height)
        )
    }

    /// Records the commands issued by a renderer.
    ///
    /// - Parameter renderer: The renderer to run.
    /// - Returns: The recorded commands.
    @MainActor
    static func record(
        _ renderer: @escaping Canvas.Renderer
    ) -> [GraphicsContext.Command] {
        Canvas(renderer: renderer).record(size: CanvasTests.size)
    }

    /// Extracts the single fill command from a command list.
    ///
    /// - Parameter commands: The commands to search.
    /// - Returns: The fill command, or `nil` if there isn't exactly one.
    static func onlyFill(
        _ commands: [GraphicsContext.Command]
    ) -> GraphicsContext.FillCommand? {
        guard commands.count == 1, case .fill(let fill) = commands[0] else {
            return nil
        }
        return fill
    }

    /// Extracts the single stroke command from a command list.
    ///
    /// - Parameter commands: The commands to search.
    /// - Returns: The stroke command, or `nil` if there isn't exactly one.
    static func onlyStroke(
        _ commands: [GraphicsContext.Command]
    ) -> GraphicsContext.StrokeCommand? {
        guard commands.count == 1, case .stroke(let stroke) = commands[0] else {
            return nil
        }
        return stroke
    }

    /// Extracts the single text command from a command list.
    ///
    /// - Parameter commands: The commands to search.
    /// - Returns: The text command, or `nil` if there isn't exactly one.
    static func onlyText(
        _ commands: [GraphicsContext.Command]
    ) -> GraphicsContext.TextCommand? {
        guard commands.count == 1, case .text(let text) = commands[0] else {
            return nil
        }
        return text
    }

    /// Asserts that two points are equal to within a small tolerance.
    ///
    /// - Parameters:
    ///   - actual: The point produced by the code under test.
    ///   - expected: The point that was expected.
    static func expectClose(
        _ actual: SIMD2<Double>,
        _ expected: SIMD2<Double>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            abs(actual.x - expected.x) < 0.001
                && abs(actual.y - expected.y) < 0.001,
            "expected \(expected), got \(actual)",
            sourceLocation: sourceLocation
        )
    }

    // MARK: Command recording

    @MainActor
    @Test("Drawing commands are recorded in issue order")
    func commandsAreRecordedInOrder() {
        let commands = CanvasTests.record { context, _ in
            context.fill(CanvasTests.line, with: .color(.red))
            context.draw(Text("label"), at: CGPoint(x: 0.0, y: 0.0))
            context.stroke(CanvasTests.line, with: .color(.blue))
        }

        #expect(commands.count == 3)
        #expect(commands.map(\.kind) == [.path, .text, .path])
        if case .fill = commands[0] {} else {
            Issue.record("first command should be a fill")
        }
        if case .stroke = commands[2] {} else {
            Issue.record("third command should be a stroke")
        }
    }

    @MainActor
    @Test("An untransformed fill records the path unchanged")
    func untransformedFillKeepsPath() {
        let commands = CanvasTests.record { context, _ in
            context.fill(CanvasTests.line, with: .color(.red))
        }

        let fill = CanvasTests.onlyFill(commands)
        #expect(fill?.path.actions == CanvasTests.line.actions)
        #expect(fill?.opacity == 1.0)
        #expect(fill?.clipPaths.isEmpty == true)
    }

    @MainActor
    @Test("stroke(_:with:lineWidth:) uses the given width")
    func strokeLineWidthIsHonoured() {
        let commands = CanvasTests.record { context, _ in
            context.stroke(CanvasTests.line, with: .color(.red), lineWidth: 3.0)
        }

        let stroke = CanvasTests.onlyStroke(commands)
        #expect(stroke?.style.width == 3.0)
        #expect(stroke?.path.strokeStyle.width == 3.0)
    }

    @MainActor
    @Test("A context's copies share its destination but not its state")
    func contextCopiesShareTheDestination() {
        let commands = CanvasTests.record { context, _ in
            var shifted = context
            shifted.translateBy(x: 10.0, y: 0.0)
            shifted.fill(CanvasTests.line, with: .color(.red))
            context.fill(CanvasTests.line, with: .color(.blue))
        }

        #expect(commands.count == 2)
        guard commands.count == 2,
            case .fill(let first) = commands[0],
            case .fill(let second) = commands[1]
        else {
            Issue.record("expected two fills")
            return
        }

        let firstPoints = Path.flatten(first.path.actions)
        let secondPoints = Path.flatten(second.path.actions)
        #expect(firstPoints.count == 1)
        #expect(secondPoints.count == 1)
        CanvasTests.expectClose(firstPoints[0][0], SIMD2(x: 10.0, y: 0.0))
        CanvasTests.expectClose(secondPoints[0][0], SIMD2(x: 0.0, y: 0.0))
    }

    // MARK: Transforms

    @MainActor
    @Test("translateBy moves recorded geometry")
    func translateMovesGeometry() {
        let commands = CanvasTests.record { context, _ in
            context.translateBy(x: 5.0, y: 3.0)
            context.fill(CanvasTests.line, with: .color(.red))
        }

        guard let fill = CanvasTests.onlyFill(commands) else {
            Issue.record("expected one fill")
            return
        }
        let points = Path.flatten(fill.path.actions)
        #expect(points.count == 1)
        CanvasTests.expectClose(points[0][0], SIMD2(x: 5.0, y: 3.0))
        CanvasTests.expectClose(points[0][1], SIMD2(x: 15.0, y: 3.0))
    }

    @MainActor
    @Test("scaleBy scales geometry and stroke width")
    func scaleScalesGeometryAndStrokeWidth() {
        let commands = CanvasTests.record { context, _ in
            context.scaleBy(x: 2.0, y: 8.0)
            context.stroke(
                CanvasTests.line,
                with: .color(.red),
                style: StrokeStyle(width: 1.0)
            )
        }

        guard let stroke = CanvasTests.onlyStroke(commands) else {
            Issue.record("expected one stroke")
            return
        }
        let points = Path.flatten(stroke.path.actions)
        CanvasTests.expectClose(points[0][1], SIMD2(x: 20.0, y: 0.0))
        // The geometric mean of the two scale factors is sqrt(2 * 8) = 4.
        #expect(abs((stroke.style.width) - 4.0) < 0.001)
    }

    @MainActor
    @Test("Transforms compose in SwiftUI's order")
    func transformsComposeInOrder() {
        // Translating and then scaling must scale the translation too, i.e.
        // the point (0, 0) ends up at (10, 0) * 2 = (20, 0).
        let commands = CanvasTests.record { context, _ in
            context.scaleBy(x: 2.0, y: 2.0)
            context.translateBy(x: 10.0, y: 0.0)
            context.fill(CanvasTests.line, with: .color(.red))
        }

        guard let fill = CanvasTests.onlyFill(commands) else {
            Issue.record("expected one fill")
            return
        }
        let points = Path.flatten(fill.path.actions)
        CanvasTests.expectClose(points[0][0], SIMD2(x: 20.0, y: 0.0))
        CanvasTests.expectClose(points[0][1], SIMD2(x: 40.0, y: 0.0))
    }

    @MainActor
    @Test("concatenate applies an explicit transform")
    func concatenateAppliesTransform() {
        let commands = CanvasTests.record { context, _ in
            context.concatenate(AffineTransform.translation(x: 1.0, y: 2.0))
            context.fill(CanvasTests.line, with: .color(.red))
        }

        guard let fill = CanvasTests.onlyFill(commands) else {
            Issue.record("expected one fill")
            return
        }
        let points = Path.flatten(fill.path.actions)
        CanvasTests.expectClose(points[0][0], SIMD2(x: 1.0, y: 2.0))
    }

    @MainActor
    @Test("rotate turns geometry about the context's origin")
    func rotateTurnsGeometry() {
        let commands = CanvasTests.record { context, _ in
            context.rotate(by: .init(degrees: 90.0))
            context.fill(CanvasTests.line, with: .color(.red))
        }

        guard let fill = CanvasTests.onlyFill(commands) else {
            Issue.record("expected one fill")
            return
        }
        let points = Path.flatten(fill.path.actions)
        CanvasTests.expectClose(points[0][1], SIMD2(x: 0.0, y: 10.0))
    }

    // MARK: Clipping

    @MainActor
    @Test("Geometry outside the clip's bounding box is discarded")
    func clipDiscardsDistantGeometry() {
        let commands = CanvasTests.record { context, _ in
            context.clip(
                to: CanvasTests.rectangle(x: 0.0, y: 0.0, width: 10, height: 10)
            )
            context.fill(
                CanvasTests.rectangle(
                    x: 100.0,
                    y: 100.0,
                    width: 10.0,
                    height: 10.0
                ),
                with: .color(.red)
            )
        }

        #expect(commands.isEmpty)
    }

    @MainActor
    @Test("Geometry overlapping the clip is kept, and records the clip")
    func clipKeepsOverlappingGeometry() {
        let commands = CanvasTests.record { context, _ in
            context.clip(
                to: CanvasTests.rectangle(x: 0.0, y: 0.0, width: 10, height: 10)
            )
            context.fill(
                CanvasTests.rectangle(
                    x: 5.0,
                    y: 5.0,
                    width: 10.0,
                    height: 10.0
                ),
                with: .color(.red)
            )
        }

        let fill = CanvasTests.onlyFill(commands)
        #expect(fill?.clipPaths.count == 1)
    }

    @MainActor
    @Test("Clip paths are recorded in canvas coordinates")
    func clipPathsAreTransformed() {
        let commands = CanvasTests.record { context, _ in
            context.translateBy(x: 50.0, y: 0.0)
            context.clip(
                to: CanvasTests.rectangle(x: 0.0, y: 0.0, width: 10, height: 10)
            )
            context.fill(
                CanvasTests.rectangle(
                    x: 0.0,
                    y: 0.0,
                    width: 10.0,
                    height: 10.0
                ),
                with: .color(.red)
            )
        }

        guard let fill = CanvasTests.onlyFill(commands),
            let clipBounds = fill.clipPaths.first?.approximateBoundingBox
        else {
            Issue.record("expected one clipped fill")
            return
        }
        CanvasTests.expectClose(clipBounds.origin, SIMD2(x: 50.0, y: 0.0))
    }

    // MARK: Text

    @MainActor
    @Test("resolve captures the string and defaults to foreground shading")
    func resolveCapturesString() {
        var resolved: ResolvedText?
        _ = CanvasTests.record { context, _ in
            resolved = context.resolve(Text("N12"))
        }

        #expect(resolved?.string == "N12")
        if case .foreground = resolved?.shading.storage {} else {
            Issue.record("resolved text should default to foreground shading")
        }
    }

    @MainActor
    @Test("Measuring without a backend reports a zero size")
    func measureWithoutBackendIsZero() {
        var measured: CGSize?
        _ = CanvasTests.record { context, _ in
            let resolved = context.resolve(Text("N12"))
            measured = resolved.measure(
                in: CGSize(width: 100.0, height: 100.0)
            )
        }

        #expect(measured?.width == 0.0)
        #expect(measured?.height == 0.0)
    }

    @MainActor
    @Test("draw(_:at:) records a centered, transformed anchor point")
    func drawAtRecordsAnchorPoint() {
        let commands = CanvasTests.record { context, _ in
            context.translateBy(x: 4.0, y: 6.0)
            context.draw(Text("N12"), at: CGPoint(x: 1.0, y: 2.0))
        }

        guard let text = CanvasTests.onlyText(commands),
            case .point(let position, let anchor) = text.placement
        else {
            Issue.record("expected one point-anchored text command")
            return
        }
        CanvasTests.expectClose(position, SIMD2(x: 5.0, y: 8.0))
        #expect(anchor == .center)
        #expect(text.text.string == "N12")
    }

    @MainActor
    @Test("draw(_:in:) records a rectangle placement")
    func drawInRecordsRect() {
        let commands = CanvasTests.record { context, _ in
            context.draw(
                Text("N12"),
                in: CGRect(x: 1.0, y: 2.0, width: 30.0, height: 12.0)
            )
        }

        guard let text = CanvasTests.onlyText(commands),
            case .rect(let rect) = text.placement
        else {
            Issue.record("expected one rect-placed text command")
            return
        }
        CanvasTests.expectClose(rect.origin, SIMD2(x: 1.0, y: 2.0))
        CanvasTests.expectClose(rect.size, SIMD2(x: 30.0, y: 12.0))
    }

    // MARK: Layout

    @MainActor
    @Test("A canvas fills the space proposed to it")
    func canvasFillsProposedSize() {
        let backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "window")
        let environment = EnvironmentValues(backend: backend)
            .with(\.window, window)
        let canvas = Canvas { _, _ in }
        let storage = CanvasStorage()

        let layout = canvas.computeLayout(
            backend.createContainer(),
            children: storage,
            proposedSize: ProposedViewSize(320.0, 240.0),
            environment: environment,
            backend: backend
        )

        #expect(layout.size == ViewSize(320.0, 240.0))
    }

    @MainActor
    @Test("A canvas falls back on 10x10 for unspecified proposals")
    func canvasFallsBackOnDefaultSize() {
        let backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "window")
        let environment = EnvironmentValues(backend: backend)
            .with(\.window, window)
        let canvas = Canvas { _, _ in }
        let storage = CanvasStorage()

        let layout = canvas.computeLayout(
            backend.createContainer(),
            children: storage,
            proposedSize: .unspecified,
            environment: environment,
            backend: backend
        )

        #expect(layout.size == ViewSize(10.0, 10.0))
    }

    // MARK: Path construction

    @Test("addPath is a spelling of addSubpath")
    func addPathMatchesAddSubpath() {
        let viaAddPath = Path().addPath(CanvasTests.line)
        let viaAddSubpath = Path().addSubpath(CanvasTests.line)
        #expect(viaAddPath.actions == viaAddSubpath.actions)
    }

    @Test("addEllipse inscribes an ellipse in the given rectangle")
    func addEllipseInscribesEllipse() {
        let path = Path().addEllipse(
            in: Path.Rect(x: 0.0, y: 0.0, width: 20.0, height: 10.0)
        )

        guard let bounds = path.approximateBoundingBox else {
            Issue.record("ellipse should have a bounding box")
            return
        }
        CanvasTests.expectClose(bounds.origin, SIMD2(x: 0.0, y: 0.0))
        CanvasTests.expectClose(bounds.size, SIMD2(x: 20.0, y: 10.0))
    }

    @Test("addEllipse ignores degenerate rectangles")
    func addEllipseIgnoresDegenerateRects() {
        let path = Path().addEllipse(
            in: Path.Rect(x: 0.0, y: 0.0, width: 0.0, height: 10.0)
        )
        #expect(path.actions.isEmpty)
    }

    @Test("closeSubpath draws back to the subpath's start")
    func closeSubpathReturnsToStart() {
        let path = Path()
            .move(to: SIMD2(x: 1.0, y: 1.0))
            .addLine(to: SIMD2(x: 5.0, y: 1.0))
            .addLine(to: SIMD2(x: 5.0, y: 4.0))
            .closeSubpath()

        #expect(path.actions.last == .lineTo(SIMD2(x: 1.0, y: 1.0)))
    }

    @Test("closeSubpath does nothing to an empty subpath")
    func closeSubpathIgnoresEmptySubpaths() {
        let empty = Path().closeSubpath()
        #expect(empty.actions.isEmpty)

        let justMoved = Path().move(to: SIMD2(x: 1.0, y: 1.0)).closeSubpath()
        #expect(justMoved.actions.count == 1)
    }

    // MARK: Trimming

    @Test("Trimming a line takes the requested fraction of it")
    func trimTakesFractionOfLine() {
        let trimmed = CanvasTests.line.trim(from: 0.0, to: 0.5)
        let points = Path.flatten(trimmed.actions)

        #expect(points.count == 1)
        guard points.count == 1 else {
            return
        }
        CanvasTests.expectClose(points[0].first!, SIMD2(x: 0.0, y: 0.0))
        CanvasTests.expectClose(points[0].last!, SIMD2(x: 5.0, y: 0.0))
    }

    @Test("Trimming from the middle skips the leading portion")
    func trimSkipsLeadingPortion() {
        let trimmed = CanvasTests.line.trim(from: 0.25, to: 0.75)
        let points = Path.flatten(trimmed.actions)

        guard points.count == 1 else {
            Issue.record("expected one trimmed subpath")
            return
        }
        CanvasTests.expectClose(points[0].first!, SIMD2(x: 2.5, y: 0.0))
        CanvasTests.expectClose(points[0].last!, SIMD2(x: 7.5, y: 0.0))
    }

    @Test("Trimming wraps around when the start is past the end")
    func trimWrapsAround() {
        let trimmed = CanvasTests.line.trim(from: 0.75, to: 0.25)
        let points = Path.flatten(trimmed.actions)

        #expect(points.count == 2)
        guard points.count == 2 else {
            return
        }
        CanvasTests.expectClose(points[0].first!, SIMD2(x: 7.5, y: 0.0))
        CanvasTests.expectClose(points[0].last!, SIMD2(x: 10.0, y: 0.0))
        CanvasTests.expectClose(points[1].first!, SIMD2(x: 0.0, y: 0.0))
        CanvasTests.expectClose(points[1].last!, SIMD2(x: 2.5, y: 0.0))
    }

    @Test("Trimming an empty range produces an empty path")
    func trimEmptyRangeProducesEmptyPath() {
        #expect(CanvasTests.line.trim(from: 0.4, to: 0.4).actions.isEmpty)
    }

    @Test("Trimming spans multiple segments proportionally")
    func trimSpansMultipleSegments() {
        // An L shape of total length 20, trimmed to its second half, should
        // start halfway along and end at the far corner.
        let shape = Path()
            .move(to: SIMD2(x: 0.0, y: 0.0))
            .addLine(to: SIMD2(x: 10.0, y: 0.0))
            .addLine(to: SIMD2(x: 10.0, y: 10.0))
        let points = Path.flatten(shape.trim(from: 0.5, to: 1.0).actions)

        guard points.count == 1 else {
            Issue.record("expected one trimmed subpath")
            return
        }
        CanvasTests.expectClose(points[0].first!, SIMD2(x: 10.0, y: 0.0))
        CanvasTests.expectClose(points[0].last!, SIMD2(x: 10.0, y: 10.0))
    }

    // MARK: Rendering through a real backend

    #if canImport(AppKitBackend)
        @MainActor
        @Test("Each command becomes one child widget, in drawing order")
        func commandsBecomeChildWidgetsInOrder() {
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    context.fill(CanvasTests.line, with: .color(.red))
                    context.draw(Text("N12"), at: CGPoint(x: 10.0, y: 10.0))
                    context.stroke(CanvasTests.line, with: .color(.blue))
                }
            )
            harness.render()

            let children = harness.container.subviews
            #expect(children.count == 3)
            guard children.count == 3 else {
                return
            }
            #expect(children[0] is AppKitBackend.NSBezierPathView)
            #expect(children[1] is NSTextField)
            #expect(children[2] is AppKitBackend.NSBezierPathView)
            #expect((children[1] as? NSTextField)?.stringValue == "N12")
        }

        @MainActor
        @Test("Fills and strokes reach the backend as colors and geometry")
        func fillsAndStrokesReachTheBackend() {
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    context.fill(CanvasTests.line, with: .color(.red))
                    context.stroke(
                        CanvasTests.line,
                        with: .color(.blue),
                        lineWidth: 4.0
                    )
                }
            )
            harness.render()

            let children = harness.container.subviews
            guard children.count == 2,
                let fill = children[0] as? AppKitBackend.NSBezierPathView,
                let stroke = children[1] as? AppKitBackend.NSBezierPathView
            else {
                Issue.record("expected two path views")
                return
            }

            #expect(fill.strokeColor.alphaComponent == 0.0)
            #expect(fill.fillColor.alphaComponent == 1.0)
            #expect(stroke.fillColor.alphaComponent == 0.0)
            #expect(stroke.strokeColor.alphaComponent == 1.0)
            #expect(stroke.path.lineWidth == 4.0)
            #expect(fill.path.elementCount == 2)
        }

        @MainActor
        @Test("Canvas geometry is flipped into AppKit's coordinate system")
        func geometryIsFlippedForAppKit() {
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    context.fill(CanvasTests.line, with: .color(.red))
                }
            )
            harness.render()

            guard
                let view = harness.container.subviews.first
                    as? AppKitBackend.NSBezierPathView
            else {
                Issue.record("expected a path view")
                return
            }
            // The canvas is 100x50 and the line runs along its top edge, which
            // is y = 50 once AppKit's flipped Y axis is accounted for.
            #expect(abs(view.path.bounds.minY - 50.0) < 0.001)
            #expect(abs(view.path.bounds.minX) < 0.001)
        }

        @MainActor
        @Test("Child widgets are reused when the command list keeps its shape")
        func childWidgetsAreReused() {
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    context.fill(CanvasTests.line, with: .color(.red))
                    context.stroke(CanvasTests.line, with: .color(.blue))
                }
            )
            harness.render()
            let firstPass = harness.container.subviews
            harness.render()
            let secondPass = harness.container.subviews

            #expect(firstPass.count == 2)
            #expect(secondPass.count == 2)
            guard firstPass.count == 2, secondPass.count == 2 else {
                return
            }
            #expect(firstPass[0] === secondPass[0])
            #expect(firstPass[1] === secondPass[1])
        }

        @MainActor
        @Test("The child pool shrinks and grows with the command list")
        func childPoolFollowsCommandCount() {
            let commandCount = CommandCountBox(3)
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    for _ in 0..<commandCount.value {
                        context.fill(CanvasTests.line, with: .color(.red))
                    }
                }
            )

            harness.render()
            #expect(harness.container.subviews.count == 3)
            let survivor = harness.container.subviews.first

            commandCount.value = 1
            harness.render()
            #expect(harness.container.subviews.count == 1)
            #expect(harness.container.subviews.first === survivor)

            commandCount.value = 5
            harness.render()
            #expect(harness.container.subviews.count == 5)
        }

        /// Reads the position that a container was told to put a child at.
        ///
        /// `AppKitBackend` positions children with Auto Layout constraints, so
        /// this reads the constants back off those constraints rather than
        /// waiting for a layout pass.
        ///
        /// - Parameters:
        ///   - child: The child to read the position of.
        ///   - container: The container holding the child.
        /// - Returns: The child's position, as leading and top offsets.
        @MainActor
        static func position(
            of child: NSView,
            in container: NSView
        ) -> SIMD2<Double>? {
            var leading: Double?
            var top: Double?
            for constraint in container.constraints {
                if constraint.firstAnchor === child.leftAnchor {
                    leading = Double(constraint.constant)
                } else if constraint.firstAnchor === child.topAnchor {
                    top = Double(constraint.constant)
                }
            }
            guard let leading, let top else {
                return nil
            }
            return SIMD2(x: leading, y: top)
        }

        @MainActor
        @Test("Text is placed relative to its anchor")
        func textIsPlacedRelativeToItsAnchor() {
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    context.draw(
                        Text("N12"),
                        at: CGPoint(x: 50.0, y: 25.0),
                        anchor: .topLeading
                    )
                    context.draw(
                        Text("N12"),
                        at: CGPoint(x: 50.0, y: 25.0),
                        anchor: .center
                    )
                }
            )
            harness.render()

            let children = harness.container.subviews
            guard children.count == 2,
                let topLeading = CanvasTests.position(
                    of: children[0],
                    in: harness.container
                ),
                let centered = CanvasTests.position(
                    of: children[1],
                    in: harness.container
                )
            else {
                Issue.record("expected two positioned text views")
                return
            }

            CanvasTests.expectClose(topLeading, SIMD2(x: 50.0, y: 25.0))
            #expect(centered.x < topLeading.x)
            #expect(centered.y < topLeading.y)
        }

        @MainActor
        @Test("Text measurement works inside a canvas")
        func textMeasurementWorksInsideACanvas() {
            var measured = CGSize(width: 0.0, height: 0.0)
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    let resolved = context.resolve(Text("N12"))
                    measured = resolved.measure(
                        in: CGSize(width: 1000.0, height: 1000.0)
                    )
                }
            )
            harness.render()

            #expect(measured.width > 0.0)
            #expect(measured.height > 0.0)
        }
    #endif

    @Test("Trimming flattens Bézier curves")
    func trimFlattensBezierCurves() {
        // Control points placed evenly along a straight line make both curves
        // degenerate into that line with a uniform parameterisation, so the
        // halfway point is exactly (5, 0).
        let cubic = Path()
            .move(to: SIMD2(x: 0.0, y: 0.0))
            .addCubicCurve(
                control1: SIMD2(x: 10.0 / 3.0, y: 0.0),
                control2: SIMD2(x: 20.0 / 3.0, y: 0.0),
                to: SIMD2(x: 10.0, y: 0.0)
            )
        let quadratic = Path()
            .move(to: SIMD2(x: 0.0, y: 0.0))
            .addQuadCurve(
                control: SIMD2(x: 5.0, y: 0.0),
                to: SIMD2(x: 10.0, y: 0.0)
            )

        let cubicPoints = Path.flatten(cubic.trim(from: 0.0, to: 0.5).actions)
        let quadraticPoints = Path.flatten(
            quadratic.trim(from: 0.0, to: 0.5).actions
        )

        guard let cubicEnd = cubicPoints.first?.last,
            let quadraticEnd = quadraticPoints.first?.last
        else {
            Issue.record("expected both curves to trim to a subpath")
            return
        }
        CanvasTests.expectClose(cubicEnd, SIMD2(x: 5.0, y: 0.0))
        CanvasTests.expectClose(quadraticEnd, SIMD2(x: 5.0, y: 0.0))
    }

    @Test("Trimming an arc follows its circumference")
    func trimFollowsArcCircumference() {
        // A full circle of radius 10, trimmed to its first quarter, should run
        // from (10, 0) to (0, 10) relative to the arc's center.
        let arc = Path().addArc(
            center: SIMD2(x: 0.0, y: 0.0),
            radius: 10.0,
            startAngle: 0.0,
            endAngle: 2.0 * .pi,
            clockwise: true
        )
        let points = Path.flatten(arc.trim(from: 0.0, to: 0.25).actions)

        guard let first = points.first?.first,
            let last = points.first?.last
        else {
            Issue.record("expected a trimmed arc")
            return
        }
        CanvasTests.expectClose(first, SIMD2(x: 10.0, y: 0.0))
        #expect(abs(last.x) < 0.1)
        #expect(abs(last.y - 10.0) < 0.1)
    }
}
