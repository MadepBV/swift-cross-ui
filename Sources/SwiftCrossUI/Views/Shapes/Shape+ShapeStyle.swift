extension Shape {
    /// Fills this shape with a shape style.
    ///
    /// ```swift
    /// Capsule().fill(.fill.secondary)
    /// Circle().fill(.white.opacity(0.08))
    /// ```
    ///
    /// - Parameters:
    ///   - style: The style to fill with. See ``ShapeStyle``.
    ///   - fillStyle: Accepted for source compatibility; shapes are filled
    ///     with the non-zero rule.
    /// - Returns: The filled shape.
    public func fill<S: ShapeStyle>(
        _ style: S,
        style fillStyle: FillStyle = FillStyle()
    ) -> some StyledShape {
        StyledShapeImpl(base: self, fillColor: style._color)
    }

    /// Traces the outline of this shape with a shape style.
    ///
    /// - Parameters:
    ///   - style: The style to stroke with. See ``ShapeStyle``.
    ///   - strokeStyle: The pen to trace with.
    /// - Returns: The stroked shape.
    public func stroke<S: ShapeStyle>(
        _ style: S,
        style strokeStyle: StrokeStyle
    ) -> some StyledShape {
        StyledShapeImpl(base: self, strokeColor: style._color, strokeStyle: strokeStyle)
    }

    /// Traces the outline of this shape with a shape style and line width.
    ///
    /// The line is centred on the shape's edge, so half of it lies outside
    /// the frame; use ``InsettableShape/strokeBorder(_:lineWidth:)`` to keep
    /// it inside.
    ///
    /// - Parameters:
    ///   - style: The style to stroke with. See ``ShapeStyle``.
    ///   - lineWidth: The width of the line.
    /// - Returns: The stroked shape.
    public func stroke<S: ShapeStyle>(
        _ style: S,
        lineWidth: Double = 1
    ) -> some StyledShape {
        StyledShapeImpl(
            base: self,
            strokeColor: style._color,
            strokeStyle: StrokeStyle(lineWidth: lineWidth)
        )
    }

    /// Traces the outline of this shape in the foreground colour with the
    /// given line width.
    ///
    /// - Parameter lineWidth: The width of the line.
    /// - Returns: The stroked shape.
    public func stroke(lineWidth: Double) -> some StyledShape {
        StyledShapeImpl(base: self, strokeStyle: StrokeStyle(lineWidth: lineWidth))
    }
}

extension InsettableShape {
    /// Traces the inside of this shape's outline, so that the whole line lies
    /// within the frame.
    ///
    /// ```swift
    /// RoundedRectangle(cornerRadius: 8)
    ///     .strokeBorder(.white.opacity(0.45), lineWidth: 2)
    /// ```
    ///
    /// - Parameters:
    ///   - style: The style to stroke with. See ``ShapeStyle``.
    ///   - lineWidth: The width of the line.
    /// - Returns: The stroked shape.
    public func strokeBorder<S: ShapeStyle>(
        _ style: S,
        lineWidth: Double = 1
    ) -> some StyledShape {
        inset(by: lineWidth / 2).stroke(style, lineWidth: lineWidth)
    }

    /// Traces the inside of this shape's outline with a stroke style.
    ///
    /// - Parameters:
    ///   - style: The style to stroke with. See ``ShapeStyle``.
    ///   - strokeStyle: The pen to trace with.
    /// - Returns: The stroked shape.
    public func strokeBorder<S: ShapeStyle>(
        _ style: S,
        style strokeStyle: StrokeStyle
    ) -> some StyledShape {
        inset(by: strokeStyle.lineWidth / 2).stroke(style, style: strokeStyle)
    }

    /// Traces the inside of this shape's outline in the foreground colour.
    ///
    /// - Parameter lineWidth: The width of the line.
    /// - Returns: The stroked shape.
    public func strokeBorder(lineWidth: Double = 1) -> some StyledShape {
        inset(by: lineWidth / 2).stroke(style: StrokeStyle(lineWidth: lineWidth))
    }
}
