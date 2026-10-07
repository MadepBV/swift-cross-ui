import Foundation

/// The widget at the origin of a named coordinate space, filled in when the
/// view that names the space commits.
///
/// Handed down through the environment by reference: the widget is only read
/// after a commit, never by layout or a body, so a stale environment revision
/// can't hide a change to it (see `ViewGraphNode.body(evaluatedBy:)`).
///
/// `@unchecked Sendable` because environment values must be: the anchor is
/// only written by a commit and read by geometry observations, both of which
/// run on the main thread.
final class CoordinateSpaceAnchor: @unchecked Sendable {
    /// The widget whose top-leading corner is the space's origin.
    var widget: AnyWidget?

    init() {}
}

extension EnvironmentValues {
    /// The named coordinate spaces enclosing a view, by space.
    @Entry var coordinateSpaceAnchors: [CoordinateSpace: CoordinateSpaceAnchor] = [:]

    /// The environment with `space` anchored at `anchor`, shadowing an
    /// enclosing space of the same name as SwiftUI does.
    func addingCoordinateSpace(
        _ space: CoordinateSpace,
        anchoredAt anchor: CoordinateSpaceAnchor
    ) -> EnvironmentValues {
        var anchors = coordinateSpaceAnchors
        anchors[space] = anchor
        return with(\.coordinateSpaceAnchors, anchors)
    }

    /// The frame of `widget` in `space`, or `nil` if `space` isn't an
    /// enclosing named space or the backend can't locate widgets.
    @MainActor
    func frame<Backend: BaseAppBackend>(
        of widget: Backend.Widget,
        in space: CoordinateSpace,
        backend: Backend
    ) -> CGRect? {
        guard let anchor = coordinateSpaceAnchors[space]?.widget,
              let geometryBackend = backend as? any BackendFeatures.WidgetGeometry
        else {
            return nil
        }
        return Self.frame(of: widget, in: anchor, backend: geometryBackend)
    }

    @MainActor
    private static func frame<GeometryBackend: BackendFeatures.WidgetGeometry>(
        of widget: Any,
        in anchor: AnyWidget,
        backend: GeometryBackend
    ) -> CGRect? {
        guard let widget = widget as? GeometryBackend.Widget,
              let ancestor = anchor.widget as? GeometryBackend.Widget,
              let frame = backend.frame(of: widget, in: ancestor)
        else {
            return nil
        }
        return CGRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: frame.size.x,
            height: frame.size.y
        )
    }
}
