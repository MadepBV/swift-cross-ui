import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A stand-in for an application's drag-and-drop payload type.
private struct DropPayload {}

/// Records whether an inert modifier's closure was ever called.
@MainActor
private final class CallRecorder {
    var didRun = false
}

/// Coverage for the desktop vocabulary added alongside ``AnyTransition``:
/// transitions, the drop-destination stub, the fractional padding overloads,
/// the split-view containers and the raised view-builder arity.
@Suite("Testing for transitions, padding, split views and builder arity")
struct TransitionsLayoutAndSplitTests {
    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    // MARK: AnyTransition

    @Test("Named transitions describe themselves")
    func namedTransitionsDescribeThemselves() {
        #expect(AnyTransition.identity.kind == .identity)
        #expect(AnyTransition.opacity.kind == .opacity)
        #expect(AnyTransition.slide.kind == .slide)
        #expect(AnyTransition.scale.kind == .scale(scale: 0, anchor: .center))
        #expect(
            AnyTransition.move(edge: .top).kind == .move(edge: .top)
        )
        #expect(
            AnyTransition.offset(x: 4, y: 8).kind == .offset(x: 4, y: 8)
        )
    }

    @Test("scale(scale:anchor:) keeps both arguments")
    func scaleTransitionKeepsArguments() {
        let transition = AnyTransition.scale(scale: 0.25, anchor: .topLeading)
        #expect(transition.kind == .scale(scale: 0.25, anchor: .topLeading))
    }

    @Test("combined(with:) nests both transitions, in order")
    func combinedTransitionNestsBothOperands() {
        let transition = AnyTransition.move(edge: .top)
            .combined(with: .opacity)

        #expect(transition.kind == .combined(.move(edge: .top), .opacity))
    }

    @Test("combined(with:) composes more than twice")
    func combinedTransitionComposesRepeatedly() {
        let transition = AnyTransition.slide
            .combined(with: .opacity)
            .combined(with: .identity)

        #expect(
            transition.kind == .combined(.combined(.slide, .opacity), .identity)
        )
    }

    @MainActor
    @Test("transition(_:) is inert and leaves layout untouched")
    func transitionModifierIsInert() {
        let plain = computeLayout(of: Text("Dummy"))
        let transitioned = computeLayout(
            of: Text("Dummy")
                .transition(.move(edge: .top).combined(with: .opacity))
        )

        #expect(transitioned.size == plain.size)
    }

    // MARK: dropDestination

    @MainActor
    @Test("dropDestination(for:action:) is inert and never fires")
    func dropDestinationIsInert() {
        let recorder = CallRecorder()
        let plain = computeLayout(of: Text("Dummy"))
        let target = computeLayout(
            of: Text("Dummy")
                .dropDestination(for: DropPayload.self) { _, _ in
                    recorder.didRun = true
                    return true
                }
        )

        #expect(target.size == plain.size)
        #expect(recorder.didRun == false)
    }

    // MARK: Padding

    @MainActor
    @Test("Fractional padding matches the integral overload")
    func fractionalPaddingMatchesIntegralPadding() {
        let integral = computeLayout(of: Text("Dummy").padding(12))
        let fractional = computeLayout(of: Text("Dummy").padding(12.0))

        #expect(fractional.size == integral.size)
    }

    @MainActor
    @Test("Fractional padding rounds to whole points")
    func fractionalPaddingRoundsToWholePoints() {
        let rounded = computeLayout(of: Text("Dummy").padding(12))
        let fractional = computeLayout(of: Text("Dummy").padding(11.6))

        #expect(fractional.size == rounded.size)
    }

    @MainActor
    @Test("Fractional edge padding matches the integral overload")
    func fractionalEdgePaddingMatchesIntegralPadding() {
        let integral = computeLayout(of: Text("Dummy").padding(.horizontal, 8))
        let fractional = computeLayout(
            of: Text("Dummy").padding(.horizontal, 8.0)
        )

        #expect(fractional.size == integral.size)
    }

    @MainActor
    @Test("padding(EdgeInsets) applies a different inset per edge")
    func edgeInsetsPaddingAppliesPerEdgeInsets() {
        let insets = EdgeInsets(top: 1, bottom: 2, leading: 3, trailing: 4)
        let plain = computeLayout(of: Text("Dummy"))
        let padded = computeLayout(of: Text("Dummy").padding(insets))

        #expect(padded.size.width == plain.size.width + 7)
        #expect(padded.size.height == plain.size.height + 3)
    }

    // MARK: Background

    @MainActor
    @Test("background(.background) resolves to a colour behind the content")
    func backgroundStyleResolvesToAColour() {
        let node = committedNode(
            for: Text("Dummy").background(.background),
            proposedSize: ProposedViewSize(200, 200)
        )

        // Background first, foreground second.
        #expect(node.widget.getChildren().count == 2)
    }

    @MainActor
    @Test("background(alignment:content:) still takes a view builder")
    func backgroundBuilderOverloadStillResolves() {
        let node = committedNode(
            for: Text("Dummy").background(alignment: .topLeading) {
                Color.red
            },
            proposedSize: ProposedViewSize(200, 200)
        )

        #expect(node.widget.getChildren().count == 2)
    }

    // MARK: Split views

    @MainActor
    @Test("HSplitView lays its panes out side by side, without spacing")
    func hSplitViewLaysPanesOutHorizontally() {
        let panes = HSplitView {
            Color.red.frame(width: 40, height: 10)
            Color.blue.frame(width: 60, height: 10)
        }
        let result = computeLayout(of: panes)

        #expect(result.size.width == 100)
        #expect(result.size.height == 10)
    }

    @MainActor
    @Test("VSplitView stacks its panes, without spacing")
    func vSplitViewStacksPanes() {
        let panes = VSplitView {
            Color.red.frame(width: 10, height: 40)
            Color.blue.frame(width: 10, height: 60)
        }
        let result = computeLayout(of: panes)

        #expect(result.size.width == 10)
        #expect(result.size.height == 100)
    }

    @MainActor
    @Test("HSplitView accepts three panes")
    func hSplitViewAcceptsThreePanes() {
        let panes = HSplitView {
            Color.red.frame(width: 20, height: 10)
            Color.green.frame(width: 30, height: 10)
            Color.blue.frame(width: 50, height: 10)
        }
        let result = computeLayout(of: panes)

        #expect(result.size.width == 100)
    }

    // MARK: View builder arity

    @MainActor
    @Test("A view builder accepts 32 children")
    func viewBuilderAcceptsThirtyTwoChildren() {
        let stack = VStack(spacing: 0) {
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
            Color.red.frame(width: 10, height: 1)
        }
        let result = computeLayout(of: stack)

        #expect(result.size.height == 32)
    }

    // MARK: Accessibility child behaviour

    @MainActor
    @Test("accessibilityElement(children: .contain) resolves by leading dot")
    func containChildBehaviourResolvesByLeadingDot() {
        let plain = computeLayout(of: Text("Dummy"))
        let contained = computeLayout(
            of: Text("Dummy").accessibilityElement(children: .contain)
        )

        #expect(contained.size == plain.size)
        #expect(AccessibilityChildBehavior.contain.kind == .contain)
    }

    // MARK: Helpers

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = .unspecified
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

    @MainActor
    func committedNode<V: View>(
        for view: V,
        proposedSize: ProposedViewSize = .unspecified
    ) -> ViewGraphNode<V, DummyBackend> {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        _ = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        return node
    }
}
