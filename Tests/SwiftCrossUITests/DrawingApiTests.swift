import Foundation
import Testing

@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

/// Tests for the drawing vocabulary that SwiftUI code reaches for when it
/// builds a hatch swatch, a mesh preview or a profile sketch: ``Path``'s
/// rectangular initializer, ``FillStyle``, and the anchored text form of
/// ``GraphicsContext/draw(_:at:anchor:)``.
///
/// The parts that can only be observed once a drawing has reached a real
/// renderer — the winding rule a fill ends up with, and where an anchored run
/// of text is actually placed — are checked through `AppKitBackend` rather
/// than by asserting on the recorded command list.
@Suite("Testing for the drawing API")
struct DrawingApiTests {
    /// The size handed to every renderer under test.
    static let size = CGSize(width: 100.0, height: 50.0)

    /// A square that self-intersects nothing, used as a fill subject.
    static let square = Path(CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0))

    /// Records the commands issued by a renderer.
    ///
    /// - Parameter renderer: The renderer to run.
    /// - Returns: The recorded commands.
    @MainActor
    static func record(
        _ renderer: @escaping Canvas.Renderer
    ) -> [GraphicsContext.Command] {
        Canvas(renderer: renderer).record(size: DrawingApiTests.size)
    }

    /// Extracts the fill rule of the single recorded fill command.
    ///
    /// - Parameter commands: The commands to search.
    /// - Returns: The fill's rule, or `nil` if there isn't exactly one fill.
    static func onlyFillRule(
        _ commands: [GraphicsContext.Command]
    ) -> FillRule? {
        guard commands.count == 1, case .fill(let fill) = commands[0] else {
            return nil
        }
        return fill.path.fillRule
    }

    // MARK: Path(_ rect: CGRect)

    @Test("Path(_:) encloses the rectangle it is given")
    func rectangleInitializerEnclosesTheRectangle() {
        let rect = CGRect(x: 1.0, y: 2.0, width: 3.0, height: 4.0)

        #expect(
            Path(rect).actions == [
                .rectangle(Path.Rect(x: 1.0, y: 2.0, width: 3.0, height: 4.0))
            ]
        )
    }

    @Test("Path(_:) agrees with addRect(_:) on an empty path")
    func rectangleInitializerAgreesWithAddRect() {
        let rect = CGRect(x: -5.0, y: 7.5, width: 20.0, height: 0.5)
        var built = Path()
        built.addRect(rect)

        #expect(Path(rect).actions == built.actions)
    }

    @Test("Path(_:) standardizes a negatively sized rectangle")
    func rectangleInitializerStandardizesNegativeSizes() {
        let flipped = CGRect(x: 10.0, y: 10.0, width: -4.0, height: -6.0)

        #expect(
            Path(flipped).actions == [
                .rectangle(Path.Rect(x: 6.0, y: 4.0, width: 4.0, height: 6.0))
            ]
        )
    }

    @Test("Path(_:) composes with the mutating builders")
    func rectangleInitializerComposesWithBuilders() {
        // The shape a hatch swatch draws: a bounding box with a diagonal
        // through it, built from the rectangle initializer.
        var path = Path(CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0))
        path.move(to: CGPoint(x: 0.0, y: 10.0))
        path.addLine(to: CGPoint(x: 10.0, y: 0.0))

        #expect(path.actions.count == 3)
        #expect(
            path.actions.first
                == .rectangle(
                    Path.Rect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
                )
        )
    }

    // MARK: FillStyle

    @Test("FillStyle's defaults match SwiftUI's")
    func fillStyleDefaultsMatchSwiftUI() {
        let style = FillStyle()

        #expect(style.isEOFilled == false)
        #expect(style.isAntialiased == true)
        #expect(FillStyle(eoFill: true).isEOFilled == true)
        #expect(FillStyle(antialiased: false).isAntialiased == false)
        #expect(FillStyle() == FillStyle(eoFill: false, antialiased: true))
        #expect(FillStyle() != FillStyle(eoFill: true))
    }

    // MARK: GraphicsContext.fill(_:with:style:)

    @MainActor
    @Test("fill(_:with:style:) applies the style's fill rule")
    func fillStyleAppliesItsFillRule() {
        let evenOdd = DrawingApiTests.record { context, _ in
            context.fill(
                DrawingApiTests.square,
                with: .color(.red),
                style: FillStyle(eoFill: true)
            )
        }
        let winding = DrawingApiTests.record { context, _ in
            context.fill(
                DrawingApiTests.square,
                with: .color(.red),
                style: FillStyle()
            )
        }

        #expect(DrawingApiTests.onlyFillRule(evenOdd) == .evenOdd)
        #expect(DrawingApiTests.onlyFillRule(winding) == .winding)
    }

    @MainActor
    @Test("fill(_:with:style:) overrides the path's own fill rule")
    func fillStyleOverridesThePathsFillRule() {
        let commands = DrawingApiTests.record { context, _ in
            context.fill(
                DrawingApiTests.square.fillRule(.winding),
                with: .color(.red),
                style: FillStyle(eoFill: true)
            )
        }

        #expect(DrawingApiTests.onlyFillRule(commands) == .evenOdd)
    }

    @MainActor
    @Test("fill(_:with:) without a style keeps the path's fill rule")
    func fillWithoutAStyleKeepsThePathsFillRule() {
        let inherited = DrawingApiTests.record { context, _ in
            context.fill(
                DrawingApiTests.square.fillRule(.winding),
                with: .color(.red)
            )
        }
        let defaulted = DrawingApiTests.record { context, _ in
            context.fill(DrawingApiTests.square, with: .color(.red))
        }

        #expect(DrawingApiTests.onlyFillRule(inherited) == .winding)
        #expect(DrawingApiTests.onlyFillRule(defaulted) == .evenOdd)
    }

    @MainActor
    @Test("A fill style survives the context's transform")
    func fillStyleSurvivesATransform() {
        let commands = DrawingApiTests.record { context, _ in
            var scaled = context
            scaled.scaleBy(x: 2.0, y: 2.0)
            scaled.fill(
                DrawingApiTests.square,
                with: .color(.red),
                style: FillStyle(eoFill: true)
            )
        }

        #expect(DrawingApiTests.onlyFillRule(commands) == .evenOdd)
    }

    // MARK: Rendering through a real backend

    #if canImport(AppKitBackend)
        /// Renders a canvas and returns the winding rules of its path widgets.
        ///
        /// - Parameter canvas: The canvas to render.
        /// - Returns: One winding rule per path widget, in drawing order.
        @MainActor
        static func windingRules(
            of canvas: Canvas
        ) -> [NSBezierPath.WindingRule] {
            let harness = AppKitCanvasHarness(canvas: canvas)
            harness.render()
            return harness.container.subviews.compactMap { child in
                (child as? AppKitBackend.NSBezierPathView)?.path.windingRule
            }
        }

        @MainActor
        @Test("A fill style reaches the backend as a winding rule")
        func fillStyleReachesTheBackend() {
            let rules = DrawingApiTests.windingRules(
                of: Canvas { context, size in
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(.red),
                        style: FillStyle(eoFill: true)
                    )
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(.blue),
                        style: FillStyle()
                    )
                }
            )

            #expect(rules == [.evenOdd, .nonZero])
        }

        @MainActor
        @Test("A path's own fill rule reaches the backend")
        func pathFillRuleReachesTheBackend() {
            let rules = DrawingApiTests.windingRules(
                of: Canvas { context, _ in
                    context.fill(
                        DrawingApiTests.square.fillRule(.winding),
                        with: .color(.red)
                    )
                    context.fill(
                        DrawingApiTests.square.fillRule(.evenOdd),
                        with: .color(.blue)
                    )
                }
            )

            #expect(rules == [.nonZero, .evenOdd])
        }

        @MainActor
        @Test("draw(_:at:anchor:) anchors each axis independently")
        func anchoredTextMovesOnBothAxes() {
            // The three anchors that a marker-style preview uses to pin a
            // label to a glyph. `.leading` should differ from `.topLeading`
            // only vertically, and `.top` only horizontally.
            let harness = AppKitCanvasHarness(
                canvas: Canvas { context, _ in
                    context.draw(
                        Text("+2.70"),
                        at: CGPoint(x: 50.0, y: 25.0),
                        anchor: .topLeading
                    )
                    context.draw(
                        Text("+2.70"),
                        at: CGPoint(x: 50.0, y: 25.0),
                        anchor: .leading
                    )
                    context.draw(
                        Text("+2.70"),
                        at: CGPoint(x: 50.0, y: 25.0),
                        anchor: .top
                    )
                }
            )
            harness.render()

            let children = harness.container.subviews
            guard children.count == 3 else {
                Issue.record("expected three text views")
                return
            }
            let positions = children.compactMap { child in
                CanvasTests.position(of: child, in: harness.container)
            }
            guard positions.count == 3 else {
                Issue.record("expected three positioned text views")
                return
            }
            let (topLeading, leading, top) = (
                positions[0], positions[1], positions[2]
            )

            CanvasTests.expectClose(topLeading, SIMD2(x: 50.0, y: 25.0))
            #expect(leading.x == topLeading.x)
            #expect(leading.y < topLeading.y)
            #expect(top.y == topLeading.y)
            #expect(top.x < topLeading.x)
        }
    #endif
}
