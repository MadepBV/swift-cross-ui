import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

/// A shape written the way SwiftUI users write shapes.
///
/// It implements only ``Shape/path(in:)-(CGRect)``, so it exercises the
/// default that derives the ``Path/Rect`` overload from this one.
struct Chevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

/// A shape written the way SwiftCrossUI's own shapes are written.
///
/// It implements only ``Shape/path(in:)-(Path.Rect)``, so it exercises the
/// default going the other way.
struct LegacyChevron: Shape {
    func path(in bounds: Path.Rect) -> Path {
        Path()
            .move(to: SIMD2(x: bounds.x, y: bounds.y))
            .addLine(to: SIMD2(x: bounds.maxX, y: bounds.center.y))
            .addLine(to: SIMD2(x: bounds.x, y: bounds.maxY))
    }
}

#if canImport(AppKitBackend)
    /// Drives a view through `AppKitBackend` so that the widgets a shape
    /// produces can be inspected.
    ///
    /// `DummyBackend` doesn't implement `BackendFeatures.Paths`, so
    /// `AppKitBackend` is the only backend available to the test suite that a
    /// shape can actually render through.
    @MainActor
    final class AppKitShapeHarness<Content: View> {
        /// The backend under test.
        let backend: AppKitBackend
        /// The view graph holding the shape.
        let viewGraph: ViewGraph<Content>
        /// The environment that layout runs in.
        let environment: EnvironmentValues

        /// The shape's widget.
        var widget: NSView {
            viewGraph.rootNode.widget.into()
        }

        /// Creates a harness for the given view.
        ///
        /// - Parameter content: The view to render.
        init(_ content: Content) {
            backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(200, 200),
                id: "window"
            )
            environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            viewGraph = ViewGraph(
                for: content,
                backend: backend,
                environment: environment
            )
            backend.setChild(
                ofWindow: window,
                to: viewGraph.rootNode.widget.into()
            )
        }

        /// Runs one layout and commit pass.
        func render() {
            _ = viewGraph.computeLayout(
                proposedSize: ProposedViewSize(40.0, 20.0),
                environment: environment
            )
            viewGraph.commit()
        }
    }
#endif

/// Tests for the framework-side API that a stock SwiftUI codebase expects:
/// ``Shape`` taking a `CGRect`, and the ``Gesture`` family.
///
/// The suite is deliberately heavy on call shapes rather than on computed
/// values — much of what it proves is that SwiftUI's spellings still *compile*
/// unchanged, which is the whole point of these APIs.
@Suite("Testing for Shape's CGRect spelling and for gestures")
struct ButtonStyleShapeAndGestureTests {
    /// The backend that layout-only tests run against.
    let backend: DummyBackend
    /// The window that layout-only tests run in.
    let window: DummyBackend.Window
    /// The environment that layout-only tests run in.
    let environment: EnvironmentValues

    /// A square used by most of the shape tests.
    static let square = Path.Rect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend)
            .with(\.window, window)
    }

    // MARK: Shape

    @Test("A shape written with SwiftUI's CGRect spelling conforms")
    func cgRectShapeConforms() {
        let path = Chevron().path(in: ButtonStyleShapeAndGestureTests.square)

        #expect(
            path.actions == [
                .moveTo(SIMD2(x: 0.0, y: 0.0)),
                .lineTo(SIMD2(x: 10.0, y: 5.0)),
                .lineTo(SIMD2(x: 0.0, y: 10.0)),
            ]
        )
    }

    @Test("A CGRect shape can also be asked for a path with a CGRect")
    func cgRectShapeAnswersCGRect() {
        let rect = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        let viaCGRect = Chevron().path(in: rect)
        let viaPathRect = Chevron().path(
            in: ButtonStyleShapeAndGestureTests.square
        )

        #expect(viaCGRect.actions == viaPathRect.actions)
    }

    @Test("A shape written with the Path.Rect spelling still conforms")
    func pathRectShapeConforms() {
        let rect = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        let viaCGRect = LegacyChevron().path(in: rect)
        let viaPathRect = LegacyChevron().path(
            in: ButtonStyleShapeAndGestureTests.square
        )

        #expect(viaCGRect.actions == viaPathRect.actions)
        #expect(viaCGRect.actions == Chevron().path(in: rect).actions)
    }

    @Test("The built-in shapes agree across both spellings")
    func builtInShapesAgreeAcrossSpellings() {
        let bounds = Path.Rect(x: 1.0, y: 2.0, width: 8.0, height: 4.0)
        let rect = CGRect(x: 1.0, y: 2.0, width: 8.0, height: 4.0)

        #expect(Rectangle().path(in: rect).actions
            == Rectangle().path(in: bounds).actions)
        #expect(Circle().path(in: rect).actions
            == Circle().path(in: bounds).actions)
        #expect(Capsule().path(in: rect).actions
            == Capsule().path(in: bounds).actions)
        #expect(Ellipse().path(in: rect).actions
            == Ellipse().path(in: bounds).actions)
        #expect(RoundedRectangle(cornerRadius: 2.0).path(in: rect).actions
            == RoundedRectangle(cornerRadius: 2.0).path(in: bounds).actions)
    }

    @Test("An inset shape keeps working through the CGRect overload")
    func insetShapesKeepWorking() {
        let rect = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        let inset = Rectangle().inset(by: 2.0)

        let insetBounds = Path.Rect(
            x: 2.0,
            y: 2.0,
            width: 6.0,
            height: 6.0
        )

        #expect(
            inset.path(in: rect).actions
                == Rectangle().path(in: insetBounds).actions
        )
    }

    @Test("A CGRect with a negative size is standardized on the way in")
    func negativeCGRectIsStandardized() {
        let flipped = CGRect(x: 10.0, y: 10.0, width: -10.0, height: -10.0)

        #expect(
            Chevron().path(in: flipped).actions
                == Chevron().path(
                    in: ButtonStyleShapeAndGestureTests.square
                ).actions
        )
    }

    @Test("A styled user-defined shape keeps its style")
    func styledUserShapeKeepsItsStyle() {
        let styled = Chevron().stroke(.red, style: StrokeStyle(lineWidth: 3.0))

        #expect(styled.strokeColor == Color.red)
        #expect(styled.strokeStyle?.lineWidth == 3.0)
        #expect(
            styled.path(in: ButtonStyleShapeAndGestureTests.square).actions
                == Chevron().path(
                    in: ButtonStyleShapeAndGestureTests.square
                ).actions
        )
    }

    #if canImport(AppKitBackend)
        @MainActor
        @Test("A user-defined shape renders through a real backend")
        func userDefinedShapeRenders() {
            let harness = AppKitShapeHarness(Chevron())
            harness.render()

            guard
                let view = harness.widget as? AppKitBackend.NSBezierPathView
            else {
                Issue.record("expected a path view")
                return
            }
            // A move plus two lines.
            #expect(view.path.elementCount == 3)
        }
    #endif

    // MARK: Gestures

    @Test("DragGesture matches SwiftUI's defaults")
    func dragGestureDefaults() {
        let gesture = DragGesture()

        #expect(gesture.minimumDistance == 10.0)
        #expect(gesture.coordinateSpace == .local)
        #expect(gesture.changeHandlers.isEmpty)
        #expect(gesture.endHandlers.isEmpty)
    }

    @Test("DragGesture takes a minimum distance and a coordinate space")
    func dragGestureTakesItsArguments() {
        let gesture = DragGesture(
            minimumDistance: 0.0,
            coordinateSpace: .named("saved-view-frame-resize")
        )

        #expect(gesture.minimumDistance == 0.0)
        #expect(gesture.coordinateSpace == .named("saved-view-frame-resize"))
        #expect(gesture.coordinateSpace != .local)
    }

    @Test("A drag's value derives its translation from its endpoints")
    func dragValueDerivesTranslation() {
        let value = DragGesture.Value(
            time: Date(timeIntervalSince1970: 0.0),
            startLocation: CGPoint(x: 10.0, y: 20.0),
            location: CGPoint(x: 30.0, y: 50.0)
        )

        #expect(value.translation.width == 20.0)
        #expect(value.translation.height == 30.0)
        #expect(value.velocity.width == 0.0)
        #expect(value.velocity.height == 0.0)
        // No momentum model, so the predicted end is where the drag is.
        #expect(value.predictedEndLocation.x == value.location.x)
        #expect(value.predictedEndLocation.y == value.location.y)
        #expect(value.predictedEndTranslation == value.translation)
    }

    @Test("Drag values compare field by field")
    func dragValuesCompare() {
        let time = Date(timeIntervalSince1970: 0.0)
        let start = CGPoint(x: 0.0, y: 0.0)
        let first = DragGesture.Value(
            time: time,
            startLocation: start,
            location: CGPoint(x: 1.0, y: 1.0)
        )
        let same = DragGesture.Value(
            time: time,
            startLocation: start,
            location: CGPoint(x: 1.0, y: 1.0)
        )
        let different = DragGesture.Value(
            time: time,
            startLocation: start,
            location: CGPoint(x: 2.0, y: 1.0)
        )

        #expect(first == same)
        #expect(first != different)
    }

    @MainActor
    @Test("A drag gesture's handlers accumulate and run in order")
    func dragHandlersAccumulate() {
        let calls = HandlerLog()
        let gesture = DragGesture(minimumDistance: 4.0)
            .onChanged { _ in calls.record("changed-1") }
            .onChanged { _ in calls.record("changed-2") }
            .onEnded { value in
                calls.record("ended-\(Int(value.translation.width))")
            }

        #expect(gesture.changeHandlers.count == 2)
        #expect(gesture.endHandlers.count == 1)

        let value = DragGesture.Value(
            time: Date(timeIntervalSince1970: 0.0),
            startLocation: CGPoint(x: 0.0, y: 0.0),
            location: CGPoint(x: 7.0, y: 0.0)
        )
        for handler in gesture.changeHandlers {
            handler(value)
        }
        for handler in gesture.endHandlers {
            handler(value)
        }

        #expect(calls.entries == ["changed-1", "changed-2", "ended-7"])
    }

    @Test("SpatialTapGesture matches SwiftUI's defaults")
    func spatialTapGestureDefaults() {
        let gesture = SpatialTapGesture()

        #expect(gesture.count == 1)
        #expect(gesture.coordinateSpace == .local)
        #expect(gesture.endHandlers.isEmpty)
    }

    @MainActor
    @Test("A spatial tap gesture's handlers receive a location")
    func spatialTapHandlersReceiveALocation() {
        let calls = HandlerLog()
        let gesture = SpatialTapGesture(count: 2)
            .onEnded { value in
                let x = Int(value.location.x)
                let y = Int(value.location.y)
                calls.record("\(x),\(y)")
            }

        #expect(gesture.count == 2)
        for handler in gesture.endHandlers {
            handler(SpatialTapGesture.Value(location: CGPoint(x: 3.0, y: 4.0)))
        }

        #expect(calls.entries == ["3,4"])
    }

    @Test("Tap values compare by location")
    func spatialTapValuesCompare() {
        let first = SpatialTapGesture.Value(location: CGPoint(x: 1.0, y: 2.0))
        let same = SpatialTapGesture.Value(location: CGPoint(x: 1.0, y: 2.0))
        let different = SpatialTapGesture.Value(
            location: CGPoint(x: 1.0, y: 3.0)
        )

        #expect(first == same)
        #expect(first != different)
    }

    @Test("Named coordinate spaces compare by name")
    func namedCoordinateSpacesCompare() {
        #expect(CoordinateSpace.named("canvas") == .named("canvas"))
        #expect(CoordinateSpace.named("canvas") != .named("sheet"))
        #expect(CoordinateSpace.named("canvas") != .local)
        #expect(CoordinateSpace.local != .global)
    }

    @MainActor
    @Test("Attaching a gesture leaves the view's layout untouched")
    func attachingAGestureIsLayoutTransparent() {
        let plain = computeLayout(of: Text("Snap"))
        let withGesture = computeLayout(
            of: Text("Snap").gesture(DragGesture(minimumDistance: 0.0))
        )
        let withSimultaneous = computeLayout(
            of: Text("Snap").simultaneousGesture(SpatialTapGesture())
        )

        #expect(withGesture.size == plain.size)
        #expect(withSimultaneous.size == plain.size)
    }

    // MARK: The call shapes a SwiftUI codebase actually writes

    /// Mirrors an app returning a gesture from a helper, as SwiftUI allows.
    ///
    /// - Returns: A tap gesture that reports where it was tapped.
    @MainActor
    func tapGesture(recordingInto log: HandlerLog) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                log.record("tap at \(Int(value.location.x))")
            }
    }

    /// Mirrors an app returning a drag gesture from a helper.
    ///
    /// - Returns: A drag gesture that reports where it started and ended.
    @MainActor
    func dragGesture(recordingInto log: HandlerLog) -> some Gesture {
        DragGesture(minimumDistance: 4.0)
            .onEnded { value in
                log.record("drag by \(Int(value.translation.width))")
            }
    }

    @MainActor
    @Test("A view can take a gesture built by a helper, as SwiftUI allows")
    func gesturesComposeTheWaySwiftUIAppsWriteThem() {
        let log = HandlerLog()
        let view = Text("Canvas")
            .gesture(tapGesture(recordingInto: log))
            .simultaneousGesture(dragGesture(recordingInto: log))

        // Nothing is delivered yet — see `View.gesture(_:)` — but the view
        // still lays out exactly as it did without the gestures.
        let plain = computeLayout(of: Text("Canvas"))
        #expect(computeLayout(of: view).size == plain.size)
        #expect(log.entries.isEmpty)
    }

    // MARK: Helpers

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = ProposedViewSize(200.0, 200.0)
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        return node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }
}

/// Collects the order in which gesture handlers ran.
///
/// A reference type so that handlers can append to it without the gesture
/// having to be mutable.
@MainActor
final class HandlerLog {
    /// The messages recorded so far, oldest first.
    private(set) var entries: [String] = []

    /// Creates an empty log.
    init() {}

    /// Appends a message to the log.
    ///
    /// - Parameter entry: The message to record.
    func record(_ entry: String) {
        entries.append(entry)
    }
}
