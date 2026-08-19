import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

#if canImport(Observation)
    import Observation
#endif

// MARK: - Button(_:systemImage:)

@Suite("Testing for Button's title-and-image initialisers")
@MainActor
struct ButtonImageInitialiserTests {
    @Test("A system image button shows its title")
    func testSystemImageButtonShowsTitle() {
        let button = Button("Pick axis", systemImage: "scope") {}

        #expect(render(button).text == ["Pick axis"])
    }

    @Test("A system image button shows a symbol beside its title")
    func testSystemImageButtonShowsSymbol() {
        // The symbol has to occupy real space, otherwise the initialiser has
        // silently degraded into `Button(_:role:action:)` with extra
        // ceremony.
        let withSymbol = render(Button("Pick axis", systemImage: "scope") {})
        let withoutSymbol = render(Button("Pick axis") {})

        #expect(withSymbol.text == withoutSymbol.text)
        #expect(withSymbol.size.x > withoutSymbol.size.x)
    }

    @Test("A system image button honours labelStyle(_:)")
    func testSystemImageButtonHonoursLabelStyle() {
        let button = Button("Pick axis", systemImage: "scope") {}

        let iconOnly = render(button.labelStyle(.iconOnly))
        #expect(iconOnly.text.isEmpty)
        #expect(iconOnly.size.x > 0)
        #expect(iconOnly.size.y > 0)

        #expect(render(button.labelStyle(.titleOnly)).text == ["Pick axis"])
    }

    @Test("A system image button's trailing closure is its action")
    func testSystemImageButtonActionRuns() {
        let recorder = ActionRecorder()
        let button = Button("Pick axis", systemImage: "scope") {
            recorder.count += 1
        }

        let rendered = render(button)
        #expect(rendered.buttons.count == 1)
        rendered.buttons.first?.action?()

        #expect(recorder.count == 1)
    }

    @Test("A system image button keeps its role")
    func testSystemImageButtonKeepsRole() {
        let plain = Button("Pick axis", systemImage: "scope") {}
        #expect(plain.role == nil)

        let destructive = Button(
            "Delete",
            systemImage: "trash",
            role: .destructive
        ) {}
        #expect(destructive.role == .destructive)

        let cancel = Button("Cancel", systemImage: "xmark", role: .cancel) {}
        #expect(cancel.role == .cancel)
    }

    @Test("A system image button resolves the symbol its call sites use")
    func testSystemImageNamesResolve() {
        // The exact names the application's inspector asks for. A name the
        // provider doesn't know renders a placeholder rather than failing, so
        // this is checked directly rather than through the rendered widget.
        for name in ["scope", "viewfinder", "square.grid.3x3.square"] {
            #expect(
                LucideSymbolProvider.lucideIcon(forSystemName: name) != nil,
                "\(name) should map to a real Lucide icon"
            )
        }
    }

    @Test("An image resource button falls back to its title")
    func testImageResourceButtonShowsTitle() {
        // There's no asset catalog, so the icon can't resolve and the title
        // has to keep showing no matter which label style is in effect.
        let button = Button("Pick axis", image: "PickAxisIcon") {}

        #expect(render(button).text == ["Pick axis"])
        #expect(render(button.labelStyle(.iconOnly)).text == ["Pick axis"])
        #expect(render(button.labelStyle(.titleOnly)).text == ["Pick axis"])
    }

    @Test("An image resource button's trailing closure is its action")
    func testImageResourceButtonActionRuns() {
        let recorder = ActionRecorder()
        let button = Button("Pick axis", image: "PickAxisIcon") {
            recorder.count += 1
        }

        let rendered = render(button)
        rendered.buttons.first?.action?()

        #expect(recorder.count == 1)
    }

    @Test("A system image button keeps its action inside a menu")
    func testSystemImageButtonSurvivesAsMenuItem() {
        // Menus can't show an icon, so the button has to come back as a text
        // menu item — but one that still runs. Arriving as a bare piece of
        // text would leave a menu command that looks right and does nothing.
        let recorder = ActionRecorder()
        let button = Button("Pick axis", systemImage: "scope", role: .cancel) {
            recorder.count += 1
        }

        let items = button._asMenuItems
        #expect(items.count == 1)

        guard case .button(let menuButton) = items.first else {
            Issue.record("Expected a button menu item, got \(items)")
            return
        }
        #expect(menuButton.title == "Pick axis")
        #expect(menuButton.role == .cancel)

        menuButton.action()
        #expect(recorder.count == 1)
    }

    @Test("An image resource button keeps its action inside a menu")
    func testImageResourceButtonSurvivesAsMenuItem() {
        let recorder = ActionRecorder()
        let button = Button("Pick axis", image: "PickAxisIcon") {
            recorder.count += 1
        }

        guard case .button(let menuButton) = button._asMenuItems.first else {
            Issue.record("Expected a button menu item")
            return
        }
        #expect(menuButton.title == "Pick axis")

        menuButton.action()
        #expect(recorder.count == 1)
    }

    @Test("Other custom-label buttons keep their old menu representation")
    func testCustomLabelButtonMenuRepresentationIsUnchanged() {
        // The menu rebuild is deliberately limited to the two new
        // initialisers, so a button whose label is any other view keeps
        // arriving exactly as it did before. A view-builder label is the
        // sharpest control available: it wraps the very same ``Label`` in a
        // ``TupleView1``, which is a different type, so the rebuild has to
        // leave it alone.
        let button = Button {
            // Never runs; menus can't represent this button's action.
        } label: {
            Label("Title", systemImage: "trash")
        }

        let items = button._asMenuItems
        #expect(items.count == 1)
        guard case .text(let text) = items.first else {
            Issue.record("Expected a text menu item, got \(items)")
            return
        }
        #expect(text.string == "Title")
    }

    @Test("The pre-existing Button spellings still resolve")
    func testExistingSpellingsAreUnambiguous() {
        // The new initialisers sit beside initialisers with defaulted `role:`
        // parameters, which is exactly the shape that makes overloads
        // ambiguous. Every existing spelling has to keep picking the same
        // initialiser it always did.
        let recorder = ActionRecorder()

        let title = Button("Title") { recorder.count += 1 }
        #expect(title.title == "Title")
        #expect(title.role == nil)

        let roled = Button("Title", role: .destructive) { recorder.count += 1 }
        #expect(roled.title == "Title")
        #expect(roled.role == .destructive)

        let custom = Button {
            recorder.count += 1
        } label: {
            Text("Title")
        }
        #expect(render(custom).text == ["Title"])

        let roledCustom = Button(role: .cancel) {
            recorder.count += 1
        } label: {
            Text("Title")
        }
        #expect(roledCustom.role == .cancel)

        // A label-less button is still a valid, action-less button.
        let empty = Button("Title")
        #expect(empty.title == "Title")
    }
}

/// The outcome of rendering a view with a ``DummyBackend``.
private struct ButtonRenderResult {
    /// The content of every rendered text view, in breadth-first order.
    var text: [String]
    /// The size that the view laid out at.
    var size: SIMD2<Int>
    /// Every rendered button widget, in breadth-first order.
    var buttons: [DummyBackend.Button]
}

/// Renders `view` with a ``DummyBackend`` and reports what it produced.
///
/// - Parameter view: The view to render.
/// - Returns: The rendered text, the view's laid out size, and its buttons.
@MainActor
private func render<Content: View>(_ view: Content) -> ButtonRenderResult {
    let backend = DummyBackend()
    let window = backend.createWindow(withDefaultSize: nil, id: "window")
    let environment = EnvironmentValues(backend: backend).with(\.window, window)

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

    let widgets = widgets(in: node.widget)
    return ButtonRenderResult(
        text: widgets.compactMap { widget in
            (widget as? DummyBackend.TextView)?.content
        },
        size: layout.size.vector,
        buttons: widgets.compactMap { widget in
            widget as? DummyBackend.Button
        }
    )
}

/// Collects a widget and all of its descendants, in breadth-first order.
///
/// ``DummyBackend/Button`` doesn't report its label through `getChildren()`,
/// so the label is walked explicitly. Without that, a button's title would be
/// invisible to these tests.
///
/// - Parameter root: The root of the hierarchy to walk.
/// - Returns: The widgets, in breadth-first order.
private func widgets(in root: DummyBackend.Widget) -> [DummyBackend.Widget] {
    var collected: [DummyBackend.Widget] = []
    var queue = [root]
    while let next = queue.first {
        queue.removeFirst()
        collected.append(next)

        var children = next.getChildren()
        if let button = next as? DummyBackend.Button, let label = button.label {
            children.append(label)
        }
        queue.append(contentsOf: children)
    }
    return collected
}

// MARK: - @Environment(SomeType.self)

// Like `ObservationTests`, these go through a real backend. The whole point of
// the change under test is that a model read out of the environment keeps
// redrawing the views that read it, and a tracking flag can't tell the
// difference between that and a view which lays out perfectly but never
// updates again.
#if canImport(AppKitBackend) && canImport(Observation)

    // MARK: Models

    /// A second `@Observable` model, so that a view can hold two distinct
    /// objects in the environment at once.
    ///
    /// Objects are keyed by their exact type, so proving that two types
    /// coexist needs two types.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Observable
    final class ObservedPreferences {
        /// The value displayed by the environment tests.
        var language: String

        /// Creates preferences.
        ///
        /// - Parameter language: The initial language.
        init(language: String) {
            self.language = language
        }
    }

    // MARK: Views

    /// Reads an `@Observable` model out of the environment and displays it.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct EnvironmentObservableReader: View {
        /// The model, read back by its exact type.
        @Environment(ObservedModel.self) private var model

        /// The counts to record body evaluations in.
        let counts: BodyEvaluationCounts
        /// The name to record body evaluations under.
        let name: String

        var body: some View {
            Text(counts.record(name, returning: model.title))
        }
    }

    /// Reads an `@Observable` model out of the environment but displays a
    /// property that never changes.
    ///
    /// Used as a sibling of ``EnvironmentObservableReader`` to check that
    /// putting an object in the environment doesn't make every reader
    /// invalidate on every mutation.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct EnvironmentObservableNoteReader: View {
        /// The model, read back by its exact type.
        @Environment(ObservedModel.self) private var model

        /// The counts to record body evaluations in.
        let counts: BodyEvaluationCounts
        /// The name to record body evaluations under.
        let name: String

        var body: some View {
            Text(counts.record(name, returning: model.unreadNote))
        }
    }

    /// Puts an `@Observable` model in the environment and reads it back
    /// further down the view tree.
    ///
    /// The model is deliberately read from a grandchild, so the value has to
    /// travel through an intermediate view rather than being handed straight
    /// back to the view that supplied it.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct EnvironmentObservableRoot: View {
        /// The model to place in the environment.
        let model: ObservedModel
        /// The counts to record body evaluations in.
        let counts: BodyEvaluationCounts

        var body: some View {
            VStack {
                EnvironmentObservableReader(counts: counts, name: "title")
                    .frame(width: 200, height: 20)
                EnvironmentObservableNoteReader(counts: counts, name: "note")
                    .frame(width: 200, height: 20)
            }
            .environment(model)
        }
    }

    /// Reads two differently-typed `@Observable` objects out of the
    /// environment.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct EnvironmentTwoObjectReader: View {
        /// The first object.
        @Environment(ObservedModel.self) private var model
        /// The second object.
        @Environment(ObservedPreferences.self) private var preferences

        var body: some View {
            VStack {
                Text(model.title)
                Text(preferences.language)
            }
        }
    }

    /// Puts two differently-typed `@Observable` objects in the environment.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct EnvironmentTwoObjectRoot: View {
        /// The first object.
        let model: ObservedModel
        /// The second object.
        let preferences: ObservedPreferences

        var body: some View {
            EnvironmentTwoObjectReader()
                .environment(model)
                .environment(preferences)
        }
    }

    /// Reads a SwiftCrossUI ``ObservableObject`` out of the environment.
    struct EnvironmentPublishedReader: View {
        /// The model, read back by its exact type.
        @Environment(PublishedModel.self) private var model

        var body: some View {
            Text(model.value)
        }
    }

    /// Owns a SwiftCrossUI ``ObservableObject`` and puts it in the
    /// environment.
    ///
    /// ``View/environment(_:)`` performs no observation, so the object is held
    /// in ``State`` here, which is what makes its changes propagate. This is
    /// the arrangement that worked before `@Observable` objects were allowed
    /// in the environment, and it has to keep working unchanged.
    struct EnvironmentPublishedRoot: View {
        /// The model, owned by this view.
        @State var model: PublishedModel

        var body: some View {
            EnvironmentPublishedReader()
                .environment(model)
        }
    }

    // MARK: Tests

    @Suite("Testing for object-typed @Environment")
    struct EnvironmentObservableTests {
        @Test("An @Observable object can be read out of the environment")
        @MainActor
        func testObservableObjectIsReadable() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before", unreadNote: "note")
            let harness = ObservationHarness(
                EnvironmentObservableRoot(
                    model: model,
                    counts: BodyEvaluationCounts()
                )
            )

            #expect(harness.renderedStrings == ["before", "note"])
        }

        @Test("Mutating an environment-held @Observable object redraws")
        @MainActor
        func testObservableMutationRedrawsEnvironmentReader() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before", unreadNote: "note")
            let counts = BodyEvaluationCounts()
            let harness = ObservationHarness(
                EnvironmentObservableRoot(model: model, counts: counts)
            )

            #expect(harness.renderedStrings == ["before", "note"])
            let initialTitleCount = counts.count("title")
            let initialNoteCount = counts.count("note")
            #expect(initialTitleCount > 0)
            #expect(initialNoteCount > 0)

            // Nothing below asks the view graph to re-render. A version of
            // this that merely compiled would leave the widget showing
            // "before" forever.
            model.title = "after"
            await waitForUpdate {
                harness.renderedStrings == ["after", "note"]
            }

            #expect(
                harness.renderedStrings == ["after", "note"],
                "Expected the environment reader's widget to pick up the mutation"
            )
            #expect(
                counts.count("title") > initialTitleCount,
                "Expected the reader's body to be re-evaluated"
            )
            #expect(
                counts.count("note") == initialNoteCount,
                "Expected the sibling reading only 'unreadNote' to be left alone"
            )
        }

        @Test("Repeated mutations keep redrawing an environment reader")
        @MainActor
        func testEnvironmentTrackingIsReinstalled() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            // `Observation`'s change handlers fire at most once, so a reader
            // that stopped re-registering would pass the first assertion and
            // then silently freeze.
            let model = ObservedModel(title: "0", unreadNote: "note")
            let harness = ObservationHarness(
                EnvironmentObservableRoot(
                    model: model,
                    counts: BodyEvaluationCounts()
                )
            )

            for index in 1...5 {
                model.title = "\(index)"
                await waitForUpdate {
                    harness.renderedStrings == ["\(index)", "note"]
                }
                #expect(
                    harness.renderedStrings == ["\(index)", "note"],
                    "Expected redraw number \(index) to happen"
                )
            }
        }

        @Test("Objects in the environment are keyed by their exact type")
        @MainActor
        func testTwoObjectTypesCoexist() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "title-before")
            let preferences = ObservedPreferences(language: "en")
            let harness = ObservationHarness(
                EnvironmentTwoObjectRoot(
                    model: model,
                    preferences: preferences
                )
            )

            #expect(harness.renderedStrings == ["title-before", "en"])

            preferences.language = "nl"
            await waitForUpdate {
                harness.renderedStrings == ["title-before", "nl"]
            }
            #expect(harness.renderedStrings == ["title-before", "nl"])

            model.title = "title-after"
            await waitForUpdate {
                harness.renderedStrings == ["title-after", "nl"]
            }
            #expect(harness.renderedStrings == ["title-after", "nl"])
        }

        @Test("A SwiftCrossUI ObservableObject still works in the environment")
        @MainActor
        func testObservableObjectEnvironmentPathStillWorks() async {
            let model = PublishedModel()
            let harness = ObservationHarness(
                EnvironmentPublishedRoot(model: model)
            )

            #expect(harness.renderedStrings == ["published"])

            model.value = "published-after"
            await waitForUpdate {
                harness.renderedStrings == ["published-after"]
            }
            #expect(
                harness.renderedStrings == ["published-after"],
                "Expected the pre-existing ObservableObject path to still work"
            )
        }

        @Test("EnvironmentValues stores objects under their exact type")
        @MainActor
        func testEnvironmentValuesSubscript() {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let backend = DummyBackend()
            var environment = EnvironmentValues(backend: backend)

            #expect(environment[observable: ObservedModel.self] == nil)
            #expect(environment[observable: PublishedModel.self] == nil)

            let model = ObservedModel(title: "stored")
            let published = PublishedModel()
            environment[observable: ObservedModel.self] = model
            environment[observable: PublishedModel.self] = published

            #expect(environment[observable: ObservedModel.self] === model)
            #expect(environment[observable: PublishedModel.self] === published)

            environment[observable: ObservedModel.self] = nil
            #expect(environment[observable: ObservedModel.self] == nil)
            #expect(
                environment[observable: PublishedModel.self] === published,
                "Expected clearing one object to leave the others alone"
            )
        }
    }
#endif
