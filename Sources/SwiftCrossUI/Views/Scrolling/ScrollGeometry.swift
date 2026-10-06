import Foundation

/// The geometry of a scroll view: how big its content and visible region
/// are, and how far it's scrolled.
///
/// Reported by ``View/onScrollGeometryChange(for:of:action:)``.
public struct ScrollGeometry: Equatable, Sendable {
    /// Insets around a scroll view's content.
    ///
    /// SwiftUI reports these as `EdgeInsets`; SwiftCrossUI's ``EdgeInsets``
    /// measures whole points, so the scroll geometry has insets of its own
    /// with the same members.
    public struct Insets: Equatable, Sendable {
        public var top: CGFloat
        public var leading: CGFloat
        public var bottom: CGFloat
        public var trailing: CGFloat

        public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
            self.top = top
            self.leading = leading
            self.bottom = bottom
            self.trailing = trailing
        }
    }

    /// How far the content is scrolled, from its top-leading corner.
    public var contentOffset: CGPoint
    /// The size of the content, margins included.
    public var contentSize: CGSize
    /// The margins around the content
    /// (``View/contentMargins(_:_:for:)-(_,CGFloat?,_)``).
    public var contentInsets: Insets
    /// The size of the scroll view's visible region.
    public var containerSize: CGSize

    /// The region of the content that's visible.
    public var visibleRect: CGRect {
        CGRect(origin: contentOffset, size: containerSize)
    }

    /// The visible region, in the scroll view's own coordinates.
    public var bounds: CGRect {
        CGRect(origin: CGPoint(x: 0, y: 0), size: containerSize)
    }

    public static func == (lhs: ScrollGeometry, rhs: ScrollGeometry) -> Bool {
        lhs.contentOffset.x == rhs.contentOffset.x
            && lhs.contentOffset.y == rhs.contentOffset.y
            && lhs.contentSize.width == rhs.contentSize.width
            && lhs.contentSize.height == rhs.contentSize.height
            && lhs.contentInsets == rhs.contentInsets
            && lhs.containerSize.width == rhs.containerSize.width
            && lhs.containerSize.height == rhs.containerSize.height
    }
}

/// One ``View/onScrollGeometryChange(for:of:action:)`` around a scroll view.
struct ScrollGeometryObserver {
    /// Reports a geometry, given the value reported last time (if any), and
    /// returns the value to remember.
    var report: @MainActor (ScrollGeometry, Any?) -> Any
}

extension EnvironmentValues {
    /// The scroll geometry observers around a scroll view, outermost first.
    /// Scroll views take them out of their content's environment.
    @Entry var scrollGeometryObservers: [ScrollGeometryObserver] = []
}

extension View {
    /// Adds an action to perform when a value derived from the geometry of
    /// the scroll view within this view changes.
    ///
    /// ```swift
    /// ScrollView { ... }
    ///     .onScrollGeometryChange(for: CGFloat.self) { geometry in
    ///         geometry.containerSize.height
    ///     } action: { _, height in
    ///         visibleHeight = height
    ///     }
    /// ```
    ///
    /// The geometry is measured each time the scroll view is laid out: when
    /// it appears, when it or its content changes size, and when it scrolls
    /// programmatically. No backend reports the user's own scrolling yet, so
    /// a value derived from ``ScrollGeometry/contentOffset`` only updates on
    /// those occasions. The action runs after the update that measured the
    /// change, starting with the first measurement.
    ///
    /// - Parameters:
    ///   - type: The type of the derived value.
    ///   - transform: Derives the value from the geometry.
    ///   - action: Performed with the old and new values when the value
    ///     changes.
    /// - Returns: A view that observes its scroll view's geometry.
    public func onScrollGeometryChange<T: Equatable>(
        for type: T.Type,
        of transform: @escaping (ScrollGeometry) -> T,
        action: @escaping (_ oldValue: T, _ newValue: T) -> Void
    ) -> some View {
        let observer = ScrollGeometryObserver { geometry, previous in
            let newValue = transform(geometry)
            let oldValue = previous as? T
            if oldValue != newValue {
                Task { @MainActor in
                    action(oldValue ?? newValue, newValue)
                }
            }
            return newValue
        }
        return EnvironmentModifier(self) { environment in
            environment.with(
                \.scrollGeometryObservers,
                environment.scrollGeometryObservers + [observer]
            )
        }
    }
}
