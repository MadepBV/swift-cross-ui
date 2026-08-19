/// A shape that has style information attached to it, including color and
/// stroke style.
public protocol StyledShape: Shape {
    /// The shape's stroke color.
    var strokeColor: Color? { get }
    /// The shape's fill color.
    var fillColor: Color? { get }
    /// The shape's stroke style.
    var strokeStyle: StrokeStyle? { get }
}

struct StyledShapeImpl<Base: Shape>: Sendable {
    var base: Base
    var strokeColor: Color?
    var fillColor: Color?
    var strokeStyle: StrokeStyle?

    init(
        base: Base,
        strokeColor: Color? = nil,
        fillColor: Color? = nil,
        strokeStyle: StrokeStyle? = nil
    ) {
        self.base = base

        if let styledBase = base as? any StyledShape {
            self.strokeColor = strokeColor ?? styledBase.strokeColor
            self.fillColor = fillColor ?? styledBase.fillColor
            self.strokeStyle = strokeStyle ?? styledBase.strokeStyle
        } else {
            self.strokeColor = strokeColor
            self.fillColor = fillColor
            self.strokeStyle = strokeStyle
        }
    }
}

extension StyledShapeImpl: StyledShape {
    func path(in bounds: Path.Rect) -> Path {
        return base.path(in: bounds)
    }

    func size(fitting proposal: ProposedViewSize) -> ViewSize {
        return base.size(fitting: proposal)
    }
}

extension Shape {
    public func fill(_ color: Color) -> some StyledShape {
        StyledShapeImpl(base: self, fillColor: color)
    }

    public func stroke(_ color: Color, style: StrokeStyle? = nil) -> some StyledShape {
        StyledShapeImpl(base: self, strokeColor: color, strokeStyle: style)
    }

    /// Traces the outline of this shape with the given stroke style.
    ///
    /// This is SwiftUI's spelling. It picks no colour of its own: just as an
    /// unstyled shape fills with the current foreground colour, a shape
    /// stroked this way strokes with it, so the colour is chosen by
    /// ``View/foregroundStyle(_:)`` or ``View/foregroundColor(_:)`` further
    /// out.
    ///
    /// ```swift
    /// Circle()
    ///     .stroke(style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
    ///     .foregroundStyle(.red)
    /// ```
    ///
    /// Use ``Shape/stroke(_:style:)`` instead to name the colour directly.
    ///
    /// - Parameter style: The pen to trace the shape's outline with.
    /// - Returns: The shape, stroked with `style` and the foreground colour.
    public func stroke(style: StrokeStyle) -> some StyledShape {
        StyledShapeImpl(base: self, strokeStyle: style)
    }
}

extension StyledShape {
    @MainActor
    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        let size = size(fitting: proposedSize)
        return ViewLayoutResult.leafView(size: size)
    }

    @MainActor
    @CastBackend<BackendFeatures.Paths>(backendGenericName: "NewBackend")
    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let bounds = Path.Rect(
            x: 0.0,
            y: 0.0,
            width: layout.size.width,
            height: layout.size.height
        )
        let path = path(in: bounds)

        let storage = children as! ShapeStorage
        let pointsChanged = storage.oldPath?.actions != path.actions
        storage.oldPath = path

        let backendPath = storage.backendPath as! NewBackend.Path
        backend.updatePath(
            backendPath,
            path,
            bounds: bounds,
            pointsChanged: pointsChanged,
            environment: environment
        )

        // A shape carrying a stroke style but no stroke colour and no fill
        // colour came from `stroke(style:)`, which leaves the colour to the
        // environment exactly as an unstyled shape's fill does.
        let resolvedStrokeColor: Color
        if let strokeColor {
            resolvedStrokeColor = strokeColor
        } else if strokeStyle != nil, fillColor == nil {
            resolvedStrokeColor = environment.suggestedForegroundColor
        } else {
            resolvedStrokeColor = .clear
        }

        backend.setSize(of: widget, to: layout.size.vector)
        backend.renderPath(
            backendPath,
            container: widget,
            strokeColor: resolvedStrokeColor.resolve(in: environment),
            fillColor: (fillColor ?? .clear).resolve(in: environment),
            overrideStrokeStyle: strokeStyle
        )
    }
}
