/// A dynamic property that scales a numeric value.
///
/// ```swift
/// @ScaledMetric(relativeTo: .caption) private var spacing: CGFloat = 8
/// ```
///
/// The value scales with ``EnvironmentValues/dynamicTypeSize``, which follows
/// the system text size where the backend reports one (Windows' "Text
/// size"). At the default size, ``DynamicTypeSize/large``, it is the base
/// value.
///
/// - Note: SwiftUI scales each text style along its own curve. SwiftCrossUI
///   scales every style by the body style's curve (body text's point size at
///   the current size over its size at `large`), so values relative to very
///   large or very small styles scale slightly differently.
@propertyWrapper
public struct ScaledMetric<Value: BinaryFloatingPoint>: DynamicProperty {
    /// The unscaled value.
    private let baseValue: Value
    /// The text style the value scales with.
    private let textStyle: Font.TextStyle
    /// The scale factor of the environment's Dynamic Type size, recorded by
    /// the view graph before each body evaluation.
    private let scaleFactor = Box<Double>(1)

    /// Creates the scaled metric with an unscaled value, scaled relative to
    /// the body text style.
    ///
    /// - Parameter wrappedValue: The unscaled value.
    public init(wrappedValue: Value) {
        self.init(wrappedValue: wrappedValue, relativeTo: .body)
    }

    /// Creates the scaled metric with an unscaled value and a text style to
    /// scale relative to.
    ///
    /// - Parameters:
    ///   - wrappedValue: The unscaled value.
    ///   - textStyle: The text style to scale relative to.
    public init(wrappedValue: Value, relativeTo textStyle: Font.TextStyle) {
        baseValue = wrappedValue
        self.textStyle = textStyle
    }

    /// The value scaled for the current environment.
    public var wrappedValue: Value {
        baseValue * Value(scaleFactor.value)
    }

    public func update(with environment: EnvironmentValues, previousValue: ScaledMetric?) {
        // The view graph only updates dynamic properties on the main actor,
        // so the environment never actually crosses an isolation boundary.
        nonisolated(unsafe) let environment = environment
        scaleFactor.value = MainActor.assumeIsolated {
            environment.dynamicTypeSize.scaleFactor
        }
    }
}
