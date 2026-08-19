/// Resolution-independent vector geometry for a single symbol.
///
/// A symbol is described in its own square canvas (24x24 for the bundled
/// Lucide icons) rather than in view coordinates, so the same geometry can be
/// drawn crisply at any size. ``path(in:)`` scales it into the bounds a view
/// was actually given.
///
/// ## See Also
///
/// - ``SymbolProvider``
/// - ``Image/init(systemName:)``
public struct SymbolGeometry: Sendable {
    /// A single drawing instruction in a symbol's canvas coordinate space.
    ///
    /// This is a deliberately small subset of ``Path``'s actions: enough to
    /// express any icon, but with no transforms, so that scaling a symbol is
    /// a pure coordinate operation and behaves identically on every backend.
    public enum Command: Equatable, Sendable {
        /// Starts a new subpath at the given point.
        case move(SIMD2<Double>)
        /// Draws a straight line from the current point to the given point.
        case line(SIMD2<Double>)
        /// Draws an order-2 Bézier curve from the current point.
        case quadCurve(control: SIMD2<Double>, end: SIMD2<Double>)
        /// Draws an order-3 Bézier curve from the current point.
        case cubicCurve(
            control1: SIMD2<Double>,
            control2: SIMD2<Double>,
            end: SIMD2<Double>
        )
        /// Draws a complete circle, leaving the current point unchanged.
        case circle(center: SIMD2<Double>, radius: Double)
    }

    /// How a symbol's geometry is meant to be shaded.
    public enum Rendering: Equatable, Sendable {
        /// The geometry is an outline to be stroked, and is never filled.
        ///
        /// This is how the bundled Lucide icons are drawn.
        case stroked
        /// The geometry encloses areas to be filled, and is never stroked.
        case filled
    }

    /// The drawing instructions, in canvas coordinates.
    public var commands: [Command]
    /// The width and height of the square canvas the commands are drawn in.
    public var canvasSize: Double
    /// The stroke width, in canvas units, used when ``rendering`` is
    /// ``Rendering/stroked``.
    public var strokeWidth: Double
    /// How the ends of stroked subpaths are drawn.
    public var strokeCap: StrokeCap
    /// How corners between stroked segments are drawn.
    public var strokeJoin: StrokeJoin
    /// Whether the geometry is stroked or filled.
    public var rendering: Rendering

    /// Creates symbol geometry.
    ///
    /// The defaults describe Lucide's drawing conventions: a 24x24 canvas
    /// stroked at width 2 with round caps and joins, and never filled.
    ///
    /// - Parameters:
    ///   - commands: The drawing instructions, in canvas coordinates.
    ///   - canvasSize: The side length of the square canvas.
    ///   - strokeWidth: The stroke width in canvas units.
    ///   - strokeCap: How the ends of stroked subpaths are drawn.
    ///   - strokeJoin: How corners between stroked segments are drawn.
    ///   - rendering: Whether the geometry is stroked or filled.
    public init(
        commands: [Command],
        canvasSize: Double = 24,
        strokeWidth: Double = 2,
        strokeCap: StrokeCap = .round,
        strokeJoin: StrokeJoin = .round,
        rendering: Rendering = .stroked
    ) {
        self.commands = commands
        self.canvasSize = canvasSize
        self.strokeWidth = strokeWidth
        self.strokeCap = strokeCap
        self.strokeJoin = strokeJoin
        self.rendering = rendering
    }

    /// The uniform scale factor that fits this symbol's canvas into `bounds`.
    ///
    /// - Parameter bounds: The bounds the symbol will be drawn in.
    /// - Returns: A scale factor to multiply canvas coordinates by.
    public func scale(in bounds: Path.Rect) -> Double {
        guard canvasSize > 0 else {
            return 1
        }
        return min(bounds.width, bounds.height) / canvasSize
    }

    /// Builds a drawable path for this symbol, scaled into the given bounds.
    ///
    /// The symbol keeps its aspect ratio and is centred in `bounds`.
    ///
    /// - Parameter bounds: The bounds to fit the symbol into.
    /// - Returns: A path in `bounds`' coordinate space.
    public func path(in bounds: Path.Rect) -> Path {
        let scale = scale(in: bounds)
        let offset = SIMD2(
            x: bounds.x + (bounds.width - canvasSize * scale) / 2,
            y: bounds.y + (bounds.height - canvasSize * scale) / 2
        )

        func place(_ point: SIMD2<Double>) -> SIMD2<Double> {
            point * scale + offset
        }

        var path = Path()
        for command in commands {
            switch command {
                case .move(let point):
                    path = path.move(to: place(point))
                case .line(let point):
                    path = path.addLine(to: place(point))
                case .quadCurve(let control, let end):
                    path = path.addQuadCurve(
                        control: place(control),
                        to: place(end)
                    )
                case .cubicCurve(let control1, let control2, let end):
                    path = path.addCubicCurve(
                        control1: place(control1),
                        control2: place(control2),
                        to: place(end)
                    )
                case .circle(let center, let radius):
                    path = path.addCircle(
                        center: place(center),
                        radius: radius * scale
                    )
            }
        }
        return path.fillRule(.winding).stroke(style: strokeStyle(in: bounds))
    }

    /// The stroke style to draw this symbol's path with in the given bounds.
    ///
    /// The stroke width is scaled alongside the geometry so that a symbol
    /// looks the same at every size.
    ///
    /// - Parameter bounds: The bounds the symbol will be drawn in.
    /// - Returns: A stroke style in `bounds`' coordinate space.
    public func strokeStyle(in bounds: Path.Rect) -> StrokeStyle {
        StrokeStyle(
            width: strokeWidth * scale(in: bounds),
            cap: strokeCap,
            join: strokeJoin
        )
    }
}

extension SymbolGeometry: Equatable {
    /// Compares two symbols' geometry.
    ///
    /// Written by hand rather than synthesised because ``StrokeCap`` and
    /// ``StrokeJoin`` aren't `Equatable`.
    public static func == (lhs: SymbolGeometry, rhs: SymbolGeometry) -> Bool {
        lhs.commands == rhs.commands
            && lhs.canvasSize == rhs.canvasSize
            && lhs.strokeWidth == rhs.strokeWidth
            && lhs.rendering == rhs.rendering
            && isEqual(lhs.strokeCap, rhs.strokeCap)
            && isEqual(lhs.strokeJoin, rhs.strokeJoin)
    }

    private static func isEqual(_ lhs: StrokeCap, _ rhs: StrokeCap) -> Bool {
        switch (lhs, rhs) {
            case (.butt, .butt), (.round, .round), (.square, .square):
                return true
            default:
                return false
        }
    }

    private static func isEqual(_ lhs: StrokeJoin, _ rhs: StrokeJoin) -> Bool {
        switch (lhs, rhs) {
            case (.miter(let lhsLimit), .miter(let rhsLimit)):
                return lhsLimit == rhsLimit
            case (.round, .round), (.bevel, .bevel):
                return true
            default:
                return false
        }
    }
}
