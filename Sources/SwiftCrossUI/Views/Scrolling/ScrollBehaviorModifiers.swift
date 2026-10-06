import Foundation

/// When a scroll view bounces at the ends of its content, on platforms whose
/// scroll views bounce.
public struct ScrollBounceBehavior: Hashable, Sendable {
    /// The behaviour's identity.
    private let rawValue: Int

    /// The platform's default: always bounce along a scrolling axis.
    public static let automatic = ScrollBounceBehavior(rawValue: 0)
    /// Always bounce along a scrolling axis.
    public static let always = ScrollBounceBehavior(rawValue: 1)
    /// Bounce only when the content is larger than the scroll view.
    public static let basedOnSize = ScrollBounceBehavior(rawValue: 2)
}

/// Where ``View/contentMargins(_:_:for:)-(_,CGFloat?,_)`` adds its margins.
public struct ContentMarginPlacement: Hashable, Sendable {
    /// The placement's identity.
    private let rawValue: Int

    /// Around the scrollable content of scroll views.
    public static let automatic = ContentMarginPlacement(rawValue: 0)
    /// Around the scrollable content of scroll views.
    public static let scrollContent = ContentMarginPlacement(rawValue: 1)
    /// Around scroll indicators, which SwiftCrossUI doesn't inset.
    public static let scrollIndicators = ContentMarginPlacement(rawValue: 2)
}

/// Margins around a scroll view's content, in points.
struct ScrollContentMargins: Equatable {
    var top = 0.0
    var bottom = 0.0
    var leading = 0.0
    var trailing = 0.0

    /// The total margin along each axis.
    var totals: SIMD2<Double> {
        SIMD2(leading + trailing, top + bottom)
    }

    /// Sets the margin of some edges.
    ///
    /// - Parameters:
    ///   - edges: The edges.
    ///   - length: The margin.
    mutating func set(_ edges: Edge.Set, to length: Double) {
        if edges.contains(.top) { top = length }
        if edges.contains(.bottom) { bottom = length }
        if edges.contains(.leading) { leading = length }
        if edges.contains(.trailing) { trailing = length }
    }
}

extension EnvironmentValues {
    /// The axes along which scroll views only bounce when their content
    /// overflows, set by ``View/scrollBounceBehavior(_:axes:)``.
    @Entry var scrollBouncesBasedOnSizeAxes: Axis.Set = []

    /// The margins scroll views put around their content, set by
    /// ``View/contentMargins(_:_:for:)-(_,CGFloat?,_)``.
    @Entry var scrollContentMargins = ScrollContentMargins()
}

extension View {
    /// Sets when the scroll views within this view bounce at the ends of their
    /// content.
    ///
    /// Passed to the backend with every scroll view update; backends whose
    /// scroll views don't bounce ignore it.
    ///
    /// - Parameters:
    ///   - behavior: When to bounce.
    ///   - axes: The axes the behaviour applies to.
    /// - Returns: A view whose scroll views bounce accordingly.
    public func scrollBounceBehavior(
        _ behavior: ScrollBounceBehavior,
        axes: Axis.Set = [.vertical]
    ) -> some View {
        EnvironmentModifier(self) { environment in
            var axesBasedOnSize = environment.scrollBouncesBasedOnSizeAxes
            if behavior == .basedOnSize {
                axesBasedOnSize.formUnion(axes)
            } else {
                axesBasedOnSize.subtract(axes)
            }
            return environment.with(\.scrollBouncesBasedOnSizeAxes, axesBasedOnSize)
        }
    }

    /// Adds margins around the content of the scroll views within this view.
    ///
    /// The margins scroll with the content: a horizontal shelf with leading
    /// and trailing margins starts inset, and its items scroll out to the
    /// scroll view's edges.
    ///
    /// - Parameters:
    ///   - edges: The edges to add margins to.
    ///   - length: The margin, or `nil` for none.
    ///   - placement: Where to add the margins. Only
    ///     ``ContentMarginPlacement/scrollContent`` and
    ///     ``ContentMarginPlacement/automatic`` have an effect.
    /// - Returns: A view whose scroll views inset their content.
    public func contentMargins(
        _ edges: Edge.Set = .all,
        _ length: CGFloat?,
        for placement: ContentMarginPlacement = .automatic
    ) -> some View {
        EnvironmentModifier(self) { environment in
            guard placement != .scrollIndicators else {
                return environment
            }
            var margins = environment.scrollContentMargins
            margins.set(edges, to: Double(length ?? 0))
            return environment.with(\.scrollContentMargins, margins)
        }
    }

    /// Adds the same margin around every edge of the content of the scroll
    /// views within this view.
    ///
    /// - Parameters:
    ///   - length: The margin.
    ///   - placement: Where to add the margins.
    /// - Returns: A view whose scroll views inset their content.
    public func contentMargins(
        _ length: CGFloat,
        for placement: ContentMarginPlacement = .automatic
    ) -> some View {
        contentMargins(.all, length, for: placement)
    }

    /// Lets the content of the scroll views within this view draw outside
    /// their bounds.
    ///
    /// Purely cosmetic: SwiftCrossUI's backends clip a scroll view's content
    /// to its bounds natively (an `NSScrollView`'s clip view, a WinUI
    /// `ScrollViewer`), so the content stays clipped; a shadow or a focus
    /// effect at the edge of a shelf is cut off rather than overflowing.
    ///
    /// - Parameter disabled: Whether clipping is disabled.
    /// - Returns: This view, unchanged.
    public func scrollClipDisabled(_ disabled: Bool = true) -> some View {
        self
    }

    /// Shows or hides the system background behind scrollable views such as
    /// ``List`` and ``Form``.
    ///
    /// Purely cosmetic: SwiftCrossUI's lists and forms don't draw a
    /// background of their own, so there is nothing to hide; whatever is
    /// behind them already shows through.
    ///
    /// - Parameter visibility: Whether the background is visible.
    /// - Returns: This view, unchanged.
    public func scrollContentBackground(_ visibility: Visibility) -> some View {
        self
    }
}
