import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing keyboard shortcuts and focus")
@MainActor
struct KeyboardAndFocusTests {
    // MARK: Key equivalents

    @Test("Key equivalents can be written as character literals")
    func testKeyEquivalentLiteral() {
        let key: KeyEquivalent = "s"
        #expect(key.character == "s")
        #expect(key == KeyEquivalent("s"))
    }

    @Test("Named keys use the character values SwiftUI uses")
    func testNamedKeyEquivalents() {
        // These match AppKit's function key constants, which is what makes
        // shortcut declarations portable from a SwiftUI codebase.
        #expect(KeyEquivalent.upArrow.character == "\u{F700}")
        #expect(KeyEquivalent.downArrow.character == "\u{F701}")
        #expect(KeyEquivalent.leftArrow.character == "\u{F702}")
        #expect(KeyEquivalent.rightArrow.character == "\u{F703}")
        #expect(KeyEquivalent.escape.character == "\u{1B}")
        #expect(KeyEquivalent.delete.character == "\u{8}")
        #expect(KeyEquivalent.return.character == "\r")
        #expect(KeyEquivalent.tab.character == "\t")
        #expect(KeyEquivalent.space.character == " ")
    }

    // MARK: Event modifiers

    @Test("Event modifiers compose as an option set")
    func testEventModifiersOptionSet() {
        let modifiers: EventModifiers = [.command, .shift]
        #expect(modifiers.contains(.command))
        #expect(modifiers.contains(.shift))
        #expect(!modifiers.contains(.option))
        #expect(EventModifiers.all.contains(.command))
        #expect(EventModifiers.all.contains(.numericPad))
    }

    // MARK: Keyboard shortcuts

    @Test("Keyboard shortcuts default to the command modifier")
    func testKeyboardShortcutDefaultModifiers() {
        let shortcut = KeyboardShortcut("s")
        #expect(shortcut.key == "s")
        #expect(shortcut.modifiers == .command)
    }

    @Test("The standard shortcuts are return and escape without modifiers")
    func testStandardShortcuts() {
        #expect(KeyboardShortcut.defaultAction.key == .return)
        #expect(KeyboardShortcut.defaultAction.modifiers.isEmpty)
        #expect(KeyboardShortcut.cancelAction.key == .escape)
        #expect(KeyboardShortcut.cancelAction.modifiers.isEmpty)
    }

    @Test("Keyboard shortcuts are comparable by key and modifiers")
    func testKeyboardShortcutEquality() {
        #expect(
            KeyboardShortcut("z", modifiers: [.command, .shift])
                == KeyboardShortcut("z", modifiers: [.shift, .command])
        )
        #expect(
            KeyboardShortcut("z", modifiers: [.command])
                != KeyboardShortcut("z", modifiers: [.command, .shift])
        )
    }

    @Test("Shortcut modifiers survive being attached to a view")
    func testKeyboardShortcutModifierStoresShortcut() {
        let view: any View = Text("Save").keyboardShortcut("s", modifiers: [.command])
        let modifier = view as? KeyboardShortcutModifier<Text>
        #expect(modifier?.shortcut == KeyboardShortcut("s", modifiers: [.command]))
    }

    @Test("Backends without shortcut support pass the child straight through")
    func testKeyboardShortcutDegradesGracefully() {
        // DummyBackend doesn't conform to BackendFeatures.KeyboardShortcuts,
        // so the modifier must be a no-op rather than trapping.
        let view = Text("Save").keyboardShortcut("s", modifiers: [.command])
        #expect(render(view).text == ["Save"])
    }

    // MARK: Focus state

    @Test("A boolean focus state starts unfocused")
    func testBooleanFocusStateDefault() {
        let state = FocusState<Bool>()
        #expect(state.wrappedValue == false)
    }

    @Test("An optional focus state starts with nothing focused")
    func testOptionalFocusStateDefault() {
        let state = FocusState<Field?>()
        #expect(state.wrappedValue == nil)
    }

    @Test("Writing to a focus state is visible through its binding")
    func testFocusStateBindingReadsThrough() {
        let state = FocusState<Field?>()
        state.wrappedValue = .name
        #expect(state.projectedValue.wrappedValue == .name)

        state.projectedValue.wrappedValue = .diameter
        #expect(state.wrappedValue == .diameter)
    }

    @Test("Gaining focus writes the bound value back to the state")
    func testFocusGainWritesBack() {
        let state = FocusState<Field?>()
        let binding = state.projectedValue.erased(matching: .name)

        #expect(binding.isFocused() == false)
        binding.setFocused(true)
        #expect(state.wrappedValue == .name)
        #expect(binding.isFocused())
    }

    @Test("Losing focus only clears the state when it names this view")
    func testFocusLossOnlyClearsItsOwnValue() {
        let state = FocusState<Field?>()
        let name = state.projectedValue.erased(matching: .name)
        let diameter = state.projectedValue.erased(matching: .diameter)

        name.setFocused(true)
        #expect(state.wrappedValue == .name)

        // The other field resigning focus must not clobber the focused one,
        // which is what makes the ordering of platform focus notifications
        // irrelevant.
        diameter.setFocused(false)
        #expect(state.wrappedValue == .name)

        name.setFocused(false)
        #expect(state.wrappedValue == nil)
    }

    @Test("Focus moving between fields updates the state exactly once")
    func testFocusMovingBetweenFields() {
        let state = FocusState<Field?>()
        let name = state.projectedValue.erased(matching: .name)
        let diameter = state.projectedValue.erased(matching: .diameter)

        name.setFocused(true)

        // Platforms may report the gain before the loss, or the other way
        // around; both orders must land on `.diameter`.
        diameter.setFocused(true)
        name.setFocused(false)
        #expect(state.wrappedValue == .diameter)

        name.setFocused(true)
        diameter.setFocused(false)
        #expect(state.wrappedValue == .name)
    }

    @Test("A boolean focus state clears to false")
    func testBooleanFocusStateClears() {
        let state = FocusState<Bool>()
        let binding = state.projectedValue.erased(matching: true)

        binding.setFocused(true)
        #expect(state.wrappedValue == true)
        binding.setFocused(false)
        #expect(state.wrappedValue == false)
    }

    // MARK: Focus through the view graph

    @Test("A focus state with nothing focused leaves every field unfocused")
    func testNoFieldFocusedInitially() {
        FocusProbe.shared.reset()
        let harness = InspectorHarness()
        _ = RenderSession(harness)

        #expect(harness.focusedField == nil)
        #expect(FocusProbe.shared.requestedFocus["Horizontal"] == false)
        #expect(FocusProbe.shared.requestedFocus["Vertical"] == false)
    }

    @Test("Platform focus changes write back into the focus state")
    func testPlatformFocusWritesBackToState() {
        FocusProbe.shared.reset()
        let harness = InspectorHarness()
        let session = RenderSession(harness)

        // The user clicks into the first field.
        FocusProbe.shared.simulatePlatformFocus(true, on: "Horizontal")
        #expect(harness.focusedField == .horizontal)

        // And then clicks away.
        session.update()
        FocusProbe.shared.simulatePlatformFocus(false, on: "Horizontal")
        #expect(harness.focusedField == nil)
    }

    @Test("Writing to the focus state asks the backend to move focus")
    func testStateWriteDrivesBackendFocus() {
        FocusProbe.shared.reset()
        let harness = InspectorHarness()
        let session = RenderSession(harness)

        harness.focusedField = .vertical
        session.update()

        #expect(FocusProbe.shared.requestedFocus["Vertical"] == true)
        #expect(FocusProbe.shared.requestedFocus["Horizontal"] == false)
    }

    @Test("Advancing focus from onSubmit moves focus to the next field")
    func testOnSubmitAdvancesFocus() {
        FocusProbe.shared.reset()
        let harness = InspectorHarness()
        let session = RenderSession(harness)

        // The user clicks into the first field, which writes back to the
        // focus state.
        FocusProbe.shared.simulatePlatformFocus(true, on: "Horizontal")
        session.update()
        #expect(harness.focusedField == .horizontal)
        #expect(FocusProbe.shared.requestedFocus["Horizontal"] == true)

        // Pressing Return runs the onSubmit handler, which writes the next
        // field into the focus state. This is the round trip that a one-way
        // focus implementation would silently fail.
        session.submit(field: "Horizontal")
        #expect(harness.focusedField == .vertical)

        session.update()
        #expect(FocusProbe.shared.requestedFocus["Vertical"] == true)
        #expect(FocusProbe.shared.requestedFocus["Horizontal"] == false)
    }

    @Test("onSubmit composes with focused(_:equals:) in either order")
    func testOnSubmitComposesWithFocusedInEitherOrder() {
        FocusProbe.shared.reset()
        let harness = ReorderedInspectorHarness()
        let session = RenderSession(harness)

        FocusProbe.shared.simulatePlatformFocus(true, on: "Horizontal")
        session.update()

        session.submit(field: "Horizontal")
        #expect(harness.focusedField == .vertical)

        session.update()
        #expect(FocusProbe.shared.requestedFocus["Vertical"] == true)
    }

    // MARK: Focused values

    @Test("Focused values round-trip through their key")
    func testFocusedValuesSubscript() {
        var values = FocusedValues()
        #expect(values[CountKey.self] == nil)

        values[CountKey.self] = 3
        #expect(values[CountKey.self] == 3)

        values[CountKey.self] = nil
        #expect(values[CountKey.self] == nil)
    }

    @Test("Publishing a focused value makes it readable")
    func testFocusedValueStorePublish() {
        let store = FocusedValuesStore.shared
        store.publish("caliper", for: \.toolName)
        #expect(store.value(for: \.toolName) == "caliper")

        store.publish(nil, for: \.toolName)
        #expect(store.value(for: \.toolName) == nil)
    }

    @Test("Republishing an equal value doesn't notify observers")
    func testFocusedValueStoreCoalescesEqualValues() {
        let store = FocusedValuesStore.shared
        store.publish(nil, for: \.notifiedValue)

        var notifications = 0
        let cancellable = store.didChange.observe {
            notifications += 1
        }
        defer { cancellable.cancel() }

        store.publish(7, for: \.notifiedValue)
        store.publish(7, for: \.notifiedValue)
        store.publish(8, for: \.notifiedValue)

        // Coalescing equal values is what stops a view that both publishes and
        // reads a focused value from looping forever.
        #expect(notifications == 2)

        store.publish(nil, for: \.notifiedValue)
    }

    @Test("A focused value property reads the published value")
    func testFocusedValueProperty() {
        FocusedValuesStore.shared.publish(42, for: \.barCount)
        defer { FocusedValuesStore.shared.publish(nil, for: \.barCount) }

        let property = FocusedValue(\.barCount)
        property.update(with: environment(), previousValue: nil)
        #expect(property.wrappedValue == 42)
    }

    @Test("An unpublished focused value reads as nil")
    func testUnpublishedFocusedValueIsNil() {
        FocusedValuesStore.shared.publish(nil, for: \.barCount)

        let property = FocusedValue(\.barCount)
        property.update(with: environment(), previousValue: nil)
        #expect(property.wrappedValue == nil)
    }

    @Test("An active scene publishes its focused value")
    func testFocusedSceneValuePublishesWhenActive() {
        FocusedValuesStore.shared.publish(nil, for: \.activeSceneValue)

        let view = Text("Content").focusedSceneValue(\.activeSceneValue, "published")
        _ = render(view, scenePhase: .active)

        #expect(FocusedValuesStore.shared.value(for: \.activeSceneValue) == "published")
        FocusedValuesStore.shared.publish(nil, for: \.activeSceneValue)
    }

    @Test("An inactive scene doesn't publish its focused value")
    func testFocusedSceneValueStaysQuietWhenInactive() {
        FocusedValuesStore.shared.publish(nil, for: \.inactiveSceneValue)

        let view = Text("Content").focusedSceneValue(\.inactiveSceneValue, "published")
        let rendered = render(view, scenePhase: .inactive)

        // The child still renders; only the publication is withheld, so the
        // frontmost window is the one whose values win.
        #expect(rendered.text == ["Content"])
        #expect(FocusedValuesStore.shared.value(for: \.inactiveSceneValue) == nil)
    }
}

// MARK: - Test fixtures

/// A focusable field, standing in for the enums real apps bind focus to.
private enum Field: Hashable {
    case name
    case diameter
}

/// The fields of ``InspectorHarness``.
private enum InspectorField: Hashable {
    case horizontal
    case vertical
}

/// A two-field form that advances focus on submit.
///
/// This mirrors how a real inspector is written: each field binds its focus,
/// and the submit handler writes the *next* field into the same focus state to
/// move the caret along.
private struct InspectorHarness: View {
    @FocusState var focusedField: InspectorField?
    @State var horizontal = ""
    @State var vertical = ""

    var body: some View {
        VStack {
            TextField("Horizontal", text: $horizontal)
                .focused($focusedField, equals: .horizontal)
                .onSubmit {
                    if focusedField == .horizontal {
                        focusedField = .vertical
                    }
                }
            TextField("Vertical", text: $vertical)
                .focused($focusedField, equals: .vertical)
        }
    }
}

/// The same form with `onSubmit` applied before `focused(_:equals:)`.
///
/// `onSubmit` works by way of the environment and `focused(_:equals:)` by way
/// of a wrapper widget, so the two are order-independent; this harness pins
/// that down.
private struct ReorderedInspectorHarness: View {
    @FocusState var focusedField: InspectorField?
    @State var horizontal = ""
    @State var vertical = ""

    var body: some View {
        VStack {
            TextField("Horizontal", text: $horizontal)
                .onSubmit {
                    if focusedField == .horizontal {
                        focusedField = .vertical
                    }
                }
                .focused($focusedField, equals: .horizontal)
            TextField("Vertical", text: $vertical)
                .focused($focusedField, equals: .vertical)
        }
    }
}

private struct CountKey: FocusedValueKey {
    typealias Value = Int
}

private struct ToolNameKey: FocusedValueKey {
    typealias Value = String
}

private struct NotifiedValueKey: FocusedValueKey {
    typealias Value = Int
}

private struct BarCountKey: FocusedValueKey {
    typealias Value = Int
}

private struct ActiveSceneValueKey: FocusedValueKey {
    typealias Value = String
}

private struct InactiveSceneValueKey: FocusedValueKey {
    typealias Value = String
}

extension FocusedValues {
    fileprivate var toolName: String? {
        get { self[ToolNameKey.self] }
        set { self[ToolNameKey.self] = newValue }
    }

    fileprivate var notifiedValue: Int? {
        get { self[NotifiedValueKey.self] }
        set { self[NotifiedValueKey.self] = newValue }
    }

    fileprivate var barCount: Int? {
        get { self[BarCountKey.self] }
        set { self[BarCountKey.self] = newValue }
    }

    fileprivate var activeSceneValue: String? {
        get { self[ActiveSceneValueKey.self] }
        set { self[ActiveSceneValueKey.self] = newValue }
    }

    fileprivate var inactiveSceneValue: String? {
        get { self[InactiveSceneValueKey.self] }
        set { self[InactiveSceneValueKey.self] = newValue }
    }
}

// MARK: - A focus-capable backend for tests

/// Records what SwiftCrossUI asks a focus-capable backend to do, and lets a
/// test play the part of the platform moving focus.
///
/// Targets are addressed by the placeholder of the text field they wrap, which
/// keeps the tests readable.
@MainActor
final class FocusProbe {
    static let shared = FocusProbe()

    /// The focus state most recently requested for each target.
    private(set) var requestedFocus: [String: Bool] = [:]

    /// The handler each target registered for platform-driven focus changes.
    private var focusChangeHandlers: [String: (Bool) -> Void] = [:]

    private init() {}

    /// Clears all recorded state. Call at the start of each test.
    func reset() {
        requestedFocus = [:]
        focusChangeHandlers = [:]
    }

    /// Records a focus update from the framework.
    func record(
        _ target: DummyBackend.Widget,
        isFocused: Bool,
        onFocusChange: @escaping (Bool) -> Void
    ) {
        let label = Self.label(of: target)
        requestedFocus[label] = isFocused
        focusChangeHandlers[label] = onFocusChange
    }

    /// Simulates the platform moving focus onto or off a target, the way a
    /// click or a Tab keypress would.
    func simulatePlatformFocus(_ isFocused: Bool, on label: String) {
        focusChangeHandlers[label]?(isFocused)
    }

    /// A readable name for a focus target.
    ///
    /// Walks down to the first focusable descendant, exactly as a real backend
    /// must: when `focused(_:equals:)` is applied outside another modifier the
    /// target is a container, not the control itself.
    static func label(of widget: DummyBackend.Widget) -> String {
        var queue = [widget]
        while let next = queue.first {
            queue.removeFirst()
            if let field = next as? DummyBackend.TextField {
                return field.placeholder
            }
            if let text = next as? DummyBackend.TextView {
                return text.content
            }
            queue.append(contentsOf: next.getChildren())
        }
        return String(describing: ObjectIdentifier(widget))
    }
}

// Conforming the dummy backend to `Focus` here (rather than in the backend
// itself, which this task doesn't own) is what makes an end-to-end test of the
// two-way focus binding possible: without a conforming backend the modifier
// short-circuits and only the state half would ever be exercised.
//
// Note that this means `DummyBackend` *does* support focus within the test
// module, so graceful degradation is covered by the keyboard shortcut test
// instead -- both modifiers share the same `as?`-and-pass-through shape.
extension DummyBackend: BackendFeatures.Focus {
    public func createFocusTarget(wrapping child: Widget) -> Widget {
        child
    }

    public func updateFocusTarget(
        _ target: Widget,
        isFocused: Bool,
        environment: EnvironmentValues,
        onFocusChange: @escaping (Bool) -> Void
    ) {
        FocusProbe.shared.record(
            target,
            isFocused: isFocused,
            onFocusChange: onFocusChange
        )
    }
}

/// A view graph that a test can update repeatedly, so that state changes can
/// be observed flowing back out to the backend.
@MainActor
private final class RenderSession<Content: View> {
    private let backend: DummyBackend
    private let environment: EnvironmentValues
    private let node: ViewGraphNode<Content, DummyBackend>

    /// Renders `view` and performs its first update.
    init(_ view: Content, scenePhase: ScenePhase = .active) {
        backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend)
            .with(\.window, window)
            .with(\.scenePhase, scenePhase)
        node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        update()
    }

    /// Runs another update pass, as a state change would.
    ///
    /// State changes normally schedule this asynchronously; driving it by hand
    /// keeps the tests synchronous.
    func update() {
        _ = node.computeLayout(
            proposedSize: .unspecified,
            environment: environment
        )
        _ = node.commit()
    }

    /// Simulates the user pressing Return in a text field.
    func submit(field placeholder: String) {
        textField(withPlaceholder: placeholder)?.submitHandler?()
    }

    /// Finds a rendered text field by its placeholder.
    private func textField(
        withPlaceholder placeholder: String
    ) -> DummyBackend.TextField? {
        var queue = [node.widget]
        while let next = queue.first {
            queue.removeFirst()
            if
                let field = next as? DummyBackend.TextField,
                field.placeholder == placeholder
            {
                return field
            }
            queue.append(contentsOf: next.getChildren())
        }
        return nil
    }
}

// MARK: - Rendering helpers

/// The outcome of rendering a view with a ``DummyBackend``.
private struct RenderResult {
    /// The content of every rendered text view, in breadth-first order.
    var text: [String]
    /// The size that the view laid out at.
    var size: SIMD2<Int>
}

/// Builds an environment backed by a ``DummyBackend`` window.
///
/// - Parameter scenePhase: The phase to report for the enclosing scene.
/// - Returns: An environment suitable for rendering a view.
@MainActor
private func environment(scenePhase: ScenePhase = .inactive) -> EnvironmentValues {
    let backend = DummyBackend()
    let window = backend.createWindow(withDefaultSize: nil, id: "window")
    return EnvironmentValues(backend: backend)
        .with(\.window, window)
        .with(\.scenePhase, scenePhase)
}

/// Renders `view` with a ``DummyBackend``, which implements neither
/// ``BackendFeatures/KeyboardShortcuts`` nor ``BackendFeatures/Focus``, so
/// these renders also check that both modifiers degrade silently.
///
/// - Parameters:
///   - view: The view to render.
///   - scenePhase: The phase to report for the enclosing scene.
/// - Returns: The rendered text and the view's laid out size.
@MainActor
private func render<Content: View>(
    _ view: Content,
    scenePhase: ScenePhase = .inactive
) -> RenderResult {
    let backend = DummyBackend()
    let window = backend.createWindow(withDefaultSize: nil, id: "window")
    let environment = EnvironmentValues(backend: backend)
        .with(\.window, window)
        .with(\.scenePhase, scenePhase)

    let node = ViewGraphNode(
        for: view,
        backend: backend,
        environment: environment
    )
    let layout = node.computeLayout(
        proposedSize: .unspecified,
        environment: environment
    )
    _ = node.commit()

    return RenderResult(
        text: textContent(in: node.widget),
        size: layout.size.vector
    )
}

/// Collects the content of every text view in a widget hierarchy.
///
/// - Parameter widget: The root of the hierarchy to search.
/// - Returns: The content of each text view, in breadth-first order.
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
