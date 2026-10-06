import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

struct MaximumKey: PreferenceKey {
    static let defaultValue = 0
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = max(value, nextValue())
    }
}

@MainActor
final class ValueRecorder<Value> {
    var values: [Value] = []
}

@Suite("Geometry, preferences and frames")
struct GeometryAndPreferenceTests {
    @MainActor
    @Test("Preferences combine with the key's reduce and reach onPreferenceChange")
    func preferencesCombine() {
        let recorder = ValueRecorder<Int>()
        let view = VStack {
            block(1, 1).preference(key: MaximumKey.self, value: 3)
            block(1, 1).preference(key: MaximumKey.self, value: 7)
            block(1, 1)
        }
        .onPreferenceChange(MaximumKey.self) { recorder.values.append($0) }

        _ = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        #expect(recorder.values == [7])
    }

    @MainActor
    @Test("onGeometryChange reports the committed geometry")
    func geometryChangeReportsSize() {
        let recorder = ValueRecorder<CGFloat>()
        let view = block(30, 12).onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            recorder.values.append(width)
        }

        _ = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(100, 100))
        #expect(recorder.values == [30])
    }

    @MainActor
    @Test("containerRelativeFrame divides the scroll view's visible width")
    func containerRelativeFrameInScrollView() {
        let view = ScrollView(.horizontal) {
            HStack(spacing: 10) {
                Color.blue.containerRelativeFrame(.horizontal, count: 2, spacing: 10)
                Color.blue.containerRelativeFrame(.horizontal, count: 2, span: 2, spacing: 10)
            }
            .frame(height: 5)
        }
        let node = ViewGraphHelpers.committedNode(for: view, proposedSize: ProposedViewSize(110, 50))
        let widths = leafFrames(of: node.widget).map(\.size.x)
        #expect(widths == [50, 110])
    }

    @MainActor
    @Test("Fractional stack spacing rounds up to whole points")
    func fractionalStackSpacing() {
        let spacing: CGFloat = 2.5
        let result = ViewGraphHelpers.computeLayout(
            of: HStack(spacing: spacing) {
                block(10, 10)
                block(10, 10)
            },
            proposedSize: ProposedViewSize(100, 100)
        )
        #expect(result.size == ViewSize(23, 10))
    }

    @MainActor
    @Test("LazyHStack lays out like an HStack")
    func lazyHStackMatchesHStack() {
        let lazy = ViewGraphHelpers.computeLayout(
            of: LazyHStack(alignment: .top, spacing: 2) {
                block(10, 10)
                block(10, 20)
            },
            proposedSize: ProposedViewSize(100, 100)
        )
        #expect(lazy.size == ViewSize(22, 20))
    }

    @MainActor
    @Test("ScaledMetric is its base value without Dynamic Type")
    func scaledMetricIsIdentity() {
        @ScaledMetric(relativeTo: .caption) var spacing: CGFloat = 12
        #expect(spacing == 12)
    }
}
