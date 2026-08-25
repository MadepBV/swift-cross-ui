import Foundation
import Testing

@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

#if canImport(Observation)
    import Observation
#endif

// These tests deliberately go through a real backend rather than
// `DummyBackend`. The failure mode that `Observation` support exists to
// prevent is a view that lays out and renders perfectly but never redraws, so
// the assertions have to be made against what the backend actually put on
// screen, not against whether a tracking closure fired.
#if canImport(AppKitBackend) && canImport(Observation)

    // MARK: - Models

    // NB: Every model below is declared with the standard library's
    // `@Observable`, in a file that also imports SwiftCrossUI. That is itself
    // a regression test. These models used to spell out the macro's expansion
    // by hand, because SwiftCrossUI declared a macro named
    // `ObservationIgnored` and so did `Observation`, which made
    // `@Observable`'s expansion fail with 'ambiguous use of
    // ObservationIgnored()' in any file that imported both modules
    // (qualifying the macro as `@Observation.Observable` didn't help, because
    // the ambiguity was in the expanded code). SwiftCrossUI's macro is now
    // called `ObservableObjectIgnored`, so the standard library's macro can be
    // used normally and these declarations compile.
    //
    // The generated code is what's under test either way: `access(_:keyPath:)`
    // on read and `withMutation(of:keyPath:)` on write is the entire contract
    // between `@Observable` and `withObservationTracking(_:onChange:)`.

    /// A model with one property that test views read and one that they don't.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Observable
    final class ObservedModel {
        /// A property that the test views read from their bodies.
        var title: String

        /// A property that no test view ever reads.
        var unreadNote: String

        /// Creates a model.
        ///
        /// - Parameters:
        ///   - title: The initial title.
        ///   - unreadNote: The initial note.
        init(title: String = "initial", unreadNote: String = "note") {
            self.title = title
            self.unreadNote = unreadNote
        }
    }

    /// The inner object of a nested observable model.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Observable
    final class ObservedInnerModel {
        /// The value displayed by the nested model tests.
        var value: String

        /// Creates an inner model.
        ///
        /// - Parameter value: The initial value.
        init(value: String) {
            self.value = value
        }
    }

    /// A model whose interesting state lives in a nested observable object.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Observable
    final class ObservedOuterModel {
        /// The nested object.
        var inner: ObservedInnerModel

        /// Creates an outer model.
        ///
        /// - Parameter inner: The initial inner object.
        init(inner: ObservedInnerModel) {
            self.inner = inner
        }
    }

    /// A model that mixes tracked storage with storage explicitly opted out of
    /// tracking using `Observation`'s own `@ObservationIgnored`.
    ///
    /// Declaring this at all is the sharpest form of the regression test: the
    /// opt-out marker is the exact name that SwiftCrossUI used to squat, so
    /// this type could not be written in a file importing both modules until
    /// SwiftCrossUI's macro was renamed.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    @Observable
    final class OptOutModel {
        /// A tracked property that a test view reads.
        var tracked: String

        /// An untracked property that the same view reads.
        ///
        /// Mutating it must not redraw anything, because `@ObservationIgnored`
        /// keeps it out of the registrar entirely.
        @ObservationIgnored var untracked: String

        /// Creates a model.
        ///
        /// - Parameters:
        ///   - tracked: The initial tracked value.
        ///   - untracked: The initial untracked value.
        init(tracked: String = "tracked", untracked: String = "untracked") {
            self.tracked = tracked
            self.untracked = untracked
        }
    }

    /// A model declared with SwiftCrossUI's ``ObservableObject()`` macro, one
    /// of whose properties opts out with ``ObservableObjectIgnored()``.
    ///
    /// Its coexistence with the `@Observable` models above is what proves the
    /// two opt-out markers no longer collide.
    @SwiftCrossUI.ObservableObject
    class MacroGeneratedModel {
        /// A property the macro wraps in ``Published``.
        var value = "macro"

        /// A property the macro leaves alone.
        @SwiftCrossUI.ObservableObjectIgnored
        var ignored = "ignored"
    }

    /// A model using SwiftCrossUI's own observation mechanism, used to check
    /// that the pre-existing path still works alongside `Observation`.
    final class PublishedModel: SwiftCrossUI.ObservableObject {
        /// The value displayed by the mixed-mechanism test.
        @SwiftCrossUI.Published
        var value = "published"
    }

    /// Counts how many times each test view's body has been evaluated.
    @MainActor
    final class BodyEvaluationCounts {
        /// The counts, keyed by an arbitrary name chosen by the test.
        private var counts: [String: Int] = [:]

        /// Creates an empty set of counts.
        init() {}

        /// Records one body evaluation and passes a value straight through.
        ///
        /// The pass-through exists so that test views can count their body
        /// evaluations from inside a `@ViewBuilder` body. Writing the count as
        /// a separate statement would need an explicit `return`, which
        /// disables the builder transform and leaves the view with no
        /// children at all.
        ///
        /// - Parameters:
        ///   - name: The name of the view that was evaluated.
        ///   - value: The value to pass through.
        /// - Returns: `value`, unchanged.
        func record(_ name: String, returning value: String) -> String {
            counts[name, default: 0] += 1
            return value
        }

        /// The number of times a view's body has been evaluated.
        ///
        /// - Parameter name: The name of the view.
        /// - Returns: The evaluation count.
        func count(_ name: String) -> Int {
            counts[name] ?? 0
        }
    }

    // MARK: - Views

    /// Displays a model's title, recording each body evaluation.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct TitleView: View {
        /// The model to display.
        let model: ObservedModel
        /// The counts to record body evaluations in.
        let counts: BodyEvaluationCounts
        /// The name to record body evaluations under.
        let name: String

        var body: some View {
            Text(counts.record(name, returning: model.title))
        }
    }

    /// Displays a model's unread note, recording each body evaluation.
    ///
    /// Used as a sibling of ``TitleView`` to check that a mutation only
    /// invalidates the views that read the mutated property.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct NoteView: View {
        /// The model to display.
        let model: ObservedModel
        /// The counts to record body evaluations in.
        let counts: BodyEvaluationCounts
        /// The name to record body evaluations under.
        let name: String

        var body: some View {
            Text(counts.record(name, returning: model.unreadNote))
        }
    }

    /// Displays a nested observable model's inner value.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct NestedModelView: View {
        /// The outer model to display.
        let model: ObservedOuterModel

        var body: some View {
            Text(model.inner.value)
        }
    }

    /// Edits a model's title through a `@Bindable` projection.
    ///
    /// The body never reads `model.title` itself; it only forms a binding to
    /// it. Redraws therefore have to come from the text field's own tracking.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct BindableFieldView: View {
        /// The model to edit.
        @Bindable private var model: ObservedModel

        /// Creates the view.
        ///
        /// The wrapped value is assigned directly, which is how views written
        /// for SwiftUI initialise their `@Bindable` properties.
        ///
        /// - Parameter model: The model to edit.
        init(model: ObservedModel) {
            self.model = model
        }

        var body: some View {
            TextField("Title", text: $model.title)
        }
    }

    /// Holds an `@Observable` model in ``State`` and displays its title.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct StateOwnedModelView: View {
        /// The model, owned by the view.
        @State var model: ObservedModel

        var body: some View {
            Text(model.title)
        }
    }

    /// Displays values from both an `@Observable` object and an
    /// ``ObservableObject``, so that both invalidation paths are exercised by
    /// a single view.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct MixedMechanismView: View {
        /// The `@Observable` model.
        let observed: ObservedModel
        /// The ``ObservableObject`` model.
        @State var published: PublishedModel

        var body: some View {
            VStack {
                Text(observed.title)
                Text(published.value)
            }
        }
    }

    /// Displays both properties of an ``OptOutModel``.
    ///
    /// Reading both means the difference between them can only come from
    /// `@ObservationIgnored`, not from what the body happened to touch.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct OptOutView: View {
        /// The model to display.
        let model: OptOutModel

        var body: some View {
            VStack {
                Text(model.tracked)
                Text(model.untracked)
            }
        }
    }

    /// Displays both properties of a ``MacroGeneratedModel``.
    struct MacroGeneratedModelView: View {
        /// The model to display.
        @State var model: MacroGeneratedModel

        var body: some View {
            VStack {
                Text(model.value)
                Text(model.ignored)
            }
        }
    }

    /// Carries a value across a concurrency boundary in tests where the value's
    /// thread safety is guaranteed by the test's own structure.
    struct UncheckedSendableBox<Value>: @unchecked Sendable {
        /// The carried value.
        let value: Value

        /// Wraps a value.
        ///
        /// - Parameter value: The value to carry.
        init(_ value: Value) {
            self.value = value
        }
    }

    // MARK: - Harness

    /// Renders a view with ``AppKitBackend`` into a real window and then lets
    /// the view graph drive its own updates, exactly as a window would.
    ///
    /// Crucially, nothing in this harness re-renders in response to a model
    /// mutation. Every redraw asserted by these tests is one that the view
    /// graph decided to perform on its own.
    @MainActor
    final class ObservationHarness<Content: View> {
        /// The size proposed to the rendered view.
        static var proposal: ProposedViewSize { ProposedViewSize(400, 300) }

        /// The backend rendering the view.
        let backend: AppKitBackend
        /// The window the view lives in.
        let window: NSCustomWindow

        /// The view's node in the view graph.
        private let node: ViewGraphNode<Content, AppKitBackend>
        /// The environment the view is rendered with.
        private var environment: EnvironmentValues

        /// Renders a view for the first time.
        ///
        /// - Parameter view: The view to render.
        init(_ view: Content) {
            backend = AppKitBackend()
            window = backend.createWindow(
                withDefaultSize: SIMD2(400, 300),
                id: "window"
            )
            let baseEnvironment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            node = ViewGraphNode(
                for: view,
                backend: backend,
                environment: baseEnvironment
            )
            backend.setChild(ofWindow: window, to: node.widget)

            // `environment` has to hold something before `self` can be
            // captured by the resize handler below.
            environment = baseEnvironment
            // Mirrors what a window does: when the root view's size changes,
            // lay it out again and commit the result.
            environment = baseEnvironment.with(\.onResize) { [weak self] _ in
                self?.render()
            }
            render()
        }

        /// Every string currently displayed by the rendered widgets.
        var renderedStrings: [String] {
            Self.strings(in: node.widget)
        }

        /// Recomputes and commits the view's layout.
        func render() {
            _ = node.computeLayout(
                proposedSize: Self.proposal,
                environment: environment
            )
            _ = node.commit()
        }

        /// Collects the strings displayed by a view and its descendants.
        ///
        /// - Parameter view: The view to search.
        /// - Returns: The strings, in tree order.
        static func strings(in view: NSView) -> [String] {
            var collected: [String] = []
            if let field = view as? NSTextField {
                collected.append(field.stringValue)
            }
            for subview in view.subviews {
                collected += strings(in: subview)
            }
            return collected
        }
    }

    /// Lets the view graph's scheduled updates run until a condition holds.
    ///
    /// Observation-driven updates are always hopped onto the backend's main
    /// thread, so they can't have happened by the time a mutation returns.
    ///
    /// - Parameters:
    ///   - timeout: How long to wait before giving up, in seconds.
    ///   - condition: The condition to wait for.
    @MainActor
    func waitForUpdate(
        timeout: Double = 2,
        until condition: () -> Bool
    ) async {
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        while ProcessInfo.processInfo.systemUptime < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 2_000_000)
        }
    }

    /// Gives any scheduled view graph update ample time to run.
    ///
    /// Used by the tests that assert that an update *doesn't* happen.
    @MainActor
    func settle() async {
        for _ in 0..<100 {
            try? await Task.sleep(nanoseconds: 2_000_000)
        }
    }

    // MARK: - Tests

    /// Records what `onChange` handlers were given, in order.
    @MainActor
    final class ChangeLog {
        private(set) var entries: [String] = []

        init() {}

        func record(_ entry: String) {
            entries.append(entry)
        }
    }

    /// A view whose body is an `onChange` modifier and nothing else.
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    struct ChangeReportingView: View {
        let model: ObservedModel
        let log: ChangeLog

        var body: some View {
            Text(model.title)
                .onChange(of: model.title) { oldValue, newValue in
                    log.record("\(oldValue)->\(newValue)")
                }
        }
    }

    @Suite("Observation-related tests")
    struct ObservationTests {
        @Test("A value read only inside a GeometryReader still drives redraws")
        @MainActor
        func testGeometryReaderContentIsObserved() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let harness = ObservationHarness(
                GeometryReader { _ in
                    Text(model.title)
                }
            )

            #expect(harness.renderedStrings == ["before"])

            model.title = "after"
            await waitForUpdate { harness.renderedStrings == ["after"] }

            #expect(
                harness.renderedStrings == ["after"],
                "Expected a read inside the GeometryReader closure to be tracked"
            )
        }

        @Test("onChange below a GeometryReader fires with the old and new values")
        @MainActor
        func testOnChangeBelowGeometryReaderFires() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let log = ChangeLog()
            let harness = ObservationHarness(
                GeometryReader { _ in
                    Text(model.title)
                        .onChange(of: model.title) { oldValue, newValue in
                            log.record("\(oldValue)->\(newValue)")
                        }
                }
            )

            #expect(log.entries.isEmpty, "onChange must not fire on the first update")

            model.title = "after"
            await waitForUpdate { !log.entries.isEmpty }
            #expect(log.entries == ["before->after"])

            // Further commits without a change stay quiet, and a change fires
            // exactly once with the values from either side of it.
            harness.render()
            #expect(log.entries == ["before->after"])

            model.title = "later"
            await waitForUpdate { log.entries.count == 2 }
            #expect(log.entries == ["before->after", "after->later"])
        }

        @Test("onChange at the root of a window's content fires on a change")
        @MainActor
        func testOnChangeAtWindowRootFires() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            // The content closure of a WindowGroup runs outside any view
            // graph node, so what it reads has to be observed by the scene.
            let model = ObservedModel(title: "before")
            let log = ChangeLog()
            let backend = AppKitBackend()
            let environment = EnvironmentValues(backend: backend)
            let scene = WindowGroup("Window") {
                Text(model.title)
                    .onChange(of: model.title) { oldValue, newValue in
                        log.record("\(oldValue)->\(newValue)")
                    }
            }
            let reference = WindowReference(
                scene: scene,
                backend: backend,
                environment: environment,
                onClose: {},
                id: "onchange-window-root"
            )
            reference.update(nil, backend: backend, environment: environment)
            let window = reference.window as! NSWindow
            #expect(log.entries.isEmpty)
            #expect(ObservationHarness<EmptyView>.strings(in: window.contentView!) == ["before"])

            model.title = "after"
            await waitForUpdate { !log.entries.isEmpty }
            #expect(log.entries == ["before->after"])
            #expect(ObservationHarness<EmptyView>.strings(in: window.contentView!) == ["after"])
            window.close()
        }

        @Test("onChange at the root of a view's body fires on a change")
        @MainActor
        func testOnChangeAtBodyRootFires() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let log = ChangeLog()
            let harness = ObservationHarness(
                VStack {
                    Text("header")
                    ChangeReportingView(model: model, log: log)
                }
            )
            #expect(log.entries.isEmpty)

            model.title = "after"
            await waitForUpdate { !log.entries.isEmpty }
            #expect(log.entries == ["before->after"])

            model.title = "later"
            await waitForUpdate { log.entries.count == 2 }
            #expect(log.entries == ["before->after", "after->later"])
            #expect(harness.renderedStrings == ["header", "later"])
        }

        @Test("onChange(initial:) runs once with the current value on both sides")
        @MainActor
        func testOnChangeInitialRunsOnce() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "start")
            let log = ChangeLog()
            let harness = ObservationHarness(
                Text(model.title)
                    .onChange(of: model.title, initial: true) { oldValue, newValue in
                        log.record("\(oldValue)->\(newValue)")
                    }
            )

            #expect(log.entries == ["start->start"])
            harness.render()
            #expect(log.entries == ["start->start"])
        }

        @Test("Mutating an observed property redraws the view that read it")
        @MainActor
        func testObservedMutationRedrawsView() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let counts = BodyEvaluationCounts()
            let harness = ObservationHarness(
                TitleView(model: model, counts: counts, name: "title")
            )

            #expect(harness.renderedStrings == ["before"])
            let initialCount = counts.count("title")
            #expect(initialCount > 0)

            // Nothing below asks the view graph to re-render. If observation
            // isn't wired up, the widget keeps showing "before" forever.
            model.title = "after"
            await waitForUpdate { harness.renderedStrings == ["after"] }

            #expect(
                harness.renderedStrings == ["after"],
                "Expected the rendered widget to pick up the mutation"
            )
            #expect(
                counts.count("title") > initialCount,
                "Expected the view's body to be re-evaluated"
            )
        }

        @Test("Mutating a property the view didn't read doesn't redraw it")
        @MainActor
        func testUnreadMutationDoesNotRedrawView() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let counts = BodyEvaluationCounts()
            let harness = ObservationHarness(
                TitleView(model: model, counts: counts, name: "title")
            )

            let initialCount = counts.count("title")
            model.unreadNote = "changed"
            await settle()

            #expect(
                counts.count("title") == initialCount,
                "Expected an unread property's mutation not to re-evaluate body"
            )
            #expect(harness.renderedStrings == ["before"])
        }

        @Test("Only the views that read a property get invalidated")
        @MainActor
        func testInvalidationIsPerViewGraphNode() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before", unreadNote: "note")
            let counts = BodyEvaluationCounts()
            // The fixed frames stop a change in one view's size from asking
            // its parent to re-lay-out, which would re-evaluate the sibling's
            // body for layout reasons that have nothing to do with
            // observation.
            let harness = ObservationHarness(
                VStack {
                    TitleView(model: model, counts: counts, name: "title")
                        .frame(width: 200, height: 20)
                    NoteView(model: model, counts: counts, name: "note")
                        .frame(width: 200, height: 20)
                }
            )

            let initialTitleCount = counts.count("title")
            let initialNoteCount = counts.count("note")
            #expect(initialTitleCount > 0)
            #expect(initialNoteCount > 0)

            model.title = "after"
            await waitForUpdate {
                harness.renderedStrings == ["after", "note"]
            }

            #expect(harness.renderedStrings == ["after", "note"])
            #expect(
                counts.count("title") > initialTitleCount,
                "Expected the view reading 'title' to be re-evaluated"
            )
            #expect(
                counts.count("note") == initialNoteCount,
                "Expected the sibling reading only 'unreadNote' to be left alone"
            )
        }

        @Test("Mutating a nested observable object redraws the view")
        @MainActor
        func testNestedObservableMutationRedrawsView() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let inner = ObservedInnerModel(value: "inner-before")
            let model = ObservedOuterModel(inner: inner)
            let harness = ObservationHarness(NestedModelView(model: model))

            #expect(harness.renderedStrings == ["inner-before"])

            // A change to the nested object's property.
            model.inner.value = "inner-after"
            await waitForUpdate {
                harness.renderedStrings == ["inner-after"]
            }
            #expect(harness.renderedStrings == ["inner-after"])

            // A change that replaces the nested object entirely.
            model.inner = ObservedInnerModel(value: "replaced")
            await waitForUpdate { harness.renderedStrings == ["replaced"] }
            #expect(harness.renderedStrings == ["replaced"])

            // And the replacement object is observed just like the original.
            model.inner.value = "replaced-again"
            await waitForUpdate {
                harness.renderedStrings == ["replaced-again"]
            }
            #expect(harness.renderedStrings == ["replaced-again"])
        }

        @Test("Writing through a @Bindable binding writes back and redraws")
        @MainActor
        func testBindableWriteBackRedrawsView() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let harness = ObservationHarness(BindableFieldView(model: model))

            #expect(harness.renderedStrings == ["before"])

            // Exactly the binding the view's `$model.title` hands to its text
            // field, driven from the test instead of from a keystroke.
            let binding = Bindable(model).title
            #expect(binding.wrappedValue == "before")

            binding.wrappedValue = "after"
            #expect(
                model.title == "after",
                "Expected the binding to write back into the model"
            )

            await waitForUpdate { harness.renderedStrings == ["after"] }
            #expect(
                harness.renderedStrings == ["after"],
                "Expected the write-back to redraw the bound text field"
            )
        }

        @Test("An @Observable object held in @State drives redraws")
        @MainActor
        func testStateOwnedObservableModelRedrawsView() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let harness = ObservationHarness(StateOwnedModelView(model: model))

            #expect(harness.renderedStrings == ["before"])

            model.title = "after"
            await waitForUpdate { harness.renderedStrings == ["after"] }
            #expect(harness.renderedStrings == ["after"])
        }

        @Test("ObservableObject and @Observable both invalidate the same view")
        @MainActor
        func testObservableObjectPathStillWorks() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let observed = ObservedModel(title: "observed-before")
            let published = PublishedModel()
            let harness = ObservationHarness(
                MixedMechanismView(observed: observed, published: published)
            )

            #expect(
                harness.renderedStrings == ["observed-before", "published"]
            )

            published.value = "published-after"
            await waitForUpdate {
                harness.renderedStrings == ["observed-before", "published-after"]
            }
            #expect(
                harness.renderedStrings == ["observed-before", "published-after"],
                "Expected the pre-existing ObservableObject path to still work"
            )

            observed.title = "observed-after"
            await waitForUpdate {
                harness.renderedStrings == ["observed-after", "published-after"]
            }
            #expect(
                harness.renderedStrings == ["observed-after", "published-after"]
            )
        }

        @Test("Repeated mutations keep redrawing the view")
        @MainActor
        func testTrackingIsReinstalledAfterEachUpdate() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            // Observation's change handlers fire at most once, so a view that
            // stops re-registering after its first update would pass the first
            // assertion and then silently freeze.
            let model = ObservedModel(title: "0")
            let harness = ObservationHarness(
                TitleView(
                    model: model,
                    counts: BodyEvaluationCounts(),
                    name: "title"
                )
            )

            for index in 1...5 {
                model.title = "\(index)"
                await waitForUpdate {
                    harness.renderedStrings == ["\(index)"]
                }
                #expect(
                    harness.renderedStrings == ["\(index)"],
                    "Expected redraw number \(index) to happen"
                )
            }
        }

        @Test("Mutating from a background thread redraws on the main thread")
        @MainActor
        func testBackgroundMutationRedrawsView() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            let model = ObservedModel(title: "before")
            let harness = ObservationHarness(
                TitleView(
                    model: model,
                    counts: BodyEvaluationCounts(),
                    name: "title"
                )
            )

            #expect(harness.renderedStrings == ["before"])

            let queue = DispatchQueue(label: "observation test mutation")
            let box = UncheckedSendableBox(model)
            queue.async {
                box.value.title = "after"
            }

            await waitForUpdate { harness.renderedStrings == ["after"] }
            #expect(harness.renderedStrings == ["after"])
        }

        @Test("Observation's own @ObservationIgnored still opts a property out")
        @MainActor
        func testObservationIgnoredOptsPropertyOut() async {
            guard
                #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
            else {
                return
            }

            // The declaration of `OptOutModel` is the real assertion here: it
            // applies both `@Observable` and `@ObservationIgnored` in a file
            // that imports SwiftCrossUI, which used to be impossible. These
            // checks confirm the expansion also behaves.
            let model = OptOutModel(tracked: "a", untracked: "b")
            let harness = ObservationHarness(OptOutView(model: model))

            #expect(harness.renderedStrings == ["a", "b"])

            model.untracked = "changed"
            await settle()
            #expect(
                harness.renderedStrings == ["a", "b"],
                "Expected an @ObservationIgnored property not to redraw"
            )

            model.tracked = "changed"
            await waitForUpdate {
                harness.renderedStrings == ["changed", "changed"]
            }
            #expect(harness.renderedStrings == ["changed", "changed"])
        }

        @Test("@ObservableObjectIgnored keeps a property unpublished")
        @MainActor
        func testObservableObjectIgnoredKeepsPropertyUnpublished() async {
            let model = MacroGeneratedModel()
            let harness = ObservationHarness(
                MacroGeneratedModelView(model: model)
            )

            #expect(harness.renderedStrings == ["macro", "ignored"])

            model.ignored = "ignored-after"
            await settle()
            #expect(
                harness.renderedStrings == ["macro", "ignored"],
                "Expected an @ObservableObjectIgnored property not to publish"
            )

            model.value = "macro-after"
            await waitForUpdate {
                harness.renderedStrings == ["macro-after", "ignored-after"]
            }
            #expect(
                harness.renderedStrings == ["macro-after", "ignored-after"],
                "Expected the published property to still drive redraws"
            )
        }
    }
#endif
