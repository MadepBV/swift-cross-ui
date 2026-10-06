import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Renders a view through a ``ViewGraph`` with ``DummyBackend``, the way an
/// app's window does, so that each render is a fresh layout pass.
@MainActor
final class GraphHarness<Content: View> {
    let backend = DummyBackend()
    let environment: EnvironmentValues
    let graph: ViewGraph<Content>
    private let makeView: () -> Content

    init(_ makeView: @escaping () -> Content) {
        environment = backend.computeRootEnvironment(
            defaultEnvironment: EnvironmentValues(backend: backend)
        ).with(\.window, backend.createWindow(withDefaultSize: nil, id: "test"))
        self.makeView = makeView
        graph = ViewGraph(for: makeView(), backend: backend, environment: environment)
    }

    /// Lays out and commits the view, recomputed from the test's state.
    ///
    /// Bars and destination registries update asynchronously in an app (their
    /// publishers schedule an update); rendering twice stands in for that.
    func render(passes: Int = 2) {
        for _ in 0..<passes {
            _ = graph.computeLayout(
                with: makeView(),
                proposedSize: ProposedViewSize(400, 300),
                environment: environment
            )
            graph.commit()
        }
    }

    var root: DummyBackend.Widget {
        graph.rootNode.concreteNode(for: DummyBackend.self).widget
    }

    var widgets: [DummyBackend.Widget] {
        func collect(_ widget: DummyBackend.Widget) -> [DummyBackend.Widget] {
            var result = [widget]
            if let button = widget as? DummyBackend.Button, let label = button.label {
                result += collect(label)
            }
            return result + widget.getChildren().flatMap(collect)
        }
        return collect(root)
    }

    /// Every text and button title, in tree order.
    var texts: [String] {
        widgets.compactMap { widget in
            if let text = widget as? DummyBackend.TextView { return text.content }
            if let button = widget as? DummyBackend.SimpleButton { return button.label }
            return nil
        }
    }

    /// Clicks the first button whose label contains the given text.
    func click(_ title: String) {
        for widget in widgets {
            guard let button = widget as? DummyBackend.Button,
                  let label = button.label
            else {
                continue
            }
            let labelTexts = [label].flatMap { collectTexts($0) }
            if labelTexts.contains(title) {
                button.action?()
                return
            }
        }
        for widget in widgets {
            if let button = widget as? DummyBackend.SimpleButton, button.label == title {
                button.action?()
                return
            }
        }
        Issue.record("No button titled \(title)")
    }

    private func collectTexts(_ widget: DummyBackend.Widget) -> [String] {
        var result: [String] = []
        if let text = widget as? DummyBackend.TextView { result.append(text.content) }
        for child in widget.getChildren() { result += collectTexts(child) }
        return result
    }

    /// The first widget of a type.
    func first<T: DummyBackend.Widget>(_ type: T.Type) -> T? {
        widgets.first { $0 is T } as? T
    }
}

/// A mutable box standing in for an app's `@State`.
final class StateBox<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
