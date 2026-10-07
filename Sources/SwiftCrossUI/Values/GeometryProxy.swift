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

    /// Locates the view in a coordinate space other than its own, when the
    /// proxy was made after the view's commit positioned it.
    var resolveFrame: ((CoordinateSpace) -> CGRect?)?

    /// Set when ``frame(in:)`` is asked for a space other than
    /// ``CoordinateSpace/local`` and the proxy can't locate the view yet, so
    /// the caller can ask again once the commit has positioned it.
    var unresolvedFrameRequest: Box<Bool>?

    public init(size: CGSize) {
        self.size = size
    }

    /// Returns the container view's bounds rectangle, converted to a defined
    /// coordinate space.
    ///
    /// A space named with ``View/coordinateSpace(name:)`` and
    /// ``CoordinateSpace/scrollView`` are resolved for proxies given to
    /// ``View/onGeometryChange(for:of:action:)-(_,_,(T)->Void)``, on backends
    /// that can locate widgets (``BackendFeatures/WidgetGeometry``). Elsewhere
    /// (``GeometryReader``, which is laid out before anything is positioned,
    /// ``CoordinateSpace/global``, or a name no ancestor gave) the rectangle is
    /// the view's local bounds: its size, at the origin.
    ///
    /// - Parameter coordinateSpace: The coordinate space to convert to.
    /// - Returns: The view's bounds in that space.
    public func frame(in coordinateSpace: CoordinateSpace) -> CGRect {
        let local = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        guard coordinateSpace != .local else {
            return local
        }
        if let resolveFrame {
            return resolveFrame(coordinateSpace) ?? local
        }
        unresolvedFrameRequest?.value = true
        return local
    }
}
