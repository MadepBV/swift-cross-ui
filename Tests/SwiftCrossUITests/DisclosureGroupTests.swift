import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A source of truth for a disclosure group's expansion state, standing in for
/// the `@State` property that an app would usually use.
final class ExpansionSource {
    var isExpanded: Bool

    var binding: Binding<Bool> {
        Binding(
            get: { self.isExpanded },
            set: { newValue in self.isExpanded = newValue }
        )
    }

    init(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
    }
}

@Suite("Testing for DisclosureGroup")
struct DisclosureGroupTests {
    /// The width proposed to every disclosure group under test. The height is
    /// left unspecified so that the groups report their ideal heights.
    static let proposal = ProposedViewSize(400, nil)

    /// The height of the content used by most of the tests below. Chosen to be
    /// far larger than any label so that mistakes are obvious.
    static let contentHeight = 500.0

    /// The spacing that ``DisclosureGroup`` puts between its label and its
    /// content while expanded.
    static let contentSpacing = 6.0

    /// The indicator that ``DisclosureGroup`` shows while collapsed.
    static let collapsedIndicator = "\u{25B8}"

    /// The indicator that ``DisclosureGroup`` shows while expanded.
    static let expandedIndicator = "\u{25BE}"

    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    @MainActor
    @Test("Collapsed DisclosureGroup's content contributes zero height")
    func collapsedContentContributesZeroHeight() {
        let source = ExpansionSource(false)

        let withContent = DisclosureGroup(isExpanded: source.binding) {
            Color.blue.frame(height: DisclosureGroupTests.contentHeight)
        } label: {
            Text("Layout")
        }
        let withoutContent = DisclosureGroup(isExpanded: source.binding) {
        } label: {
            Text("Layout")
        }

        let withContentHeight = computeLayout(of: withContent).size.height
        let withoutContentHeight = computeLayout(of: withoutContent).size.height

        // The collapsed content must be absent from the layout entirely, not
        // just invisible, so it can't contribute height or stack spacing.
        #expect(withContentHeight == withoutContentHeight)
    }

    @MainActor
    @Test("Expanded DisclosureGroup's content contributes its full height")
    func expandedContentContributesItsHeight() {
        let collapsed = ExpansionSource(false)
        let expanded = ExpansionSource(true)

        let collapsedHeight = computeLayout(
            of: disclosureGroup(boundTo: collapsed)
        ).size.height
        let expandedHeight = computeLayout(
            of: disclosureGroup(boundTo: expanded)
        ).size.height

        #expect(
            expandedHeight
                >= collapsedHeight + DisclosureGroupTests.contentHeight
        )
    }

    @MainActor
    @Test("DisclosureGroup honours external changes to its binding")
    func externalBindingChangesAreHonoured() {
        let source = ExpansionSource(true)
        let view = disclosureGroup(boundTo: source)

        let node = committedNode(for: view)
        let expandedHeight = node.currentLayout?.size.height

        // Collapse the group from the outside, exactly like a parent view
        // writing to the state that backs the binding would.
        source.isExpanded = false
        let collapsedHeight = node.computeLayout(
            proposedSize: DisclosureGroupTests.proposal,
            environment: environment
        ).size.height

        #expect(expandedHeight != nil)
        #expect(
            expandedHeight
                == collapsedHeight
                + DisclosureGroupTests.contentHeight
                + DisclosureGroupTests.contentSpacing
        )
    }

    @MainActor
    @Test("Interacting with DisclosureGroup's label writes back to its binding")
    func interactionWritesBackToBinding() {
        let source = ExpansionSource(false)
        let view = disclosureGroup(boundTo: source)

        let node = committedNode(for: view)
        let button = node.widget.firstWidget(ofType: DummyBackend.Button.self)

        #expect(button != nil)
        button?.action?()

        #expect(source.isExpanded)

        button?.action?()

        #expect(!source.isExpanded)
    }

    @MainActor
    @Test("Uncontrolled DisclosureGroup manages its own expansion state")
    func uncontrolledGroupManagesItsOwnState() {
        let view = DisclosureGroup("Layout") {
            Color.blue.frame(height: DisclosureGroupTests.contentHeight)
        }

        let node = committedNode(for: view)
        let collapsedHeight = node.currentLayout?.size.height

        node.widget.firstWidget(ofType: DummyBackend.Button.self)?.action?()

        let expandedHeight = node.computeLayout(
            proposedSize: DisclosureGroupTests.proposal,
            environment: environment
        ).size.height

        #expect(collapsedHeight != nil)
        #expect(
            expandedHeight
                >= (collapsedHeight ?? 0) + DisclosureGroupTests.contentHeight
        )
    }

    @MainActor
    @Test("DisclosureGroup takes up the width that it's proposed")
    func disclosureGroupFillsProposedWidth() {
        let source = ExpansionSource(false)

        let result = computeLayout(of: disclosureGroup(boundTo: source))

        #expect(result.size.width == DisclosureGroupTests.proposal.width)
    }

    @MainActor
    @Test("DisclosureGroup's label isn't decorated like a regular button")
    func disclosureGroupLabelIsPlain() {
        let source = ExpansionSource(false)

        let node = committedNode(for: disclosureGroup(boundTo: source))
        let button = node.widget.firstWidget(ofType: DummyBackend.Button.self)

        // `any ButtonStyle` isn't `Equatable`, so assert the style's identity
        // and the chrome it asks the backend for instead.
        #expect(button?.buttonStyle is PlainButtonStyle)
        #expect(button?.buttonStyle.kind == .plain)
    }

    @MainActor
    @Test("DisclosureGroup renders its label alongside a disclosure indicator")
    func disclosureGroupRendersItsLabel() {
        let collapsed = ExpansionSource(false)
        let expanded = ExpansionSource(true)

        let collapsedText = labelTexts(of: disclosureGroup(boundTo: collapsed))
        let expandedText = labelTexts(of: disclosureGroup(boundTo: expanded))

        #expect(collapsedText.contains("Layout"))
        #expect(expandedText.contains("Layout"))
        #expect(
            collapsedText.contains(DisclosureGroupTests.collapsedIndicator)
        )
        #expect(expandedText.contains(DisclosureGroupTests.expandedIndicator))
    }

    @MainActor
    @Test("DisclosureGroup provides SwiftUI's initializers")
    func disclosureGroupProvidesSwiftUIInitializers() {
        let source = ExpansionSource(false)
        let isExpanded = source.binding

        let uncontrolled = DisclosureGroup {
            Text("Margin")
        } label: {
            Text("Layout")
        }
        let controlled = DisclosureGroup(isExpanded: isExpanded) {
            Text("Margin")
        } label: {
            Text("Layout")
        }
        let titled = DisclosureGroup("Layout") {
            Text("Margin")
        }
        let titledAndControlled = DisclosureGroup(
            "Layout",
            isExpanded: isExpanded
        ) {
            Text("Margin")
        }

        #expect(computeLayout(of: uncontrolled).size.height > 0)
        #expect(computeLayout(of: controlled).size.height > 0)
        #expect(computeLayout(of: titled).size.height > 0)
        #expect(computeLayout(of: titledAndControlled).size.height > 0)
    }

    // MARK: Helpers

    /// Creates the disclosure group used by most of the tests above.
    @MainActor
    func disclosureGroup(boundTo source: ExpansionSource) -> some View {
        DisclosureGroup(isExpanded: source.binding) {
            Color.blue.frame(height: DisclosureGroupTests.contentHeight)
        } label: {
            Text("Layout")
        }
    }

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = DisclosureGroupTests.proposal
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
        proposedSize: ProposedViewSize = DisclosureGroupTests.proposal
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

    /// Collects the text rendered inside a disclosure group's label button.
    @MainActor
    func labelTexts<V: View>(of view: V) -> [String] {
        let node = committedNode(for: view)
        let button = node.widget.firstWidget(ofType: DummyBackend.Button.self)
        guard let label = button?.label else {
            return []
        }
        return texts(in: label)
    }

    /// Collects the content of every text widget in a widget hierarchy.
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
}
