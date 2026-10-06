import Foundation

extension View {
    /// Rotates this view's drawing around a point in its frame.
    ///
    /// - Note: Drawn for shapes, whose paths SwiftCrossUI rotates itself
    ///   (see ``Shape/rotationEffect(_:anchor:)``). Other views need a backend
    ///   render transform, which no backend exposes yet, so they draw
    ///   unrotated. Layout is unaffected either way, as in SwiftUI.
    ///
    /// - Parameters:
    ///   - angle: The rotation, clockwise.
    ///   - anchor: The point to rotate around, relative to the frame.
    /// - Returns: The view.
    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some View {
        self
    }

    /// Scales this view's drawing around a point in its frame.
    ///
    /// - Note: Drawn for shapes, whose paths SwiftCrossUI scales itself
    ///   (see ``Shape/scaleEffect(_:anchor:)``). Other views need a backend
    ///   render transform, which no backend exposes yet, so they draw at their
    ///   own size. Layout is unaffected either way, as in SwiftUI.
    ///
    /// - Parameters:
    ///   - scale: The scale factor.
    ///   - anchor: The point to scale around, relative to the frame.
    /// - Returns: The view.
    public func scaleEffect(_ scale: CGFloat, anchor: UnitPoint = .center) -> some View {
        self
    }

    /// Scales this view's drawing by different factors horizontally and
    /// vertically.
    ///
    /// - Note: Not drawn yet; see ``View/scaleEffect(_:anchor:)-(CGFloat,_)``.
    ///
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    ///   - anchor: The point to scale around, relative to the frame.
    /// - Returns: The view.
    public func scaleEffect(
        x: CGFloat = 1,
        y: CGFloat = 1,
        anchor: UnitPoint = .center
    ) -> some View {
        self
    }

    /// Scales this view's drawing by a size's width and height.
    ///
    /// - Note: Not drawn yet; see ``View/scaleEffect(_:anchor:)-(CGFloat,_)``.
    ///
    /// - Parameters:
    ///   - scale: The horizontal and vertical scale factors.
    ///   - anchor: The point to scale around, relative to the frame.
    /// - Returns: The view.
    public func scaleEffect(_ scale: CGSize, anchor: UnitPoint = .center) -> some View {
        self
    }
}
