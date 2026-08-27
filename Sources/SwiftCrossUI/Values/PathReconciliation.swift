/// Decides whether two versions of a ``Path`` build the same shape, so that a
/// backend can update the objects it already built instead of rebuilding them.
///
/// Backends build a path into a tree of native objects — one per segment, plus
/// the figures and geometries holding them. Rebuilding that tree means creating
/// and inserting every one of those objects again, which on Windows is a COM
/// crossing each. An overlay that animates draws the *same shape with moved
/// points* on every pointer sample, so the objects already there are the right
/// ones and only their coordinates are stale.
///
/// The analysis lives here rather than in a backend because it is entirely
/// about ``Path/Action``, so it can be shared and, more importantly, tested
/// without a native toolchain.
///
/// ## What "the same shape" means
///
/// Two action lists build the same tree when they have the same kinds in the
/// same order — but only for actions whose effect on the tree's structure is
/// fixed by their kind. Three kinds fail that:
///
/// - ``Path/Action/arc(center:radius:startAngle:endAngle:clockwise:)``, because
///   whether it needs a connecting line depends on where the previous action
///   left off, so moving a point can change the structure;
/// - ``Path/Action/transform(_:)``, because it mutates the transforms of the
///   geometry already built, and applying it twice would compound it;
/// - ``Path/Action/subpath(_:)``, because it nests another collection.
///
/// A path containing any of them is rebuilt.
@_spi(Backends)
public enum PathReconciliation {
    /// Whether a path's structure is fixed by its actions' kinds, so that a
    /// later version of it with the same kinds can be reconciled.
    ///
    /// - Parameter actions: The path's actions.
    /// - Returns: Whether the path can be reconciled later.
    public static func canReconcile(_ actions: [Path.Action]) -> Bool {
        !actions.isEmpty && actions.allSatisfy(hasFixedShape)
    }

    /// Whether two action lists build the same tree.
    ///
    /// - Parameters:
    ///   - previous: The actions the tree was built from.
    ///   - current: The actions to be applied.
    /// - Returns: Whether the tree can be updated in place.
    public static func haveSameShape(
        _ previous: [Path.Action],
        _ current: [Path.Action]
    ) -> Bool {
        previous.count == current.count
            && !current.isEmpty
            && zip(previous, current).allSatisfy { previous, current in
                hasFixedShape(previous)
                    && hasFixedShape(current)
                    && kind(of: previous) == kind(of: current)
            }
    }

    /// Where an action leaves the path's current point.
    ///
    /// A figure's start point comes from wherever the previous action left off,
    /// so a segment whose own coordinates are unchanged can still need its
    /// figure's start point rewritten. Backends mirror this bookkeeping while
    /// reconciling.
    ///
    /// - Parameters:
    ///   - action: The action.
    ///   - current: The path's current point before it.
    /// - Returns: The path's current point after it.
    public static func endPoint(
        after action: Path.Action,
        current: SIMD2<Double>
    ) -> SIMD2<Double> {
        switch action {
            case .moveTo(let point), .lineTo(let point):
                point
            case .quadCurve(_, let end):
                end
            case .cubicCurve(_, _, let end):
                end
            case .rectangle, .circle, .arc, .transform, .subpath:
                current
        }
    }

    /// Whether an action's effect on a path's structure depends only on its
    /// kind.
    private static func hasFixedShape(_ action: Path.Action) -> Bool {
        switch action {
            case .moveTo, .lineTo, .quadCurve, .cubicCurve, .rectangle, .circle:
                true
            case .arc, .transform, .subpath:
                false
        }
    }

    /// An action's kind, ignoring its values.
    private static func kind(of action: Path.Action) -> Int {
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
}
