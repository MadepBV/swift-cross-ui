import Foundation

/// The shape drawn at the endpoints of a stroked subpath.
///
/// This is SwiftCrossUI's spelling of Core Graphics' `CGLineCap`.
public enum StrokeCap: Equatable, Sendable {
    /// The stroke ends square exactly at the last point.
    case butt
    /// The stroke ends with a semicircle.
    case round
    /// The stroke ends square half of the stroke width past the last point.
    case square
}

/// The shape drawn where two segments of a stroked subpath meet.
///
/// This is SwiftCrossUI's spelling of Core Graphics' `CGLineJoin`. Unlike
/// `CGLineJoin`, the miter limit travels with the case that uses it.
public enum StrokeJoin: Equatable, Sendable {
    /// Corners are sharp, unless they are longer than `limit` times half the
    /// stroke width, in which case they are beveled.
    case miter(limit: Double)
    /// Corners are rounded.
    case round
    /// Corners are beveled.
    case bevel
}

/// The pen used to stroke a ``Path``.
///
/// The property and initializer names mirror SwiftUI's `StrokeStyle`, so code
/// ported from SwiftUI keeps compiling:
///
/// ```swift
/// StrokeStyle(lineWidth: 1.25, dash: [5.0, 3.0])
/// ```
///
/// SwiftCrossUI's original ``width``/``cap``/``join`` spelling remains
/// available as a set of aliases over the same storage, so both spellings can
/// be mixed freely:
///
/// ```swift
/// var style = StrokeStyle(width: 2.0, cap: .round)
/// style.dash = [4.0, 2.0]
/// style.dashPhase = 1.0
/// ```
public struct StrokeStyle: Equatable, Sendable {
    /// The width of the stroked line, in points.
    public var lineWidth: Double

    /// The shape drawn at the endpoints of each stroked subpath.
    public var lineCap: StrokeCap

    /// The shape drawn where two stroked segments meet.
    public var lineJoin: StrokeJoin

    /// The dash pattern applied to the stroke, in points.
    ///
    /// The values alternate between the length of a drawn segment and the
    /// length of the gap that follows it, repeating for the length of the
    /// path. An empty array (the default) strokes a solid line.
    ///
    /// - Note: Backends should read ``resolvedDash`` instead of this property,
    ///   which does not filter out patterns that draw nothing.
    public var dash: [CGFloat]

    /// How far into ``dash`` the pattern starts, in points.
    public var dashPhase: CGFloat

    /// Creates a stroke style using SwiftUI's spelling.
    ///
    /// - Parameters:
    ///   - lineWidth: The width of the stroked line, in points.
    ///   - lineCap: The shape drawn at the endpoints of each subpath.
    ///   - lineJoin: The shape drawn where two stroked segments meet.
    ///   - miterLimit: Overrides the limit carried by `lineJoin` when
    ///     `lineJoin` is ``StrokeJoin/miter(limit:)``. Pass `nil` (the
    ///     default) to keep the limit that `lineJoin` already carries.
    ///   - dash: The dash pattern, in points. Empty means a solid line.
    ///   - dashPhase: How far into `dash` the pattern starts, in points.
    public init(
        lineWidth: Double = 1.0,
        lineCap: StrokeCap = .butt,
        lineJoin: StrokeJoin = .miter(limit: 10.0),
        miterLimit: Double? = nil,
        dash: [CGFloat] = [],
        dashPhase: CGFloat = 0.0
    ) {
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        if let miterLimit, case .miter = lineJoin {
            self.lineJoin = .miter(limit: miterLimit)
        } else {
            self.lineJoin = lineJoin
        }
        self.dash = dash
        self.dashPhase = dashPhase
    }

    /// Creates a stroke style using SwiftCrossUI's original spelling.
    ///
    /// - Parameters:
    ///   - width: The width of the stroked line, in points.
    ///   - cap: The shape drawn at the endpoints of each subpath.
    ///   - join: The shape drawn where two stroked segments meet.
    public init(
        width: Double,
        cap: StrokeCap = .butt,
        join: StrokeJoin = .miter(limit: 10.0)
    ) {
        self.init(lineWidth: width, lineCap: cap, lineJoin: join)
    }
}

extension StrokeStyle {
    /// The width of the stroked line, in points.
    ///
    /// This is SwiftCrossUI's original spelling of ``lineWidth``.
    public var width: Double {
        get { lineWidth }
        set { lineWidth = newValue }
    }

    /// The shape drawn at the endpoints of each stroked subpath.
    ///
    /// This is SwiftCrossUI's original spelling of ``lineCap``.
    public var cap: StrokeCap {
        get { lineCap }
        set { lineCap = newValue }
    }

    /// The shape drawn where two stroked segments meet.
    ///
    /// This is SwiftCrossUI's original spelling of ``lineJoin``.
    public var join: StrokeJoin {
        get { lineJoin }
        set { lineJoin = newValue }
    }

    /// The limit past which a miter join is drawn as a bevel join.
    ///
    /// Reading this returns 10 (Core Graphics' default) when ``lineJoin`` is
    /// not ``StrokeJoin/miter(limit:)``. Writing it is ignored for the same
    /// reason: the limit only means anything for a miter join, and silently
    /// converting a round or beveled join into a miter one would be worse
    /// than doing nothing.
    public var miterLimit: Double {
        get {
            guard case .miter(let limit) = lineJoin else {
                return 10.0
            }
            return limit
        }
        set {
            guard case .miter = lineJoin else {
                return
            }
            lineJoin = .miter(limit: newValue)
        }
    }

    /// The dash pattern to hand to a renderer, or `nil` for a solid stroke.
    ///
    /// Backends should use this rather than ``dash``. It rejects patterns that
    /// draw nothing — an empty pattern, one containing a negative length, or
    /// one whose lengths are all zero — because several native renderers treat
    /// such patterns as a programmer error rather than as a solid line.
    public var resolvedDash: [Double]? {
        guard !dash.isEmpty else {
            return nil
        }
        var total = 0.0
        var pattern: [Double] = []
        pattern.reserveCapacity(dash.count)
        for length in dash {
            let value = Double(length)
            guard value >= 0.0 else {
                return nil
            }
            total += value
            pattern.append(value)
        }
        guard total > 0.0 else {
            return nil
        }
        return pattern
    }
}
