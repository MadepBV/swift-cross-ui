/// A dynamic property that scales a numeric value.
///
/// ```swift
/// @ScaledMetric(relativeTo: .caption) private var spacing: CGFloat = 8
/// ```
///
/// SwiftUI scales the value with the user's Dynamic Type size, relative to
/// the given text style. SwiftCrossUI's environment has no Dynamic Type size
/// (text styles resolve to fixed sizes per device class), so the value is
/// always the unscaled base value. Declaring it this way keeps the intent in
/// the source, and the value will scale here once text does.
@propertyWrapper
public struct ScaledMetric<Value: BinaryFloatingPoint>: DynamicProperty {
    /// The unscaled value.
    private let baseValue: Value
    /// The text style the value scales with.
    private let textStyle: Font.TextStyle

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
        baseValue
    }

    public func update(with environment: EnvironmentValues, previousValue: ScaledMetric?) {}
}
