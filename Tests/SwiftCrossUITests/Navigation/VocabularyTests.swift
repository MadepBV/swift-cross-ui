import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing SwiftUI initializer shapes and small vocabulary")
@MainActor
struct VocabularyTests {
    @Test("TapGesture().onEnded resolves to a tap whose handlers run")
    func tapGestureRunsItsHandlers() {
        let count = StateBox(0)
        let gesture = TapGesture(count: 2).onEnded { count.value += 1 }
        guard case .spatialTap(let tap) = gesture._resolved else {
            Issue.record("A tap gesture should resolve to a spatial tap")
            return
        }
        #expect(tap.count == 2)
        for handler in tap.endHandlers {
            handler(SpatialTapGesture.Value(location: CGPoint(x: 0, y: 0), clickCount: 2))
        }
        #expect(count.value == 1)
        #expect(TapGesture(count: 2) == gesture)
    }

    @Test("Button(role: .close) is a cancelling button titled Close")
    func closeRoleButton() {
        #expect(ButtonRole.close == .cancel)
        #expect(ButtonRole.close.defaultTitle == "Close")
        let harness = GraphHarness { Button(role: .close) {} }
        harness.render(passes: 1)
        #expect(harness.texts == ["Close"])
    }

    @Test("A Menu with a label view is titled by the label's text")
    func menuWithALabelView() {
        let harness = GraphHarness {
            Menu {
                Button("Rename") {}
            } label: {
                Label("More", systemImage: "ellipsis")
            }
        }
        harness.render(passes: 1)
        #expect(harness.texts == ["More"])
    }

    @Test("NavigationLink with a title pushes its destination")
    func titledNavigationLinkPushes() {
        let harness = GraphHarness {
            NavigationStack {
                NavigationLink("Privacy") { Text("Privacy policy") }
            }
        }
        harness.render(passes: 1)
        harness.click("Privacy")
        harness.render()
        #expect(harness.texts == ["Back", "Privacy policy"])
    }

    @Test("ContentUnavailableView takes a title, a symbol and a description")
    func contentUnavailableTitleAndSymbol() {
        let harness = GraphHarness {
            ContentUnavailableView(
                "Nothing downloaded",
                systemImage: "arrow.down.circle",
                description: Text("Downloads play offline.")
            )
        }
        harness.render(passes: 1)
        #expect(harness.texts.contains("Nothing downloaded"))
        #expect(harness.texts.contains("Downloads play offline."))
    }

    @Test("String interpolation formats with a format style")
    func formatInterpolation() {
        let delay = 1.5
        let style = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(2))
            .locale(Locale(identifier: "en_US"))
        #expect("Delay \(delay, format: style) s" == "Delay 1.50 s")
    }

    @Test("State(initialValue:) seeds state like State(wrappedValue:)")
    func stateInitialValue() {
        struct Seeded: View {
            @State private var value: Int
            init() { _value = State(initialValue: 7) }
            var body: some View { Text("\(value)") }
        }
        let harness = GraphHarness { Seeded() }
        harness.render(passes: 1)
        #expect(harness.texts == ["7"])
    }

    @Test("Text field modifiers reach the environment backends read")
    func textFieldModifiersSetTheEnvironment() {
        let environment = StateBox<EnvironmentValues?>(nil)
        struct Probe: View {
            @Environment(\.self) var environment
            let box: StateBox<EnvironmentValues?>
            var body: some View {
                let _ = box.value = environment
                Text("Probe")
            }
        }
        let harness = GraphHarness {
            Probe(box: environment)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
                .submitLabel(.go)
        }
        harness.render(passes: 1)
        #expect(environment.value?.autocorrectionDisabled == true)
        #expect(environment.value?.textFieldIsPlain == true)
    }

    @Test("swipeActions offers its actions in the row's context menu")
    func swipeActionsBecomeAContextMenu() {
        let view = Text("Row").swipeActions(edge: .trailing) {
            Button("Remove") {}
        }
        #expect(String(describing: type(of: view)).contains("ContextMenu"))
    }
}
