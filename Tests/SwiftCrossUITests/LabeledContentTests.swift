import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing for LabeledContent")
struct LabeledContentTests {
    /// The minimum gap that ``LabeledContent`` leaves between its label and
    /// its content. Mirrors `LabeledContent.minimumSpacing`.
    static let minimumSpacing = 8

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
    @Test("Label hugs the leading edge and content hugs the trailing edge")
    func labelLeadsAndContentTrails() throws {
        let width = 300.0
        let view = LabeledContent("Label") {
            Text("Content")
        }

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(width, 100)
        )
        let children = try rowChildren(of: node.widget)

        let label = children[0]
        let content = children[2]

        // The labelled content fills the width offered to it, with the label
        // at one end and the content at the other.
        #expect(label.position.x == 0)
        #expect(content.position.x + content.widget.size.x == Int(width))
        #expect(content.position.x > label.position.x + label.widget.size.x)
    }

    @MainActor
    @Test("Ideal size fits the label, the content, and the minimum spacing")
    func idealSize() {
        let view = LabeledContent("Label") {
            Text("Content")
        }

        let labelSize = computeLayout(of: Text("Label")).size
        let contentSize = computeLayout(of: Text("Content")).size
        let result = computeLayout(of: view)

        #expect(
            result.size.vector.x
                == labelSize.vector.x + Self.minimumSpacing + contentSize.vector.x
        )
        #expect(
            result.size.vector.y == max(labelSize.vector.y, contentSize.vector.y)
        )
    }

    @MainActor
    @Test("Minimum spacing survives a proposal that's too small")
    func minimumSpacingWhenCramped() throws {
        let idealWidth = computeLayout(
            of: LabeledContent("Label") {
                Text("Content")
            }
        ).size.vector.x
        let view = LabeledContent("Label") {
            Text("Content")
        }

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(Double(idealWidth) / 2, 100)
        )
        let children = try rowChildren(of: node.widget)

        let label = children[0]
        let content = children[2]
        let gap = content.position.x - (label.position.x + label.widget.size.x)

        // The label and the content shrink to fit rather than eating into the
        // gap that separates them.
        #expect(gap >= Self.minimumSpacing)
        #expect(node.widget.size.x < idealWidth)
    }

    @MainActor
    @Test("Label column width lines the contents of siblings up")
    func labelColumnWidth() throws {
        let labelWidth = 120.0
        let view = LabeledContent("Label", value: "Value")
            .environment(\.labeledContentLabelWidth, labelWidth)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )

        // The environment modifier introduces a container of its own, so the
        // labelled content is one level deeper than usual.
        let modifierChildren = try positionedChildren(of: node.widget)
        try #require(modifierChildren.count == 1)

        let children = try rowChildren(of: modifierChildren[0].widget)

        let label = children[0]
        #expect(label.widget.size.x == Int(labelWidth))

        // The label itself remains aligned to the leading edge of its column.
        let labelColumnChildren = try positionedChildren(of: label.widget)
        #expect(labelColumnChildren.first?.position.x == 0)
    }

    @MainActor
    @Test("Title and value convenience initializer displays both strings")
    func titleAndValueInitializer() throws {
        let view = LabeledContent("Title", value: "Value")

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let children = try rowChildren(of: node.widget)

        let label = children[0].widget
            .firstWidget(ofType: DummyBackend.TextView.self)
        let content = children[2].widget
            .firstWidget(ofType: DummyBackend.TextView.self)

        #expect(label?.content == "Title")
        #expect(content?.content == "Value")
    }

    @MainActor
    @Test("Controls can be labelled")
    func controlContent() throws {
        var value = "16"
        let view = LabeledContent {
            TextField(
                "",
                text: Binding(
                    get: { value },
                    set: { newValue in value = newValue }
                )
            )
        } label: {
            Text("Diameter")
        }

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let children = try rowChildren(of: node.widget)

        let label = children[0].widget
            .firstWidget(ofType: DummyBackend.TextView.self)
        let field = children[2].widget
            .firstWidget(ofType: DummyBackend.TextField.self)

        #expect(label?.content == "Diameter")
        #expect(field != nil)
        #expect(field?.value == "16")
    }

    @MainActor
    @Test("Stacked rows all fill the available width")
    func stackedRows() throws {
        var text = "16"
        let view = VStack(spacing: 0) {
            LabeledContent("Diameter") {
                TextField(
                    "",
                    text: Binding(
                        get: { text },
                        set: { newValue in text = newValue }
                    )
                )
            }
            LabeledContent("Profile") {
                Text("IPE 200")
            }
            LabeledContent("Spacing", value: "150 mm")
        }

        let width = 320.0
        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(width, 200)
        )
        let rows = try positionedChildren(of: node.widget)
        try #require(rows.count == 3)

        for row in rows {
            #expect(row.position.x == 0)
            #expect(row.widget.size.x == Int(width))
        }
    }

    // MARK: Helpers

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = .unspecified
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
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
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        _ = node.computeLayout(proposedSize: proposedSize, environment: environment)
        _ = node.commit()
        return node
    }

    /// Gets the label, spacer, and content widgets of a labelled view.
    ///
    /// ``LabeledContent`` is a composed view, so its widget is a container
    /// holding the widget of its body. ``ViewBuilder`` wraps that body in a
    /// `TupleView1`, hence the extra layer of containers between the labelled
    /// view's widget and the widgets that it lays out.
    ///
    /// - Parameter widget: The widget of a committed ``LabeledContent`` view.
    /// - Returns: The label, spacer, and content widgets, along with their
    ///   positions within the widget that lays them out.
    @MainActor
    func rowChildren(
        of widget: DummyBackend.Widget
    ) throws -> [(widget: DummyBackend.Widget, position: SIMD2<Int>)] {
        let bodyWrapper = try positionedChildren(of: widget)
        try #require(bodyWrapper.count == 1)

        let children = try positionedChildren(of: bodyWrapper[0].widget)
        try #require(children.count == 3)

        return children
    }

    /// Gets the children of a container widget along with their positions.
    ///
    /// - Parameter widget: The container widget to inspect.
    /// - Returns: The container's children and their positions within it.
    @MainActor
    func positionedChildren(
        of widget: DummyBackend.Widget
    ) throws -> [(widget: DummyBackend.Widget, position: SIMD2<Int>)] {
        let container = try #require(
            widget as? DummyBackend.Container,
            "Expected a container widget, got \(type(of: widget))"
        )
        return container.children
    }
}
