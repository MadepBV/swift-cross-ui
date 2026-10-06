import Foundation

/// A type that defines the geometry of a collection of views.
///
/// Conform to this protocol to write a custom container, then apply it to
/// views by calling it like a function:
///
/// ```swift
/// struct FlowLayout: Layout {
///     func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
///         ...
///     }
///
///     func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
///         ...
///     }
/// }
///
/// FlowLayout {
///     ForEach(tags) { Text($0.name) }
/// }
/// ```
///
/// SwiftCrossUI asks the layout for its size during layout and has it place
/// its subviews when the layout is committed. Each subview is then laid out
/// once more at the proposal it was placed with, which becomes its final
/// size.
///
/// Spacing preferences (`spacing(subviews:cache:)`) and layout values
/// (`LayoutValueKey`) aren't supported.
@MainActor
@preconcurrency
public protocol Layout {
    /// Cached values associated with the layout instance.
    associatedtype Cache = Void

    /// A collection of proxies for the subviews of a layout view.
    typealias Subviews = LayoutSubviews

    /// Creates and initializes a cache for a layout instance.
    ///
    /// SwiftCrossUI creates a fresh cache each time the layout is asked for
    /// its size, and hands the same cache to the matching placement.
    ///
    /// - Parameter subviews: The views that the layout arranges.
    /// - Returns: The new cache.
    func makeCache(subviews: Subviews) -> Cache

    /// Updates the layout's cache when something changes.
    ///
    /// - Parameters:
    ///   - cache: The cache to update.
    ///   - subviews: The views that the layout arranges.
    func updateCache(_ cache: inout Cache, subviews: Subviews)

    /// Returns the size of the composite view, given a proposed size and the
    /// view's subviews.
    ///
    /// - Parameters:
    ///   - proposal: The size proposed by the container's parent.
    ///   - subviews: The views that the layout arranges.
    ///   - cache: The layout's cache.
    /// - Returns: The size the layout needs.
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize

    /// Assigns positions to each of the layout's subviews.
    ///
    /// - Parameters:
    ///   - bounds: The region that the layout occupies, in its own
    ///     coordinate space.
    ///   - proposal: The size proposed by the container's parent.
    ///   - subviews: The views that the layout arranges. Call
    ///     ``LayoutSubview/place(at:anchor:proposal:)`` on each; one that
    ///     isn't placed is centred in `bounds`.
    ///   - cache: The layout's cache.
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    )

    /// Returns the position of the specified horizontal alignment guide
    /// along the x axis.
    func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat?

    /// Returns the position of the specified vertical alignment guide along
    /// the y axis.
    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat?
}

extension Layout where Cache == () {
    public func makeCache(subviews: Subviews) -> Cache {
        ()
    }
}

extension Layout {
    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache = makeCache(subviews: subviews)
    }

    public func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat? {
        nil
    }

    public func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat? {
        nil
    }

    /// Combines the specified views into a single composite view using the
    /// layout algorithm of the custom layout container.
    ///
    /// - Parameter content: The views to arrange.
    /// - Returns: The arranged views.
    public func callAsFunction<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        LayoutView(layout: self, content: content())
    }
}
