import Foundation

/// A type-erased instance of the layout protocol.
///
/// Switching the layout an ``AnyLayout`` wraps keeps the identity, and so the
/// state, of the views it arranges:
///
/// ```swift
/// let layout = isCompact ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
/// layout {
///     Text("One")
///     Text("Two")
/// }
/// ```
public struct AnyLayout: Layout {
    /// The wrapped layout.
    var base: any Layout

    /// Creates a type-erased value that wraps the specified layout.
    ///
    /// - Parameter layout: The layout to wrap.
    public init<L: Layout>(_ layout: L) {
        if let anyLayout = layout as? AnyLayout {
            base = anyLayout.base
        } else {
            base = layout
        }
    }

    /// The wrapped layout's cache.
    public struct Cache {
        var value: Any
    }

    public func makeCache(subviews: Subviews) -> Cache {
        func make<L: Layout>(_ layout: L) -> Cache {
            Cache(value: layout.makeCache(subviews: subviews))
        }
        return make(base)
    }

    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        func update<L: Layout>(_ layout: L) {
            guard var value = cache.value as? L.Cache else {
                cache = makeCache(subviews: subviews)
                return
            }
            layout.updateCache(&value, subviews: subviews)
            cache.value = value
        }
        update(base)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        func size<L: Layout>(_ layout: L) -> CGSize {
            var value = cache.value as? L.Cache ?? layout.makeCache(subviews: subviews)
            defer { cache.value = value }
            return layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &value)
        }
        return size(base)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        func place<L: Layout>(_ layout: L) {
            var value = cache.value as? L.Cache ?? layout.makeCache(subviews: subviews)
            defer { cache.value = value }
            layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &value)
        }
        place(base)
    }
}
