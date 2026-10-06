import Foundation

// A shape is drawn from a path, so SwiftCrossUI can rotate and scale a
// shape's drawing itself, exactly and on every backend, by transforming the
// path. As in SwiftUI the shape keeps its layout; only the drawing changes.
// Other views need a backend render transform; see `RenderTransformModifiers`.

extension Shape {
    /// Rotates this shape's drawing around a point in its frame.
    ///
    /// ```swift
    /// Circle()
    ///     .trim(from: 0, to: progress)
    ///     .stroke(.white, lineWidth: 4)
    ///     .rotationEffect(.degrees(-90))
    /// ```
    ///
    /// - Parameters:
    ///   - angle: The rotation, clockwise.
    ///   - anchor: The point to rotate around, relative to the frame.
    /// - Returns: The rotated shape.
    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some Shape {
        TransformedShape(base: self, transform: .rotation(angle, anchor: anchor))
    }

    /// Scales this shape's drawing around a point in its frame.
    ///
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    ///   - anchor: The point to scale around, relative to the frame.
    /// - Returns: The scaled shape.
    public func scaleEffect(
        x: CGFloat = 1,
        y: CGFloat = 1,
        anchor: UnitPoint = .center
    ) -> some Shape {
        TransformedShape(
            base: self,
            transform: .scale(SIMD2(Double(x), Double(y)), anchor: anchor)
        )
    }

    /// Scales this shape's drawing around a point in its frame.
    ///
    /// - Parameters:
    ///   - scale: The scale factor.
    ///   - anchor: The point to scale around, relative to the frame.
    /// - Returns: The scaled shape.
    public func scaleEffect(_ scale: CGFloat, anchor: UnitPoint = .center) -> some Shape {
        scaleEffect(x: scale, y: scale, anchor: anchor)
    }
}

extension StyledShape {
    /// Rotates this shape's drawing, keeping its fill and stroke. See
    /// ``Shape/rotationEffect(_:anchor:)``.
    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some StyledShape {
        restyled(TransformedShape(base: self, transform: .rotation(angle, anchor: anchor)))
    }

    /// Scales this shape's drawing, keeping its fill and stroke. See
    /// ``Shape/scaleEffect(x:y:anchor:)``.
    public func scaleEffect(
        x: CGFloat = 1,
        y: CGFloat = 1,
        anchor: UnitPoint = .center
    ) -> some StyledShape {
        restyled(
            TransformedShape(
                base: self,
                transform: .scale(SIMD2(Double(x), Double(y)), anchor: anchor)
            )
        )
    }

    /// Scales this shape's drawing, keeping its fill and stroke. See
    /// ``Shape/scaleEffect(_:anchor:)``.
    public func scaleEffect(_ scale: CGFloat, anchor: UnitPoint = .center) -> some StyledShape {
        scaleEffect(x: scale, y: scale, anchor: anchor)
    }

    /// `shape`, wearing this shape's fill and stroke.
    private func restyled<Base: Shape>(_ shape: Base) -> StyledShapeImpl<Base> {
        StyledShapeImpl(
            base: shape,
            strokeColor: strokeColor,
            fillColor: fillColor,
            strokeStyle: strokeStyle
        )
    }
}

/// A transform of a shape's drawing, relative to its frame.
enum ShapeTransform: Hashable, Sendable {
    case rotation(Angle, anchor: UnitPoint)
    case scale(SIMD2<Double>, anchor: UnitPoint)

    /// The transform for a shape drawn in `bounds`.
    func affineTransform(in bounds: Path.Rect) -> AffineTransform {
        func point(_ anchor: UnitPoint) -> SIMD2<Double> {
            SIMD2(bounds.x + anchor.x * bounds.width, bounds.y + anchor.y * bounds.height)
        }
        switch self {
            case .rotation(let angle, let anchor):
                return .rotation(radians: angle.radians, center: point(anchor))
            case .scale(let scale, let anchor):
                let center = point(anchor)
                return AffineTransform(
                    linearTransform: SIMD4(x: scale.x, y: 0, z: 0, w: scale.y),
                    translation: center * (1 - scale)
                )
        }
    }
}

/// A shape drawn with a transformed path.
struct TransformedShape<Base: Shape>: Shape {
    var base: Base
    var transform: ShapeTransform

    func path(in bounds: Path.Rect) -> Path {
        base.path(in: bounds).applyTransform(transform.affineTransform(in: bounds))
    }

    func size(fitting proposal: ProposedViewSize) -> ViewSize {
        base.size(fitting: proposal)
    }
}
