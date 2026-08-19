import Foundation // for CGRect

/// A 2D shape that can be drawn as a view.
///
/// If no stroke color or fill color is specified, the default is no stroke and
/// a fill of the current foreground color.
///
/// ## Drawing a shape
///
/// Conform to this protocol and implement ``Shape/path(in:)-(CGRect)``, exactly
/// as you would in SwiftUI:
///
/// ```swift
/// struct Chevron: Shape {
///     func path(in rect: CGRect) -> Path {
///         var path = Path()
///         path.move(to: CGPoint(x: rect.minX, y: rect.minY))
///         path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
///         path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
///         return path
///     }
/// }
/// ```
///
/// SwiftCrossUI's own ``Path/Rect`` spelling,
/// ``Shape/path(in:)-(Path.Rect)``, is equally valid and is what the built-in
/// shapes use. Whichever one a shape implements, the other is derived from it,
/// so callers may use either.
///
/// - Important: Every conforming type must implement at least one of the two
///   `path(in:)` overloads. Implementing neither still compiles, because each
///   one has a default that forwards to the other, but calling it recurses
///   forever.
public protocol Shape: View, Sendable, _RemoveGlobalActorIsolation where Content == EmptyView {
    /// Draw the path for this shape.
    ///
    /// This is SwiftUI's spelling of ``Shape/path(in:)-(Path.Rect)``. The
    /// default implementation converts `rect` and forwards to that overload,
    /// so a shape only ever has to implement one of the two.
    ///
    /// - Parameter rect: The frame to draw this shape in.
    /// - Returns: The shape's path.
    func path(in rect: CGRect) -> Path

    /// Draw the path for this shape.
    ///
    /// The bounds passed to a shape that is immediately drawn as a view will
    /// always have an origin of (0, 0). However, you may pass a different
    /// bounding box to subpaths. For example, this code draws a rectangle in
    /// the left half of the bounds and an ellipse in the right half:
    /// ```swift
    /// func path(in bounds: Path.Rect) -> Path {
    ///     Path()
    ///         .addSubpath(
    ///             Rectangle().path(
    ///                 in: Path.Rect(
    ///                     x: bounds.x,
    ///                     y: bounds.y,
    ///                     width: bounds.width / 2.0,
    ///                     height: bounds.height
    ///                 )
    ///             )
    ///         )
    ///         .addSubpath(
    ///             Ellipse().path(
    ///                 in: Path.Rect(
    ///                     x: bounds.center.x,
    ///                     y: bounds.y,
    ///                     width: bounds.width / 2.0,
    ///                     height: bounds.height
    ///                 )
    ///             )
    ///         )
    /// }
    /// ```
    ///
    /// The default implementation converts `bounds` and forwards to
    /// ``Shape/path(in:)-(CGRect)``, so a shape only ever has to implement one
    /// of the two.
    ///
    /// - Parameter bounds: The bounds of this shape.
    /// - Returns: The shape's path.
    func path(in bounds: Path.Rect) -> Path

    /// Determine the ideal size of this shape given the proposed bounds.
    ///
    /// The default implementation accepts the proposal, replacing unspecified
    /// dimensions with 10.
    ///
    /// - Parameter proposal: The proposed bounds of this shape.
    /// - Returns: The shape's size for the given proposal.
    func size(fitting proposal: ProposedViewSize) -> ViewSize
}

extension Shape {
    public var body: EmptyView { return EmptyView() }

    /// Draws the shape by forwarding to ``Shape/path(in:)-(Path.Rect)``.
    ///
    /// - Parameter rect: The frame to draw this shape in.
    /// - Returns: The shape's path.
    public func path(in rect: CGRect) -> Path {
        path(in: Path.Rect(rect))
    }

    /// Draws the shape by forwarding to ``Shape/path(in:)-(CGRect)``.
    ///
    /// - Parameter bounds: The bounds of this shape.
    /// - Returns: The shape's path.
    public func path(in bounds: Path.Rect) -> Path {
        path(in: bounds.cgRect)
    }

    public func size(fitting proposal: ProposedViewSize) -> ViewSize {
        proposal.replacingUnspecifiedDimensions(by: ViewSize(10, 10))
    }

    @MainActor
    public func children<Backend: BaseAppBackend>(
        backend _: Backend,
        snapshots _: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment _: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        ShapeStorage()
    }

    @MainActor
    @CastBackend<BackendFeatures.Paths>(returnsWidget: true)
    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createPathWidget()
        let storage = children as! ShapeStorage
        storage.backendPath = backend.createPath()
        storage.oldPath = nil
        return container
    }

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

        backend.setSize(of: widget, to: layout.size.vector)
        backend.renderPath(
            backendPath,
            container: widget,
            strokeColor: Color.clear.resolve(in: environment),
            fillColor: environment.suggestedForegroundColor.resolve(in: environment),
            overrideStrokeStyle: nil
        )
    }
}

final class ShapeStorage: ViewGraphNodeChildren {
    let widgets: [AnyWidget] = []
    let erasedNodes: [ErasedViewGraphNode] = []
    var backendPath: Any!
    var oldPath: Path?
}
