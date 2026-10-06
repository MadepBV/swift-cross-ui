import Foundation

/// A proxy for querying a view's geometry. See ``GeometryReader``.
public struct GeometryProxy {
    /// The size proposed to the view by its parent. In the context of
    /// ``GeometryReader``, this is the size that the ``GeometryReader``
    /// will take on (to prevent feedback loops).
    ///
    /// - Note: SwiftUI types this property as `CGSize`, and so does
    ///   SwiftCrossUI, so that a proxy's size can be handed straight to
    ///   Core Graphics geometry without a conversion step.
    public var size: CGSize

    /// The safe area insets of the container view.
    ///
    /// Always zero: SwiftCrossUI's windows have no regions obscured by
    /// system chrome (desktop windows draw their title bars outside the
    /// content area), so there is nothing to inset.
    public var safeAreaInsets: EdgeInsets {
        EdgeInsets()
    }

    public init(size: CGSize) {
        self.size = size
    }

    /// Returns the container view's bounds rectangle, converted to a defined
    /// coordinate space.
    ///
    /// - Important: SwiftCrossUI doesn't track where a view sits within its
    ///   ancestors, so the rectangle is always the view's local bounds: its
    ///   size, at the origin, whatever the coordinate space.
    ///
    /// - Parameter coordinateSpace: The coordinate space to convert to.
    /// - Returns: The view's bounds.
    public func frame(in coordinateSpace: CoordinateSpace) -> CGRect {
        CGRect(origin: CGPoint(x: 0, y: 0), size: size)
    }
}
