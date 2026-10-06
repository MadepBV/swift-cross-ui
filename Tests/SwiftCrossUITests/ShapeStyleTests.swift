import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Shape styles")
@MainActor
struct ShapeStyleTests {
    private func environment(
        _ scheme: ColorScheme = .light,
        foreground: Color? = nil,
        tint: Color? = nil
    ) -> EnvironmentValues {
        EnvironmentValues(backend: DummyBackend())
            .with(\.colorScheme, scheme)
            .with(\.foregroundColor, foreground)
            .with(\.tintColor, tint)
    }

    @Test("Hierarchical levels dim the current foreground colour")
    func hierarchicalLevelsFollowForeground() {
        let red = Color(red: 1, green: 0, blue: 0)
        let resolved = Color.secondary.resolve(in: environment(foreground: red))
        #expect(resolved == Color.Resolved(red: 1, green: 0, blue: 0, opacity: 0.6))
        #expect(Color.primary.resolve(in: environment(foreground: red)).opacity == 1)
        #expect(Color.quaternary.resolve(in: environment(foreground: red)).opacity == Float(0.18))
    }

    @Test("Hierarchical levels fall back to the colour scheme's label colour")
    func hierarchicalLevelsFollowColorScheme() {
        #expect(
            Color.secondary.resolve(in: environment(.light))
                == Color.Resolved(red: 0, green: 0, blue: 0, opacity: 0.6)
        )
        #expect(
            Color.secondary.resolve(in: environment(.dark))
                == Color.Resolved(red: 1, green: 1, blue: 1, opacity: 0.6)
        )
    }

    @Test("A nested hierarchical foreground binds to the style outside it")
    func nestedForegroundStyleBindsToOuterStyle() {
        let orange = Color(red: 1, green: 0.5, blue: 0)
        let outer = environment(foreground: orange)
        let bound = Color.secondary.opacity(0.5).bindingStyle(in: outer)
        let inner = outer.with(\.foregroundColor, bound)
        #expect(
            Color.primary.resolve(in: inner)
                == Color.Resolved(red: 1, green: 0.5, blue: 0, opacity: 0.3)
        )
    }

    @Test("The foreground modifier keeps a hierarchical style relative to its parent")
    func foregroundModifierBindsHierarchicalStyle() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "styles"))
        let view = VStack {
            Text("Hello").foregroundStyle(.secondary)
        }
        .foregroundStyle(Color(red: 0, green: 0, blue: 1))
        let graph = ViewGraph(for: view, backend: backend, environment: environment)
        _ = graph.computeLayout(proposedSize: ProposedViewSize(200, 50), environment: environment)
        graph.commit()
        let text = graph.rootNode.concreteNode(for: DummyBackend.self).widget
            .firstWidget(ofType: DummyBackend.TextView.self)
        #expect(text?.color == Color.Resolved(red: 0, green: 0, blue: 1, opacity: 0.6))
    }

    @Test("Tint resolves to the environment's tint, or the accent colour")
    func tintFollowsEnvironment() {
        let green = Color(red: 0, green: 1, blue: 0)
        #expect(Color.tint.resolve(in: environment(tint: green)) == green.resolve(in: environment()))
        #expect(
            Color.tint.resolve(in: environment())
                == Color.accentColor.resolve(in: environment())
        )
    }

    @Test("Styles that refer to each other resolve without recursing")
    func mutuallyReferringStylesTerminate() {
        let environment = environment(foreground: .tint, tint: .secondary)
        #expect(
            Color.secondary.resolve(in: environment)
                == Color.accentColor.opacity(0.6).resolve(in: environment)
        )
    }

    @Test("Materials and fills adapt to the colour scheme")
    func materialsAndFillsAdapt() {
        let light = Material.thin._color.resolve(in: environment(.light))
        let dark = Material.thin._color.resolve(in: environment(.dark))
        #expect(light.red > dark.red)
        #expect(light.opacity == dark.opacity)
        #expect(Material.ultraThin._color.resolve(in: environment()).opacity
            < Material.thick._color.resolve(in: environment()).opacity)

        let primaryFill = FillShapeStyle.primary._color.resolve(in: environment())
        let tertiaryFill = FillShapeStyle.primary.tertiary._color.resolve(in: environment())
        #expect(tertiaryFill.opacity < primaryFill.opacity)
    }

    @Test("Erasing a style keeps its colour")
    func anyShapeStyleKeepsColor() {
        let style = AnyShapeStyle(Color.secondary)
        #expect(style._color == Color.secondary)
        #expect(AnyShapeStyle(Material.regular)._color == Material.regular._color)
    }

    @Test("Shape styles fill and stroke shapes")
    func shapesUseStyles() {
        let filled = Capsule().fill(.fill.secondary)
        #expect(filled.fillColor == FillShapeStyle.primary.secondary._color)

        let bordered = RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.5), lineWidth: 2)
        #expect(bordered.strokeColor == Color.white.opacity(0.5))
        #expect(bordered.strokeStyle?.lineWidth == 2)
    }

    @Test("Shape transforms turn and scale around their anchor")
    func shapeTransformsUseAnchor() {
        func apply(_ transform: SwiftCrossUI.AffineTransform, _ point: SIMD2<Double>) -> SIMD2<Double> {
            let m = transform.linearTransform
            return SIMD2(m.x * point.x + m.y * point.y, m.z * point.x + m.w * point.y)
                + transform.translation
        }
        let bounds = Path.Rect(x: 0, y: 0, width: 100, height: 10)

        let scale = ShapeTransform.scale(SIMD2(0.5, 1), anchor: .leading)
            .affineTransform(in: bounds)
        #expect(apply(scale, SIMD2(100, 5)) == SIMD2(50, 5))
        #expect(apply(scale, SIMD2(0, 5)) == SIMD2(0, 5))

        let square = Path.Rect(x: 0, y: 0, width: 10, height: 10)
        let rotation = ShapeTransform.rotation(.degrees(-90), anchor: .center)
            .affineTransform(in: square)
        let top = apply(rotation, SIMD2(10, 5))
        #expect(abs(top.x - 5) < 1e-9)
        #expect(abs(top.y - 0) < 1e-9)
    }
}
