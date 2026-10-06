import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Prominent buttons and border shapes")
@MainActor
struct ProminentButtonTests {
    @Test("The prominent styles are prominent and fill with the tint, else the accent colour")
    func prominentStylesFillWithTheTint() {
        let environment = EnvironmentValues(backend: DummyBackend())
        #expect(!environment.resolvedButtonIsProminent)
        for style in [BorderedProminentButtonStyle() as any ButtonStyle, GlassProminentButtonStyle()] {
            #expect(environment.with(\.buttonStyle, style).resolvedButtonIsProminent)
        }
        for style in [BorderedButtonStyle() as any ButtonStyle, GlassButtonStyle(), PlainButtonStyle()] {
            #expect(!environment.with(\.buttonStyle, style).resolvedButtonIsProminent)
        }
        #expect(environment.prominentButtonFill == .accentColor)
        #expect(environment.with(\.tintColor, .white).prominentButtonFill == .white)
    }

    @Test("A border shape gives the corner radius a backend draws")
    func borderShapeCornerRadius() {
        let size = SIMD2<Double>(250, 42)
        #expect(ButtonBorderShape.automatic.cornerRadius(forSize: size) == nil)
        #expect(ButtonBorderShape.roundedRectangle.cornerRadius(forSize: size) == nil)
        #expect(ButtonBorderShape.capsule.cornerRadius(forSize: size) == 21)
        #expect(ButtonBorderShape.circle.cornerRadius(forSize: SIMD2(44, 44)) == 22)
        #expect(ButtonBorderShape.roundedRectangle(radius: 8).cornerRadius(forSize: size) == 8)
    }
}
