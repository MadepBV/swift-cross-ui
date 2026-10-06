extension View {
    /// Adds space between the characters of the text inside this view.
    ///
    /// See ``Text/tracking(_:)``.
    ///
    /// - Parameter tracking: The extra space after each character, in points.
    /// - Returns: A view whose text uses `tracking`.
    public func tracking(_ tracking: Double) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.fontOverlay.tracking, tracking)
        }
    }

    /// Adjusts the space between the characters of the text inside this view.
    ///
    /// See ``Text/kerning(_:)``.
    ///
    /// - Parameter kerning: The extra space, in points.
    /// - Returns: A view whose text uses `kerning`.
    public func kerning(_ kerning: Double) -> some View {
        tracking(kerning)
    }

    /// Adds space between the lines of the text inside this view.
    ///
    /// The space is added to the font's line height, so every backend draws
    /// and measures it.
    ///
    /// - Parameter lineSpacing: The extra space between lines, in points.
    /// - Returns: A view whose text uses `lineSpacing`.
    public func lineSpacing(_ lineSpacing: Double) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.fontOverlay.lineSpacing, lineSpacing)
        }
    }

    /// Uses fixed-width digits in the text inside this view.
    ///
    /// - Note: No visible effect yet; see ``Font/monospacedDigit()``.
    ///
    /// - Returns: The view.
    public func monospacedDigit() -> some View {
        self
    }
}

/// The alignment of the lines of a multiline text, relative to each other.
///
/// SwiftUI's `TextAlignment` has the same three cases as
/// ``HorizontalAlignment``, which is what SwiftCrossUI's
/// ``View/multilineTextAlignment(_:)`` and backends already use.
public typealias TextAlignment = HorizontalAlignment
