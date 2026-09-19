import Foundation
import Testing

@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

/// Tests for ``Path``'s two builder spellings and for ``StrokeStyle``,
/// including whether a dash pattern survives the trip into a real backend.
///
/// ``Path`` deliberately exposes SwiftUI's mutating, Core Graphics-flavoured
/// builders alongside SwiftCrossUI's original chaining ones. Most of these
/// tests exist as much to prove that both spellings still *compile* in the
/// positions callers use them in as to check what they compute.
@Suite("Testing for Path and StrokeStyle")
struct PathAndStrokeTests {
    /// A horizontal line from (0, 0) to (10, 0), built by chaining.
    static let line = Path()
        .move(to: SIMD2(x: 0.0, y: 0.0))
        .addLine(to: SIMD2(x: 10.0, y: 0.0))

    // MARK: SwiftUI's mutating spelling

    @Test("The mutating builders modify the path in place")
    func mutatingBuildersModifyInPlace() {
        var path = Path()
        path.move(to: CGPoint(x: 1.0, y: 2.0))
        path.addLine(to: CGPoint(x: 3.0, y: 4.0))

        #expect(
            path.actions == [
                .moveTo(SIMD2(x: 1.0, y: 2.0)),
                .lineTo(SIMD2(x: 3.0, y: 4.0)),
            ]
        )
    }

    @Test("Both builder spellings produce the same actions")
    func spellingsAgree() {
        var mutating = Path()
        mutating.move(to: CGPoint(x: 0.0, y: 0.0))
        mutating.addLine(to: CGPoint(x: 10.0, y: 0.0))

        #expect(mutating.actions == PathAndStrokeTests.line.actions)
    }

    @Test("closeSubpath mutates in statement position")
    func closeSubpathMutatesInStatementPosition() {
        var path = Path()
        path.move(to: CGPoint(x: 1.0, y: 1.0))
        path.addLine(to: CGPoint(x: 5.0, y: 1.0))
        path.closeSubpath()

        #expect(path.actions.count == 3)
        #expect(path.actions.last == .lineTo(SIMD2(x: 1.0, y: 1.0)))
    }

    @Test("closeSubpath still chains off a temporary")
    func closeSubpathStillChains() {
        let path = Path()
            .move(to: SIMD2(x: 1.0, y: 1.0))
            .addLine(to: SIMD2(x: 5.0, y: 1.0))
            .closeSubpath()

        #expect(path.actions.count == 3)
        #expect(path.actions.last == .lineTo(SIMD2(x: 1.0, y: 1.0)))
    }

    @Test("addPath mutates in statement position and chains off a temporary")
    func addPathHasBothSpellings() {
        var mutating = Path()
        mutating.addPath(PathAndStrokeTests.line)

        let chained = Path().addPath(PathAndStrokeTests.line)

        #expect(mutating.actions == chained.actions)
        #expect(mutating.actions == [.subpath(PathAndStrokeTests.line.actions)])
    }

    @Test("trim mutates in statement position and chains off a temporary")
    func trimHasBothSpellings() {
        var mutating = PathAndStrokeTests.line
        mutating.trim(from: 0.0, to: 0.5)

        let chained = PathAndStrokeTests.line.trim(from: 0.0, to: 0.5)

        #expect(mutating.actions == chained.actions)

        let points = Path.flatten(mutating.actions)
        guard points.count == 1 else {
            Issue.record("expected one trimmed subpath")
            return
        }
        #expect(abs(points[0].last!.x - 5.0) < 0.001)
    }

    @Test("The mutating curve builders use SwiftUI's argument order")
    func curveBuildersUseSwiftUIArgumentOrder() {
        var path = Path()
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addQuadCurve(
            to: CGPoint(x: 10.0, y: 0.0),
            control: CGPoint(x: 5.0, y: 5.0)
        )
        path.addCurve(
            to: CGPoint(x: 20.0, y: 0.0),
            control1: CGPoint(x: 12.0, y: 5.0),
            control2: CGPoint(x: 18.0, y: 5.0)
        )

        #expect(
            path.actions == [
                .moveTo(SIMD2(x: 0.0, y: 0.0)),
                .quadCurve(
                    control: SIMD2(x: 5.0, y: 5.0),
                    end: SIMD2(x: 10.0, y: 0.0)
                ),
                .cubicCurve(
                    control1: SIMD2(x: 12.0, y: 5.0),
                    control2: SIMD2(x: 18.0, y: 5.0),
                    end: SIMD2(x: 20.0, y: 0.0)
                ),
            ]
        )
    }

    @Test("addRect is a Core Graphics spelling of addRectangle")
    func addRectMatchesAddRectangle() {
        var mutating = Path()
        mutating.addRect(
            CGRect(origin: .zero, size: CGSize(width: 4.0, height: 2.0))
        )

        let chained = Path().addRectangle(
            Path.Rect(x: 0.0, y: 0.0, width: 4.0, height: 2.0)
        )

        #expect(mutating.actions == chained.actions)
    }

    @Test("addEllipse has a mutating Core Graphics spelling")
    func addEllipseHasBothSpellings() {
        var mutating = Path()
        mutating.addEllipse(
            in: CGRect(origin: .zero, size: CGSize(width: 20.0, height: 10.0))
        )

        let chained = Path().addEllipse(
            in: Path.Rect(x: 0.0, y: 0.0, width: 20.0, height: 10.0)
        )

        #expect(mutating.actions == chained.actions)

        guard let bounds = mutating.approximateBoundingBox else {
            Issue.record("ellipse should have a bounding box")
            return
        }
        #expect(abs(bounds.width - 20.0) < 0.001)
        #expect(abs(bounds.height - 10.0) < 0.001)
    }

    @Test("The mutating addArc wraps angles into the model's range")
    func addArcWrapsAngles() {
        var path = Path()
        path.addArc(
            center: CGPoint(x: 0.0, y: 0.0),
            radius: 5.0,
            startAngle: .radians(-.pi / 2.0),
            endAngle: .radians(0.0),
            clockwise: true
        )

        guard
            case .arc(_, _, let startAngle, let endAngle, _) = path.actions
            .first
        else {
            Issue.record("expected an arc action")
            return
        }
        #expect(abs(startAngle - 3.0 * .pi / 2.0) < 0.001)
        #expect(abs(endAngle) < 0.001)
    }

    @Test("Path.Rect standardizes rectangles with a negative size")
    func rectStandardizesNegativeSizes() {
        let rect = Path.Rect(
            CGRect(
                origin: CGPoint(x: 10.0, y: 10.0),
                size: CGSize(width: -4.0, height: -2.0)
            )
        )

        #expect(rect.x == 6.0)
        #expect(rect.y == 8.0)
        #expect(rect.width == 4.0)
        #expect(rect.height == 2.0)
        #expect(rect.cgRect.origin.x == 6.0)
        #expect(rect.cgRect.size.width == 4.0)
    }

    // MARK: StrokeStyle

    @Test("SwiftUI's initializer stores every stroke property")
    func swiftUIInitializerStoresProperties() {
        let style = StrokeStyle(
            lineWidth: 1.25,
            lineCap: .round,
            lineJoin: .bevel,
            dash: [5.0, 3.0],
            dashPhase: 2.0
        )

        #expect(style.lineWidth == 1.25)
        #expect(style.lineCap == .round)
        #expect(style.lineJoin == .bevel)
        #expect(style.dash == [5.0, 3.0])
        #expect(style.dashPhase == 2.0)
    }

    @Test("The original spelling aliases the same storage")
    func originalSpellingAliasesSameStorage() {
        var style = StrokeStyle(width: 3.0, cap: .square, join: .round)

        #expect(style.lineWidth == 3.0)
        #expect(style.lineCap == .square)
        #expect(style.lineJoin == .round)
        #expect(style.dash.isEmpty)

        style.lineWidth = 4.0
        #expect(style.width == 4.0)

        style.width = 5.0
        #expect(style.lineWidth == 5.0)

        style.dash = [1.0, 1.0]
        style.dashPhase = 0.5
        #expect(style.dash == [1.0, 1.0])
        #expect(style.dashPhase == 0.5)
    }

    @Test("miterLimit reads and writes the miter join's limit")
    func miterLimitFollowsTheJoin() {
        var style = StrokeStyle(lineWidth: 1.0, lineJoin: .miter(limit: 4.0))
        #expect(style.miterLimit == 4.0)

        style.miterLimit = 6.0
        #expect(style.lineJoin == .miter(limit: 6.0))

        // A non-miter join has no limit to change, so writing is a no-op and
        // reading falls back to Core Graphics' default.
        var round = StrokeStyle(lineWidth: 1.0, lineJoin: .round)
        #expect(round.miterLimit == 10.0)
        round.miterLimit = 2.0
        #expect(round.lineJoin == .round)
    }

    @Test("miterLimit overrides the limit carried by lineJoin")
    func miterLimitArgumentWins() {
        let style = StrokeStyle(
            lineWidth: 1.0,
            lineJoin: .miter(limit: 4.0),
            miterLimit: 2.0
        )

        #expect(style.lineJoin == .miter(limit: 2.0))
    }

    @Test("resolvedDash rejects patterns that draw nothing")
    func resolvedDashRejectsEmptyPatterns() {
        let solid = StrokeStyle(lineWidth: 1.0)
        let allZero = StrokeStyle(lineWidth: 1.0, dash: [0.0, 0.0])
        let negative = StrokeStyle(lineWidth: 1.0, dash: [-1.0, 2.0])
        let dashed = StrokeStyle(lineWidth: 1.0, dash: [4.0, 2.0])
        let single = StrokeStyle(lineWidth: 1.0, dash: [4.0])

        #expect(solid.resolvedDash == nil)
        #expect(allZero.resolvedDash == nil)
        #expect(negative.resolvedDash == nil)
        #expect(dashed.resolvedDash == [4.0, 2.0])
        #expect(single.resolvedDash == [4.0])
    }

    // MARK: Dashes reaching a real backend

    #if canImport(AppKitBackend)
        /// Reads the dash pattern back off an `NSBezierPath`.
        ///
        /// - Parameter path: The path to read.
        /// - Returns: The dash pattern and phase currently set on the path.
        static func lineDash(
            of path: NSBezierPath
        ) -> (pattern: [CGFloat], phase: CGFloat) {
            var count = 0
            path.getLineDash(nil, count: &count, phase: nil)
            guard count > 0 else {
                return ([], 0.0)
            }

            var pattern = [CGFloat](repeating: 0.0, count: count)
            var phase: CGFloat = 0.0
            path.getLineDash(&pattern, count: &count, phase: &phase)
            return (pattern, phase)
        }

        /// Pushes a source path through `AppKitBackend.updatePath`.
        ///
        /// - Parameters:
        ///   - source: The path to push through the backend.
        ///   - backend: The backend to use.
        /// - Returns: The `NSBezierPath` the backend built.
        @MainActor
        static func nsBezierPath(
            for source: Path,
            backend: AppKitBackend
        ) -> NSBezierPath {
            let path = backend.createPath()
            backend.updatePath(
                path,
                source,
                bounds: Path.Rect(x: 0.0, y: 0.0, width: 10.0, height: 10.0),
                pointsChanged: true,
                environment: EnvironmentValues(backend: backend)
            )
            return path
        }

        @MainActor
        @Test("A dashed stroke style reaches NSBezierPath")
        func dashReachesNSBezierPath() {
            let backend = AppKitBackend()
            let source = PathAndStrokeTests.line.stroke(
                style: StrokeStyle(
                    lineWidth: 1.25,
                    dash: [5.0, 3.0],
                    dashPhase: 2.0
                )
            )

            let path = PathAndStrokeTests.nsBezierPath(
                for: source,
                backend: backend
            )
            let dash = PathAndStrokeTests.lineDash(of: path)

            #expect(path.lineWidth == 1.25)
            #expect(dash.pattern == [5.0, 3.0])
            #expect(dash.phase == 2.0)
        }

        @MainActor
        @Test("A solid stroke style clears a path's previous dash")
        func solidStrokeClearsPreviousDash() {
            let backend = AppKitBackend()
            let path = backend.createPath()
            let environment = EnvironmentValues(backend: backend)
            let bounds = Path.Rect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)

            backend.updatePath(
                path,
                PathAndStrokeTests.line.stroke(
                    style: StrokeStyle(lineWidth: 1.0, dash: [4.0, 4.0])
                ),
                bounds: bounds,
                pointsChanged: true,
                environment: environment
            )
            #expect(PathAndStrokeTests.lineDash(of: path).pattern == [4.0, 4.0])

            backend.updatePath(
                path,
                PathAndStrokeTests.line.stroke(
                    style: StrokeStyle(lineWidth: 1.0)
                ),
                bounds: bounds,
                pointsChanged: true,
                environment: environment
            )
            #expect(PathAndStrokeTests.lineDash(of: path).pattern.isEmpty)
        }

        @MainActor
        @Test("An overriding stroke style's dash reaches NSBezierPath")
        func overrideStrokeStyleDashReachesNSBezierPath() {
            let backend = AppKitBackend()
            let container = backend.createPathWidget()
            let path = PathAndStrokeTests.nsBezierPath(
                for: PathAndStrokeTests.line,
                backend: backend
            )

            backend.renderPath(
                path,
                container: container,
                strokeColor: Color.Resolved(red: 0.0, green: 0.0, blue: 1.0),
                fillColor: Color.Resolved(
                    red: 0.0,
                    green: 0.0,
                    blue: 0.0,
                    opacity: 0.0
                ),
                overrideStrokeStyle: StrokeStyle(
                    lineWidth: 2.0,
                    dash: [6.0, 2.0, 1.0, 2.0],
                    dashPhase: 3.0
                )
            )

            let dash = PathAndStrokeTests.lineDash(of: path)
            #expect(dash.pattern == [6.0, 2.0, 1.0, 2.0])
            #expect(dash.phase == 3.0)
        }

        @MainActor
        @Test("A canvas's dashed stroke reaches the rendered NSBezierPath")
        func canvasDashReachesRenderedPath() {
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    context.stroke(
                        PathAndStrokeTests.line,
                        with: .color(.blue),
                        style: StrokeStyle(
                            lineWidth: 1.25,
                            dash: [5.0, 3.0],
                            dashPhase: 2.0
                        )
                    )
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

            let dash = PathAndStrokeTests.lineDash(of: view.path)
            #expect(dash.pattern == [5.0, 3.0])
            #expect(dash.phase == 2.0)
        }
    #endif
}
