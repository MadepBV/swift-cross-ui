import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

extension FocusedValues {
    @Entry var entryMacroTestSelection: String?
}

@Suite("System settings in the environment")
struct SystemSettingsEnvironmentTests {
    @MainActor
    @Test("Backends that report nothing get the documented defaults")
    func defaults() {
        let environment = ViewGraphHelpers.environment
        #expect(environment.accessibilityReduceMotion == false)
        #expect(environment.accessibilityVoiceOverEnabled == false)
        #expect(environment.accessibilitySwitchControlEnabled == false)
        #expect(environment.dynamicTypeSize == .large)
        #expect(environment.horizontalSizeClass == .regular)
        #expect(environment.verticalSizeClass == .regular)
        #expect(environment.isFocused == false)
        #expect(environment.displayScale == CGFloat(environment.windowScaleFactor))
    }

    @MainActor
    @Test("Explicit values override the system's")
    func overrides() {
        let environment = ViewGraphHelpers.environment
            .with(\.accessibilityReduceMotion, true)
            .with(\.dynamicTypeSize, .accessibility2)
            .with(\.displayScale, 2)
        #expect(environment.accessibilityReduceMotion)
        #expect(environment.dynamicTypeSize.isAccessibilitySize)
        #expect(environment.windowScaleFactor == 2)
    }

    @Test("System text scale factors map onto Dynamic Type sizes")
    func textScaleFactorMapping() {
        #expect(DynamicTypeSize(textScaleFactor: 1) == .large)
        #expect(DynamicTypeSize(textScaleFactor: 0.8) == .large)
        #expect(DynamicTypeSize(textScaleFactor: 1.25) == .xxLarge)
        #expect(DynamicTypeSize(textScaleFactor: 2.25) == .accessibility3)
        #expect(!DynamicTypeSize.xxxLarge.isAccessibilitySize)
        #expect(DynamicTypeSize.accessibility1.isAccessibilitySize)
    }

    @MainActor
    @Test("ScaledMetric scales with the Dynamic Type size")
    func scaledMetricScales() {
        let metric = ScaledMetric<Double>(wrappedValue: 17)
        metric.update(with: ViewGraphHelpers.environment, previousValue: nil)
        #expect(metric.wrappedValue == 17)

        metric.update(
            with: ViewGraphHelpers.environment.with(\.dynamicTypeSize, .accessibility1),
            previousValue: nil
        )
        #expect(metric.wrappedValue == 28)
    }

    @Test("@Entry declares focused values")
    func focusedValuesEntry() {
        var values = FocusedValues()
        #expect(values.entryMacroTestSelection == nil)
        values.entryMacroTestSelection = "row"
        #expect(values.entryMacroTestSelection == "row")
    }
}
