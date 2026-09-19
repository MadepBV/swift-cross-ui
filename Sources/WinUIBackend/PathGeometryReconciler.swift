import Foundation
@_spi(Backends) import SwiftCrossUI
import UWP
import WinUI
@preconcurrency import WindowsFoundation

/// The WinRT object one ``SwiftCrossUI/Path/Action`` wrote into.
///
/// Recorded while a path's geometry is built so that a later upload of the same
/// shape can write new coordinates into the objects already there instead of
/// activating replacements. See ``PathGeometryReconciler``.
enum PathActionTarget {
    /// The action wrote nothing that can be updated.
    ///
    /// A `moveTo` before anything has been drawn is the case that matters: its
    /// point is carried into the figure that the next drawing action creates,
    /// and is rewritten through that figure's start point.
    case none
    /// The action set a figure's start point.
    case figureStart(PathFigure)
    /// The action appended a rectangle to the geometry collection.
    case rectangle(RectangleGeometry)
    /// The action appended an ellipse to the geometry collection.
    case ellipse(EllipseGeometry)
    /// The action appended a line segment, and created the figure holding it
    /// if `startedFigure` is non-`nil`.
    case line(LineSegment, startedFigure: PathFigure?)
    /// The action appended a quadratic segment.
    case quad(QuadraticBezierSegment, startedFigure: PathFigure?)
    /// The action appended a cubic segment.
    case cubic(BezierSegment, startedFigure: PathFigure?)
    /// The action's effect on the tree's shape isn't fixed by its kind alone,
    /// so a path containing one is never reconciled.
    case unsupported
}

/// Collects the target of each action as a path's geometry is built.
final class PathTargetRecorder {
    /// One entry per action, in order.
    private(set) var targets: [PathActionTarget] = []

    func record(_ target: PathActionTarget) {
        targets.append(target)
    }
}

/// Writes a reconciled path's new coordinates into the WinRT objects already
/// built for it.
///
/// Rebuilding a path's geometry costs a WinRT activation and several property
/// writes per segment, plus a second walk of the collection to drop empty
/// figures — every one of them a COM crossing. An overlay that animates draws
/// the same shape with moved points on every pointer sample, so the objects
/// already in the tree are the right ones and only their coordinates are stale.
///
/// Whether a path *can* be reconciled is decided by
/// ``SwiftCrossUI/PathReconciliation``, which is shared and tested without a
/// Windows toolchain. Everything a drafting overlay draws — rectangles,
/// circles, polylines and béziers — qualifies.
///
/// A mismatch between an action and the target recorded for it is treated as
/// "cannot reconcile" rather than skipped, so the failure mode is a redundant
/// rebuild and never a stale drawing.
enum PathGeometryReconciler {
    /// Writes an action's values into the object it was built into.
    ///
    /// - Parameters:
    ///   - action: The action to apply.
    ///   - changed: Whether the action differs from the one previously applied.
    ///     When it doesn't, its own values are already correct and are not
    ///     rewritten.
    ///   - incomingPoint: The path's current point before this action.
    ///   - incomingPointMoved: Whether `incomingPoint` differs from where the
    ///     previous upload left off. A segment whose own coordinates are
    ///     unchanged still needs its figure's start point rewritten when it is.
    ///   - target: The object the action was built into.
    /// - Returns: Whether the action was applied. `false` means the caller must
    ///   rebuild.
    static func apply(
        _ action: SwiftCrossUI.Path.Action,
        changed: Bool,
        incomingPoint: Point,
        incomingPointMoved: Bool,
        to target: PathActionTarget
    ) -> Bool {
        /// Rewrites a figure's start point if this action created the figure
        /// and the point it was given has moved.
        func updateStart(_ figure: PathFigure?) {
            if let figure, incomingPointMoved {
                figure.startPoint = incomingPoint
            }
        }

        switch (action, target) {
            case (.moveTo(let destination), .figureStart(let figure)):
                if changed {
                    figure.startPoint = point(destination)
                }
            case (.moveTo, .none):
                break
            case (.lineTo(let destination), .line(let segment, let startedFigure)):
                updateStart(startedFigure)
                if changed {
                    segment.point = point(destination)
                }
            case (.quadCurve(let control, let end), .quad(let segment, let startedFigure)):
                updateStart(startedFigure)
                if changed {
                    segment.point1 = point(control)
                    segment.point2 = point(end)
                }
            case (
            .cubicCurve(let control1, let control2, let end),
            .cubic(let segment, let startedFigure)
        ):
                updateStart(startedFigure)
                if changed {
                    segment.point1 = point(control1)
                    segment.point2 = point(control2)
                    segment.point3 = point(end)
                }
            case (.rectangle(let rect), .rectangle(let geometry)):
                if changed {
                    geometry.rect = Rect(
                        x: Float(rect.x),
                        y: Float(rect.y),
                        width: Float(rect.width),
                        height: Float(rect.height)
                    )
                }
            case (.circle(let center, let radius), .ellipse(let ellipse)):
                if changed {
                    ellipse.radiusX = radius
                    ellipse.radiusY = radius
                    ellipse.center = point(center)
                }
            default:
                // The recorded target doesn't match the action. Shouldn't
                // happen once `haveSameShape` has agreed, but rebuilding is
                // always safe and a stale drawing never is.
                return false
        }
        return true
    }

    /// An action's kind, ignoring its values.
    private static func kind(of action: SwiftCrossUI.Path.Action) -> Int {
        switch action {
            case .moveTo: 0
            case .lineTo: 1
            case .quadCurve: 2
            case .cubicCurve: 3
            case .rectangle: 4
            case .circle: 5
            case .arc: 6
            case .transform: 7
            case .subpath: 8
        }
    }

    private static func point(_ value: SIMD2<Double>) -> Point {
        Point(x: Float(value.x), y: Float(value.y))
    }
}
