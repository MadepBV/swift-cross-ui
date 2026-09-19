import Foundation
import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

@MainActor
private struct LabelTestPickerStyle: PickerStyle {
    func makeView<Value: Equatable>(
        options: [Value], selection: Binding<Value?>, environment: EnvironmentValues
    ) -> TextField {
        TextField("Choose an option", text: Binding {
            selection.wrappedValue.map { "\($0)" } ?? ""
        } set: { _ in
            selection.wrappedValue = options.last
        })
    }
}

@Suite("Labels hidden layout and control identity")
@MainActor
struct LabelsHiddenTests {
    let backend = DummyBackend()

    private func environment(hidden: Bool = false) -> EnvironmentValues {
        EnvironmentValues(backend: backend)
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "labels"))
            .with(\.labelsHidden, hidden)
    }

    @Test("Hidden labelled content removes its column and spacer")
    func labelledContentOmitsReservedWidth() {
        let view = LabeledContent("Length", value: "120 mm")
            .environment(\.labeledContentLabelWidth, 160)
        let env = environment()
        let node = ViewGraphNode(for: view, backend: backend, environment: env)
        let visible = node.computeLayout(proposedSize: .unspecified, environment: env)
        _ = node.commit()
        #expect(visible.size.width > 160)
        let hidden = node.computeLayout(with: view, proposedSize: ProposedViewSize(nil, 200),
            environment: env.with(\.labelsHidden, true))
        _ = node.commit()
        #expect(texts(node.widget) == ["120 mm"])
        #expect(hidden.size.width < 160)
        // The value's width is its intrinsic width, not a leftover label gap.
        let direct = ViewGraphNode(for: Text("120 mm"), backend: backend, environment: env)
        let directLayout = direct.computeLayout(proposedSize: .unspecified, environment: env)
        #expect(hidden.size == directLayout.size)
    }

    @Test("Visibility is inherited and can be restored for an inner control")
    func nestedVisibility() {
        let view = VStack {
            Text("Section heading")
            LabeledContent("Hidden caption", value: "Hidden value")
            LabeledContent("Restored caption", value: "Restored value")
                .environment(\.labelsHidden, false)
        }.labelsHidden()
        let env = environment()
        let node = ViewGraphNode(for: view, backend: backend, environment: env)
        _ = node.computeLayout(proposedSize: .unspecified, environment: env)
        _ = node.commit()
        let labels = texts(node.widget)
        #expect(labels.contains("Section heading"))
        #expect(!labels.contains("Hidden caption"))
        #expect(labels.contains("Hidden value"))
        #expect(labels.contains("Restored caption"))
        #expect(labels.contains("Restored value"))
    }

    @Test("Picker loses only its caption and keeps the same bound control")
    func pickerIdentityAndSelection() throws {
        var selected = "Alpha"
        let view = Picker("Workspace", selection: Binding(get: { selected }, set: { selected = $0 })) {
            Text("Alpha").tag("Alpha")
            Text("Beta").tag("Beta")
        }.pickerStyle(LabelTestPickerStyle())
        let env = environment()
        let node = ViewGraphNode(for: view, backend: backend, environment: env)
        let visible = node.computeLayout(proposedSize: .unspecified, environment: env)
        _ = node.commit()
        let field = try #require(node.widget.firstWidget(ofType: DummyBackend.TextField.self))
        #expect(texts(node.widget).contains("Workspace"))
        #expect(field.value == "Alpha")
        let hidden = node.computeLayout(with: view, proposedSize: ProposedViewSize(nil, 200),
            environment: env.with(\.labelsHidden, true))
        _ = node.commit()
        #expect(!texts(node.widget).contains("Workspace"))
        #expect(hidden.size.width < visible.size.width)
        #expect(node.widget.firstWidget(ofType: DummyBackend.TextField.self) === field)
        field.changeHandler?("select last")
        #expect(selected == "Beta")
        _ = node.computeLayout(with: view, proposedSize: ProposedViewSize(200, nil), environment: env)
        _ = node.commit()
        #expect(node.widget.firstWidget(ofType: DummyBackend.TextField.self) === field)
        #expect(texts(node.widget).contains("Workspace"))
        #expect(field.value == "Beta")
    }

    @Test("Hidden toggle labels preserve switch and checkbox widgets and bindings")
    func toggleIdentityAndBinding() throws {
        var active = false
        let view = HStack {
            Toggle("Switch caption", isOn: Binding(get: { active }, set: { active = $0 }))
                .toggleStyle(.switch)
            Toggle("Checkbox caption", isOn: Binding(get: { active }, set: { active = $0 }))
                .toggleStyle(.checkbox)
        }
        let env = environment()
        let node = ViewGraphNode(for: view, backend: backend, environment: env)
        let visible = node.computeLayout(proposedSize: .unspecified, environment: env)
        _ = node.commit()
        let toggle = try #require(node.widget.firstWidget(ofType: DummyBackend.ToggleSwitch.self))
        let checkbox = try #require(node.widget.firstWidget(ofType: DummyBackend.Checkbox.self))
        let hidden = node.computeLayout(with: view, proposedSize: ProposedViewSize(nil, 200),
            environment: env.with(\.labelsHidden, true))
        _ = node.commit()
        #expect(texts(node.widget).isEmpty)
        #expect(hidden.size.width < visible.size.width)
        #expect(node.widget.firstWidget(ofType: DummyBackend.ToggleSwitch.self) === toggle)
        #expect(node.widget.firstWidget(ofType: DummyBackend.Checkbox.self) === checkbox)
        toggle.toggleHandler?(true)
        #expect(active)
        checkbox.toggleHandler?(false)
        #expect(!active)
    }

    @Test("Text placeholders and button-style toggle content remain visible")
    func contentIsNotASeparateLabel() throws {
        let view = VStack {
            TextField("Enter length", text: Binding(get: { "12" }, set: { _ in }))
            Toggle("Selected tool", isOn: Binding(get: { true }, set: { _ in })).toggleStyle(.button)
        }.labelsHidden()
        let env = environment()
        let node = ViewGraphNode(for: view, backend: backend, environment: env)
        _ = node.computeLayout(proposedSize: ProposedViewSize(220, 100), environment: env)
        _ = node.commit()
        let field = try #require(node.widget.firstWidget(ofType: DummyBackend.TextField.self))
        let button = try #require(node.widget.firstWidget(ofType: DummyBackend.ToggleButton.self))
        #expect(field.placeholder == "Enter length" && field.value == "12")
        #expect(button.label == "Selected tool" && button.state)
    }

    @Test("Textual labels yield accessibility metadata without evaluating custom bodies")
    func textualAccessibility() {
        #expect(controlLabelText(Text("Diameter")) == "Diameter")
        #expect(controlLabelText(TupleView1(Text("Spacing"))) == "Spacing")
        #expect(controlLabelText(EmptyView()) == nil)
        let hidden = Text("120 mm").retainingHiddenControlLabel(Text("Length"), hidden: true)
        let visible = Text("120 mm").retainingHiddenControlLabel(Text("Length"), hidden: false)
        #expect((hidden as? any AccessibilityPropertyProvider)?.accumulatedAccessibilityProperties.label == "Length")
        #expect((visible as? any AccessibilityPropertyProvider)?.accumulatedAccessibilityProperties.label == nil)
    }

    #if canImport(AppKitBackend)
    @Test("Native menu picker hides its caption while retaining options, selection and identity")
    func nativePicker() throws {
        let nativeBackend = AppKitBackend()
        let window = nativeBackend.createWindow(withDefaultSize: SIMD2(320, 200), id: "labels-native")
        let env = EnvironmentValues(backend: nativeBackend).with(\.window, window).with(\.pickerStyle, .menu)
        var selected = 0
        let view = Picker("Workspace", selection: Binding(get: { selected }, set: { selected = $0 })) {
            Text("Reinforcement").tag(0)
            Text("Modelling").tag(1)
        }
        let node = ViewGraphNode(for: view, backend: nativeBackend, environment: env)
        let visible = node.computeLayout(proposedSize: .unspecified, environment: env)
        _ = node.commit()
        let popup = try #require(nativeViews(node.widget).compactMap { $0 as? NSPopUpButton }.first)
        let hidden = node.computeLayout(with: view, proposedSize: ProposedViewSize(nil, 201), environment: env.with(\.labelsHidden, true))
        _ = node.commit()
        #expect(nativeViews(node.widget).compactMap { $0 as? NSPopUpButton }.first === popup)
        #expect(popup.itemTitles == ["Reinforcement", "Modelling"])
        #expect(popup.indexOfSelectedItem == 0)
        #expect(!nativeViews(node.widget).contains { ($0 as? NSTextField)?.stringValue == "Workspace" })
        #expect(nativeViews(node.widget).contains { $0.accessibilityLabel() == "Workspace" })
        #expect(hidden.size.width < visible.size.width)
        popup.selectItem(at: 1)
        popup.onAction?(popup)
        #expect(selected == 1)
    }

    @Test("Native date and colour controls omit only their labels")
    func nativeDateAndColour() throws {
        let nativeBackend = AppKitBackend()
        let window = nativeBackend.createWindow(withDefaultSize: SIMD2(400, 200), id: "labels-other-native")
        let env = EnvironmentValues(backend: nativeBackend).with(\.window, window)
        let view = VStack {
            DatePicker("Revision date", selection: Binding(get: { Date(timeIntervalSince1970: 0) }, set: { _ in }))
            ColorPicker("Layer colour", selection: Binding(get: { .red }, set: { _ in }))
        }
        let node = ViewGraphNode(for: view, backend: nativeBackend, environment: env)
        _ = node.computeLayout(proposedSize: ProposedViewSize(400, 200), environment: env)
        _ = node.commit()
        let date = try #require(nativeViews(node.widget).compactMap { $0 as? NSDatePicker }.first)
        let colour = try #require(nativeViews(node.widget).compactMap { $0 as? NSColorWell }.first)
        _ = node.computeLayout(with: view, proposedSize: ProposedViewSize(401, 200), environment: env.with(\.labelsHidden, true))
        _ = node.commit()
        let views = nativeViews(node.widget)
        #expect(views.compactMap { $0 as? NSDatePicker }.first === date)
        #expect(views.compactMap { $0 as? NSColorWell }.first === colour)
        #expect(!views.contains { ($0 as? NSTextField)?.stringValue == "Revision date" })
        #expect(!views.contains { ($0 as? NSTextField)?.stringValue == "Layer colour" })
    }

    private func nativeViews(_ root: NSView) -> [NSView] {
        [root] + root.subviews.flatMap(nativeViews)
    }
    #endif

    private func texts(_ widget: DummyBackend.Widget) -> [String] {
        (widget as? DummyBackend.TextView).map { [$0.content] } ?? widget.getChildren().flatMap(texts)
    }
}
