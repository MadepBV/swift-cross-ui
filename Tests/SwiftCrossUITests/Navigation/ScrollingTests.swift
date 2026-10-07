import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing programmatic scrolling and scroll view configuration")
@MainActor
struct ScrollingTests {
    /// Forty rows of 20 points, in a scroll view 100 points tall.
    static func rows() -> some View {
        ForEach(0..<40, id: \.self) { index in
            Text("Row \(index)").frame(height: 20)
        }
    }

    @Test("ScrollViewProxy scrolls to an identified row, honouring the anchor")
    func proxyScrollsToARow() throws {
        let proxy = StateBox<ScrollViewProxy?>(nil)
        let harness = GraphHarness {
            ScrollViewReader { reader in
                let _ = proxy.value = reader
                ScrollView {
                    VStack(spacing: 0) { Self.rows() }
                }
                .frame(height: 100)
            }
        }
        harness.render(passes: 1)
        let scrollView = try #require(harness.first(DummyBackend.ScrollContainer.self))

        proxy.value?.scrollTo(10, anchor: .top)
        #expect(scrollView.scrollOffset.y == 200)

        proxy.value?.scrollTo(10, anchor: .bottom)
        #expect(scrollView.scrollOffset.y == 120)

        // Already visible: no anchor means no movement.
        proxy.value?.scrollTo(9)
        #expect(scrollView.scrollOffset.y == 120)

        proxy.value?.scrollTo(39)
        #expect(scrollView.scrollOffset.y == 700)
    }

    @Test("A ScrollPosition scrolls to an edge, an offset and a view, once per request")
    func scrollPositionScrolls() throws {
        let position = StateBox(ScrollPosition(edge: .top))
        let harness = GraphHarness {
            ScrollView {
                VStack(spacing: 0) { Self.rows() }
            }
            .scrollPosition(position.binding)
            .frame(height: 100)
        }
        harness.render(passes: 1)
        let scrollView = try #require(harness.first(DummyBackend.ScrollContainer.self))
        #expect(scrollView.scrollOffset.y == 0)

        position.value.scrollTo(edge: .bottom)
        harness.render(passes: 1)
        #expect(scrollView.scrollOffset.y == 700)

        position.value.scrollTo(y: 40)
        harness.render(passes: 1)
        #expect(scrollView.scrollOffset.y == 40)

        // The user scrolls away; re-rendering doesn't repeat the request.
        scrollView.scrollOffset.y = 300
        harness.render(passes: 1)
        #expect(scrollView.scrollOffset.y == 300)

        position.value.scrollTo(id: 5, anchor: .top)
        harness.render(passes: 1)
        #expect(scrollView.scrollOffset.y == 100)
    }

    @Test("scrollPosition(id:) scrolls to the bound view when the binding changes")
    func scrollPositionIDScrolls() throws {
        let id = StateBox<Int?>(nil)
        let harness = GraphHarness {
            ScrollView {
                VStack(spacing: 0) { Self.rows() }
            }
            .scrollPosition(id: id.binding, anchor: .top)
            .frame(height: 100)
        }
        harness.render(passes: 1)
        let scrollView = try #require(harness.first(DummyBackend.ScrollContainer.self))

        id.value = 3
        harness.render(passes: 1)
        #expect(scrollView.scrollOffset.y == 60)
    }

    @Test("scrollPosition(id:) keeps its view in place when the scroll view is resized")
    func scrollPositionIDSurvivesResize() throws {
        let id = StateBox<Int?>(2)
        let width = StateBox(100.0)
        let harness = GraphHarness {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { page in
                        Color.blue.frame(width: width.value, height: 20).id(page)
                    }
                }
            }
            .scrollPosition(id: id.binding, anchor: .leading)
            .frame(width: width.value, height: 20)
        }
        harness.render(passes: 1)
        let scrollView = try #require(harness.first(DummyBackend.ScrollContainer.self))
        #expect(scrollView.scrollOffset.x == 200)

        // A wider window makes every page wider; page 2 stays in view.
        width.value = 150
        harness.render(passes: 1)
        #expect(scrollView.scrollOffset.x == 300)
    }

    @Test("Hidden scroll indicators reserve no room for a scroll bar")
    func hiddenIndicatorsReserveNoRoom() throws {
        let harness = GraphHarness {
            ScrollView {
                VStack(spacing: 0) { Self.rows() }
            }
            .scrollIndicators(.never)
            .frame(height: 100)
        }
        harness.render(passes: 1)
        let scrollView = try #require(harness.first(DummyBackend.ScrollContainer.self))

        #expect(!scrollView.hasVerticalScrollBar)
    }

    @Test("Content margins inset the content and scroll with it")
    func contentMarginsInsetTheContent() throws {
        let harness = GraphHarness {
            ScrollView(.horizontal) {
                Text("Shelf").frame(width: 50, height: 20)
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .frame(width: 200, height: 20)
        }
        harness.render(passes: 1)
        let scrollView = try #require(harness.first(DummyBackend.ScrollContainer.self))
        let content = try #require(scrollView.child as? DummyBackend.Container)

        #expect(content.children.first?.position.x == 16)
        #expect(content.size.x == 200)
    }

    @Test("onScrollGeometryChange reports the container size")
    func scrollGeometryIsReported() async throws {
        let height = StateBox<Double>(0)
        let harness = GraphHarness {
            ScrollView {
                VStack(spacing: 0) { Self.rows() }
            }
            .onScrollGeometryChange(for: Double.self) { geometry in
                Double(geometry.containerSize.height)
            } action: { _, newValue in
                height.value = newValue
            }
            .frame(height: 100)
        }
        harness.render(passes: 1)
        await Task.yield()

        #expect(height.value == 100)
    }

    @Test("onScrollTargetVisibilityChange reports the identified rows on screen")
    func visibleTargetsAreReported() async throws {
        let visible = StateBox<[Int]>([])
        let harness = GraphHarness {
            ScrollView {
                VStack(spacing: 0) { Self.rows() }
            }
            .onScrollTargetVisibilityChange(idType: Int.self, threshold: 0.5) { ids in
                visible.value = ids
            }
            .frame(height: 100)
        }
        harness.render(passes: 1)
        await Task.yield()

        #expect(visible.value == [0, 1, 2, 3, 4])
    }
}
