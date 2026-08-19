import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend

    /// Drives a ``Canvas`` through `AppKitBackend` with a chosen environment
    /// font, so that the font and color a drawn ``Text`` ends up wearing can be
    /// read back off the backend's text widget.
    ///
    /// This is deliberately separate from the harness in `CanvasTests`, which
    /// always renders with the default environment.
    @MainActor
    final class StyledCanvasHarness {
        /// The view graph holding the canvas.
        private let viewGraph: ViewGraph<Canvas>
        /// The environment that layout runs in.
        private let environment: EnvironmentValues

        /// The canvas' container widget.
        var container: NSView {
            viewGraph.rootNode.widget.into()
        }

        /// Creates a harness for the given canvas.
        ///
        /// - Parameters:
        ///   - canvas: The canvas to render.
        ///   - font: The font to seed the environment with, or `nil` to leave
        ///     the environment's default in place.
        init(canvas: Canvas, font: Font? = nil) {
            let backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(200, 200),
                id: "window"
            )
            var environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            if let font {
                environment = environment.with(\.font, font)
            }
            self.environment = environment
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

        /// The attributes of the only text widget the canvas produced.
        var textAttributes: [NSAttributedString.Key: Any]? {
            let field = container.subviews.compactMap { child in
                child as? NSTextField
            }.first
            guard let field, field.attributedStringValue.length > 0 else {
                return nil
            }
            return field.attributedStringValue.attributes(
                at: 0,
                effectiveRange: nil
            )
        }
    }
#endif

/// A mutable slot that a view-building closure can write into.
final class GeometryObservation {
    /// The size most recently handed to a ``GeometryReader``'s content.
    var size: CGSize?

    /// Creates an empty observation.
    init() {}

    /// Records a size and returns a placeholder view.
    ///
    /// ``ViewBuilder`` can't collect a bare assignment, so the recording has
    /// to happen inside an expression that produces a view.
    ///
    /// - Parameter size: The size to record.
    /// - Returns: A placeholder to fill the geometry reader with.
    func record(_ size: CGSize) -> Color {
        self.size = size
        return .blue
    }
}

/// Tests for the SwiftUI vocabulary that a drawing-heavy app reaches for when
/// it measures its own canvas and labels it: ``GeometryProxy``'s size, the
/// styling attributes that ``Text`` carries with it, and the `CGFloat` typing
/// of ``View/frame(width:height:alignment:)``.
///
/// The attribute tests deliberately assert on what reaches `AppKitBackend`
/// rather than on what got stored on the ``Text``. Storing an attribute is the
/// easy half; the half that actually broke real code is whether a styled
/// ``Text`` handed to ``GraphicsContext/draw(_:at:anchor:)`` comes out of the
/// other end wearing its font and its color.
@Suite("Testing for Text attributes and geometry types")
struct TextAttributesAndGeometryTests {
    /// A stand-in for an app type that consumes a proxy's size.
    ///
    /// Its initializer takes `CGSize` and nothing else, so the geometry tests
    /// only compile if ``GeometryProxy/size`` really is a `CGSize`.
    struct Mapping {
        /// The size that the mapping covers.
        let size: CGSize

        /// Creates a mapping over a size.
        ///
        /// - Parameter size: The size to cover.
        init(size: CGSize) {
            self.size = size
        }
    }

    /// The point size that the styling tests ask for.
    ///
    /// Deliberately unlike any default, so that inheriting the environment's
    /// font instead of the text's own would be obvious.
    static let styledPointSize = 21.0

    /// An unambiguous, non-adaptive ink color for the styling tests.
    ///
    /// Every component is exactly representable as a `Float`, so the expected
    /// value can be written out by hand.
    static let ink = Color(red: 0.25, green: 0.5, blue: 0.75)

    /// ``ink`` as the backend receives it.
    static let resolvedInk = Color.Resolved(red: 0.25, green: 0.5, blue: 0.75)

    // MARK: GeometryProxy

    @MainActor
    @Test("GeometryProxy.size is a CGSize, and carries the proposal")
    func geometryProxySizeIsCGSize() {
        let observation = GeometryObservation()
        let view = GeometryReader { proxy in
            // The call that used to fail with 'cannot convert value of type
            // ViewSize to expected argument type CGSize'.
            observation.record(Mapping(size: proxy.size).size)
        }

        _ = renderWithDummyBackend(view, proposedSize: ProposedViewSize(80, 40))

        #expect(observation.size == CGSize(width: 80.0, height: 40.0))
    }

    @MainActor
    @Test("GeometryProxy's size feeds straight into CGGeometry")
    func geometryProxySizeComposesWithCoreGraphics() {
        let observation = GeometryObservation()
        let view = GeometryReader { proxy in
            observation.record(
                CGRect(origin: .zero, size: proxy.size).size
            )
        }

        _ = renderWithDummyBackend(view, proposedSize: ProposedViewSize(30, 15))

        #expect(observation.size == CGSize(width: 30.0, height: 15.0))
    }

    // MARK: Text's own modifiers

    @Test("Text's style modifiers keep returning Text")
    func styleModifiersReturnText() {
        // Every one of these has to stay a `Text`, because that's what
        // `GraphicsContext.draw(_:at:anchor:)` demands. The type annotations
        // are the assertion; without `Text`-returning overloads they would
        // resolve to the `View` modifiers and erase to `some View`.
        let font: Text = Text("N12").font(.title)
        let weight: Text = Text("N12").fontWeight(.semibold)
        let design: Text = Text("N12").fontDesign(.monospaced)
        let color: Text = Text("N12").foregroundColor(.blue)
        let bold: Text = Text("N12").bold()
        let italic: Text = Text("N12").italic()
        let monospaced: Text = Text("N12").monospaced()
        let monospacedDigit: Text = Text("N12").monospacedDigit()
        let struck: Text = Text("N12").strikethrough()
        let underlined: Text = Text("N12").underline(true, color: .red)

        // A full chain, in the order the application writes it.
        let chained: Text = Text("N12")
            .font(.system(size: 9.0))
            .fontWeight(.semibold)
            .foregroundColor(.blue)

        #expect(font.attributes.font == .title)
        #expect(weight.attributes.weight == .semibold)
        #expect(design.attributes.design == .monospaced)
        #expect(color.attributes.foregroundColor == .blue)
        #expect(bold.attributes.isEmphasized)
        #expect(italic.attributes.isItalic)
        #expect(monospaced.attributes.design == .monospaced)
        #expect(monospacedDigit.attributes.usesMonospacedDigits)
        #expect(struck.attributes.isStruckThrough)
        #expect(underlined.attributes.underlineColor == .red)
        #expect(chained.attributes.font == .system(size: 9.0))
        #expect(chained.attributes.weight == .semibold)
        #expect(chained.attributes.foregroundColor == .blue)
        #expect(chained.string == "N12")
    }

    @MainActor
    @Test("An inferred Text chain stays a Text")
    func inferredTextChainStaysAText() {
        // The application binds the styled run of text to a `let` and only
        // draws it a few lines later, so type inference has to land on `Text`
        // with no contextual type to help it. It does that only while
        // ``Text``'s modifiers cost no more conversions than the ``View``
        // modifiers of the same name — hence the optional parameters on
        // ``View/font(_:)`` and ``View/foregroundColor(_:)``. If this
        // regresses, the chain silently erases to `some View` again and the
        // `resolve` call below stops compiling.
        let label = Text("N12")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(.blue)

        let context = GraphicsContext(recorder: GraphicsContext.Recorder())
        let resolved = context.resolve(label)

        #expect(resolved.string == "N12")
        #expect(resolved.font == Font.title.weight(.semibold))
        #expect(resolved.shading.namesAColor)
    }

    @Test("Passing false to a Text style modifier turns it back off")
    func styleModifiersHonourTheirActiveFlag() {
        #expect(!Text("N12").bold().bold(false).attributes.isEmphasized)
        #expect(!Text("N12").italic().italic(false).attributes.isItalic)
        #expect(
            Text("N12").monospaced().monospaced(false).attributes.design
                == .default
        )
        #expect(Text("N12").font(.title).font(nil).attributes.font == nil)
    }

    // MARK: Resolving text in a graphics context

    @MainActor
    @Test("resolve(_:) prefers the text's own font over the context's")
    func resolveUsesTheTextsOwnFont() {
        let context = GraphicsContext(
            recorder: GraphicsContext.Recorder(),
            font: .body
        )

        #expect(context.resolve(Text("N12")).font == .body)
        #expect(
            context.resolve(Text("N12").font(.system(size: 9.0))).font
                == .system(size: 9.0)
        )
    }

    @MainActor
    @Test("resolve(_:) folds the weight into the inherited font")
    func resolveFoldsWeightIntoTheInheritedFont() {
        let context = GraphicsContext(
            recorder: GraphicsContext.Recorder(),
            font: .body
        )
        let resolved = context.resolve(Text("N12").fontWeight(.semibold))

        #expect(resolved.font == Font.body.weight(.semibold))
    }

    @MainActor
    @Test("resolve(_:) turns a text color into a shading")
    func resolveTurnsTheTextColorIntoShading() {
        let context = GraphicsContext(recorder: GraphicsContext.Recorder())

        #expect(!context.resolve(Text("N12")).shading.namesAColor)
        #expect(
            context.resolve(Text("N12").foregroundColor(.blue))
                .shading.namesAColor
        )
    }

    // MARK: The Text a Canvas actually draws

    #if canImport(AppKitBackend)
        @MainActor
        @Test("A drawn Text's font reaches AppKitBackend")
        func drawnTextCarriesItsFontToTheBackend() throws {
            let size = TextAttributesAndGeometryTests.styledPointSize
            let attributes = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12").font(.system(size: size))
            )
            let font = try #require(attributes[.font] as? NSFont)

            #expect(font.pointSize == CGFloat(size))
        }

        @MainActor
        @Test("A drawn Text's weight reaches AppKitBackend")
        func drawnTextCarriesItsWeightToTheBackend() throws {
            let size = TextAttributesAndGeometryTests.styledPointSize
            let semibold = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12")
                    .font(.system(size: size))
                    .fontWeight(.semibold)
            )
            let regular = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12").font(.system(size: size))
            )

            let semiboldFont = try #require(semibold[.font] as? NSFont)
            let regularFont = try #require(regular[.font] as? NSFont)
            let expected = NSFont.systemFont(
                ofSize: CGFloat(size),
                weight: .semibold
            )

            #expect(semiboldFont.fontName == expected.fontName)
            #expect(semiboldFont.fontName != regularFont.fontName)
        }

        @MainActor
        @Test("A drawn Text's color reaches AppKitBackend")
        func drawnTextCarriesItsColorToTheBackend() throws {
            let styled = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12")
                    .foregroundColor(TextAttributesAndGeometryTests.ink)
            )
            let inherited = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12")
            )

            let styledColor = try #require(styled[.foregroundColor] as? NSColor)
            let inheritedColor = try #require(
                inherited[.foregroundColor] as? NSColor
            )

            #expect(
                styledColor
                    == TextAttributesAndGeometryTests.resolvedInk.nsColor
            )
            #expect(styledColor != inheritedColor)
        }

        @MainActor
        @Test("The application's whole draw(_:at:anchor:) chain reaches the backend")
        func drawnTextCarriesTheWholeChainToTheBackend() throws {
            // Exactly the shape the application writes inside a renderer.
            let size = TextAttributesAndGeometryTests.styledPointSize
            let attributes = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("+2.70")
                    .font(.system(size: size))
                    .fontWeight(.semibold)
                    .foregroundColor(TextAttributesAndGeometryTests.ink)
            )

            let font = try #require(attributes[.font] as? NSFont)
            let color = try #require(attributes[.foregroundColor] as? NSColor)
            let expected = NSFont.systemFont(
                ofSize: CGFloat(size),
                weight: .semibold
            )

            #expect(font.pointSize == CGFloat(size))
            #expect(font.fontName == expected.fontName)
            #expect(color == TextAttributesAndGeometryTests.resolvedInk.nsColor)
        }

        @MainActor
        @Test("A drawn Text's italic and monospaced attributes reach the backend")
        func drawnTextCarriesItsDesignToTheBackend() throws {
            let size = TextAttributesAndGeometryTests.styledPointSize
            let plain = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12").font(.system(size: size))
            )
            let italic = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12").font(.system(size: size)).italic()
            )
            let monospaced = try TextAttributesAndGeometryTests.drawnAttributes(
                of: Text("N12").font(.system(size: size)).monospaced()
            )

            let plainFont = try #require(plain[.font] as? NSFont)
            let italicFont = try #require(italic[.font] as? NSFont)
            let monospacedFont = try #require(monospaced[.font] as? NSFont)

            #expect(italicFont.fontName != plainFont.fontName)
            #expect(
                monospacedFont.fontName
                    == NSFont.monospacedSystemFont(
                        ofSize: CGFloat(size),
                        weight: .regular
                    ).fontName
            )
        }

        @MainActor
        @Test("An unstyled drawn Text still inherits the canvas' font")
        func unstyledDrawnTextInheritsTheCanvasFont() throws {
            let size = TextAttributesAndGeometryTests.styledPointSize
            let harness = StyledCanvasHarness(
                canvas: Canvas { context, _ in
                    context.draw(Text("N12"), at: CGPoint(x: 10.0, y: 10.0))
                },
                font: .system(size: size)
            )
            harness.render()

            let attributes = try #require(harness.textAttributes)
            let font = try #require(attributes[.font] as? NSFont)

            #expect(font.pointSize == CGFloat(size))
        }

        @MainActor
        @Test("A drawn Text's font beats the canvas' inherited font")
        func drawnTextFontBeatsTheCanvasFont() throws {
            let size = TextAttributesAndGeometryTests.styledPointSize
            let harness = StyledCanvasHarness(
                canvas: Canvas { context, _ in
                    context.draw(
                        Text("N12").font(.system(size: size)),
                        at: CGPoint(x: 10.0, y: 10.0)
                    )
                },
                font: .system(size: 7.0)
            )
            harness.render()

            let attributes = try #require(harness.textAttributes)
            let font = try #require(attributes[.font] as? NSFont)

            #expect(font.pointSize == CGFloat(size))
        }

        @MainActor
        @Test("A styled Text rendered as a view reaches AppKitBackend")
        func styledTextRenderedAsAViewReachesTheBackend() throws {
            let size = TextAttributesAndGeometryTests.styledPointSize
            let field = try #require(
                TextAttributesAndGeometryTests.renderWithAppKit(
                    Text("N12")
                        .font(.system(size: size))
                        .fontWeight(.semibold)
                        .foregroundColor(TextAttributesAndGeometryTests.ink)
                )
            )
            let attributes = field.attributedStringValue.attributes(
                at: 0,
                effectiveRange: nil
            )

            let font = try #require(attributes[.font] as? NSFont)
            let color = try #require(attributes[.foregroundColor] as? NSColor)
            let expected = NSFont.systemFont(
                ofSize: CGFloat(size),
                weight: .semibold
            )

            #expect(font.pointSize == CGFloat(size))
            #expect(font.fontName == expected.fontName)
            #expect(color == TextAttributesAndGeometryTests.resolvedInk.nsColor)
        }

        @MainActor
        @Test("The View font modifier still styles views that aren't Text")
        func viewFontModifierStillStylesOtherViews() throws {
            // `View.font(_:)` takes an optional now, so that `Text`'s own
            // modifier wins on a `Text`. It still has to work on everything
            // else, and `nil` has to mean 'inherit'.
            let size = TextAttributesAndGeometryTests.styledPointSize
            let styled = try #require(
                TextAttributesAndGeometryTests.renderWithAppKit(
                    VStack {
                        Text("N12")
                    }
                    .font(.system(size: size))
                )
            )
            let cleared = try #require(
                TextAttributesAndGeometryTests.renderWithAppKit(
                    VStack {
                        Text("N12")
                    }
                    .font(nil)
                )
            )

            let styledFont = try #require(
                styled.attributedStringValue.attributes(
                    at: 0,
                    effectiveRange: nil
                )[.font] as? NSFont
            )
            let clearedFont = try #require(
                cleared.attributedStringValue.attributes(
                    at: 0,
                    effectiveRange: nil
                )[.font] as? NSFont
            )

            #expect(styledFont.pointSize == CGFloat(size))
            #expect(clearedFont.pointSize != CGFloat(size))
        }

        @MainActor
        @Test("A Text's font beats the surrounding hierarchy's font")
        func textFontOverridesTheEnvironment() throws {
            let size = TextAttributesAndGeometryTests.styledPointSize
            let field = try #require(
                TextAttributesAndGeometryTests.renderWithAppKit(
                    VStack {
                        Text("N12").font(.system(size: size))
                    }
                    .font(.system(size: 7.0))
                )
            )
            let attributes = field.attributedStringValue.attributes(
                at: 0,
                effectiveRange: nil
            )
            let font = try #require(attributes[.font] as? NSFont)

            #expect(font.pointSize == CGFloat(size))
        }

        /// Draws one run of text into a canvas and reports the attributes that
        /// reached the backend's text widget.
        ///
        /// - Parameter text: The text to draw.
        /// - Returns: The attributes of the resulting `NSTextField`.
        @MainActor
        static func drawnAttributes(
            of text: Text
        ) throws -> [NSAttributedString.Key: Any] {
            let harness = StyledCanvasHarness(
                canvas: Canvas { context, _ in
                    context.draw(text, at: CGPoint(x: 10.0, y: 10.0))
                }
            )
            harness.render()

            return try #require(harness.textAttributes)
        }

        /// Renders a view with `AppKitBackend` and finds its first text field.
        ///
        /// - Parameter view: The view to render.
        /// - Returns: The first `NSTextField` in the rendered hierarchy, or
        ///   `nil` if there isn't one.
        @MainActor
        static func renderWithAppKit<Content: View>(
            _ view: Content
        ) -> NSTextField? {
            let backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(200, 200),
                id: "window"
            )
            let environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            let node = ViewGraphNode(
                for: view,
                backend: backend,
                environment: environment
            )
            _ = node.computeLayout(
                proposedSize: ProposedViewSize(200, 200),
                environment: environment
            )
            _ = node.commit()

            return firstTextField(in: node.widget)
        }

        /// Searches a widget hierarchy for a text field, depth first.
        ///
        /// - Parameter view: The root of the hierarchy to search.
        /// - Returns: The first text field found, or `nil`.
        @MainActor
        static func firstTextField(in view: NSView) -> NSTextField? {
            if let field = view as? NSTextField {
                return field
            }
            for child in view.subviews {
                if let field = firstTextField(in: child) {
                    return field
                }
            }
            return nil
        }
    #endif

    // MARK: frame's CGFloat typing

    @MainActor
    @Test("frame(minHeight:) accepts a CGFloat without a conversion")
    func frameAcceptsCGFloat() {
        // The application's shape: a `CGFloat` control height fed straight
        // into `max(_:_:)` and then into the modifier. With a `Double?`
        // parameter this failed with 'conflicting arguments to generic
        // parameter T (CGFloat vs Double)'.
        let controlHeight: CGFloat = 34.0
        let view = Color.blue.frame(minHeight: max(controlHeight, 28.0))

        let size = renderWithDummyBackend(
            view,
            proposedSize: ProposedViewSize(50, 10)
        )

        #expect(size.height == 34.0)
    }

    @MainActor
    @Test("frame(width:height:) accepts CGFloats")
    func strictFrameAcceptsCGFloat() {
        let width: CGFloat = 40.0
        let height: CGFloat = 20.0
        let view = Color.blue.frame(width: width, height: height)

        let size = renderWithDummyBackend(
            view,
            proposedSize: ProposedViewSize(100, 100)
        )

        #expect(size == ViewSize(40.0, 20.0))
    }

    @MainActor
    @Test("frame still accepts literals and .infinity")
    func frameStillAcceptsLiteralsAndInfinity() {
        let literal = renderWithDummyBackend(
            Color.blue.frame(width: 12, height: 8),
            proposedSize: ProposedViewSize(100, 100)
        )
        let filling = renderWithDummyBackend(
            Color.blue.frame(maxWidth: .infinity, maxHeight: .infinity),
            proposedSize: ProposedViewSize(60, 30)
        )

        #expect(literal == ViewSize(12.0, 8.0))
        #expect(filling == ViewSize(60.0, 30.0))
    }

    /// Lays a view out with a ``DummyBackend`` and reports the size it took.
    ///
    /// - Parameters:
    ///   - view: The view to lay out.
    ///   - proposedSize: The size to propose to the view.
    /// - Returns: The size that the view laid out at.
    @MainActor
    func renderWithDummyBackend<Content: View>(
        _ view: Content,
        proposedSize: ProposedViewSize
    ) -> ViewSize {
        let backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "window")
        let environment = EnvironmentValues(backend: backend)
            .with(\.window, window)
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        let layout = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        return layout.size
    }
}

extension GraphicsContext.Shading {
    /// Whether this shading names an explicit color rather than deferring to
    /// the canvas' inherited foreground style.
    var namesAColor: Bool {
        switch storage {
            case .color:
                true
            case .foreground:
                false
        }
    }
}

