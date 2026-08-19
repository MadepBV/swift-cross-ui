import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A view that reports the ``FormStyle`` it sees in the environment through
/// its width, so that tests can observe environment propagation without
/// reaching into the view graph.
private struct FormStyleProbe: View {
    /// The width reported for ``FormStyle/grouped``.
    static let groupedWidth = 50.0
    /// The width reported for any other form style.
    static let ungroupedWidth = 10.0

    @Environment(\.formStyle) var formStyle

    var body: some View {
        Color.blue
            .frame(
                width: formStyle is GroupedFormStyle
                    ? Self.groupedWidth
                    : Self.ungroupedWidth,
                height: 10
            )
    }
}

/// A form style defined outside of SwiftCrossUI, standing in for one that an
/// app would write.
///
/// Deliberately unlike every built-in style: it doesn't scroll, and it insets
/// its rows by its own padding, so a form laid out with it is unmistakably
/// laid out by this style.
struct PaddedFormStyle: FormStyle {
    /// The padding that this style leaves around a form's rows.
    static let padding = 7

    nonisolated init() {}

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
        }
        .padding(Self.padding)
    }
}

extension FormStyle where Self == PaddedFormStyle {
    /// A form style that insets its rows without scrolling them.
    static var padded: Self { Self() }
}

@Suite("Testing for Form and Section")
struct FormTests {
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
    @Test("Form style defaults to automatic and formStyle(_:) overrides it")
    func formStylePropagatesThroughEnvironment() {
        let unstyled = computeLayout(of: FormStyleProbe())
        #expect(unstyled.size.width == FormStyleProbe.ungroupedWidth)

        let grouped = computeLayout(of: FormStyleProbe().formStyle(.grouped))
        #expect(grouped.size.width == FormStyleProbe.groupedWidth)

        // .automatic must be able to undo an inherited style.
        let reverted = computeLayout(
            of: FormStyleProbe().formStyle(.automatic).formStyle(.grouped)
        )
        #expect(reverted.size.width == FormStyleProbe.ungroupedWidth)
    }

    @MainActor
    @Test("The built-in accessors name the built-in styles")
    func builtInStyleAccessors() {
        // Each accessor has to keep vending its own type so that apps can name
        // the styles they extend or match against.
        let automatic: any FormStyle = .automatic
        let columns: any FormStyle = .columns
        let grouped: any FormStyle = .grouped

        #expect(automatic is AutomaticFormStyle)
        #expect(columns is ColumnsFormStyle)
        #expect(grouped is GroupedFormStyle)
    }

    @MainActor
    @Test("The default form style is automatic")
    func defaultEnvironmentFormStyle() {
        #expect(environment.formStyle is AutomaticFormStyle)
    }

    @MainActor
    @Test("Section without a header or footer only occupies its content")
    func emptySectionHeaderAndFooterTakeNoSpace() {
        let row = Text("Row")
        let rowResult = computeLayout(of: row, proposedSize: ProposedViewSize(200, 400))
        let sectionResult = computeLayout(
            of: Section { row },
            proposedSize: ProposedViewSize(200, 400)
        )

        #expect(sectionResult.size.height == rowResult.size.height)
    }

    @MainActor
    @Test("Section header and footer add height")
    func sectionHeaderAndFooterAddHeight() {
        let proposedSize = ProposedViewSize(200, 400)

        let plain = computeLayout(
            of: Section { Text("Row") },
            proposedSize: proposedSize
        )
        let titled = computeLayout(
            of: Section("Title") { Text("Row") },
            proposedSize: proposedSize
        )
        let footed = computeLayout(
            of: Section { Text("Row") } footer: { Text("Footer") },
            proposedSize: proposedSize
        )
        let both = computeLayout(
            of: Section { Text("Row") } header: { Text("Title") } footer: { Text("Footer") },
            proposedSize: proposedSize
        )

        #expect(titled.size.height > plain.size.height)
        #expect(footed.size.height > plain.size.height)
        #expect(both.size.height > titled.size.height)
        #expect(both.size.height > footed.size.height)
    }

    @MainActor
    @Test("Section stacks its rows vertically with spacing")
    func sectionStacksRowsVertically() {
        let proposedSize = ProposedViewSize(200, 400)
        let metrics = FormMetrics.automatic

        let oneRow = computeLayout(
            of: Section { Text("Row") },
            proposedSize: proposedSize
        )
        let twoRows = computeLayout(
            of: Section {
                Text("Row")
                Text("Row")
            },
            proposedSize: proposedSize
        )

        #expect(
            twoRows.size.height
                == oneRow.size.height * 2 + Double(metrics.sectionRowSpacing)
        )
    }

    @MainActor
    @Test("Form fills the width it's proposed")
    func formFillsProposedWidth() {
        let width = 300.0
        let proposedSize = ProposedViewSize(width, 400)

        let automatic = computeLayout(
            of: Form { Text("Row") },
            proposedSize: proposedSize
        )
        let grouped = computeLayout(
            of: Form { Text("Row") }.formStyle(.grouped),
            proposedSize: proposedSize
        )

        #expect(automatic.size.width == width)
        #expect(grouped.size.width == width)
    }

    @MainActor
    @Test("Grouped forms inset their content")
    func groupedFormInsetsItsContent() {
        // An unspecified height makes the form report its intrinsic height
        // instead of greedily filling the proposal, which is what lets us
        // measure the inset.
        let proposedSize = ProposedViewSize(300, nil)
        let padding = Double(FormMetrics.grouped.formPadding)

        let automatic = computeLayout(
            of: Form { Text("Row") },
            proposedSize: proposedSize
        )
        let grouped = computeLayout(
            of: Form { Text("Row") }.formStyle(.grouped),
            proposedSize: proposedSize
        )

        #expect(FormMetrics.automatic.formPadding == 0)
        #expect(padding == 16)
        #expect(grouped.size.height == automatic.size.height + padding * 2)
    }

    @MainActor
    @Test("Overflowing form content stays reachable by scrolling")
    func overflowingFormContentIsScrollable() throws {
        let width = 300.0
        let height = 100.0
        let contentHeight = 400.0
        let form = Form {
            Color.blue.frame(width: 10, height: contentHeight)
        }

        // Sanity check: the content really does overflow the proposal.
        let intrinsic = computeLayout(of: form, proposedSize: ProposedViewSize(width, nil))
        #expect(intrinsic.size.height == contentHeight)

        let node = ViewGraphNode(for: form, backend: backend, environment: environment)
        let result = node.computeLayout(
            proposedSize: ProposedViewSize(width, height),
            environment: environment
        )
        _ = node.commit()

        // The form is bounded by its proposal rather than growing to fit its
        // content, which is what stops it from overflowing its container.
        #expect(result.size.height == height)

        let scrollContainer = try #require(
            node.widget.firstWidget(ofType: DummyBackend.ScrollContainer.self)
        )
        #expect(scrollContainer.hasVerticalScrollBar)
        // The scrollable content keeps its full height, so the rows below the
        // fold remain reachable.
        #expect(Double(scrollContainer.child.size.y) >= contentHeight)
    }

    @MainActor
    @Test("A form inside a scroll view doesn't scroll independently")
    func formInsideAScrollViewDoesNotScrollIndependently() throws {
        let width = 300.0
        let contentHeight = 400.0
        let view = ScrollView {
            Form {
                Color.blue.frame(width: 10, height: contentHeight)
            }
        }

        // The outer scroll view proposes an unspecified height, so the form
        // reports its full intrinsic height rather than clipping itself to the
        // outer scroll view's bounds. If it didn't, the outer scroll view would
        // have nothing to scroll.
        let node = committedNode(for: view, proposedSize: ProposedViewSize(width, 100))
        let outerScrollContainer = try #require(
            node.widget.firstWidget(ofType: DummyBackend.ScrollContainer.self)
        )

        #expect(outerScrollContainer.hasVerticalScrollBar)
        #expect(Double(outerScrollContainer.child.size.y) >= contentHeight)
    }

    @MainActor
    @Test("Grouped sections draw a container around their content")
    func groupedSectionWrapsItsContentInAContainer() {
        let proposedSize = ProposedViewSize(300, 400)
        let metrics = FormMetrics.grouped
        let containerPadding = Double(metrics.sectionContentPadding) * 2
        let spacingDifference = Double(
            metrics.sectionHeaderSpacing - FormMetrics.automatic.sectionHeaderSpacing
        )

        let automatic = computeLayout(
            of: Section("Title") { Text("Row") },
            proposedSize: proposedSize
        )
        let grouped = computeLayout(
            of: Section("Title") { Text("Row") }.formStyle(.grouped),
            proposedSize: proposedSize
        )

        #expect(FormMetrics.automatic.groupsSectionContent == false)
        #expect(metrics.groupsSectionContent == true)
        #expect(
            grouped.size.height
                == automatic.size.height + containerPadding + spacingDifference
        )
    }

    @MainActor
    @Test("Sections fill the width of their enclosing form")
    func sectionsFillTheirFormsWidth() {
        let width = 300.0
        let form = Form {
            Section("Title") {
                Text("Row")
            }
        }
        let node = committedNode(for: form, proposedSize: ProposedViewSize(width, 400))

        #expect(node.widget.size.x == Int(width))
    }

    @MainActor
    @Test("A form style defined outside SwiftCrossUI lays forms out")
    func userDefinedFormStyleLaysOutTheForm() {
        // The whole point of FormStyle being a protocol: an app can supply a
        // style that SwiftCrossUI has never heard of.
        let proposedSize = ProposedViewSize(300, nil)
        let padding = Double(PaddedFormStyle.padding)

        let row = computeLayout(of: Text("Row"), proposedSize: proposedSize)
        let form = computeLayout(
            of: Form { Text("Row") }.formStyle(.padded),
            proposedSize: proposedSize
        )

        // The custom style neither scrolls nor uses the built-in padding, so
        // the form is exactly one row plus the style's own inset tall.
        #expect(form.size.height == row.size.height + padding * 2)
    }

    @MainActor
    @Test("Sections stack plainly beneath a form style defined outside SwiftCrossUI")
    func sectionsFallBackToPlainMetricsBeneathACustomStyle() {
        let proposedSize = ProposedViewSize(300, 400)

        let automatic = computeLayout(
            of: Section("Title") { Text("Row") },
            proposedSize: proposedSize
        )
        let custom = computeLayout(
            of: Section("Title") { Text("Row") }.formStyle(.padded),
            proposedSize: proposedSize
        )

        // A style SwiftCrossUI doesn't ship has no metrics of its own, so
        // sections keep the plain layout rather than guessing.
        #expect(custom.size.height == automatic.size.height)
    }

    @MainActor
    @Test("Every SwiftUI Section initializer is available")
    func sectionInitializersCompile() {
        // A compile-time check of the API surface. Each of these mirrors an
        // initializer that SwiftUI's Section provides.
        _ = Section { Text("Row") }
        _ = Section("Title") { Text("Row") }
        _ = Section { Text("Row") } header: { Text("Title") }
        _ = Section { Text("Row") } footer: { Text("Footer") }
        _ = Section { Text("Row") } header: { Text("Title") } footer: { Text("Footer") }
        _ = Section("Title") { Text("Row") } footer: { Text("Footer") }
        _ = Section(header: Text("Title")) { Text("Row") }
        _ = Section(footer: Text("Footer")) { Text("Row") }
        _ = Section(header: Text("Title"), footer: Text("Footer")) { Text("Row") }
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
}
