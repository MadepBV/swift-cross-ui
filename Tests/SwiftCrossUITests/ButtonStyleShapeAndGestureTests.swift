import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

/// A button style written the way SwiftUI users write them.
///
/// Brackets the label so that the style's body is visible in the rendered
/// widget tree, proving `makeBody(configuration:)` really ran.
struct BracketButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Text("[")
            configuration.label
            Text("]")
        }
    }
}

/// A button style written exactly the way the ported application writes its
/// own, down to the stored property and the modifier chain.
///
/// This exists to keep the shape compiling, not for what it computes.
private struct FamilyRowButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
    }
}

/// A button style that reports the role it was handed.
struct RoleReportingButtonStyle: ButtonStyle {
    /// Where to record the role the configuration carried.
    var log: HandlerLog

    func makeBody(configuration: Configuration) -> some View {
        log.record(configuration.role.map(String.init(describing:)) ?? "none")
        return configuration.label
    }
}

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
    /// An `NSPanGestureRecognizer` whose state and positions the test drives.
    ///
    /// Synthesising real mouse events would need a running event loop and a
    /// key window; replaying the recognizer callbacks exercises exactly the
    /// same code in `NSCustomPointerGestureTarget`.
    final class ReplayedPanGestureRecognizer: NSPanGestureRecognizer {
        /// The state to report.
        var replayedState: NSGestureRecognizer.State = .began
        /// The position to report.
        var replayedLocation: CGPoint = .zero
        /// The velocity to report.
        var replayedVelocity: CGPoint = .zero

        override var state: NSGestureRecognizer.State {
            get { replayedState }
            set { replayedState = newValue }
        }

        override func location(in view: NSView?) -> NSPoint {
            replayedLocation
        }

        override func velocity(in view: NSView?) -> NSPoint {
            replayedVelocity
        }
    }

    /// An `NSClickGestureRecognizer` whose position the test drives.
    final class ReplayedClickGestureRecognizer: NSClickGestureRecognizer {
        /// The position to report.
        var replayedLocation: CGPoint = .zero

        override func location(in view: NSView?) -> NSPoint {
            replayedLocation
        }
    }

    /// An `NSMagnificationGestureRecognizer` whose state, position and
    /// magnification the test drives.
    final class ReplayedMagnificationGestureRecognizer: NSMagnificationGestureRecognizer {
        /// The state to report.
        var replayedState: NSGestureRecognizer.State = .began
        /// The position to report.
        var replayedLocation: CGPoint = .zero
        /// The accumulated change in scale to report.
        var replayedMagnification: CGFloat = 0.0

        override var state: NSGestureRecognizer.State {
            get { replayedState }
            set { replayedState = newValue }
        }

        override var magnification: CGFloat {
            get { replayedMagnification }
            set { replayedMagnification = newValue }
        }

        override func location(in view: NSView?) -> NSPoint {
            replayedLocation
        }
    }

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
        /// The window the view lives in.
        let window: NSCustomWindow
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
            self.window = window
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
@Suite("Testing for ButtonStyle, Shape's CGRect spelling and gestures")
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

    // MARK: ButtonStyle

    @MainActor
    @Test("Every built-in style keeps its leading-dot spelling")
    func builtInStylesKeepTheirSpelling() {
        // Purely a compilation test: these are the spellings the port must
        // keep accepting, and `.buttonStyle(_:)` takes them all.
        let styles: [any ButtonStyle] = [
            .automatic, .bordered, .borderedProminent, .borderless, .plain,
            .link,
        ]

        #expect(styles.count == 6)
        #expect(styles[0] is DefaultButtonStyle)
        #expect(styles[1] is BorderedButtonStyle)
        #expect(styles[2] is BorderedProminentButtonStyle)
        #expect(styles[3] is BorderlessButtonStyle)
        #expect(styles[4] is PlainButtonStyle)
        #expect(styles[5] is LinkButtonStyle)
    }

    @MainActor
    @Test("Each built-in style asks the backend for the right chrome")
    func builtInStylesMapOntoBackendChrome() {
        #expect(BorderedButtonStyle().kind == .bordered)
        #expect(BorderedProminentButtonStyle().kind == .bordered)
        #expect(BorderlessButtonStyle().kind == .borderless)
        #expect(PlainButtonStyle().kind == .plain)
        #expect(LinkButtonStyle().kind == .borderless)
    }

    @MainActor
    @Test("A built-in style reaches the backend's button")
    func builtInStyleReachesTheBackend() {
        let button = renderedButton(
            for: Button("Extrude") {}.buttonStyle(.borderless)
        )

        #expect(button?.buttonStyle is BorderlessButtonStyle)
        #expect(button?.buttonStyle.kind == .borderless)
    }

    @MainActor
    @Test("An unstyled button falls back to the backend's default")
    func unstyledButtonUsesTheBackendDefault() {
        let unstyled = renderedButton(for: Button("Extrude") {})
        let automatic = renderedButton(
            for: Button("Extrude") {}.buttonStyle(.automatic)
        )

        // DummyBackend declares `.bordered` as its default, and asking for
        // the automatic style has to mean the same thing.
        #expect(unstyled?.buttonStyle is BorderedButtonStyle)
        #expect(automatic?.buttonStyle is BorderedButtonStyle)
    }

    @MainActor
    @Test("A user-defined style's body becomes the button's label")
    func userDefinedStyleRendersItsBody() {
        let styled = renderedButton(
            for: Button("Extrude") {}.buttonStyle(BracketButtonStyle())
        )
        let plain = renderedButton(for: Button("Extrude") {})

        #expect(labelTexts(of: styled) == ["[", "Extrude", "]"])
        #expect(labelTexts(of: plain) == ["Extrude"])
    }

    @MainActor
    @Test("A user-defined style suppresses the backend's own chrome")
    func userDefinedStyleSuppressesBackendChrome() {
        let button = renderedButton(
            for: Button("Extrude") {}.buttonStyle(BracketButtonStyle())
        )

        #expect(button?.buttonStyle is BracketButtonStyle)
        // A custom style draws everything itself, so the backend must be
        // asked for no chrome at all.
        #expect(button?.buttonStyle.kind == .plain)
    }

    @MainActor
    @Test("A user-defined style is handed the button's role")
    func userDefinedStyleReceivesTheRole() {
        let log = HandlerLog()
        _ = renderedButton(
            for: Button("Delete", role: .destructive) {}
                .buttonStyle(RoleReportingButtonStyle(log: log))
        )

        #expect(log.entries.first == "destructive")
    }

    @MainActor
    @Test("A style written the way the ported app writes one still works")
    func applicationShapedStyleWorks() {
        let button = renderedButton(
            for: Button("Angles") {}
                .buttonStyle(FamilyRowButtonStyle(isSelected: true))
        )

        #expect(button?.buttonStyle is FamilyRowButtonStyle)
        #expect(button?.buttonStyle.kind == .plain)
        #expect(labelTexts(of: button) == ["Angles"])
    }

    @MainActor
    @Test("A style set on an ancestor reaches every button beneath it")
    func stylePropagatesThroughTheEnvironment() {
        let node = committedNode(
            for: VStack {
                Button("One") {}
                Button("Two") {}
            }
            .buttonStyle(.plain)
        )

        let buttons = allButtons(in: node.widget)
        #expect(buttons.count == 2)
        #expect(buttons.allSatisfy { $0.buttonStyle is PlainButtonStyle })
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

    @MainActor
    @Test("A button whose label fills an infinite proposal doesn't trap")
    func buttonLabelWithInfiniteFrameDoesNotTrap() {
        // `.frame(maxWidth: .infinity)` reports an infinite width for an
        // infinite proposal, which the button used to convert to `Int`.
        let layout = computeLayout(
            of: Button(action: {}) {
                Text("Go").frame(maxWidth: .infinity)
            },
            proposedSize: ProposedViewSize(.infinity, 20.0)
        )

        #expect(layout.size.width.isInfinite)
        #expect(layout.size.height.isFinite)

        let finite = computeLayout(
            of: Button(action: {}) {
                Text("Go").frame(maxWidth: .infinity)
            },
            proposedSize: ProposedViewSize(120.0, 20.0)
        )
        #expect(finite.size.width >= 120.0)
        #expect(finite.size.width.isFinite)
    }

    @Test("Hover phases compare by location")
    func hoverPhasesCompare() {
        #expect(HoverPhase.active(CGPoint(x: 1.0, y: 2.0)) == .active(CGPoint(x: 1.0, y: 2.0)))
        #expect(HoverPhase.active(CGPoint(x: 1.0, y: 2.0)) != .active(CGPoint(x: 1.0, y: 3.0)))
        #expect(HoverPhase.ended == .ended)
        #expect(HoverPhase.ended != .active(.zero))

        let event = PointerMoveEvent(phase: .ended)
        #expect(event.phase == .ended)
        #expect(event.modifiers.isEmpty)
    }

    @MainActor
    @Test("Hover modifiers leave the view's layout untouched")
    func hoverModifiersAreLayoutTransparent() {
        let plain = computeLayout(of: Text("Snap"))
        let withHover = computeLayout(
            of: Text("Snap").onContinuousHover { _ in }
        )
        let withMove = computeLayout(
            of: Text("Snap").onPointerMove { _ in }
        )
        let chained = computeLayout(
            of: Text("Snap")
                .gesture(DragGesture(minimumDistance: 0.0))
                .onContinuousHover(coordinateSpace: .global) { _ in }
                .onPointerMove { _ in }
        )

        #expect(withHover.size == plain.size)
        #expect(withMove.size == plain.size)
        #expect(chained.size == plain.size)
    }

    @Test("Pointer modifiers are an option set with readable names")
    func pointerModifiersAreAnOptionSet() {
        let modifiers: PointerModifiers = [.shift, .command]

        #expect(modifiers.contains(.shift))
        #expect(modifiers.contains(.command))
        #expect(!modifiers.contains(.option))
        #expect(modifiers.description == "shift+command")
        #expect(PointerModifiers().description == "none")
        #expect(PointerModifiers.all.contains(.capsLock))
    }

    @Test("Pointer events default to no modifiers")
    func pointerEventsDefaultToNoModifiers() {
        let point = CGPoint(x: 1.0, y: 2.0)
        let gesture = PointerGestureEvent(startLocation: point, location: point)
        let scroll = PointerScrollEvent(location: point, deltaX: 0.0, deltaY: -3.0)
        let magnify = PointerMagnifyEvent(location: point, magnification: 1.5)

        #expect(gesture.modifiers.isEmpty)
        #expect(scroll.modifiers.isEmpty)
        #expect(scroll.phase == .changed)
        #expect(!scroll.isPrecise)
        #expect(magnify.modifiers.isEmpty)
        #expect(magnify.phase == .changed)
    }

    @Test("Drag and tap values carry the modifier keys")
    func gestureValuesCarryModifiers() {
        let time = Date(timeIntervalSince1970: 0.0)
        let plain = DragGesture.Value(
            time: time,
            startLocation: .zero,
            location: CGPoint(x: 1.0, y: 1.0)
        )
        let shifted = DragGesture.Value(
            time: time,
            startLocation: .zero,
            location: CGPoint(x: 1.0, y: 1.0),
            modifiers: [.shift]
        )
        let tap = SpatialTapGesture.Value(
            location: CGPoint(x: 1.0, y: 2.0),
            modifiers: [.command]
        )

        #expect(plain.modifiers.isEmpty)
        #expect(shifted.modifiers == [.shift])
        #expect(plain != shifted)
        #expect(tap.modifiers == [.command])
        #expect(tap != SpatialTapGesture.Value(location: CGPoint(x: 1.0, y: 2.0)))
    }

    @MainActor
    @Test("Scroll and magnify modifiers leave the view's layout untouched")
    func scrollAndMagnifyAreLayoutTransparent() {
        let plain = computeLayout(of: Text("Snap"))
        let withScroll = computeLayout(
            of: Text("Snap").onScrollWheel { _ in }
        )
        let withMagnify = computeLayout(
            of: Text("Snap").onMagnify { _ in }
        )
        let withBoth = computeLayout(
            of: Text("Snap")
                .gesture(DragGesture(minimumDistance: 0.0))
                .onScrollWheel { _ in }
                .onMagnify { _ in }
        )

        #expect(withScroll.size == plain.size)
        #expect(withMagnify.size == plain.size)
        #expect(withBoth.size == plain.size)
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

    #if canImport(AppKitBackend)
        @MainActor
        @Test("A drag delivers a real translation through AppKitBackend")
        func dragDeliversTranslationThroughAppKit() {
            let log = HandlerLog()
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .gesture(
                        DragGesture(minimumDistance: 4.0)
                            .onChanged { value in
                                log.record(
                                    "changed \(Self.describe(value.translation))"
                                )
                            }
                            .onEnded { value in
                                log.record(
                                    """
                                    ended \(Self.describe(value.translation)) \
                                    from \(Self.describe(value.startLocation)) \
                                    to \(Self.describe(value.location))
                                    """
                                )
                            }
                    )
            )
            harness.render()

            guard let target = Self.pointerTarget(in: harness.widget) else {
                Issue.record("expected a pointer gesture target")
                return
            }

            let recognizer = ReplayedPanGestureRecognizer()
            recognizer.replayedState = .began
            recognizer.replayedLocation = CGPoint(x: 10.0, y: 10.0)
            target.pan(sender: recognizer)

            // Still inside the 4pt threshold, so nothing is delivered yet.
            recognizer.replayedState = .changed
            recognizer.replayedLocation = CGPoint(x: 12.0, y: 10.0)
            target.pan(sender: recognizer)
            #expect(log.entries.isEmpty)

            // Past the threshold now.
            recognizer.replayedLocation = CGPoint(x: 20.0, y: 15.0)
            target.pan(sender: recognizer)

            recognizer.replayedState = .ended
            recognizer.replayedLocation = CGPoint(x: 30.0, y: 20.0)
            target.pan(sender: recognizer)

            #expect(
                log.entries == [
                    "changed (10, 5)",
                    "ended (20, 10) from (10, 10) to (30, 20)",
                ]
            )
        }

        @MainActor
        @Test("A cancelled drag never reaches the gesture's handlers")
        func cancelledDragIsNotDelivered() {
            let log = HandlerLog()
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .gesture(
                        DragGesture(minimumDistance: 0.0)
                            .onEnded { _ in log.record("ended") }
                    )
            )
            harness.render()

            guard let target = Self.pointerTarget(in: harness.widget) else {
                Issue.record("expected a pointer gesture target")
                return
            }

            let recognizer = ReplayedPanGestureRecognizer()
            recognizer.replayedState = .began
            recognizer.replayedLocation = CGPoint(x: 5.0, y: 5.0)
            target.pan(sender: recognizer)
            recognizer.replayedState = .cancelled
            target.pan(sender: recognizer)

            #expect(log.entries.isEmpty)
        }

        @MainActor
        @Test("A spatial tap delivers its location through AppKitBackend")
        func spatialTapDeliversLocationThroughAppKit() {
            let log = HandlerLog()
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                log.record(Self.describe(value.location))
                            }
                    )
            )
            harness.render()

            guard let target = Self.pointerTarget(in: harness.widget) else {
                Issue.record("expected a pointer gesture target")
                return
            }

            let recognizer = ReplayedClickGestureRecognizer()
            recognizer.replayedLocation = CGPoint(x: 7.0, y: 3.0)
            target.click(sender: recognizer)

            #expect(log.entries == ["(7, 3)"])
        }

        @MainActor
        @Test("A tap and a drag share one target, so both are delivered")
        func simultaneousGesturesShareOneTarget() {
            let log = HandlerLog()
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .gesture(
                        SpatialTapGesture().onEnded { _ in log.record("tap") }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0.0)
                            .onEnded { _ in log.record("drag") }
                    )
            )
            harness.render()

            guard let target = Self.pointerTarget(in: harness.widget) else {
                Issue.record("expected a pointer gesture target")
                return
            }

            let click = ReplayedClickGestureRecognizer()
            click.replayedLocation = CGPoint(x: 1.0, y: 1.0)
            target.click(sender: click)

            let pan = ReplayedPanGestureRecognizer()
            pan.replayedState = .began
            pan.replayedLocation = CGPoint(x: 1.0, y: 1.0)
            target.pan(sender: pan)
            pan.replayedState = .changed
            pan.replayedLocation = CGPoint(x: 9.0, y: 1.0)
            target.pan(sender: pan)
            pan.replayedState = .ended
            target.pan(sender: pan)

            #expect(log.entries == ["tap", "drag"])
        }

        @MainActor
        @Test("Layout containers let clicks through to the view beneath")
        func layoutContainersArePassThrough() {
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .onTapGesture {}
                    .overlay {
                        GeometryReader { _ in
                            VStack {
                                Text("")
                            }
                        }
                    }
            )
            harness.render()
            // The gesture target is sized by Auto Layout constraints, which
            // only resolve once layout runs.
            harness.widget.layoutSubtreeIfNeeded()

            guard let target = Self.firstView(ofType: NSCustomTapGestureTarget.self, in: harness.widget)
            else {
                Issue.record("expected a tap gesture target")
                return
            }
            #expect(target.bounds.width > 0.0 && target.bounds.height > 0.0)

            // `hitTest(_:)` takes a point in the receiver's superview's
            // coordinates, so convert the target's centre up to there.
            let centre = target.convert(
                CGPoint(x: target.bounds.midX, y: target.bounds.midY),
                to: harness.widget.superview
            )

            let hit = harness.widget.hitTest(centre)
            #expect(
                hit === target,
                """
                Expected the overlay's containers to be transparent, got \
                \(String(describing: hit)); target frame \(target.frame), \
                root frame \(harness.widget.frame), centre \(centre)
                """
            )
        }

        @MainActor
        @Test("Updating a window for a colour scheme sets its appearance")
        func windowAppearanceFollowsColorScheme() {
            let backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(100, 100),
                id: "appearance-test"
            )
            let environment = EnvironmentValues(backend: backend)

            backend.updateWindow(window, environment: environment.with(\.colorScheme, .dark))
            #expect(
                window.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            )

            backend.updateWindow(window, environment: environment.with(\.colorScheme, .light))
            #expect(
                window.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
            )
        }

        @MainActor
        @Test("Mouse movement delivers hover phases through AppKitBackend")
        func continuousHoverDeliversPhasesThroughAppKit() {
            let log = HandlerLog()
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .onContinuousHover { phase in
                        switch phase {
                            case .active(let location):
                                log.record("active \(Self.describe(location))")
                            case .ended:
                                log.record("ended")
                        }
                    }
                    .onPointerMove { event in
                        if case .active = event.phase {
                            log.record("move \(event.modifiers)")
                        }
                    }
            )
            harness.render()

            guard let target = Self.pointerTarget(in: harness.widget) else {
                Issue.record("expected a pointer gesture target")
                return
            }

            // Mouse events carry window coordinates; the target converts
            // them into its own flipped space, so start from the point the
            // handler should see and convert it the other way.
            let windowPoint = target.convert(CGPoint(x: 7.0, y: 3.0), to: nil)
            guard
                let move = NSEvent.mouseEvent(
                    with: .mouseMoved,
                    location: windowPoint,
                    modifierFlags: [.shift],
                    timestamp: 0.0,
                    windowNumber: harness.window.windowNumber,
                    context: nil,
                    eventNumber: 0,
                    clickCount: 0,
                    pressure: 0.0
                ),
                let exit = NSEvent.enterExitEvent(
                    with: .mouseExited,
                    location: CGPoint(x: -1.0, y: -1.0),
                    modifierFlags: [],
                    timestamp: 0.0,
                    windowNumber: harness.window.windowNumber,
                    context: nil,
                    eventNumber: 0,
                    trackingNumber: 0,
                    userData: nil
                )
            else {
                Issue.record("could not synthesise mouse events")
                return
            }

            target.mouseMoved(with: move)
            target.mouseExited(with: exit)
            // Leaving twice reports once.
            target.mouseExited(with: exit)

            #expect(log.entries == ["active (7, 3)", "move shift", "ended"])
        }

        @Test("AppKit modifier flags map onto pointer modifiers")
        func appKitModifierFlagsMap() {
            let flags: NSEvent.ModifierFlags = [.shift, .command, .option, .control, .capsLock]

            #expect(PointerModifiers(flags) == PointerModifiers.all)
            #expect(PointerModifiers(NSEvent.ModifierFlags()).isEmpty)
            #expect(PointerModifiers([.numericPad]).isEmpty)
        }

        @MainActor
        @Test("A pinch delivers its scale factor and phases through AppKitBackend")
        func magnifyDeliversScaleThroughAppKit() {
            let log = HandlerLog()
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .onMagnify { event in
                        log.record(
                            "\(event.phase) \(event.magnification) at \(Self.describe(event.location))"
                        )
                    }
            )
            harness.render()

            guard let target = Self.pointerTarget(in: harness.widget) else {
                Issue.record("expected a pointer gesture target")
                return
            }

            let recognizer = ReplayedMagnificationGestureRecognizer()
            recognizer.replayedState = .began
            recognizer.replayedLocation = CGPoint(x: 10.0, y: 5.0)
            recognizer.replayedMagnification = 0.0
            target.magnify(sender: recognizer)
            recognizer.replayedState = .changed
            recognizer.replayedMagnification = 0.5
            target.magnify(sender: recognizer)
            recognizer.replayedState = .ended
            target.magnify(sender: recognizer)

            #expect(
                log.entries == [
                    "began 1.0 at (10, 5)",
                    "changed 1.5 at (10, 5)",
                    "ended 1.5 at (10, 5)",
                ]
            )
        }

        @MainActor
        @Test("A gesture in a named coordinate space is refused, not faked")
        func namedCoordinateSpaceIsRefused() {
            let harness = AppKitShapeHarness(
                Color.blue.frame(width: 40.0, height: 20.0)
                    .gesture(
                        DragGesture(
                            minimumDistance: 0.0,
                            coordinateSpace: .named("canvas")
                        )
                        .onEnded { _ in }
                    )
            )
            harness.render()

            // No target at all, rather than one reporting positions measured
            // from the wrong origin.
            #expect(Self.pointerTarget(in: harness.widget) == nil)
        }

        /// Finds the pointer gesture target in a rendered widget tree.
        ///
        /// - Parameter widget: The widget to search.
        /// - Returns: The target, if the gesture was attached at all.
        @MainActor
        static func pointerTarget(
            in widget: NSView
        ) -> NSCustomPointerGestureTarget? {
            if let target = widget as? NSCustomPointerGestureTarget {
                return target
            }
            for subview in widget.subviews {
                if let target = pointerTarget(in: subview) {
                    return target
                }
            }
            return nil
        }

        /// Renders a point as `(x, y)` with whole numbers.
        ///
        /// - Parameter point: The point to describe.
        /// - Returns: The point's description.
        static func describe(_ point: CGPoint) -> String {
            "(\(Int(point.x)), \(Int(point.y)))"
        }

        /// Renders a size as `(width, height)` with whole numbers.
        ///
        /// - Parameter size: The size to describe.
        /// - Returns: The size's description.
        static func describe(_ size: CGSize) -> String {
            "(\(Int(size.width)), \(Int(size.height)))"
        }
    #endif

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

        // `DummyBackend` doesn't implement `BackendFeatures.PointerGestures`,
        // so nothing is delivered and the view lays out exactly as it did
        // without the gestures. `AppKitBackend` does implement it; the tests
        // above drive the real thing through it.
        let plain = computeLayout(of: Text("Canvas"))
        #expect(computeLayout(of: view).size == plain.size)
        #expect(log.entries.isEmpty)
    }

    // MARK: Helpers

    /// Commits a view and returns the first button widget it rendered.
    ///
    /// - Parameter view: The view to render.
    /// - Returns: The button widget, if the view produced one.
    @MainActor
    func renderedButton<V: View>(for view: V) -> DummyBackend.Button? {
        committedNode(for: view).widget
            .firstWidget(ofType: DummyBackend.Button.self)
    }

    /// Commits a view so that its widgets can be inspected.
    ///
    /// - Parameter view: The view to render.
    /// - Returns: The view's committed graph node.
    @MainActor
    func committedNode<V: View>(for view: V) -> ViewGraphNode<V, DummyBackend> {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        _ = node.computeLayout(
            proposedSize: ProposedViewSize(200.0, 200.0),
            environment: environment
        )
        _ = node.commit()
        return node
    }

    /// Collects the text a button's label renders, in order.
    ///
    /// - Parameter button: The button to read.
    /// - Returns: The label's text, outermost first.
    @MainActor
    func labelTexts(of button: DummyBackend.Button?) -> [String] {
        guard let label = button?.label else {
            return []
        }
        return texts(in: label)
    }

    /// Collects the content of every text widget in a widget hierarchy.
    ///
    /// - Parameter widget: The root of the hierarchy to walk.
    /// - Returns: The text found, in traversal order.
    @MainActor
    func texts(in widget: DummyBackend.Widget) -> [String] {
        var result: [String] = []
        if let textView = widget as? DummyBackend.TextView {
            result.append(textView.content)
        }
        for child in widget.getChildren() {
            result += texts(in: child)
        }
        return result
    }

    /// Collects every button widget in a widget hierarchy.
    ///
    /// - Parameter widget: The root of the hierarchy to walk.
    /// - Returns: The buttons found, in traversal order.
    @MainActor
    func allButtons(in widget: DummyBackend.Widget) -> [DummyBackend.Button] {
        var result: [DummyBackend.Button] = []
        if let button = widget as? DummyBackend.Button {
            result.append(button)
        }
        for child in widget.getChildren() {
            result += allButtons(in: child)
        }
        return result
    }

    /// Finds the first view of a type in a hierarchy, depth first.
    #if canImport(AppKitBackend)
        @MainActor
        static func firstView<T: NSView>(ofType type: T.Type, in view: NSView) -> T? {
            if let match = view as? T {
                return match
            }
            for subview in view.subviews {
                if let match = firstView(ofType: type, in: subview) {
                    return match
                }
            }
            return nil
        }
    #endif

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
