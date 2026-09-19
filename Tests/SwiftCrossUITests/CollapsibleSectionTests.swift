import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

@Suite("Collapsible Sections")
@MainActor
struct CollapsibleSectionTests {
    private let backend: DummyBackend
    private let environment: EnvironmentValues

    init() {
        backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "collapsible-section")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    @Test("External expansion removes and restores rows without writing the binding")
    func externalExpansion() throws {
        let source = SectionExpansionSource(false)
        let node = node(section(source))
        let collapsedHeight = try #require(node.currentLayout?.size.height)
        #expect(!texts(node.widget).contains("Section row"))
        #expect(texts(node.widget).contains("Category"))
        source.value = true
        render(node)
        #expect(texts(node.widget).contains("Section row"))
        #expect(try #require(node.currentLayout?.size.height) > collapsedHeight)
        source.value = false
        render(node)
        #expect(!texts(node.widget).contains("Section row"))
        #expect(node.currentLayout?.size.height == collapsedHeight)
        #expect(source.writes == 0)
    }

    @Test("Disclosure uses the current binding and latest externally supplied value")
    func disclosureBinding() throws {
        let first = SectionExpansionSource(false)
        let second = SectionExpansionSource(true)
        let node = node(section(first))
        let button = try #require(node.widget.firstWidget(ofType: DummyBackend.Button.self))
        button.action?()
        #expect(first.value)
        #expect(first.writes == 1)
        render(node, view: section(second))
        let current = try #require(node.widget.firstWidget(ofType: DummyBackend.Button.self))
        #expect(current === button)
        // The action reads the binding now, not a stale captured Bool.
        second.value = false
        current.action?()
        #expect(second.value)
        #expect(second.writes == 1)
        #expect(first.writes == 1)
        render(node)
        current.action?()
        #expect(!second.value)
        #expect(second.writes == 2)
    }

    @Test("Grouped expansion retains Section row spacing and padding")
    func groupedMetrics() throws {
        let source = SectionExpansionSource(false)
        let view = Section("Grouped", isExpanded: source.binding) {
            Color.blue.frame(width: 100, height: 40)
            Color.red.frame(width: 100, height: 60)
        }.formStyle(.grouped)
        let node = node(view)
        let collapsed = try #require(node.currentLayout?.size.height)
        source.value = true
        render(node)
        let expanded = try #require(node.currentLayout?.size.height)
        let metrics = FormMetrics.grouped
        #expect(expanded - collapsed == 100 + Double(metrics.sectionRowSpacing)
            + Double(metrics.sectionContentPadding * 2 + metrics.sectionHeaderSpacing))
        #expect(source.writes == 0)
    }

    @Test("Ordinary Section retains header, footer and rows without a disclosure button")
    func ordinarySection() {
        let node = node(Section {
            Text("Ordinary row")
        } header: {
            Text("Ordinary header")
        } footer: {
            Text("Ordinary footer")
        })
        #expect(texts(node.widget) == ["Ordinary header", "Ordinary row", "Ordinary footer"])
        #expect(node.widget.firstWidget(ofType: DummyBackend.Button.self) == nil)
    }

    @Test("Menu sections retain header, separators and actions independently of expansion")
    func menuBehavior() {
        let source = SectionExpansionSource(false)
        var calls = 0
        let view = Section(isExpanded: source.binding) {
            Button("Menu action") { calls += 1 }
        } header: {
            Text("Menu category")
        }
        func check(_ items: [MenuItem]) {
            #expect(items.count == 4)
            guard items.count == 4 else { return }
            if case .separator = items[0] {} else { Issue.record("Missing leading separator") }
            if case .text(let title) = items[1] { #expect(title.string == "Menu category") }
            else { Issue.record("Missing menu title") }
            if case .button(let button) = items[2] {
                #expect(button.title == "Menu action")
                button.action()
            } else { Issue.record("Missing menu action") }
            if case .separator = items[3] {} else { Issue.record("Missing trailing separator") }
        }
        check(view._asMenuItems)
        source.value = true
        check(view._asMenuItems)
        #expect(calls == 2)
        #expect(source.writes == 0)
    }

    #if canImport(AppKitBackend)
    @Test("Disclosure and a custom header action are independent native siblings and obey disabled state")
    func nativeHeaderActions() throws {
        let backend = AppKitBackend()
        let window = backend.createWindow(withDefaultSize: SIMD2(320, 240), id: "section-native")
        let env = EnvironmentValues(backend: backend).with(\.window, window)
        let source = SectionExpansionSource(false)
        var adds = 0
        func view(enabled: Bool) -> some View {
            Section(isExpanded: source.binding) {
                Text("Native row")
            } header: {
                HStack {
                    Text("Library")
                    Button("Add") { adds += 1 }
                }
            }.disabled(!enabled)
        }
        let node = ViewGraphNode(for: view(enabled: true), backend: backend, environment: env)
        LayoutPass.begin()
        _ = node.computeLayout(proposedSize: ProposedViewSize(320, nil), environment: env)
        _ = node.commit()
        let controls = descendants(node.widget).compactMap { $0 as? NSCustomButton }
        try #require(controls.count == 2)
        let disclosure = controls[0]
        let add = controls[1]
        #expect(!descendants(disclosure).contains { $0 === add })
        #expect(!descendants(add).contains { $0 === disclosure })
        #expect(add.accessibilityPerformPress())
        #expect(adds == 1)
        #expect(!source.value)
        #expect(source.writes == 0)
        #expect(disclosure.accessibilityPerformPress())
        #expect(source.value)
        #expect(source.writes == 1)
        #expect(adds == 1)

        LayoutPass.begin()
        _ = node.computeLayout(with: view(enabled: false),
            proposedSize: ProposedViewSize(319, nil), environment: env)
        _ = node.commit()
        #expect(!disclosure.isEnabled)
        #expect(!add.isEnabled)
        #expect(!disclosure.accessibilityPerformPress())
        #expect(!add.accessibilityPerformPress())
        #expect(source.value)
        #expect(source.writes == 1)
        #expect(adds == 1)
        // No window is ordered; this tests native graph/action dispatch, not
        // OS pointer routing, focus, keyboard traversal or visible rendering.
    }

    private func descendants(_ view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap(descendants)
    }
    #endif

    private func section(_ source: SectionExpansionSource) -> some View {
        Section(isExpanded: source.binding) {
            Text("Section row").frame(height: 80)
        } header: {
            Text("Category")
        }
    }

    private func node<V: View>(_ view: V) -> ViewGraphNode<V, DummyBackend> {
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        render(node)
        return node
    }

    private func render<V: View>(_ node: ViewGraphNode<V, DummyBackend>, view: V? = nil) {
        LayoutPass.begin()
        _ = node.computeLayout(with: view, proposedSize: ProposedViewSize(320, nil), environment: environment)
        _ = node.commit()
    }

    private func texts(_ widget: DummyBackend.Widget) -> [String] {
        (widget as? DummyBackend.TextView).map { [$0.content] } ?? widget.getChildren().flatMap(texts)
    }
}

@MainActor
private final class SectionExpansionSource {
    var value: Bool
    var writes = 0
    init(_ value: Bool) { self.value = value }
    var binding: Binding<Bool> {
        Binding(get: { self.value }, set: { self.value = $0; self.writes += 1 })
    }
}
