import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Tests for `@ViewBuilder` *closure arguments* that opt out of the result
/// builder.
///
/// ``UnwrappedBodyTests`` covers a view's `body`. The same rule applies to any
/// closure marked `@ViewBuilder`, which is how every container takes its
/// content — so `VStack { let x = f(); return HStack { ... } }` hands the stack
/// a bare `HStack` rather than a `TupleView1` wrapping one.
///
/// Containers that go through their own `children`/`layoutableChildren`
/// defaults are covered by the same fix. The ones that reached to
/// `body.children(...)` directly were not, and are covered here: `ViewThatFits`
/// treated each of an unwrapped container's children as a separate candidate,
/// and `Grid`/`LazyVGrid` were internally inconsistent — their `children`
/// wrapped while their `layoutableChildren` did not.
@Suite("Testing for ViewBuilder closures that opt out")
@MainActor
struct UnwrappedBuilderClosureTests {
    static func size<V: View>(
        _ view: V,
        _ proposal: ProposedViewSize = ProposedViewSize(100, 60)
    ) -> ViewSize {
        let backend = DummyBackend()
        let environment = backend
            .computeRootEnvironment(defaultEnvironment: EnvironmentValues(backend: backend))
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "window"))
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            snapshot: nil,
            environment: environment
        )
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: proposal, environment: environment)
        return node.commit().size
    }

    /// Two 30x10 swatches side by side: 60x10 laid out horizontally, and
    /// something else if the container they are in got lost.
    struct Pair: View {
        var spacing: Int

        var body: some View {
            HStack(spacing: spacing) {
                Color.red.frame(width: 30, height: 10)
                Color.blue.frame(width: 30, height: 10)
            }
        }
    }

    @Test("A VStack whose content closure returns still sees one child")
    func vStackClosure() {
        struct Builder: View {
            var body: some View { VStack(spacing: 0) { Pair(spacing: 0) } }
        }
        struct Returned: View {
            var body: some View {
                VStack(spacing: 0) {
                    let spacing = 0
                    return Pair(spacing: spacing)
                }
            }
        }
        #expect(Self.size(Builder()) == Self.size(Returned()))
        #expect(Self.size(Builder()) == ViewSize(60, 10))
    }

    @Test("A ScrollView whose content closure returns still sees one child")
    func scrollViewClosure() {
        struct Builder: View {
            var body: some View { ScrollView { Pair(spacing: 0) } }
        }
        struct Returned: View {
            var body: some View {
                ScrollView {
                    let spacing = 0
                    return Pair(spacing: spacing)
                }
            }
        }
        #expect(Self.size(Builder()) == Self.size(Returned()))
    }

    @Test("A ViewThatFits whose content closure returns still sees one candidate")
    func viewThatFitsClosure() {
        struct Builder: View {
            var body: some View { ViewThatFits { Pair(spacing: 0) } }
        }
        struct Returned: View {
            var body: some View {
                ViewThatFits {
                    let spacing = 0
                    return Pair(spacing: spacing)
                }
            }
        }
        // Before the fix this was 30x10: the pair's two swatches became two
        // separate candidates and the first one that fitted won, instead of
        // the pair being the single candidate.
        #expect(Self.size(Builder()) == Self.size(Returned()))
        #expect(Self.size(Builder()) == ViewSize(60, 10))
    }

    @Test("A Group whose content closure returns still sees one child")
    func groupClosure() {
        struct Builder: View {
            var body: some View { VStack(spacing: 0) { Group { Pair(spacing: 0) } } }
        }
        struct Returned: View {
            var body: some View {
                VStack(spacing: 0) {
                    Group {
                        let spacing = 0
                        return Pair(spacing: spacing)
                    }
                }
            }
        }
        #expect(Self.size(Builder()) == Self.size(Returned()))
    }

    @Test("A ForEach whose item closure returns still sees one child per item")
    func forEachClosure() {
        struct Builder: View {
            var body: some View {
                ForEach(Array(0..<2)) { _ in Pair(spacing: 0) }
            }
        }
        struct Returned: View {
            var body: some View {
                ForEach(Array(0..<2)) { _ in
                    let spacing = 0
                    return Pair(spacing: spacing)
                }
            }
        }
        #expect(Self.size(Builder()) == Self.size(Returned()))
    }

    @Test("A Grid whose content closure returns stays internally consistent")
    func gridClosure() {
        struct Builder: View {
            var body: some View {
                Grid { GridRow { Pair(spacing: 0) } }
            }
        }
        struct Returned: View {
            var body: some View {
                Grid {
                    let spacing = 0
                    return GridRow { Pair(spacing: spacing) }
                }
            }
        }
        // `Grid.children` already wrapped while `Grid.layoutableChildren` did
        // not, so the two disagreed about how many children there were.
        #expect(Self.size(Builder()) == Self.size(Returned()))
    }

    @Test("A LazyVGrid whose content closure returns stays internally consistent")
    func lazyVGridClosure() {
        struct Builder: View {
            var body: some View {
                LazyVGrid(columns: [GridItem(.fixed(60))]) { Pair(spacing: 0) }
            }
        }
        struct Returned: View {
            var body: some View {
                LazyVGrid(columns: [GridItem(.fixed(60))]) {
                    let spacing = 0
                    return Pair(spacing: spacing)
                }
            }
        }
        #expect(Self.size(Builder()) == Self.size(Returned()))
    }
}
