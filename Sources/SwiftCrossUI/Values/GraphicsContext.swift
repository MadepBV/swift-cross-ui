import Foundation

/// An immediate-mode drawing destination handed to a ``Canvas``'s renderer.
///
/// A graphics context records drawing operations rather than rasterising them
/// itself. ``Canvas`` replays the recorded operations onto backend path and
/// text widgets after the renderer returns. See ``Canvas`` for a description of
/// how immediate-mode drawing is bridged onto SwiftCrossUI's retained-mode view
/// graph, and for the limitations that fall out of that bridge.
///
/// ```swift
/// Canvas { context, size in
///     let hatch = Path()
///         .move(to: SIMD2(x: 0.0, y: size.height))
///         .addLine(to: SIMD2(x: size.width, y: 0.0))
///     context.stroke(hatch, with: .color(.blue), lineWidth: 1.0)
/// }
/// ```
///
/// Copying a context copies its drawing state (transform, clip, opacity) but
/// not its destination, exactly like SwiftUI. This makes it safe to snapshot a
/// context, mutate the copy's transform, and keep drawing into the same canvas:
///
/// ```swift
/// var scaled = context
/// scaled.scaleBy(x: 2.0, y: 2.0)
/// scaled.fill(path, with: .color(.red))
/// ```
public struct GraphicsContext {
    /// The destination that recorded commands accumulate in.
    ///
    /// This is a reference so that context copies share one destination.
    let recorder: Recorder

    /// The font that ``resolve(_:)`` attaches to resolved text.
    let font: Font?

    /// The text measurement function handed out to resolved text.
    let measurement: ResolvedText.Measurement?

    /// The current transformation matrix.
    ///
    /// Drawing operations map their geometry through this transform before
    /// recording it.
    ///
    /// - Note: SwiftUI types this property as `CGAffineTransform`.
    ///   SwiftCrossUI has its own ``AffineTransform`` because backends other
    ///   than AppKit/UIKit have no Core Graphics types to convert to.
    public var transform: AffineTransform

    /// The opacity applied to everything drawn by this context.
    ///
    /// This multiplies into the alpha component of each shading's color.
    public var opacity: Double

    /// How many drawing commands this context has recorded so far.
    ///
    /// Diagnostic only. Every command becomes a backend path or text widget
    /// on commit, and on WinUI each of those is a XAML element — so a
    /// renderer's command count is the number that decides what a canvas
    /// costs there. Exposed so an application can log it beside its own
    /// timings without reaching into the recorder.
    public var recordedCommandCount: Int { recorder.commands.count }

    /// The clip paths currently in effect, in canvas coordinates.
    ///
    /// - Important: Clipping is only partially honoured. See ``clip(to:)``.
    private(set) var clipPaths: [Path]

    /// Creates a graphics context.
    ///
    /// - Parameters:
    ///   - recorder: The destination to record drawing operations into.
    ///   - font: The font to attach to text resolved by this context.
    ///   - measurement: The function backing ``ResolvedText/measure(in:)``.
    init(
        recorder: Recorder,
        font: Font? = nil,
        measurement: ResolvedText.Measurement? = nil
    ) {
        self.recorder = recorder
        self.font = font
        self.measurement = measurement
        self.transform = .identity
        self.opacity = 1.0
        self.clipPaths = []
    }
}

// MARK: - Transform state

extension GraphicsContext {
    /// Translates subsequent drawing by the given offset.
    ///
    /// - Parameters:
    ///   - x: The horizontal offset.
    ///   - y: The vertical offset.
    public mutating func translateBy(x: Double, y: Double) {
        concatenate(AffineTransform.translation(x: x, y: y))
    }

    /// Scales subsequent drawing by the given factors.
    ///
    /// Stroke widths are scaled by the geometric mean of the two factors, since
    /// no backend supports non-uniform pen scaling.
    ///
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    public mutating func scaleBy(x: Double, y: Double) {
        concatenate(
            AffineTransform(
                linearTransform: SIMD4(x: x, y: 0.0, z: 0.0, w: y),
                translation: .zero
            )
        )
    }

    /// Rotates subsequent drawing about the context's current origin.
    ///
    /// - Parameter angle: The angle to rotate by. Positive angles rotate
    ///   clockwise, because the canvas' Y axis points down.
    public mutating func rotate(by angle: Angle) {
        concatenate(
            AffineTransform.rotation(radians: angle.radians, center: .zero)
        )
    }

    /// Concatenates the given transform onto the context's current transform.
    ///
    /// The new transform is applied *before* the context's existing transform,
    /// which matches SwiftUI's behaviour.
    ///
    /// - Parameter transform: The transform to concatenate.
    public mutating func concatenate(_ transform: AffineTransform) {
        self.transform = transform.followedBy(self.transform)
    }

    /// Restricts subsequent drawing to the region enclosed by the given path.
    ///
    /// - Important: SwiftCrossUI has no backend clipping primitive, so this is
    ///   only partially honoured: drawing operations whose geometry lies
    ///   entirely outside the bounding box of the accumulated clip paths are
    ///   discarded, but geometry that straddles the clip boundary is drawn
    ///   whole rather than being cut. Honouring it exactly needs a new backend
    ///   feature (see ``Canvas``' documentation). Text is never clipped.
    ///
    /// - Parameter path: The path to clip to, in the context's current
    ///   coordinate space.
    public mutating func clip(to path: Path) {
        clipPaths.append(transformed(path))
    }
}

// MARK: - Drawing

extension GraphicsContext {
    /// Fills the given path.
    ///
    /// - Parameters:
    ///   - path: The path to fill, in the context's current coordinate space.
    ///   - shading: The shading to fill the path with.
    public func fill(_ path: Path, with shading: Shading) {
        let path = transformed(path)
        guard !isCulled(path) else {
            return
        }
        recorder.commands.append(
            .fill(
                FillCommand(
                    path: path,
                    shading: shading,
                    clipPaths: clipPaths,
                    opacity: opacity
                )
            )
        )
    }

    /// Fills the given path, choosing filled regions with a fill style.
    ///
    /// The style replaces the path's own ``Path/fillRule``. Omitting it, by
    /// calling ``fill(_:with:)`` instead, keeps whatever rule the path already
    /// carries.
    ///
    /// - Parameters:
    ///   - path: The path to fill, in the context's current coordinate space.
    ///   - shading: The shading to fill the path with.
    ///   - style: The style that decides which regions of the path the fill
    ///     covers.
    public func fill(_ path: Path, with shading: Shading, style: FillStyle) {
        fill(path.fillRule(style.fillRule), with: shading)
    }

    /// Strokes the given path.
    ///
    /// - Parameters:
    ///   - path: The path to stroke, in the context's current coordinate space.
    ///   - shading: The shading to stroke the path with.
    ///   - style: The stroke style. Its width is scaled by the context's
    ///     current transform.
    public func stroke(
        _ path: Path,
        with shading: Shading,
        style: StrokeStyle
    ) {
        var scaledStyle = style
        scaledStyle.width = style.width * transform.approximateScaleFactor
        let path = transformed(path).stroke(style: scaledStyle)
        guard !isCulled(path) else {
            return
        }
        recorder.commands.append(
            .stroke(
                StrokeCommand(
                    path: path,
                    shading: shading,
                    style: scaledStyle,
                    clipPaths: clipPaths,
                    opacity: opacity
                )
            )
        )
    }

    /// Strokes the given path with a plain round-capped pen.
    ///
    /// - Parameters:
    ///   - path: The path to stroke, in the context's current coordinate space.
    ///   - shading: The shading to stroke the path with.
    ///   - lineWidth: The width of the stroke, before the context's transform
    ///     is applied.
    public func stroke(
        _ path: Path,
        with shading: Shading,
        lineWidth: Double = 1.0
    ) {
        stroke(path, with: shading, style: StrokeStyle(width: lineWidth))
    }

    /// Draws resolved text, anchoring it at the given point.
    ///
    /// - Important: Text is drawn by placing a backend text widget inside the
    ///   canvas, not by rasterising glyphs into the drawing. The consequences
    ///   are documented on ``Canvas``; the most visible one is that the
    ///   context's transform only moves text, it does not rotate, scale or
    ///   shear it.
    ///
    /// - Parameters:
    ///   - text: The resolved text to draw.
    ///   - point: The point to anchor the text at, in the context's current
    ///     coordinate space.
    ///   - anchor: The point within the text's bounding box that lands on
    ///     `point`. Defaults to the text's center, as in SwiftUI.
    public func draw(
        _ text: ResolvedText,
        at point: CGPoint,
        anchor: UnitPoint = .center
    ) {
        let position = transform.apply(
            to: SIMD2(x: Double(point.x), y: Double(point.y))
        )
        recorder.commands.append(
            .text(
                TextCommand(
                    text: text,
                    placement: .point(position, anchor: anchor),
                    clipPaths: clipPaths,
                    opacity: opacity
                )
            )
        )
    }

    /// Draws resolved text, centered within the given rectangle.
    ///
    /// The rectangle also constrains the text's layout width, so long strings
    /// wrap or ellipsize according to the backend's text view behaviour.
    ///
    /// - Important: See ``draw(_:at:anchor:)`` for the limitations that apply
    ///   to text inside a canvas.
    ///
    /// - Parameters:
    ///   - text: The resolved text to draw.
    ///   - rect: The rectangle to draw the text in, in the context's current
    ///     coordinate space.
    public func draw(_ text: ResolvedText, in rect: CGRect) {
        let origin = transform.apply(
            to: SIMD2(x: Double(rect.origin.x), y: Double(rect.origin.y))
        )
        let scale = transform.axisScaleFactors
        recorder.commands.append(
            .text(
                TextCommand(
                    text: text,
                    placement: .rect(
                        Path.Rect(
                            origin: origin,
                            size: SIMD2(
                                x: Double(rect.size.width) * scale.x,
                                y: Double(rect.size.height) * scale.y
                            )
                        )
                    ),
                    clipPaths: clipPaths,
                    opacity: opacity
                )
            )
        )
    }

    /// Resolves and draws text, anchoring it at the given point.
    ///
    /// - Parameters:
    ///   - text: The text to draw.
    ///   - point: The point to anchor the text at.
    ///   - anchor: The point within the text's bounding box that lands on
    ///     `point`.
    public func draw(
        _ text: Text,
        at point: CGPoint,
        anchor: UnitPoint = .center
    ) {
        draw(resolve(text), at: point, anchor: anchor)
    }

    /// Resolves and draws text, centered within the given rectangle.
    ///
    /// - Parameters:
    ///   - text: The text to draw.
    ///   - rect: The rectangle to draw the text in.
    public func draw(_ text: Text, in rect: CGRect) {
        draw(resolve(text), in: rect)
    }

    /// Resolves text against this context's environment.
    ///
    /// The text's own attributes win over the context's. A ``Text`` styled
    /// with ``Text/font(_:)``, ``Text/fontWeight(_:)`` or
    /// ``Text/foregroundColor(_:)`` therefore keeps that styling when it is
    /// drawn into a canvas; anything it leaves unset falls back to the font
    /// and foreground color the canvas inherited from its environment.
    ///
    /// - Parameter text: The text to resolve.
    /// - Returns: The resolved text, ready to be measured and drawn.
    public func resolve(_ text: Text) -> ResolvedText {
        let attributes = text.attributes
        let shading: Shading
        if let color = attributes.foregroundColor {
            shading = .color(color)
        } else {
            shading = .foreground
        }

        return ResolvedText(
            string: text.string,
            shading: shading,
            font: attributes.resolvedFont(basedOn: font),
            measurement: measurement
        )
    }
}

// MARK: - Internal helpers

extension GraphicsContext {
    /// Maps a path through the context's current transform.
    ///
    /// The transform is baked into the returned path as a
    /// ``Path/Action/transform(_:)`` action, which every backend that
    /// implements `BackendFeatures.Paths` already knows how to apply.
    ///
    /// - Parameter path: The path to transform.
    /// - Returns: The path in canvas coordinates.
    private func transformed(_ path: Path) -> Path {
        guard transform != .identity else {
            return path
        }
        return Path()
            .addSubpath(path)
            .applyTransform(transform)
            .fillRule(path.fillRule)
            .stroke(style: path.strokeStyle)
    }

    /// Determines whether a path is entirely outside the current clip region.
    ///
    /// This is the only part of clipping that can be honoured without backend
    /// support, and it is conservative: it never discards geometry that might
    /// have been visible.
    ///
    /// - Parameter path: The path to test, in canvas coordinates.
    /// - Returns: Whether the path can be discarded.
    private func isCulled(_ path: Path) -> Bool {
        guard !clipPaths.isEmpty else {
            return false
        }
        guard let pathBounds = path.approximateBoundingBox else {
            return true
        }
        for clipPath in clipPaths {
            guard let clipBounds = clipPath.approximateBoundingBox else {
                return true
            }
            let separated =
                pathBounds.maxX < clipBounds.x
                    || clipBounds.maxX < pathBounds.x
                    || pathBounds.maxY < clipBounds.y
                    || clipBounds.maxY < pathBounds.y
            if separated {
                return true
            }
        }
        return false
    }
}

// MARK: - Shading

extension GraphicsContext {
    /// A way of coloring in a path.
    ///
    /// SwiftCrossUI's backend path API only accepts flat colors, so unlike
    /// SwiftUI this type only models solid colors. Gradient, tiling and image
    /// shadings would need a new backend feature.
    public struct Shading: Sendable {
        /// The underlying representation of a shading.
        enum Storage: Sendable {
            /// A solid color.
            case color(Color)
            /// The canvas' inherited foreground color.
            case foreground
        }

        /// The shading's representation.
        let storage: Storage

        /// A shading that uses the canvas' inherited foreground color.
        public static let foreground = Shading(storage: .foreground)

        /// Creates a shading that paints a solid color.
        ///
        /// - Parameter color: The color to paint.
        /// - Returns: The shading.
        public static func color(_ color: Color) -> Shading {
            Shading(storage: .color(color))
        }

        /// Resolves the shading to a color.
        ///
        /// - Parameter defaultColor: The color to use for
        ///   ``GraphicsContext/Shading/foreground``.
        /// - Returns: The color to paint with.
        func color(withDefault defaultColor: Color) -> Color {
            switch storage {
                case .color(let color):
                    color
                case .foreground:
                    defaultColor
            }
        }
    }

    /// Text that has been resolved against a context's environment.
    ///
    /// This is an alias for the top-level ``SwiftCrossUI/ResolvedText`` type,
    /// provided so that SwiftUI's `GraphicsContext.ResolvedText` spelling also
    /// compiles.
    public typealias ResolvedText = SwiftCrossUI.ResolvedText
}

// MARK: - Recorded commands

extension GraphicsContext {
    /// The shared destination that a context and its copies record into.
    final class Recorder {
        /// The commands recorded so far, in drawing order.
        var commands: [Command] = []

        /// Creates an empty recorder.
        init() {}
    }

    /// A single drawing operation issued by a renderer.
    enum Command {
        /// Fill a path.
        case fill(FillCommand)
        /// Stroke a path.
        case stroke(StrokeCommand)
        /// Draw a run of text.
        case text(TextCommand)

        /// The kind of backend child widget that this command needs.
        var kind: Kind {
            switch self {
                case .fill, .stroke:
                    .path
                case .text:
                    .text
            }
        }
    }

    /// The kinds of backend child widget that commands are replayed onto.
    enum Kind: Equatable {
        /// A path widget.
        case path
        /// A text widget.
        case text
    }

    /// A recorded fill operation.
    struct FillCommand {
        /// The path to fill, in canvas coordinates.
        var path: Path
        /// The shading to fill with.
        var shading: Shading
        /// The clip paths that were in effect, in canvas coordinates.
        var clipPaths: [Path]
        /// The opacity that was in effect.
        var opacity: Double
    }

    /// A recorded stroke operation.
    struct StrokeCommand {
        /// The path to stroke, in canvas coordinates.
        var path: Path
        /// The shading to stroke with.
        var shading: Shading
        /// The stroke style, with its width already scaled by the transform.
        var style: StrokeStyle
        /// The clip paths that were in effect, in canvas coordinates.
        var clipPaths: [Path]
        /// The opacity that was in effect.
        var opacity: Double
    }

    /// A recorded text operation.
    struct TextCommand {
        /// The text to draw.
        var text: ResolvedText
        /// Where to place the text, in canvas coordinates.
        var placement: TextPlacement
        /// The clip paths that were in effect, in canvas coordinates.
        var clipPaths: [Path]
        /// The opacity that was in effect.
        var opacity: Double
    }

    /// Where a run of text goes, in canvas coordinates.
    enum TextPlacement {
        /// Anchor the text's `anchor` point at the given position.
        case point(SIMD2<Double>, anchor: UnitPoint)
        /// Center the text within the given rectangle.
        case rect(Path.Rect)
    }
}

// MARK: - Transform maths

extension AffineTransform {
    /// Maps a point through the transform.
    ///
    /// - Parameter point: The point to map.
    /// - Returns: The mapped point.
    func apply(to point: SIMD2<Double>) -> SIMD2<Double> {
        SIMD2(
            x: linearTransform.x * point.x + linearTransform.y * point.y
                + translation.x,
            y: linearTransform.z * point.x + linearTransform.w * point.y
                + translation.y
        )
    }

    /// The transform's scale factor along each axis.
    var axisScaleFactors: SIMD2<Double> {
        SIMD2(
            x: (linearTransform.x * linearTransform.x
                + linearTransform.z * linearTransform.z).squareRoot(),
            y: (linearTransform.y * linearTransform.y
                + linearTransform.w * linearTransform.w).squareRoot()
        )
    }

    /// A single scale factor summarising the transform.
    ///
    /// This is the square root of the absolute determinant, i.e. the factor by
    /// which the transform scales lengths when it scales uniformly. It is used
    /// to scale stroke widths, which backends can only express as a scalar.
    var approximateScaleFactor: Double {
        let determinant =
            linearTransform.x * linearTransform.w
                - linearTransform.y * linearTransform.z
        return abs(determinant).squareRoot()
    }
}

// MARK: - Path geometry

extension Path {
    /// The number of line segments used to approximate a Bézier curve.
    static let curveFlatteningSegmentCount = 24

    /// The largest arc sweep, in radians, spanned by one flattened segment.
    static let arcFlatteningStep = Double.pi / 32.0

    /// The path's bounding box, computed from a flattened approximation.
    ///
    /// Returns `nil` for paths that enclose nothing.
    var approximateBoundingBox: Rect? {
        var minimum: SIMD2<Double>?
        var maximum: SIMD2<Double>?
        for subpath in Path.flatten(actions) {
            for point in subpath {
                guard let currentMinimum = minimum,
                      let currentMaximum = maximum
                else {
                    minimum = point
                    maximum = point
                    continue
                }
                minimum = SIMD2(
                    x: Swift.min(currentMinimum.x, point.x),
                    y: Swift.min(currentMinimum.y, point.y)
                )
                maximum = SIMD2(
                    x: Swift.max(currentMaximum.x, point.x),
                    y: Swift.max(currentMaximum.y, point.y)
                )
            }
        }
        guard let minimum, let maximum else {
            return nil
        }
        return Rect(origin: minimum, size: maximum - minimum)
    }

    /// Approximates a list of path actions as a list of polylines.
    ///
    /// - Parameter actions: The actions to flatten.
    /// - Returns: One point list per subpath. Subpaths with fewer than two
    ///   points are dropped because they draw nothing.
    static func flatten(_ actions: [Action]) -> [[SIMD2<Double>]] {
        var subpaths: [[SIMD2<Double>]] = []
        var current: [SIMD2<Double>] = []
        var currentPoint = SIMD2<Double>.zero

        func flush() {
            if current.count > 1 {
                subpaths.append(current)
            }
            current = []
        }

        func ensureStarted() {
            if current.isEmpty {
                current.append(currentPoint)
            }
        }

        for action in actions {
            switch action {
                case .moveTo(let point):
                    flush()
                    currentPoint = point
                    current = [point]
                case .lineTo(let point):
                    ensureStarted()
                    current.append(point)
                    currentPoint = point
                case .quadCurve(let control, let end):
                    ensureStarted()
                    current.append(
                        contentsOf: quadCurvePoints(
                            from: currentPoint,
                            control: control,
                            to: end
                        )
                    )
                    currentPoint = end
                case .cubicCurve(let control1, let control2, let end):
                    ensureStarted()
                    current.append(
                        contentsOf: cubicCurvePoints(
                            from: currentPoint,
                            control1: control1,
                            control2: control2,
                            to: end
                        )
                    )
                    currentPoint = end
                case .rectangle(let rect):
                    flush()
                    subpaths.append([
                        rect.origin,
                        SIMD2(x: rect.maxX, y: rect.y),
                        SIMD2(x: rect.maxX, y: rect.maxY),
                        SIMD2(x: rect.x, y: rect.maxY),
                        rect.origin,
                    ])
                case .circle(let center, let radius):
                    flush()
                    subpaths.append(
                        arcPoints(
                            center: center,
                            radius: radius,
                            startAngle: 0.0,
                            endAngle: 2.0 * .pi,
                            clockwise: true
                        )
                    )
                case .arc(
                let center,
                let radius,
                let startAngle,
                let endAngle,
                let clockwise
            ):
                    let points = arcPoints(
                        center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: clockwise
                    )
                    if !current.isEmpty {
                        current.append(contentsOf: points)
                    } else {
                        current = points
                    }
                    if let last = points.last {
                        currentPoint = last
                    }
                case .transform(let transform):
                    subpaths = subpaths.map { subpath in
                        subpath.map { point in transform.apply(to: point) }
                    }
                    current = current.map { point in
                        transform.apply(to: point)
                    }
                    currentPoint = transform.apply(to: currentPoint)
                case .subpath(let subpathActions):
                    subpaths.append(contentsOf: flatten(subpathActions))
            }
        }

        flush()
        return subpaths
    }

    /// Samples a quadratic Bézier curve, excluding its start point.
    ///
    /// - Parameters:
    ///   - start: The curve's start point.
    ///   - control: The curve's control point.
    ///   - end: The curve's end point.
    /// - Returns: The sampled points.
    private static func quadCurvePoints(
        from start: SIMD2<Double>,
        control: SIMD2<Double>,
        to end: SIMD2<Double>
    ) -> [SIMD2<Double>] {
        (1...curveFlatteningSegmentCount).map { step in
            let t = Double(step) / Double(curveFlatteningSegmentCount)
            let inverse = 1.0 - t
            return start * (inverse * inverse)
                + control * (2.0 * inverse * t)
                + end * (t * t)
        }
    }

    /// Samples a cubic Bézier curve, excluding its start point.
    ///
    /// - Parameters:
    ///   - start: The curve's start point.
    ///   - control1: The curve's first control point.
    ///   - control2: The curve's second control point.
    ///   - end: The curve's end point.
    /// - Returns: The sampled points.
    private static func cubicCurvePoints(
        from start: SIMD2<Double>,
        control1: SIMD2<Double>,
        control2: SIMD2<Double>,
        to end: SIMD2<Double>
    ) -> [SIMD2<Double>] {
        (1...curveFlatteningSegmentCount).map { step in
            let t = Double(step) / Double(curveFlatteningSegmentCount)
            let inverse = 1.0 - t
            return start * (inverse * inverse * inverse)
                + control1 * (3.0 * inverse * inverse * t)
                + control2 * (3.0 * inverse * t * t)
                + end * (t * t * t)
        }
    }

    /// Samples an arc, including both of its endpoints.
    ///
    /// - Parameters:
    ///   - center: The arc's center.
    ///   - radius: The arc's radius.
    ///   - startAngle: The angle to start at, in radians clockwise from the
    ///     trailing direction.
    ///   - endAngle: The angle to end at.
    ///   - clockwise: Whether the arc sweeps clockwise.
    /// - Returns: The sampled points.
    private static func arcPoints(
        center: SIMD2<Double>,
        radius: Double,
        startAngle: Double,
        endAngle: Double,
        clockwise: Bool
    ) -> [SIMD2<Double>] {
        var sweep = endAngle - startAngle
        if clockwise {
            while sweep < 0.0 {
                sweep += 2.0 * .pi
            }
        } else {
            while sweep > 0.0 {
                sweep -= 2.0 * .pi
            }
        }

        let steps = (abs(sweep) / arcFlatteningStep).rounded(.up)
        let count = Swift.max(2, Int(steps))
        return (0...count).map { step in
            let angle = startAngle + sweep * Double(step) / Double(count)
            return SIMD2(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }
    }

    /// Trims a flattened approximation of the given actions.
    ///
    /// - Parameters:
    ///   - actions: The actions to trim.
    ///   - start: The fraction of the total length to start at.
    ///   - end: The fraction of the total length to end at.
    /// - Returns: The trimmed path.
    static func trimmed(
        _ actions: [Action],
        from start: Double,
        to end: Double
    ) -> Path {
        let lower = Swift.min(Swift.max(start, 0.0), 1.0)
        let upper = Swift.min(Swift.max(end, 0.0), 1.0)
        guard lower != upper else {
            return Path()
        }
        guard lower < upper else {
            let head = trimmed(actions, from: lower, to: 1.0)
            let tail = trimmed(actions, from: 0.0, to: upper)
            return head.addSubpath(tail)
        }

        let subpaths = flatten(actions)
        let totalLength = subpaths.reduce(0.0) { total, subpath in
            total + polylineLength(subpath)
        }
        guard totalLength > 0.0 else {
            return Path()
        }

        let startLength = totalLength * lower
        let endLength = totalLength * upper
        var result = Path()
        var traversed = 0.0

        for subpath in subpaths {
            var pending: [SIMD2<Double>] = []
            for index in 1..<subpath.count {
                let from = subpath[index - 1]
                let to = subpath[index]
                let length = distance(from, to)
                defer { traversed += length }
                guard length > 0.0 else {
                    continue
                }

                let overlapStart = Swift.max(traversed, startLength)
                let overlapEnd = Swift.min(traversed + length, endLength)
                guard overlapStart < overlapEnd else {
                    continue
                }

                let firstFraction = (overlapStart - traversed) / length
                let lastFraction = (overlapEnd - traversed) / length
                if pending.isEmpty {
                    pending.append(interpolate(from, to, firstFraction))
                }
                pending.append(interpolate(from, to, lastFraction))
            }
            if pending.count > 1 {
                var piece = Path().move(to: pending[0])
                for point in pending.dropFirst() {
                    piece = piece.addLine(to: point)
                }
                result = result.addSubpath(piece)
            }
        }

        return result
    }

    /// The total length of a polyline.
    ///
    /// - Parameter points: The polyline's points.
    /// - Returns: The polyline's length.
    private static func polylineLength(_ points: [SIMD2<Double>]) -> Double {
        guard points.count > 1 else {
            return 0.0
        }
        var total = 0.0
        for index in 1..<points.count {
            total += distance(points[index - 1], points[index])
        }
        return total
    }

    /// The distance between two points.
    ///
    /// - Parameters:
    ///   - from: The first point.
    ///   - to: The second point.
    /// - Returns: The distance between the points.
    private static func distance(
        _ from: SIMD2<Double>,
        _ to: SIMD2<Double>
    ) -> Double {
        let delta = to - from
        return (delta.x * delta.x + delta.y * delta.y).squareRoot()
    }

    /// Linearly interpolates between two points.
    ///
    /// - Parameters:
    ///   - from: The point at fraction 0.
    ///   - to: The point at fraction 1.
    ///   - fraction: The fraction to interpolate at.
    /// - Returns: The interpolated point.
    private static func interpolate(
        _ from: SIMD2<Double>,
        _ to: SIMD2<Double>,
        _ fraction: Double
    ) -> SIMD2<Double> {
        from + (to - from) * fraction
    }
}
