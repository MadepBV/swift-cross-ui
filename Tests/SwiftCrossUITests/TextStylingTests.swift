import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Text styling")
@MainActor
struct TextStylingTests {
    private func render<V: View>(_ view: V, width: Double = 400) -> DummyBackend.TextView? {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "text"))
        let graph = ViewGraph(for: view, backend: backend, environment: environment)
        _ = graph.computeLayout(
            proposedSize: ProposedViewSize(width, 200),
            environment: environment
        )
        graph.commit()
        return graph.rootNode.concreteNode(for: DummyBackend.self).widget
            .firstWidget(ofType: DummyBackend.TextView.self)
    }

    @Test("SwiftUI's argument order picks a design and a weight")
    func systemFontWithDesignAndWeight() {
        let text = render(
            Text("Title").font(.system(.title, design: .rounded, weight: .bold))
        )
        #expect(text?.font?.design == .rounded)
        #expect(text?.font?.weight == .bold)
    }

    @Test("Font.bold() uses the bold weight")
    func boldFont() {
        #expect(render(Text("Bold").font(.largeTitle.bold()))?.font?.weight == .bold)
    }

    @Test("Tracking reaches the resolved font, from Text and from the environment")
    func trackingResolves() {
        #expect(render(Text("CODE").tracking(8))?.font?.tracking == 8)
        #expect(render(Text("CODE").tracking(-1))?.font?.tracking == -1)
        #expect(render(VStack { Text("CODE") }.tracking(3))?.font?.tracking == 3)
        #expect(render(Text("CODE"))?.font?.tracking == 0)
    }

    @Test("Line spacing adds to the line height")
    func lineSpacingAddsToLineHeight() throws {
        let plain = try #require(render(Text("A"))?.font)
        let spaced = try #require(render(Text("A").lineSpacing(4))?.font)
        #expect(spaced.lineHeight == plain.lineHeight + 4)
        #expect(spaced.pointSize == plain.pointSize)
    }

    @Test("Single-line text shrinks to fit, but not below the minimum")
    func minimumScaleFactorShrinksSingleLineText() throws {
        // DummyBackend draws a character two thirds of the point size wide,
        // so ten characters at 15 points are 100 points wide.
        let label = Text("ABCDEFGHIJ").font(.system(size: 15)).lineLimit(1)

        let fitted = try #require(render(label.minimumScaleFactor(0.5), width: 60)?.font)
        #expect(fitted.pointSize == 9)

        let floored = try #require(render(label.minimumScaleFactor(0.8), width: 60)?.font)
        #expect(floored.pointSize == 12)

        let unscaled = try #require(render(label, width: 60)?.font)
        #expect(unscaled.pointSize == 15)

        let roomy = try #require(render(label.minimumScaleFactor(0.5), width: 200)?.font)
        #expect(roomy.pointSize == 15)
    }

    @Test("Symbol variants compose Apple's symbol names")
    func symbolVariantNames() {
        #expect(SymbolVariants.fill.applied(to: "heart") == "heart.fill")
        #expect(SymbolVariants.fill.applied(to: "heart.fill") == "heart.fill")
        #expect(SymbolVariants.circle.fill.applied(to: "play") == "play.circle.fill")
        #expect(SymbolVariants.slash.applied(to: "bell") == "bell.slash")
        #expect(SymbolVariants.none.applied(to: "star") == "star")
        #expect(SymbolVariants.circle.fill.contains(.fill))
        #expect(!SymbolVariants.fill.contains(.circle))
    }

    @Test("TextAlignment is the multiline alignment")
    func textAlignment() {
        let alignment: TextAlignment = .center
        #expect(alignment == HorizontalAlignment.center)
    }
}
