/// Whether a scroll view shows its scroll indicators.
public struct ScrollIndicatorVisibility: Hashable, Sendable {
    /// Whether indicators are shown.
    let isVisible: Bool

    /// The platform's default: indicators are shown.
    public static let automatic = ScrollIndicatorVisibility(isVisible: true)
    /// Indicators are shown.
    public static let visible = ScrollIndicatorVisibility(isVisible: true)
    /// Indicators are hidden (SwiftUI may still show them while the user
    /// scrolls; SwiftCrossUI never does).
    public static let hidden = ScrollIndicatorVisibility(isVisible: false)
    /// Indicators are never shown.
    public static let never = ScrollIndicatorVisibility(isVisible: false)
}

extension EnvironmentValues {
    /// The axes along which scroll views hide their indicators, set by
    /// ``View/scrollIndicators(_:axes:)``.
    @Entry var scrollIndicatorsHiddenAxes: Axis.Set = []
}

extension View {
    /// Shows or hides the scroll indicators of the scroll views within this
    /// view.
    ///
    /// A scroll view whose indicators are hidden along an axis never reserves
    /// room for a scroll bar along it, and still scrolls.
    ///
    /// - Parameters:
    ///   - visibility: Whether to show the indicators.
    ///   - axes: The axes the setting applies to.
    /// - Returns: A view whose scroll views show or hide their indicators.
    public func scrollIndicators(
        _ visibility: ScrollIndicatorVisibility,
        axes: Axis.Set = [.vertical, .horizontal]
    ) -> some View {
        EnvironmentModifier(self) { environment in
            var hidden = environment.scrollIndicatorsHiddenAxes
            if visibility.isVisible {
                hidden.subtract(axes)
            } else {
                hidden.formUnion(axes)
            }
            return environment.with(\.scrollIndicatorsHiddenAxes, hidden)
        }
    }
}
