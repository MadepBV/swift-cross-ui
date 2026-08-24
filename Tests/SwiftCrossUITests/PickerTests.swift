import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit
    @testable import AppKitBackend
#endif

/// A selection type standing in for the enums that apps drive pickers with.
private enum Flavor: String, CaseIterable, Hashable {
    case vanilla
    case chocolate
    case strawberry

    /// The text that a picker displays for the flavour.
    var title: String {
        rawValue.capitalized
    }
}

/// The tags of every ``Flavor``, in order.
private let flavorTags = Flavor.allCases.map { flavor in
    AnyHashable(flavor)
}

/// The options of a picker, factored out into a view of their own the way an
/// app would.
private struct FlavorOptions: View {
    var body: some View {
        ForEach(Flavor.allCases, id: \.self) { flavor in
            Text(flavor.title).tag(flavor)
        }
    }
}

/// A mutable value that tests can hand to a view as a ``Binding``.
private final class Box<Value> {
    /// The stored value.
    var value: Value

    /// A binding onto the stored value.
    var binding: Binding<Value> {
        Binding {
            self.value
        } set: { newValue in
            self.value = newValue
        }
    }

    /// Stores an initial value.
    ///
    /// - Parameter value: The initial value.
    init(_ value: Value) {
        self.value = value
    }
}

/// A picker option whose title depends on an environment value.
///
/// Its body reads `@Environment`, exactly like ``Label`` does, so it can only
/// be walked into once the collector has installed the environment.
private struct EnvironmentTitledOption: View {
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Text(isEnabled ? "Enabled" : "Disabled").tag(Flavor.vanilla)
    }
}

@Suite("Testing for Picker")
@MainActor
struct PickerTests {
    // MARK: Option collection

    @Test("Literal tagged children become options in order")
    func testLiteralChildrenBecomeOptions() {
        let content = TupleView2(
            Text("Alpha").tag(Flavor.vanilla),
            Text("Beta").tag(Flavor.chocolate)
        )

        let options = PickerOptionCollector.options(of: content)
        #expect(options.map(\.title) == ["Alpha", "Beta"])
        #expect(
            options.map(\.tag) == [
                AnyHashable(Flavor.vanilla),
                AnyHashable(Flavor.chocolate),
            ]
        )
    }

    @Test("ForEach-generated children each become their own option")
    func testForEachChildrenBecomeOptions() {
        let content = ForEach(Flavor.allCases, id: \.self) { flavor in
            Text(flavor.title).tag(flavor)
        }

        let options = PickerOptionCollector.options(of: content)
        #expect(options.map(\.title) == ["Vanilla", "Chocolate", "Strawberry"])
        #expect(options.map(\.tag) == flavorTags)
    }

    @Test("Group content is transparent to option collection")
    func testGroupChildrenBecomeOptions() {
        let content = TupleView2(
            Text("Vanilla").tag(Flavor.vanilla),
            Group {
                Text("Chocolate").tag(Flavor.chocolate)
                ForEach([Flavor.strawberry], id: \.self) { flavor in
                    Text(flavor.title).tag(flavor)
                }
            }
        )

        let options = PickerOptionCollector.options(of: content)
        #expect(options.map(\.title) == ["Vanilla", "Chocolate", "Strawberry"])
        #expect(options.map(\.tag) == flavorTags)
    }

    @Test("Conditional content only contributes the branch that's taken")
    func testConditionalContent() {
        let withChocolate = Self.conditionalContent(includingChocolate: true)
        let withStrawberry = Self.conditionalContent(includingChocolate: false)

        #expect(
            PickerOptionCollector.options(of: withChocolate)
                .map(\.title) == ["Vanilla", "Chocolate"]
        )
        #expect(
            PickerOptionCollector.options(of: withStrawberry)
                .map(\.title) == ["Vanilla", "Strawberry"]
        )
    }

    @Test("A Label option contributes its title without evaluating its body")
    func testLabelOptionsUseTheirTitle() {
        // `Label.body` reads `@Environment(\.labelStyle)`, which traps outside
        // the view graph; the collector must take the title directly.
        let content = TupleView2(
            Label("Vanilla", systemImage: "circle").tag(Flavor.vanilla),
            Label("Chocolate", image: "bar").tag(Flavor.chocolate)
        )

        let options = PickerOptionCollector.options(of: content)
        #expect(options.map(\.title) == ["Vanilla", "Chocolate"])
        #expect(
            options.map(\.tag) == [
                AnyHashable(Flavor.vanilla),
                AnyHashable(Flavor.chocolate),
            ]
        )
    }

    @Test("Untagged labels become options titled after their text")
    func testUntaggedLabelsBecomeOptions() {
        let content = ForEach(Flavor.allCases, id: \.self) { flavor in
            Label(flavor.title, systemImage: "circle")
        }

        let options = PickerOptionCollector.options(of: content)
        #expect(options.map(\.title) == ["Vanilla", "Chocolate", "Strawberry"])
    }

    @Test("A view whose body reads the environment is collected with one")
    func testEnvironmentReadingContentIsCollected() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)

        #expect(
            PickerOptionCollector.options(
                of: EnvironmentTitledOption(),
                environment: environment
            ).map(\.title) == ["Enabled"]
        )
        #expect(
            PickerOptionCollector.options(
                of: EnvironmentTitledOption(),
                environment: environment.with(\.isEnabled, false)
            ).map(\.title) == ["Disabled"]
        )
    }

    @Test("A view that factors the options out contributes them all")
    func testCustomViewContributesItsOptions() {
        let options = PickerOptionCollector.options(of: FlavorOptions())
        #expect(options.map(\.title) == ["Vanilla", "Chocolate", "Strawberry"])
        #expect(options.map(\.tag) == flavorTags)
    }

    @Test("Untagged text is tagged with the text that it displays")
    func testUntaggedTextIsSelfTagged() {
        let content = TupleView2(Text("Red"), Text("Green"))

        let options = PickerOptionCollector.options(of: content)
        #expect(options.map(\.title) == ["Red", "Green"])
        #expect(options.map(\.tag) == [AnyHashable("Red"), AnyHashable("Green")])
    }

    @Test("A tag on a view that displays no text falls back to the tag itself")
    func testTagWithoutTextFallsBackToTagDescription() {
        let content = TupleView1(EmptyView().tag(Flavor.vanilla))

        let options = PickerOptionCollector.options(of: content)
        #expect(options.map(\.title) == ["vanilla"])
        #expect(options.map(\.tag) == [AnyHashable(Flavor.vanilla)])
    }

    @Test("Options that share a title and tag stay distinguishable")
    func testDuplicateOptionsAreDistinct() {
        let content = TupleView2(
            Text("Same").tag(Flavor.vanilla),
            Text("Same").tag(Flavor.vanilla)
        )

        let options = PickerOptionCollector.options(of: content)
        #expect(options.count == 2)
        #expect(options[0] != options[1])
    }

    // MARK: Tag matching

    @Test("An optional selection matches tags of its wrapped type")
    func testOptionalSelectionMatchesWrappedTag() {
        #expect(
            PickerOption.tag(
                AnyHashable(Flavor.vanilla),
                matches: AnyHashable(Flavor?.some(.vanilla))
            )
        )
        #expect(
            !PickerOption.tag(
                AnyHashable(Flavor.vanilla),
                matches: AnyHashable(Flavor?.some(.chocolate))
            )
        )
        #expect(
            !PickerOption.tag(
                AnyHashable(Flavor.vanilla),
                matches: AnyHashable(Flavor?.none)
            )
        )
    }

    @Test("An option interpolates into a string as its title")
    func testOptionDescription() {
        let option = PickerOption(
            title: "Vanilla",
            tag: AnyHashable(Flavor.vanilla),
            index: 0
        )
        #expect("\(option)" == "Vanilla")
    }

    /// Content whose second option depends on a condition.
    ///
    /// - Parameter includingChocolate: Which branch to take.
    /// - Returns: Picker content with two options.
    @ViewBuilder
    private static func conditionalContent(includingChocolate: Bool) -> some View {
        Text("Vanilla").tag(Flavor.vanilla)
        if includingChocolate {
            Text("Chocolate").tag(Flavor.chocolate)
        } else {
            Text("Strawberry").tag(Flavor.strawberry)
        }
    }

    // MARK: Rendering

    #if canImport(AppKitBackend)
        @Test("An enum selection round-trips through a menu picker")
        func testEnumSelectionRoundTrips() throws {
            let selection = Box(Flavor.vanilla)
            let render = Render(
                Picker("Flavor", selection: selection.binding) {
                    Text("Vanilla").tag(Flavor.vanilla)
                    Text("Chocolate").tag(Flavor.chocolate)
                    Text("Strawberry").tag(Flavor.strawberry)
                },
                style: .menu
            )

            let popUp = try #require(render.find(NSPopUpButton.self))
            #expect(popUp.optionTitles == ["Vanilla", "Chocolate", "Strawberry"])
            #expect(popUp.indexOfSelectedItem == 0)

            // Picking an option writes its tag back to the binding.
            popUp.selectItem(at: 2)
            popUp.onAction?(popUp)
            #expect(selection.value == .strawberry)

            // Setting the binding moves the control.
            selection.value = .chocolate
            render.rerender()
            #expect(popUp.indexOfSelectedItem == 1)
        }

        @Test("ForEach-generated options render and round-trip")
        func testForEachOptionsRender() throws {
            let selection = Box(Flavor.chocolate)
            let render = Render(
                Picker("Flavor", selection: selection.binding) {
                    ForEach(Flavor.allCases, id: \.self) { flavor in
                        Text(flavor.title).tag(flavor)
                    }
                },
                style: .menu
            )

            let popUp = try #require(render.find(NSPopUpButton.self))
            #expect(popUp.optionTitles == ["Vanilla", "Chocolate", "Strawberry"])
            #expect(popUp.indexOfSelectedItem == 1)

            popUp.selectItem(at: 0)
            popUp.onAction?(popUp)
            #expect(selection.value == .vanilla)
        }

        @Test("An optional selection round-trips without spelling the optional out")
        func testOptionalSelectionRoundTrips() throws {
            let selection = Box(Flavor?.none)
            let render = Render(
                Picker("Flavor", selection: selection.binding) {
                    ForEach(Flavor.allCases, id: \.self) { flavor in
                        Text(flavor.title).tag(flavor)
                    }
                },
                style: .menu
            )

            let popUp = try #require(render.find(NSPopUpButton.self))
            // Nothing matches a nil selection.
            #expect(popUp.indexOfSelectedItem == -1)

            selection.value = .strawberry
            render.rerender()
            #expect(popUp.indexOfSelectedItem == 2)

            popUp.selectItem(at: 1)
            popUp.onAction?(popUp)
            #expect(selection.value == .chocolate)
        }

        @Test("A picker shows its label alongside the control")
        func testLabelIsShown() {
            let selection = Box(Flavor.vanilla)
            let render = Render(
                Picker("Flavor", selection: selection.binding) {
                    Text("Vanilla").tag(Flavor.vanilla)
                },
                style: .menu
            )

            #expect(render.labels.contains("Flavor"))
        }

        @Test("An empty title isn't rendered")
        func testEmptyLabelIsHidden() {
            let selection = Box(Flavor.vanilla)
            let render = Render(
                Picker("", selection: selection.binding) {
                    Text("Vanilla").tag(Flavor.vanilla)
                },
                style: .menu
            )

            #expect(render.labels.isEmpty)
        }

        @Test("A custom label view is rendered")
        func testCustomLabel() {
            let selection = Box(Flavor.vanilla)
            let render = Render(
                Picker(selection: selection.binding) {
                    Text("Vanilla").tag(Flavor.vanilla)
                } label: {
                    Text("Pick a flavour")
                },
                style: .menu
            )

            #expect(render.labels.contains("Pick a flavour"))
        }

        @Test("The menu style renders a pop up button")
        func testMenuStyle() throws {
            let popUp = try #require(Self.styledRender(.menu).find(NSPopUpButton.self))
            #expect(popUp.optionTitles == ["Vanilla", "Chocolate", "Strawberry"])
        }

        @Test("The automatic style renders the backend's default picker")
        func testAutomaticStyle() {
            #expect(Self.styledRender(.automatic).find(NSPopUpButton.self) != nil)
        }

        @Test("The segmented style renders a segmented control")
        func testSegmentedStyle() throws {
            let segmented = try #require(
                Self.styledRender(.segmented).find(NSSegmentedControl.self)
            )
            #expect(segmented.segmentCount == 3)
            #expect(segmented.label(forSegment: 1) == "Chocolate")
            #expect(segmented.selectedSegment == 0)
        }

        @Test("The radioGroup style renders a radio group")
        func testRadioGroupStyle() throws {
            let group = try #require(Self.styledRender(.radioGroup).find(RadioGroup.self))
            #expect(group.optionTitles == ["Vanilla", "Chocolate", "Strawberry"])
        }

        @Test("The inline style resolves to a radio group on AppKit")
        func testInlineStyle() {
            #expect(Self.styledRender(.inline).find(RadioGroup.self) != nil)
        }

        @Test("A segmented picker writes the chosen tag back")
        func testSegmentedSelectionRoundTrips() throws {
            let selection = Box(Flavor.vanilla)
            let render = Render(
                Picker("Flavor", selection: selection.binding) {
                    ForEach(Flavor.allCases, id: \.self) { flavor in
                        Text(flavor.title).tag(flavor)
                    }
                },
                style: .segmented
            )

            let segmented = try #require(render.find(NSSegmentedControl.self))
            segmented.selectedSegment = 2
            segmented.onAction?(segmented)
            #expect(selection.value == .strawberry)
        }

        @Test("A radio group writes the chosen tag back")
        func testRadioGroupSelectionRoundTrips() throws {
            let selection = Box(Flavor.vanilla)
            let render = Render(
                Picker("Flavor", selection: selection.binding) {
                    ForEach(Flavor.allCases, id: \.self) { flavor in
                        Text(flavor.title).tag(flavor)
                    }
                },
                style: .radioGroup
            )

            try #require(render.find(RadioGroup.self)).onChange?(1)
            #expect(selection.value == .chocolate)
        }

        @Test("The value-list picker still works")
        func testValueListPickerStillWorks() throws {
            let selection = Box(Flavor?.some(.chocolate))
            let render = Render(
                Picker(of: Flavor.allCases, selection: selection.binding),
                style: .menu
            )

            let popUp = try #require(render.find(NSPopUpButton.self))
            #expect(popUp.optionTitles == ["vanilla", "chocolate", "strawberry"])
            #expect(popUp.indexOfSelectedItem == 1)

            popUp.selectItem(at: 0)
            popUp.onAction?(popUp)
            #expect(selection.value == .vanilla)
        }

        /// Renders a three-option picker with the given style.
        ///
        /// - Parameter style: The style to render with.
        /// - Returns: The render, ready to be searched.
        private static func styledRender(_ style: any PickerStyle) -> Render {
            let selection = Box(Flavor.vanilla)
            return Render(
                Picker("Flavor", selection: selection.binding) {
                    ForEach(Flavor.allCases, id: \.self) { flavor in
                        Text(flavor.title).tag(flavor)
                    }
                },
                style: style
            )
        }
    #endif
}

#if canImport(AppKitBackend)
    /// A view rendered with an ``AppKitBackend``, kept alive so that tests can
    /// re-render it after changing a binding.
    @MainActor
    private final class Render {
        /// The rendered view's graph node.
        private let node: ErasedViewGraphNode
        /// The environment that the view is rendered in.
        private let environment: EnvironmentValues
        /// The width proposed by the most recent render.
        private var proposedWidth = 400.0

        /// The root of the rendered widget hierarchy.
        var widget: NSView {
            node.getWidget().into()
        }

        /// The content of every text field in the rendered hierarchy.
        ///
        /// A picker's options live inside its control rather than in text
        /// fields of their own, so this only picks up the picker's label.
        var labels: [String] {
            var labels: [String] = []
            for view in Self.hierarchy(under: widget) {
                guard let textField = view as? NSTextField else {
                    continue
                }
                labels.append(textField.stringValue)
            }
            return labels
        }

        /// Renders a view.
        ///
        /// - Parameters:
        ///   - view: The view to render.
        ///   - style: The picker style to seed the environment with.
        init<Content: View>(_ view: Content, style: any PickerStyle) {
            let backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(400, 200),
                id: "window"
            )
            environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
                .with(\.pickerStyle, style)
            node = ErasedViewGraphNode(
                for: view,
                backend: backend,
                environment: environment
            )
            render()
        }

        /// Lays the view out again, picking up any changes to its bindings.
        ///
        /// Proposes a different width each time, because the view graph reuses
        /// the previous layout when a node is proposed the same size twice in
        /// a row.
        func rerender() {
            proposedWidth += 1
            render()
        }

        /// Finds the first widget of the given type in the rendered hierarchy.
        ///
        /// - Parameter type: The type of widget to look for.
        /// - Returns: The first matching widget, or `nil` if there is none.
        func find<Widget: NSView>(_ type: Widget.Type) -> Widget? {
            for view in Self.hierarchy(under: widget) {
                if let match = view as? Widget {
                    return match
                }
            }
            return nil
        }

        /// Runs a layout and commit pass.
        private func render() {
            _ = node.computeLayoutWithNewView(
                nil,
                ProposedViewSize(proposedWidth, 200),
                environment
            )
            _ = node.commit()
        }

        /// Every view at or below the given root, breadth first.
        ///
        /// - Parameter root: The root of the hierarchy to walk.
        /// - Returns: The root and all of its descendants.
        private static func hierarchy(under root: NSView) -> [NSView] {
            var found: [NSView] = []
            var queue = [root]
            while let next = queue.first {
                queue.removeFirst()
                found.append(next)
                queue.append(contentsOf: next.subviews)
            }
            return found
        }
    }

    extension NSPopUpButton {
        /// The titles of the button's menu items.
        ///
        /// ``AppKitBackend`` styles option titles, so they're stored as
        /// attributed strings rather than plain ones.
        fileprivate var optionTitles: [String] {
            guard let menu else {
                return []
            }
            return menu.items.map { item in
                item.attributedTitle?.string ?? item.title
            }
        }
    }

    extension RadioGroup {
        /// The titles of the group's radio buttons.
        fileprivate var optionTitles: [String] {
            arrangedSubviews.compactMap { subview in
                (subview as? NSButton)?.attributedTitle.string
            }
        }
    }
#endif
