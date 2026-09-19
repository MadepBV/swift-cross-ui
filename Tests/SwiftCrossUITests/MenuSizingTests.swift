import Testing
@_spi(Backends) @testable import SwiftCrossUI
#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend

@Suite("Menu button width proposals")
@MainActor
struct MenuSizingTests {
    @Test("A long closed menu title fits a narrow row without losing menu content")
    func narrowRowRetainsMenuContents() throws {
        let backend = AppKitBackend()
        let environment = EnvironmentValues(backend: backend)
        let title = "A long user-authored section name for the active drawing"
        let menu = Menu(title) { Text("The complete first option") }
        let children = menu.children(backend: backend, snapshots: nil, environment: environment)
        let widget = menu.asWidget(children, backend: backend)
        func layout(_ width: Double?) -> ViewLayoutResult {
            menu.computeLayout(widget, children: children,
                proposedSize: ProposedViewSize(width, 80), environment: environment, backend: backend)
        }
        let ideal = layout(nil)
        #expect(ideal.size.width > 220)
        let narrow = layout(220)
        #expect(narrow.size == ViewSize(220, ideal.size.height))
        menu.commit(widget, children: children, layout: narrow, environment: environment, backend: backend)
        let constraint = try #require(widget.constraints.first {
            $0.firstAnchor === widget.widthAnchor && $0.isActive
        })
        #expect(constraint.constant == 220)
        #expect(layout(.infinity).size == ideal.size)
        #expect(layout(2_000).size == ideal.size)
        #expect(layout(0).size == ViewSize(0, ideal.size.height))
        #expect(menu.label == title)
        #expect(menu.items.count == 1)
        guard case .text(let option) = menu.items[0] else {
            Issue.record("Expected the original menu option")
            return
        }
        #expect(option.string == "The complete first option")
    }

    @Test("Explicit menu button widths remain exact")
    func explicitWidthIsPreserved() {
        let backend = AppKitBackend()
        let environment = EnvironmentValues(backend: backend)
        let menu = Menu("Choose") { Text("First") }._buttonWidth(180)
        let children = menu.children(backend: backend, snapshots: nil, environment: environment)
        let widget = menu.asWidget(children, backend: backend)
        let layout = menu.computeLayout(widget, children: children,
            proposedSize: ProposedViewSize(100, 80), environment: environment, backend: backend)
        #expect(layout.size.width == 180)
    }
}
#endif
