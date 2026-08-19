import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A source of truth for a numeric binding, standing in for the `@State`
/// property that an app would usually use.
final class NumberSource<Value> {
    var value: Value

    var binding: Binding<Value> {
        Binding(
            get: { self.value },
            set: { newValue in self.value = newValue }
        )
    }

    init(_ value: Value) {
        self.value = value
    }
}

/// A source of truth for a ``Toggle``'s state.
final class FlagSource {
    var isOn: Bool

    var binding: Binding<Bool> {
        Binding(
            get: { self.isOn },
            set: { newValue in self.isOn = newValue }
        )
    }

    init(_ isOn: Bool) {
        self.isOn = isOn
    }
}

/// A counter used to observe the actions of a ``Stepper``.
final class NudgeCounter {
    var increments = 0
    var decrements = 0
    var editingChanges: [Bool] = []
}

@Suite("Testing for format styles, steppers, and toggle labels")
struct FormattedTextAndControlsTests {
    /// A fixed locale, so that the formatted output of these tests doesn't
    /// depend on the machine that runs them.
    static let locale = Locale(identifier: "en_US")

    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    // MARK: Text with a format style

    @MainActor
    @Test("Text formats a floating point value with a precision style")
    func textFormatsFloatingPointValue() throws {
        let view = Text(
            1234.5678,
            format: .number
                .precision(.fractionLength(2))
                .locale(Self.locale)
        )

        #expect(try renderedText(of: view) == "1,234.57")
    }

    @MainActor
    @Test("Text formats an integer value")
    func textFormatsIntegerValue() throws {
        let view = Text(12345, format: .number.locale(Self.locale))

        #expect(try renderedText(of: view) == "12,345")
    }

    @MainActor
    @Test("Text formats a value as a percentage")
    func textFormatsPercentage() throws {
        let view = Text(0.25, format: .percent.locale(Self.locale))

        #expect(try renderedText(of: view) == "25%")
    }

    @MainActor
    @Test("Text agrees with the format style it was given")
    func textMatchesFoundationsOwnOutput() throws {
        // Spelled exactly as an app would spell it, with the format style's
        // base inferred from context rather than written out.
        let view = Text(2.5, format: .number.precision(.fractionLength(3)))
        let expected = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(3))
            .format(2.5)

        #expect(try renderedText(of: view) == expected)
    }

    // MARK: TextField with a format style

    @MainActor
    @Test("Text field displays its value through the format style")
    func textFieldDisplaysFormattedValue() throws {
        let source = NumberSource(1234.5678)
        let view = TextField(
            "Diameter",
            value: source.binding,
            format: .number
                .precision(.fractionLength(2))
                .locale(Self.locale)
        )

        let field = try textField(of: view)

        #expect(field.value == "1,234.57")
        #expect(field.placeholder == "Diameter")
    }

    @MainActor
    @Test("Editing a formatted text field parses the new value")
    func textFieldParsesEdits() throws {
        let source = NumberSource(1.0)
        let view = TextField(
            "",
            value: source.binding,
            format: .number.locale(Self.locale)
        )

        let field = try textField(of: view)
        let changeHandler = try #require(field.changeHandler)
        changeHandler("12.5")

        #expect(source.value == 12.5)
    }

    @MainActor
    @Test("Unparseable input leaves a formatted text field's value alone")
    func textFieldIgnoresUnparseableEdits() throws {
        let source = NumberSource(7.0)
        let view = TextField(
            "",
            value: source.binding,
            format: .number.locale(Self.locale)
        )

        let field = try textField(of: view)
        let changeHandler = try #require(field.changeHandler)
        changeHandler("not a number")

        #expect(source.value == 7.0)
    }

    @MainActor
    @Test("An integer field round trips through its format style")
    func integerTextFieldRoundTrips() throws {
        let source = NumberSource(3)
        let view = TextField(
            "",
            value: source.binding,
            format: .number.locale(Self.locale)
        )

        let field = try textField(of: view)
        #expect(field.value == "3")

        let changeHandler = try #require(field.changeHandler)
        changeHandler("42")

        #expect(source.value == 42)
    }

    @MainActor
    @Test("A formatted field lets the user type an intermediate decimal point")
    func textFieldKeepsIntermediateInput() throws {
        let source = NumberSource(1.0)
        let view = TextField(
            "",
            value: source.binding,
            format: .number.locale(Self.locale)
        )

        let proposal = ProposedViewSize(300, 100)
        let node = committedNode(for: view, proposedSize: proposal)
        let field = try #require(
            node.widget.firstWidget(ofType: DummyBackend.TextField.self)
        )
        #expect(field.value == "1")

        // The user types "12.". A real backend updates its own content before
        // reporting the change, so the dummy one has to as well.
        field.value = "12."
        let firstEdit = try #require(field.changeHandler)
        firstEdit("12.")
        update(node, proposedSize: proposal)

        // "12." parses to the value that the field is already showing, so the
        // trailing decimal point survives long enough to type the rest.
        #expect(source.value == 12.0)
        #expect(field.value == "12.")

        field.value = "12.5"
        let secondEdit = try #require(field.changeHandler)
        secondEdit("12.5")
        update(node, proposedSize: proposal)

        #expect(source.value == 12.5)
        #expect(field.value == "12.5")
    }

    @MainActor
    @Test("A formatted field catches up when its value changes elsewhere")
    func textFieldFollowsExternalChanges() throws {
        let source = NumberSource(1.0)
        let view = TextField(
            "",
            value: source.binding,
            format: .number.locale(Self.locale)
        )

        let proposal = ProposedViewSize(300, 100)
        let node = committedNode(for: view, proposedSize: proposal)
        let field = try #require(
            node.widget.firstWidget(ofType: DummyBackend.TextField.self)
        )

        source.value = 8.25
        update(node, proposedSize: proposal)

        #expect(field.value == "8.25")
    }

    // MARK: Stepper

    @MainActor
    @Test("Stepper nudges its value up and down by the step amount")
    func stepperNudgesValue() throws {
        let source = NumberSource(4)
        let view = Stepper("Bars", value: source.binding, in: 0...10, step: 2)

        let buttons = try stepperButtons(of: view)
        buttons.increment()
        #expect(source.value == 6)

        buttons.decrement()
        #expect(source.value == 4)
    }

    @MainActor
    @Test("Stepper defaults to a step of one")
    func stepperDefaultsToStepOfOne() throws {
        let source = NumberSource(0.0)
        let view = Stepper("Cover", value: source.binding, in: 0.0...5.0)

        let buttons = try stepperButtons(of: view)
        buttons.increment()

        #expect(source.value == 1.0)
    }

    @MainActor
    @Test("Stepper clamps its value to the given range")
    func stepperClampsToBounds() throws {
        let source = NumberSource(9)
        let view = Stepper("Bars", value: source.binding, in: 0...10, step: 4)

        let buttons = try stepperButtons(of: view)
        buttons.increment()
        #expect(source.value == 10)

        // Already at the upper bound, so a further nudge does nothing.
        buttons.increment()
        #expect(source.value == 10)
    }

    @MainActor
    @Test("Stepper stops at the lower bound")
    func stepperStopsAtLowerBound() throws {
        let source = NumberSource(1)
        let view = Stepper("Bars", value: source.binding, in: 0...10, step: 3)

        let buttons = try stepperButtons(of: view)
        buttons.decrement()
        #expect(source.value == 0)

        buttons.decrement()
        #expect(source.value == 0)
    }

    @MainActor
    @Test("Stepper runs custom increment and decrement actions")
    func stepperRunsCustomActions() throws {
        let counter = NudgeCounter()
        let view = Stepper(
            "Count",
            onIncrement: { counter.increments += 1 },
            onDecrement: { counter.decrements += 1 },
            onEditingChanged: { isEditing in
                counter.editingChanges.append(isEditing)
            }
        )

        let buttons = try stepperButtons(of: view)
        buttons.increment()
        buttons.decrement()

        #expect(counter.increments == 1)
        #expect(counter.decrements == 1)
        #expect(counter.editingChanges == [true, false, true, false])
    }

    @MainActor
    @Test("A nil stepper action does nothing when pressed")
    func stepperNilActionDoesNothing() throws {
        let counter = NudgeCounter()
        let view = Stepper(
            "Count",
            onIncrement: { counter.increments += 1 },
            onDecrement: nil
        )

        let buttons = try stepperButtons(of: view)
        buttons.decrement()

        #expect(counter.decrements == 0)
        #expect(counter.editingChanges.isEmpty)
    }

    @MainActor
    @Test("Stepper labels its buttons with a minus sign and a plus sign")
    func stepperButtonLabels() throws {
        let source = NumberSource(0)
        let view = Stepper("Bars", value: source.binding, in: 0...10)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let labels = buttons(in: node.widget).map(buttonLabel(of:))

        #expect(labels == ["\u{2212}", "+"])
    }

    // MARK: Toggle labels

    @MainActor
    @Test("A toggle with a text label view matches one with a string title")
    func toggleWithTextLabelMatchesStringTitle() throws {
        let source = FlagSource(false)
        let view = Toggle(isOn: source.binding) {
            Text("Show grid")
        }
        .toggleStyle(.switch)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let text = try #require(
            node.widget.firstWidget(ofType: DummyBackend.TextView.self)
        )

        #expect(text.content == "Show grid")
    }

    @MainActor
    @Test("A toggle with a label view still writes through its binding")
    func toggleWithLabelViewWritesThroughBinding() throws {
        let source = FlagSource(false)
        let view = Toggle(isOn: source.binding) {
            Text("Show grid")
        }
        .toggleStyle(.switch)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let toggleSwitch = try #require(
            node.widget.firstWidget(ofType: DummyBackend.ToggleSwitch.self)
        )
        let toggleHandler = try #require(toggleSwitch.toggleHandler)
        toggleHandler(true)

        #expect(source.isOn)
    }

    @MainActor
    @Test("A non-textual toggle label is rendered as-is")
    func toggleRendersNonTextualLabel() throws {
        let source = FlagSource(false)
        let view = Toggle(isOn: source.binding) {
            HStack {
                Text("Grid")
                Text("(beta)")
            }
        }
        .toggleStyle(.switch)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let contents = textViews(in: node.widget).map(\.content)

        #expect(contents == ["Grid", "(beta)"])
    }

    @MainActor
    @Test("A toggle with a string title keeps SwiftUI's argument order")
    func toggleWithStringTitle() throws {
        let source = FlagSource(true)
        let view = Toggle("Show grid", isOn: source.binding)
            .toggleStyle(.switch)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let text = try #require(
            node.widget.firstWidget(ofType: DummyBackend.TextView.self)
        )
        let toggleSwitch = try #require(
            node.widget.firstWidget(ofType: DummyBackend.ToggleSwitch.self)
        )

        #expect(text.content == "Show grid")
        #expect(toggleSwitch.state)
    }

    @MainActor
    @Test("The button style still renders a native toggle button")
    func toggleButtonStyleUsesNativeWidget() throws {
        let source = FlagSource(true)
        let view = Toggle("Show grid", isOn: source.binding)
            .toggleStyle(.button)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let toggleButton = try #require(
            node.widget.firstWidget(ofType: DummyBackend.ToggleButton.self)
        )

        #expect(toggleButton.label == "Show grid")
        #expect(toggleButton.state)
    }

    @MainActor
    @Test("A non-textual label falls back to a button under the button style")
    func toggleButtonStyleFallsBackForLabelViews() throws {
        let source = FlagSource(false)
        let view = Toggle(isOn: source.binding) {
            HStack {
                Text("Grid")
                Text("(beta)")
            }
        }
        .toggleStyle(.button)

        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let found = buttons(in: node.widget)
        try #require(found.count == 1)

        let action = try #require(found[0].action)
        action()

        #expect(source.isOn)
        #expect(node.widget.firstWidget(ofType: DummyBackend.ToggleButton.self) == nil)
    }

    // MARK: Helpers

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

    /// Lays out and commits a node that has already been committed once,
    /// standing in for the update that follows a state change.
    ///
    /// - Parameters:
    ///   - node: The node to update.
    ///   - proposedSize: The size to propose to the node.
    @MainActor
    func update<V: View>(
        _ node: ViewGraphNode<V, DummyBackend>,
        proposedSize: ProposedViewSize
    ) {
        _ = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
    }

    /// Renders a view and reads the content of its first text widget.
    ///
    /// - Parameter view: The view to render.
    /// - Returns: The content of the view's first text widget.
    @MainActor
    func renderedText<V: View>(of view: V) throws -> String {
        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let text = try #require(
            node.widget.firstWidget(ofType: DummyBackend.TextView.self)
        )
        return text.content
    }

    /// Renders a view and finds its first text field widget.
    ///
    /// - Parameter view: The view to render.
    /// - Returns: The view's first text field widget.
    @MainActor
    func textField<V: View>(of view: V) throws -> DummyBackend.TextField {
        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        return try #require(
            node.widget.firstWidget(ofType: DummyBackend.TextField.self)
        )
    }

    /// Renders a stepper and returns actions that press its two buttons.
    ///
    /// - Parameter view: The stepper to render.
    /// - Returns: The stepper's decrement and increment actions, in the order
    ///   that the buttons appear.
    @MainActor
    func stepperButtons<Label: View>(
        of view: Stepper<Label>
    ) throws -> (decrement: () -> Void, increment: () -> Void) {
        let node = committedNode(
            for: view,
            proposedSize: ProposedViewSize(300, 100)
        )
        let found = buttons(in: node.widget)
        try #require(found.count == 2)

        let decrement = try #require(found[0].action)
        let increment = try #require(found[1].action)
        return (decrement, increment)
    }

    /// Collects the button widgets of a widget hierarchy, in layout order.
    ///
    /// - Parameter widget: The root of the hierarchy to search.
    /// - Returns: Every button in the hierarchy.
    @MainActor
    func buttons(in widget: DummyBackend.Widget) -> [DummyBackend.Button] {
        widgets(in: widget, ofType: DummyBackend.Button.self)
    }

    /// Collects the text widgets of a widget hierarchy, in layout order.
    ///
    /// - Parameter widget: The root of the hierarchy to search.
    /// - Returns: Every text widget in the hierarchy.
    @MainActor
    func textViews(in widget: DummyBackend.Widget) -> [DummyBackend.TextView] {
        widgets(in: widget, ofType: DummyBackend.TextView.self)
    }

    /// Collects the widgets of a given type in a widget hierarchy.
    ///
    /// ``DummyBackend/Widget/firstWidget(ofType:)`` only ever finds one
    /// widget, and these tests need to inspect pairs of buttons and pairs of
    /// text views, hence this depth first equivalent.
    ///
    /// - Parameters:
    ///   - widget: The root of the hierarchy to search.
    ///   - type: The type of widget to collect.
    /// - Returns: Every widget of the given type, in layout order.
    @MainActor
    func widgets<T: DummyBackend.Widget>(
        in widget: DummyBackend.Widget,
        ofType type: T.Type
    ) -> [T] {
        var found: [T] = []
        if let match = widget as? T {
            found.append(match)
        }
        for child in widget.getChildren() {
            found += widgets(in: child, ofType: type)
        }
        return found
    }

    /// Reads the text shown on a button.
    ///
    /// - Parameter button: The button to inspect.
    /// - Returns: The button's text, or the empty string if it has none.
    @MainActor
    func buttonLabel(of button: DummyBackend.Button) -> String {
        guard let label = button.label else {
            return ""
        }
        return label.firstWidget(ofType: DummyBackend.TextView.self)?.content ?? ""
    }
}
