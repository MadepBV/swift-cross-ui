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
}
