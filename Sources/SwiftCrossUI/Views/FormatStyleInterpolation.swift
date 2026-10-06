import Foundation

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *)
extension DefaultStringInterpolation {
    /// Interpolates a value formatted with a format style, SwiftUI's
    /// `Text("\(progress, format: .percent)")` spelling.
    ///
    /// SwiftUI provides this on `LocalizedStringKey`; SwiftCrossUI's ``Text``
    /// takes a `String`, so the interpolation is available wherever a string
    /// is interpolated:
    ///
    /// ```swift
    /// Text("Delay: \(delay, format: .number.precision(.fractionLength(1))) s")
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value to format.
    ///   - format: The format style.
    public mutating func appendInterpolation<F: FormatStyle>(
        _ value: F.FormatInput,
        format: F
    ) where F.FormatOutput == String {
        appendLiteral(format.format(value))
    }
}
