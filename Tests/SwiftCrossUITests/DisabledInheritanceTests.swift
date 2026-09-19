import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

private struct EnabledLabel: View {
    @Environment(\.isEnabled) private var isEnabled
    var name: String

    var body: some View { Text("\(name):\(isEnabled)") }
}

@Suite("Disabled interaction inheritance")
@MainActor
struct DisabledInheritanceTests {
    @Test("An inner enabling request cannot escape any disabled ancestor")
    func nestedConditionsReachTheViewGraph() {
        let backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "disabled-combinations")
        let env = EnvironmentValues(backend: backend).with(\.window, window)
        for parentDisabled in [false, true] {
            for childDisabled in [false, true] {
                let view = VStack {
                    EnabledLabel(name: "field").disabled(childDisabled)
                }.disabled(false).disabled(parentDisabled)
                let node = ViewGraphNode(for: view, backend: backend, environment: env)
                _ = node.computeLayout(proposedSize: .unspecified, environment: env)
                _ = node.commit()
                #expect(node.widget.firstWidget(ofType: DummyBackend.TextView.self)?.content
                    == "field:\(!parentDisabled && !childDisabled)")
            }
        }
    }

    @Test("Disabled conditions stay within their own subtree")
    func disabledSiblingDoesNotLeak() {
        let backend = DummyBackend()
        let env = EnvironmentValues(backend: backend).with(\.window,
            backend.createWindow(withDefaultSize: nil, id: "disabled-siblings"))
        let view = VStack {
            EnabledLabel(name: "blocked").disabled(false).disabled(true)
            EnabledLabel(name: "available").disabled(false)
        }
        let node = ViewGraphNode(for: view, backend: backend, environment: env)
        _ = node.computeLayout(proposedSize: .unspecified, environment: env)
        _ = node.commit()
        #expect(texts(node.widget) == ["blocked:false", "available:true"])
    }

    #if canImport(AppKitBackend)
    @Test("A retained inspector keeps native Apply, its shortcut and fields disabled until shown")
    func nativeRetainedInspectorActions() throws {
        let backend = AppKitBackend()
        let window = backend.createWindow(withDefaultSize: SIMD2(320, 180), id: "disabled-native")
        let env = EnvironmentValues(backend: backend).with(\.window, window)
        var calls = 0
        func inspector(presented: Bool, canApply: Bool) -> some View {
            VStack {
                Button("Apply") { calls += 1 }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canApply)
                TextField("Length", text: Binding(get: { "120" }, set: { _ in }))
                    .disabled(false)
            }.disabled(!presented)
        }
        let initial = inspector(presented: true, canApply: true)
        let node = ViewGraphNode(for: initial, backend: backend, environment: env)
        _ = node.computeLayout(proposedSize: ProposedViewSize(320, 180), environment: env)
        _ = node.commit()
        let button = try #require(views(node.widget).compactMap { $0 as? NSCustomButton }.first)
        let shortcut = try #require(views(node.widget).compactMap { $0 as? NSKeyboardShortcutTarget }.first)
        let field = try #require(views(node.widget).compactMap { $0 as? NSTextField }
            .first { $0.placeholderString == "Length" })
        let space = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero,
            modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil,
            characters: " ", charactersIgnoringModifiers: " ", isARepeat: false, keyCode: 49))
        var expectedCalls = 0
        let phases = [(false, true), (true, true), (true, false), (false, true), (true, true)]
        for (index, phase) in phases.enumerated() {
            let (presented, canApply) = phase
            _ = node.computeLayout(with: inspector(presented: presented, canApply: canApply),
                proposedSize: ProposedViewSize(Double(321 + index), 180), environment: env)
            _ = node.commit()
            let enabled = presented && canApply
            #expect(views(node.widget).compactMap { $0 as? NSCustomButton }.first === button)
            #expect(views(node.widget).compactMap { $0 as? NSKeyboardShortcutTarget }.first === shortcut)
            #expect(button.isEnabled == enabled)
            #expect(shortcut.isEnabled == enabled)
            #expect(shortcut.shortcut == .defaultAction)
            #expect(field.isEnabled == presented)
            // Invoke the control's native key method directly. This validates
            // disabled action dispatch; it does not assert OS focus or routing.
            button.keyDown(with: space)
            if enabled { expectedCalls += 1 }
            #expect(calls == expectedCalls)
            // Accessibility activation must obey the same disabled state;
            // invoking this native entry point bypasses no test-side guard.
            #expect(button.accessibilityPerformPress() == enabled)
            if enabled { expectedCalls += 1 }
            #expect(calls == expectedCalls)
        }
    }

    private func views(_ root: NSView) -> [NSView] {
        [root] + root.subviews.flatMap(views)
    }
    #endif

    private func texts(_ widget: DummyBackend.Widget) -> [String] {
        (widget as? DummyBackend.TextView).map { [$0.content] } ?? widget.getChildren().flatMap(texts)
    }
}
