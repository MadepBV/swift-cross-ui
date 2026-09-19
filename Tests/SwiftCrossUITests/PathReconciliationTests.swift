import Foundation
import Testing

@testable @_spi(Backends) import SwiftCrossUI

/// Tests for reconciling a path's native geometry instead of rebuilding it.
///
/// A backend builds a path into a tree of native objects, one per segment plus
/// the figures and geometries holding them. `WinUIBackend` updates that tree in
/// place when a new version of the path has the same shape, because rebuilding
/// costs a COM crossing per object and an animating overlay redraws the same
/// shape with moved points on every pointer sample.
///
/// The decision — ``PathReconciliation`` — is shared core code and is tested
/// directly. The *algorithm* that walks the tree alongside the actions can only
/// run against WinRT objects, so it is mirrored here by a model of the same
/// structure, and the property that matters is checked against it: reconciling
/// must leave exactly the tree a rebuild would have produced. That is what
/// stands between this optimisation and a stale drawing.
@Suite("Testing for path reconciliation")
struct PathReconciliationTests {
    // MARK: The shared decision

    @Test("Shapes made only of fixed-structure actions can be reconciled")
    func fixedShapesCanBeReconciled() {
        #expect(
            PathReconciliation.canReconcile([
                .moveTo(SIMD2(0, 0)),
                .lineTo(SIMD2(10, 10)),
                .cubicCurve(control1: SIMD2(1, 1), control2: SIMD2(2, 2), end: SIMD2(3, 3)),
                .rectangle(Path.Rect(x: 0, y: 0, width: 5, height: 5)),
                .circle(center: SIMD2(1, 1), radius: 2),
            ])
        )
        #expect(!PathReconciliation.canReconcile([]))
    }

    @Test("Actions whose structure isn't fixed by their kind are never reconciled")
    func variableShapesAreNotReconciled() {
        // An arc may or may not need a connecting line depending on where the
        // previous action left off, so moving a point can change the structure.
        #expect(
            !PathReconciliation.canReconcile([
                .moveTo(SIMD2(0, 0)),
                .arc(
                    center: SIMD2(0, 0),
                    radius: 1,
                    startAngle: 0,
                    endAngle: 1,
                    clockwise: true
                ),
            ])
        )
        // A transform mutates what was already built; applying it twice would
        // compound it.
        #expect(
            !PathReconciliation.canReconcile([
                .rectangle(Path.Rect(x: 0, y: 0, width: 1, height: 1)),
                .transform(AffineTransform.identity),
            ])
        )
        // A subpath nests another collection.
        #expect(
            !PathReconciliation.canReconcile([
                .subpath([.lineTo(SIMD2(1, 1))])
            ])
        )
    }

    @Test("Same kinds in the same order is the same shape")
    func sameKindsAreSameShape() {
        let a: [Path.Action] = [.moveTo(SIMD2(0, 0)), .lineTo(SIMD2(1, 1))]
        let b: [Path.Action] = [.moveTo(SIMD2(5, 5)), .lineTo(SIMD2(9, 9))]
        #expect(PathReconciliation.haveSameShape(a, b))

        // Different kind.
        #expect(!PathReconciliation.haveSameShape(a, [.moveTo(SIMD2(0, 0)), .moveTo(SIMD2(1, 1))]))
        // Different length.
        #expect(!PathReconciliation.haveSameShape(a, [.moveTo(SIMD2(0, 0))]))
        // Contains a kind that is never reconciled, even matched against itself.
        let arc: [Path.Action] = [
            .arc(center: SIMD2(0, 0), radius: 1, startAngle: 0, endAngle: 1, clockwise: true)
        ]
        #expect(!PathReconciliation.haveSameShape(arc, arc))
    }

    @Test("The current point advances the way the drawing actions move it")
    func currentPointAdvances() {
        let start = SIMD2<Double>(7, 7)
        #expect(PathReconciliation.endPoint(after: .moveTo(SIMD2(1, 2)), current: start) == SIMD2(
            1,
            2
        ))
        #expect(PathReconciliation.endPoint(after: .lineTo(SIMD2(3, 4)), current: start) == SIMD2(
            3,
            4
        ))
        #expect(
            PathReconciliation.endPoint(
                after: .quadCurve(control: SIMD2(0, 0), end: SIMD2(5, 6)),
                current: start
            ) == SIMD2(5, 6)
        )
        #expect(
            PathReconciliation.endPoint(
                after: .cubicCurve(control1: SIMD2(0, 0), control2: SIMD2(0, 0), end: SIMD2(8, 9)),
                current: start
            ) == SIMD2(8, 9)
        )
        // Whole-shape actions leave it alone, as the backend's builder does.
        #expect(
            PathReconciliation.endPoint(
                after: .rectangle(Path.Rect(x: 0, y: 0, width: 1, height: 1)),
                current: start
            ) == start
        )
        #expect(
            PathReconciliation.endPoint(
                after: .circle(center: SIMD2(0, 0), radius: 1),
                current: start
            ) == start
        )
    }

    // MARK: Reconciling must equal rebuilding

    @Test("Reconciling leaves the tree a rebuild would have produced")
    func reconcilingEqualsRebuilding() {
        var generator = SeededGenerator(seed: 0x5EED)

        for shape in GeometryModel.shapes {
            for _ in 0..<40 {
                let before = GeometryModel.actions(for: shape, using: &generator)
                let after = GeometryModel.actions(for: shape, using: &generator)

                #expect(PathReconciliation.canReconcile(before))
                #expect(PathReconciliation.haveSameShape(before, after))

                let rebuilt = GeometryModel()
                rebuilt.build(after)

                let reconciled = GeometryModel()
                reconciled.build(before)
                let didReconcile = reconciled.reconcile(from: before, to: after)

                #expect(didReconcile)
                #expect(
                    reconciled.description == rebuilt.description,
                    """
                    Reconciling \(shape) diverged from rebuilding it.
                    reconciled: \(reconciled.description)
                    rebuilt:    \(rebuilt.description)
                    """
                )
            }
        }
    }

    @Test("A shape change is refused rather than reconciled wrongly")
    func shapeChangeIsRefused() {
        let before: [Path.Action] = [.moveTo(SIMD2(0, 0)), .lineTo(SIMD2(1, 1))]
        let after: [Path.Action] = [
            .moveTo(SIMD2(0, 0)),
            .lineTo(SIMD2(1, 1)),
            .lineTo(SIMD2(2, 2))
        ]

        let model = GeometryModel()
        model.build(before)
        #expect(!model.reconcile(from: before, to: after))
    }
}

// MARK: - A model of the native geometry tree

/// A pure-Swift stand-in for the tree of native objects a backend builds a path
/// into, structured exactly as `WinUIBackend` structures its
/// `PathGeometry`/`PathFigure`/segment objects.
///
/// It exists so that the walk that reconciles that tree can be exercised
/// without a Windows toolchain. It mirrors `WinUIBackend.applyActions(_:to:recorder:)`
/// and `WinUIBackend.reconcileGeometry(of:to:)`; if either of those changes,
/// this has to change with them.
final class GeometryModel {
    final class Figure {
        var startPoint: SIMD2<Double>
        var segments: [Segment] = []

        init(startPoint: SIMD2<Double>) {
            self.startPoint = startPoint
        }
    }

    final class Segment {
        var points: [SIMD2<Double>]

        init(_ points: [SIMD2<Double>]) {
            self.points = points
        }
    }

    final class Shape {
        enum Kind {
            case path
            case rectangle
            case ellipse
        }

        let kind: Kind
        var figures: [Figure] = []
        var rect: Path.Rect?
        var center: SIMD2<Double>?
        var radius: Double?

        init(kind: Kind) {
            self.kind = kind
        }
    }

    enum Target {
        case none
        case figureStart(Figure)
        case rectangle(Shape)
        case ellipse(Shape)
        case segment(Segment, startedFigure: Figure?)
    }

    private(set) var shapes: [Shape] = []
    private(set) var targets: [Target] = []

    /// Mirrors `applyActions`, recording what each action wrote into.
    func build(_ actions: [Path.Action]) {
        shapes = []
        targets = []
        var lastPoint = SIMD2<Double>(0, 0)

        for action in actions {
            switch action {
                case .moveTo(let point):
                    lastPoint = point
                    if let last = shapes.last, last.kind == .path, let figure = last.figures.last {
                        if figure.segments.isEmpty {
                            figure.startPoint = point
                            targets.append(.figureStart(figure))
                        } else {
                            let newFigure = Figure(startPoint: point)
                            last.figures.append(newFigure)
                            targets.append(.figureStart(newFigure))
                        }
                    } else {
                        targets.append(.none)
                    }
                case .lineTo(let point):
                    let (figure, created) = requireFigure(lastPoint: lastPoint)
                    let segment = Segment([point])
                    figure.segments.append(segment)
                    targets.append(.segment(segment, startedFigure: created ? figure : nil))
                    lastPoint = point
                case .quadCurve(let control, let end):
                    let (figure, created) = requireFigure(lastPoint: lastPoint)
                    let segment = Segment([control, end])
                    figure.segments.append(segment)
                    targets.append(.segment(segment, startedFigure: created ? figure : nil))
                    lastPoint = end
                case .cubicCurve(let control1, let control2, let end):
                    let (figure, created) = requireFigure(lastPoint: lastPoint)
                    let segment = Segment([control1, control2, end])
                    figure.segments.append(segment)
                    targets.append(.segment(segment, startedFigure: created ? figure : nil))
                    lastPoint = end
                case .rectangle(let rect):
                    let shape = Shape(kind: .rectangle)
                    shape.rect = rect
                    shapes.append(shape)
                    targets.append(.rectangle(shape))
                case .circle(let center, let radius):
                    let shape = Shape(kind: .ellipse)
                    shape.center = center
                    shape.radius = radius
                    shapes.append(shape)
                    targets.append(.ellipse(shape))
                case .arc, .transform, .subpath:
                    targets.append(.none)
            }
        }

        // Mirrors the backend's cleanup of empty path geometries.
        shapes.removeAll { $0.kind == .path && $0.figures.isEmpty }
    }

    private func requireFigure(lastPoint: SIMD2<Double>) -> (Figure, Bool) {
        let shape: Shape
        if let last = shapes.last, last.kind == .path {
            shape = last
        } else {
            shape = Shape(kind: .path)
            shapes.append(shape)
        }

        if let figure = shape.figures.last {
            return (figure, false)
        }
        let figure = Figure(startPoint: lastPoint)
        shape.figures.append(figure)
        return (figure, true)
    }

    /// Mirrors `reconcileGeometry`.
    func reconcile(from previous: [Path.Action], to actions: [Path.Action]) -> Bool {
        guard
            targets.count == actions.count,
            previous.count == actions.count,
            PathReconciliation.haveSameShape(previous, actions)
        else {
            return false
        }

        var previousLastPoint = SIMD2<Double>(0, 0)
        var newLastPoint = SIMD2<Double>(0, 0)

        for index in actions.indices {
            let old = previous[index]
            let new = actions[index]
            let incomingPointMoved = previousLastPoint != newLastPoint
            let changed = old != new

            func updateStart(_ figure: Figure?) {
                if let figure, incomingPointMoved {
                    figure.startPoint = newLastPoint
                }
            }

            switch (new, targets[index]) {
                case (.moveTo(let point), .figureStart(let figure)):
                    if changed { figure.startPoint = point }
                case (.moveTo, .none):
                    break
                case (.lineTo(let point), .segment(let segment, let startedFigure)):
                    updateStart(startedFigure)
                    if changed { segment.points = [point] }
                case (.quadCurve(let control, let end), .segment(let segment, let startedFigure)):
                    updateStart(startedFigure)
                    if changed { segment.points = [control, end] }
                case (
                .cubicCurve(let control1, let control2, let end),
                .segment(let segment, let startedFigure)
            ):
                    updateStart(startedFigure)
                    if changed { segment.points = [control1, control2, end] }
                case (.rectangle(let rect), .rectangle(let shape)):
                    if changed { shape.rect = rect }
                case (.circle(let center, let radius), .ellipse(let shape)):
                    if changed {
                        shape.center = center
                        shape.radius = radius
                    }
                default:
                    return false
            }

            previousLastPoint = PathReconciliation.endPoint(after: old, current: previousLastPoint)
            newLastPoint = PathReconciliation.endPoint(after: new, current: newLastPoint)
        }

        return true
    }

    /// A structural description, for comparing a reconciled tree with a rebuilt
    /// one.
    var description: String {
        shapes.map { shape in
            switch shape.kind {
                case .rectangle:
                    "rect(\(shape.rect.map { "\($0.x),\($0.y),\($0.width),\($0.height)" } ?? "-"))"
                case .ellipse:
                    "ellipse(\(shape.center.map { "\($0.x),\($0.y)" } ?? "-"),\(shape.radius ?? -1))"
                case .path:
                    "path["
                        + shape.figures.map { figure in
                            "start(\(figure.startPoint.x),\(figure.startPoint.y))"
                                + figure.segments.map { segment in
                                    "seg" + segment.points.map { "(\($0.x),\($0.y))" }.joined()
                                }.joined()
                        }.joined(separator: "|") + "]"
            }
        }.joined(separator: " ")
    }

    /// The action-kind sequences the equivalence test covers.
    ///
    /// Includes the orderings that decide whether a figure gets created, reused
    /// or started afresh, which is where the reconciling walk is subtlest.
    static let shapes: [[Int]] = [
        [1, 1, 1], // a bare polyline: the first line creates the figure
        [0, 1, 1, 1], // a move then a polyline
        [0, 1, 1, 0, 1, 1], // two subpaths in one geometry
        [0, 0, 1], // consecutive moves before anything is drawn
        [4], // a lone rectangle
        [4, 4, 4], // several rectangles
        [5, 5], // circles
        [4, 1, 1], // a rectangle forces the next line into a new geometry
        [0, 1, 4, 0, 1], // interleaved whole shapes and figures
        [0, 2, 3, 1], // curves
        [0, 1, 1, 4, 5, 0, 1], // a bit of everything
    ]

    /// Builds an action list with the given kinds and freshly random values.
    static func actions(
        for kinds: [Int],
        using generator: inout SeededGenerator
    ) -> [Path.Action] {
        func value() -> Double {
            Double(generator.next() % 200)
        }
        func point() -> SIMD2<Double> {
            SIMD2(value(), value())
        }
        return kinds.map { kind in
            switch kind {
                case 0: .moveTo(point())
                case 1: .lineTo(point())
                case 2: .quadCurve(control: point(), end: point())
                case 3: .cubicCurve(control1: point(), control2: point(), end: point())
                case 4:
                    .rectangle(
                        Path.Rect(x: value(), y: value(), width: value(), height: value())
                    )
                default: .circle(center: point(), radius: value())
            }
        }
    }
}

/// A deterministic generator, so a failure can be reproduced.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
