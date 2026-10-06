extension Shape {
    /// Draws only part of this shape's outline, between two fractions of its
    /// length.
    ///
    /// ```swift
    /// Circle()
    ///     .trim(from: 0, to: progress)
    ///     .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
    /// ```
    ///
    /// The outline is measured from where the shape's path starts (a circle
    /// starts at its trailing point), as in SwiftUI. See
    /// ``Path/trim(from:to:)`` for the approximation curves go through.
    ///
    /// - Parameters:
    ///   - startFraction: Where to start, from 0 to 1.
    ///   - endFraction: Where to end, from 0 to 1.
    /// - Returns: The trimmed shape.
    public func trim(from startFraction: Double = 0, to endFraction: Double = 1) -> some Shape {
        TrimmedShape(base: self, startFraction: startFraction, endFraction: endFraction)
    }
}

/// A shape drawn between two fractions of another shape's outline.
struct TrimmedShape<Base: Shape>: Shape {
    var base: Base
    var startFraction: Double
    var endFraction: Double

    func path(in bounds: Path.Rect) -> Path {
        var path = base.path(in: bounds)
        path.trim(from: startFraction, to: endFraction)
        return path
    }

    func size(fitting proposal: ProposedViewSize) -> ViewSize {
        base.size(fitting: proposal)
    }
}
