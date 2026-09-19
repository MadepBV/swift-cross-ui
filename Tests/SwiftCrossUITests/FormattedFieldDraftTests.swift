import Foundation
import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Formatted field draft reconciliation")
@MainActor
struct FormattedFieldDraftTests {
    private let backend: DummyBackend
    private let environment: EnvironmentValues

    init() {
        backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "formatted-draft")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    private var format: FloatingPointFormatStyle<Double> {
        .number.locale(Locale(identifier: "en_US_POSIX"))
    }

    @Test("Incomplete tokens survive layout and a newly evaluated view without model writes")
    func incompleteTokensSurvive() throws {
        let source = DraftSource(12.0)
        let node = makeNode(TextField("Value", value: source.binding, format: format))
        let field = try field(node)
        for (index, token) in ["-", "", "not a number"].enumerated() {
            type(token, into: field)
            render(node, view: TextField("Value", value: source.binding, format: format), width: Double(319 - index))
            #expect(try self.field(node) === field)
            #expect(field.value == token)
            #expect(source.value == 12)
            #expect(source.writes == 0)
        }
    }

    @Test("A valid edit followed by an incomplete edit before layout retains the second token")
    func consecutiveNativeEdits() throws {
        let source = DraftSource(1.0)
        let node = makeNode(TextField("Value", value: source.binding, format: format))
        let field = try field(node)
        type("12.", into: field)
        type("-", into: field)
        render(node, width: 321)
        #expect(source.value == 12)
        #expect(source.writes == 1)
        #expect(field.value == "-")
    }

    @Test("An external value supersedes a draft even when rounding hides the value change")
    func externalChangesWin() throws {
        let source = DraftSource(12.1)
        let rounded = format.precision(.fractionLength(0))
        let node = makeNode(TextField("Value", value: source.binding, format: rounded))
        let field = try field(node)
        type("-", into: field)
        source.value = 12.2
        render(node, width: 319)
        #expect(field.value == rounded.format(source.value))
        #expect(source.writes == 0)

        type("12.20", into: field)
        #expect(source.value == 12.2)
        source.value = 12.3
        render(node, width: 318)
        #expect(field.value == rounded.format(source.value))
        #expect(field.value != "12.20")
        #expect(source.writes == 1)

        source.value = 19
        render(node, width: 317)
        #expect(field.value == "19")
        #expect(source.writes == 1)
    }

    @Test("A changed format reconciles the draft without changing the bound value")
    func formatChangesWin() throws {
        let source = DraftSource(12.0)
        let node = makeNode(TextField("Value", value: source.binding, format: format))
        let field = try field(node)
        type("12.", into: field)
        let precise = format.precision(.fractionLength(2))
        render(node, view: TextField("Value", value: source.binding, format: precise), width: 319)
        #expect(try self.field(node) === field)
        #expect(field.value == precise.format(source.value))
        #expect(source.value == 12)
        #expect(source.writes == 1)
    }

    @Test("Rejected and clamped parsed edits do not become authoritative native drafts")
    func setterReconciliation() throws {
        let source = DraftSource(5.0)
        let rejected = Binding<Double>(get: { source.value }, set: { _ in source.writes += 1 })
        let node = makeNode(TextField("Value", value: rejected, format: format))
        let field = try field(node)
        type("30", into: field)
        render(node, width: 319)
        #expect(field.value == "5")
        #expect(source.value == 5)
        let clamped = Binding<Double>(get: { source.value }, set: { source.value = min(10, $0); source.writes += 1 })
        render(node, view: TextField("Value", value: clamped, format: format), width: 318)
        type("30", into: field)
        render(node, width: 317)
        #expect(field.value == "10")
        #expect(source.value == 10)
        #expect(source.writes == 2)
    }

    @Test("A synchronous binding-triggered layout retains a valid token and subsequent incomplete edit")
    func synchronousSetterLayout() throws {
        let source = DraftSource(1.0)
        let view = TextField("Value", value: source.binding, format: format)
        let node = makeNode(view)
        let field = try field(node)
        source.onSet = { self.render(node, width: 321) }
        type("12.50", into: field)
        #expect(field.value == "12.50")
        #expect(source.value == 12.5)
        type("-", into: field)
        render(node, width: 322)
        #expect(field.value == "-")
        #expect(source.writes == 1)
        source.onSet = nil
    }

    @Test("Replacing a binding updates the same field and installs the latest edit destination")
    func latestBinding() throws {
        let first = DraftSource(1.0)
        let second = DraftSource(8.0)
        let node = makeNode(TextField("Value", value: first.binding, format: format))
        let field = try field(node)
        type("-", into: field)
        render(node, view: TextField("Value", value: second.binding, format: format), width: 319)
        #expect(try self.field(node) === field)
        #expect(field.value == "8")
        type("9.5", into: field)
        #expect(first.value == 1)
        #expect(first.writes == 0)
        #expect(second.value == 9.5)
        #expect(second.writes == 1)
    }

    @Test("Non-Equatable inputs conservatively retain the previous reconciliation behavior")
    func nonEquatableFallback() throws {
        let source = DraftSource(UncomparableNumber(number: 12))
        let node = makeNode(TextField("Value", value: source.binding, format: UncomparableFormat()))
        let field = try field(node)
        type("-", into: field)
        render(node, width: 319)
        #expect(field.value == "12")
        #expect(source.writes == 0)
        source.value.number = 19
        render(node, width: 318)
        #expect(field.value == "19")
        #expect(source.writes == 0)
    }

    @Test("String bindings continue to reconcile externally supplied text")
    func stringBindingControl() throws {
        let source = DraftSource("12")
        let node = makeNode(TextField("Value", text: source.binding))
        let field = try field(node)
        type("-", into: field)
        render(node, width: 319)
        #expect(field.value == "-")
        source.value = "replacement"
        render(node, width: 318)
        #expect(field.value == "replacement")
        #expect(source.writes == 1)
    }

    private func makeNode(_ view: TextField) -> ViewGraphNode<TextField, DummyBackend> {
        let node = ViewGraphNode(for: view, backend: backend, environment: environment)
        render(node, width: 320)
        return node
    }

    private func render(_ node: ViewGraphNode<TextField, DummyBackend>, view: TextField? = nil, width: Double) {
        _ = node.computeLayout(with: view, proposedSize: ProposedViewSize(width, 40), environment: environment)
        _ = node.commit()
    }

    private func field(_ node: ViewGraphNode<TextField, DummyBackend>) throws -> DummyBackend.TextField {
        try #require(node.widget.firstWidget(ofType: DummyBackend.TextField.self))
    }

    private func type(_ content: String, into field: DummyBackend.TextField) {
        field.value = content
        field.changeHandler?(content)
    }
}

@MainActor
private final class DraftSource<Value> {
    var value: Value
    var writes = 0
    var onSet: (() -> Void)?
    init(_ value: Value) { self.value = value }
    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0; self.writes += 1; self.onSet?() })
    }
}

private struct UncomparableNumber {
    var number: Int
}

private struct UncomparableFormat: ParseableFormatStyle {
    struct Strategy: ParseStrategy {
        enum Invalid: Error { case number }
        func parse(_ value: String) throws -> UncomparableNumber {
            guard let number = Int(value) else { throw Invalid.number }
            return UncomparableNumber(number: number)
        }
    }
    var parseStrategy: Strategy { Strategy() }
    func format(_ value: UncomparableNumber) -> String { String(value.number) }
}
