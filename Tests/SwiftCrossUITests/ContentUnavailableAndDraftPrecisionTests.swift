import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

/// A shape standing in for the glyph an app draws next to a snapping option.
///
/// Drawn as a single diagonal line, which is enough for the stroke tests: all
/// they care about is that a path reaches the backend and that it is stroked
/// rather than filled.
private struct MarkerShape: Shape {
    func path(in bounds: Path.Rect) -> Path {
        Path()
            .move(to: SIMD2(x: bounds.x, y: bounds.y))
            .addLine(to: SIMD2(x: bounds.maxX, y: bounds.maxY))
    }
}

/// A chip built exactly the way an app builds one: a shape stroked with a
/// style but no colour of its own, tinted from the outside.
private struct SnapKindChip: View {
    /// The colour the chip's glyph should end up stroked with.
    var tint: Color

    var body: some View {
        HStack(spacing: 7) {
            MarkerShape()
                .stroke(style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .frame(width: 15, height: 15)
                .foregroundStyle(tint)
        }
    }
}

/// A list that shows a standard "No Results" presentation when it is empty,
/// written the way an app writes it.
private struct SearchResultsView: View {
    /// The results to display.
    var results: [String]
    /// The term that produced `results`.
    var query: String

    var body: some View {
        VStack {
            ForEach(results, id: \.self) { result in
                Text(result)
            }
        }
        .overlay {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}

/// Everything rendering a view with ``DummyBackend`` reveals about it.
private struct RenderResult {
    /// The content of every text view in the hierarchy, breadth-first.
    var text: [String]
    /// The scroll container at the root of the hierarchy, if there is one.
    var scrollContainer: DummyBackend.ScrollContainer?
}

/// Tests for the two framework gaps a real SwiftUI app hit last: the
/// `ContentUnavailableView.search` statics, and the two APIs a draft precision
/// panel needed — `Shape.stroke(style:)` and `ScrollView`'s
/// `showsIndicators:` initializer.
///
/// The compiler blamed neither of the latter two by name. It reported a
/// missing first argument at the `stroke(style:)` call (having fallen back to
/// ``Shape/stroke(_:style:)``) and a `Bool` where a view builder belonged at
/// the `ScrollView` call (having fallen back to ``ScrollView/init(_:_:)``), so
/// several of these tests exist as much to pin the call *shapes* as to check
/// what they compute.
@Suite("Testing for ContentUnavailableView.search and draft precision APIs")
@MainActor
struct ContentUnavailableAndDraftPrecisionTests {
    // MARK: ContentUnavailableView.search

    @Test("search(text:) quotes the term that came up empty")
    func searchWithTextIncludesTheSearchedTerm() {
        let rendered = render(ContentUnavailableView.search(text: "HEA 200"))

        guard let message = rendered.text.first else {
            Issue.record("expected the search presentation to render text")
            return
        }
        #expect(message.contains("HEA 200"))
        #expect(message.contains("No Results"))
    }

    @Test("search(text:) still explains how to recover")
    func searchWithTextKeepsItsDescription() {
        let rendered = render(ContentUnavailableView.search(text: "IPE"))

        #expect(rendered.text.count == 2)
        #expect(rendered.text.last == "Check the spelling or try a new search.")
    }

    @Test("search names no term when it isn't given one")
    func searchWithoutTextNamesNoTerm() {
        let rendered = render(ContentUnavailableView.search)

        #expect(rendered.text.first == "No Results")
        #expect(rendered.text.last == "Check the spelling or try a new search.")
    }

    @Test("An empty search term still renders a well-formed message")
    func searchWithEmptyTextRendersAMessage() {
        let rendered = render(ContentUnavailableView.search(text: ""))

        #expect(rendered.text.first?.hasPrefix("No Results for") == true)
    }

    @Test("search(text:) reaches the overlay of a result list")
    func searchOverlaysAnEmptyResultList() {
        let empty = render(SearchResultsView(results: [], query: "UPN"))
        #expect(empty.text.contains { message in message.contains("UPN") })

        let filled = render(
            SearchResultsView(results: ["UPN 100"], query: "UPN")
        )
        #expect(filled.text == ["UPN 100"])
    }

    // MARK: Shape.stroke(style:)

    @Test("stroke(style:) keeps the style and picks no colour of its own")
    func strokeWithStyleOnlyCarriesTheStyle() {
        let style = StrokeStyle(lineWidth: 1.4, lineCap: .round)
        let stroked = MarkerShape().stroke(style: style)

        #expect(stroked.strokeStyle == style)
        #expect(stroked.strokeColor == nil)
        #expect(stroked.fillColor == nil)
    }

    @Test("stroke(style:) leaves the shape's path alone")
    func strokeWithStylePreservesThePath() {
        let bounds = Path.Rect(x: 0.0, y: 0.0, width: 15.0, height: 15.0)
        let stroked = MarkerShape().stroke(
            style: StrokeStyle(lineWidth: 1.4)
        )

        #expect(
            stroked.path(in: bounds).actions
                == MarkerShape().path(in: bounds).actions
        )
    }

    @Test("stroke(_:style:) still names its own colour")
    func strokeWithColourIsUnchanged() {
        let stroked = MarkerShape().stroke(
            .red,
            style: StrokeStyle(lineWidth: 3.0)
        )

        #expect(stroked.strokeColor == Color.red)
        #expect(stroked.strokeStyle?.lineWidth == 3.0)
    }

    @Test("A filled shape is not stroked just because it has a style")
    func fillIsNotStrokedByTheForegroundColour() {
        let filled = MarkerShape()
            .fill(.blue)
            .stroke(style: StrokeStyle(lineWidth: 2.0))

        #expect(filled.fillColor == Color.blue)
        #expect(filled.strokeColor == nil)
    }

    #if canImport(AppKitBackend)
        @Test("stroke(style:) strokes with the foreground colour")
        func strokeWithStyleUsesTheForegroundColour() {
            let harness = AppKitPathHarness(SnapKindChip(tint: .red))
            harness.render()

            guard let view = harness.pathView else {
                Issue.record("expected a path view")
                return
            }
            let environment = harness.environment
            #expect(view.strokeColor == Color.red.resolve(in: environment).nsColor)
            #expect(view.fillColor == Color.clear.resolve(in: environment).nsColor)
            #expect(view.path.lineWidth == 1.4)
        }

        @Test("An unstyled shape still fills with the foreground colour")
        func plainShapeStillFills() {
            let harness = AppKitPathHarness(
                MarkerShape()
                    .frame(width: 15.0, height: 15.0)
                    .foregroundStyle(.red)
            )
            harness.render()

            guard let view = harness.pathView else {
                Issue.record("expected a path view")
                return
            }
            let environment = harness.environment
            #expect(view.fillColor == Color.red.resolve(in: environment).nsColor)
            #expect(view.strokeColor == Color.clear.resolve(in: environment).nsColor)
        }
    #endif

    // MARK: ScrollView(_:showsIndicators:content:)

    @Test("showsIndicators: false hides an overflowing scroll bar")
    func showsIndicatorsFalseHidesTheScrollBar() {
        let rendered = render(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(
                        ContentUnavailableAndDraftPrecisionTests.angles,
                        id: \.self
                    ) { angle in
                        Text("\(angle)")
                    }
                }
            },
            proposedSize: ProposedViewSize(30.0, 40.0)
        )

        guard let scrollContainer = rendered.scrollContainer else {
            Issue.record("expected a scroll container")
            return
        }
        #expect(!scrollContainer.hasHorizontalScrollBar)
        #expect(!scrollContainer.hasVerticalScrollBar)
    }

    @Test("The scroll bar is still shown when indicators are left alone")
    func overflowingContentStillShowsAScrollBar() {
        let rendered = render(
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(
                        ContentUnavailableAndDraftPrecisionTests.angles,
                        id: \.self
                    ) { angle in
                        Text("\(angle)")
                    }
                }
            },
            proposedSize: ProposedViewSize(30.0, 40.0)
        )

        guard let scrollContainer = rendered.scrollContainer else {
            Issue.record("expected a scroll container")
            return
        }
        #expect(scrollContainer.hasHorizontalScrollBar)
    }

    @Test("showsIndicators: true keeps the scroll bar")
    func showsIndicatorsTrueKeepsTheScrollBar() {
        let rendered = render(
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 6) {
                    ForEach(
                        ContentUnavailableAndDraftPrecisionTests.angles,
                        id: \.self
                    ) { angle in
                        Text("\(angle)")
                    }
                }
            },
            proposedSize: ProposedViewSize(30.0, 40.0)
        )

        #expect(rendered.scrollContainer?.hasHorizontalScrollBar == true)
    }

    @Test("showsIndicators: doesn't stop the content from rendering")
    func hiddenIndicatorsStillRenderTheContent() {
        let rendered = render(
            ScrollView(showsIndicators: false) {
                Text("Content")
            }
        )

        #expect(rendered.text == ["Content"])
    }

    @Test("The axis argument keeps its default alongside showsIndicators:")
    func showsIndicatorsKeepsTheAxisDefault() {
        let scrollView = ScrollView(showsIndicators: false) {
            Text("Content")
        }

        #expect(scrollView.axes == .vertical)
        #expect(!scrollView.showsIndicators)
        #expect(ScrollView(.horizontal) { Text("Content") }.showsIndicators)
    }

    /// Angles wide enough to overflow the scroll views under test.
    static let angles: [Int] = [0, 15, 30, 45, 60, 75, 90, 105, 120, 135]
}

#if canImport(AppKitBackend)
    /// Renders a view through `AppKitBackend`, the only backend in the test
    /// suite that implements `BackendFeatures.Paths`.
    @MainActor
    private final class AppKitPathHarness<Content: View> {
        /// The backend under test.
        let backend: AppKitBackend
        /// The view graph holding the view.
        let viewGraph: ViewGraph<Content>
        /// The environment that layout runs in.
        let environment: EnvironmentValues

        /// The first path view in the rendered hierarchy, if there is one.
        var pathView: AppKitBackend.NSBezierPathView? {
            var queue: [NSView] = [viewGraph.rootNode.widget.into()]
            while let next = queue.first {
                queue.removeFirst()
                if let pathView = next as? AppKitBackend.NSBezierPathView {
                    return pathView
                }
                queue.append(contentsOf: next.subviews)
            }
            return nil
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
                proposedSize: ProposedViewSize(100.0, 100.0),
                environment: environment
            )
            viewGraph.commit()
        }
    }
#endif

/// Renders `view` with a ``DummyBackend`` and reports what it produced.
///
/// - Parameters:
///   - view: The view to render.
///   - proposedSize: The size to propose to the view. Defaults to an
///     unspecified proposal, under which nothing ever overflows.
/// - Returns: The rendered text and the root scroll container, if any.
@MainActor
private func render<Content: View>(
    _ view: Content,
    proposedSize: ProposedViewSize = .unspecified
) -> RenderResult {
    let backend = DummyBackend()
    let window = backend.createWindow(withDefaultSize: nil, id: "window")
    let environment = EnvironmentValues(backend: backend).with(\.window, window)

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

    return RenderResult(
        text: textContent(in: node.widget),
        scrollContainer: node.widget.firstWidget(
            ofType: DummyBackend.ScrollContainer.self
        )
    )
}

/// Collects the content of every text view in a widget hierarchy.
///
/// - Parameter widget: The root of the hierarchy to search.
/// - Returns: The content of each text view, in breadth-first order.
@MainActor
private func textContent(in widget: DummyBackend.Widget) -> [String] {
    var content: [String] = []
    var queue = [widget]
    while let next = queue.first {
        queue.removeFirst()
        if let textView = next as? DummyBackend.TextView {
            content.append(textView.content)
        }
        queue.append(contentsOf: next.getChildren())
    }
    return content
}
