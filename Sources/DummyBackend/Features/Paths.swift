@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.Paths {
    /// A recorded path, kept so that benchmarks can exercise ``Canvas``.
    public final class DummyPath {
        public var actions: [SwiftCrossUI.Path.Action] = []
        public var strokeStyle: StrokeStyle?
        public var strokeColor: Color.Resolved?
        public var fillColor: Color.Resolved?

        public init() {}
    }

    public func createPathWidget() -> Widget {
        Widget()
    }

    public func createPath() -> DummyPath {
        DummyPath()
    }

    public func updatePath(
        _ path: DummyPath,
        _ source: SwiftCrossUI.Path,
        bounds: SwiftCrossUI.Path.Rect,
        pointsChanged: Bool,
        environment: EnvironmentValues
    ) {
        record("updatePath")
        path.strokeStyle = source.strokeStyle
        if pointsChanged {
            path.actions = source.actions
        }
    }

    public func renderPath(
        _ path: DummyPath,
        container: Widget,
        strokeColor: Color.Resolved,
        fillColor: Color.Resolved,
        overrideStrokeStyle: StrokeStyle?
    ) {
        record("renderPath")
        path.strokeColor = strokeColor
        path.fillColor = fillColor
        if let overrideStrokeStyle {
            path.strokeStyle = overrideStrokeStyle
        }
    }
}
