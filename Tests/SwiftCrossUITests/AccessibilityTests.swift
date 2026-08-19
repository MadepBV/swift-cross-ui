import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit
    @testable import AppKitBackend
#endif

@Suite("Testing for accessibility")
@MainActor
struct AccessibilityTests {
    @Test("Nested modifiers merge instead of overwriting each other")
    func testNestedModifiersMerge() {
        let inner = BackendFeatures.AccessibilityProperties(
            label: "Inner",
            traits: .isButton
        )
        let outer = BackendFeatures.AccessibilityProperties(
            label: "Outer",
            hint: "Outer hint",
            traits: .isHeader
        )

        let merged = inner.merging(outer)
        #expect(merged.label == "Inner")
        #expect(merged.hint == "Outer hint")
        #expect(merged.traits == [.isButton, .isHeader])
    }

    @Test("Empty properties describe nothing")
    func testEmptyProperties() {
        #expect(BackendFeatures.AccessibilityProperties().isEmpty)
        #expect(
            !BackendFeatures.AccessibilityProperties(identifier: "id").isEmpty
        )
    }

    @Test("Backends without accessibility support don't trap")
    func testUnsupportedBackendDegradesSilently() {
        let view = VStack {
            Text("Body")
                .accessibilityLabel("Label")
                .accessibilityHidden()
        }
        .accessibilityIdentifier("root")
        .accessibilityElement(children: .combine)

        let backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "window")
        let environment = EnvironmentValues(backend: backend)
            .with(\.window, window)
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        _ = node.computeLayout(
            proposedSize: .unspecified,
            environment: environment
        )
        _ = node.commit()
    }

    #if canImport(AppKitBackend)
        @Test("A label, hint and identifier reach the underlying NSView")
        func testTextualPropertiesReachTheWidget() {
            let view = Text("Ø12")
                .accessibilityLabel("Bar diameter")
                .accessibilityHint("Sets the reinforcement bar diameter")
                .accessibilityIdentifier("bar-diameter")

            let widget = Self.render(view)
            #expect(widget.accessibilityLabel() == "Bar diameter")
            #expect(
                widget.accessibilityHelp()
                    == "Sets the reinforcement bar diameter"
            )
            #expect(widget.accessibilityIdentifier() == "bar-diameter")
        }

        @Test("A value reaches the underlying NSView")
        func testValueReachesTheWidget() {
            // Applied to a stack rather than to text because NSTextField
            // computes its own accessibility value and ignores overrides.
            let view = VStack {
                Text("4200")
            }
            .accessibilityValue("4200 millimetres")

            let widget = Self.render(view)
            let value = widget.accessibilityValue() as? String
            #expect(value == "4200 millimetres")
        }

        @Test("Traits become an NSAccessibility role")
        func testTraitsBecomeARole() {
            let widget = Self.render(
                Text("Delete").accessibilityAddTraits(.isButton)
            )
            #expect(widget.accessibilityRole() == .button)
        }

        @Test("The search field trait sets a subrole too")
        func testSearchFieldTrait() {
            let widget = Self.render(
                Text("Find").accessibilityAddTraits(.isSearchField)
            )
            #expect(widget.accessibilityRole() == .textField)
            #expect(widget.accessibilitySubrole() == .searchField)
        }

        @Test("Traits from separate modifiers accumulate")
        func testTraitsAccumulate() {
            let widget = Self.render(
                Text("Section")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityAddTraits(.isSelected)
            )
            #expect(
                widget.accessibilityRole()
                    == NSAccessibility.Role(rawValue: "AXHeading")
            )
            #expect(widget.isAccessibilitySelected())
        }

        @Test("Hiding a view removes it and its children from the AX tree")
        func testHiddenRemovesSubtree() {
            let view = VStack {
                Text("Decoration")
            }
            .accessibilityHidden()

            let widget = Self.render(view)
            #expect(!widget.isAccessibilityElement())
            #expect(widget.accessibilityChildren()?.isEmpty == true)
        }

        @Test("Explicitly un-hiding a view keeps its children exposed")
        func testExplicitlyVisibleKeepsChildren() {
            let view = VStack {
                Text("Ø12")
            }
            .accessibilityHidden(false)

            let widget = Self.render(view)
            #expect(widget.accessibilityChildren()?.isEmpty == false)
        }

        @Test("Combining children builds one element out of their text")
        func testCombineChildren() {
            let view = HStack {
                Text("Ø12")
                Text("4200mm")
            }
            .accessibilityElement(children: .combine)

            let widget = Self.render(view)
            #expect(widget.isAccessibilityElement())
            #expect(widget.accessibilityLabel() == "Ø12, 4200mm")
            #expect(widget.accessibilityChildren()?.isEmpty == true)
        }

        @Test("An explicit label wins over the combined description")
        func testCombineChildrenWithExplicitLabel() {
            let view = HStack {
                Text("Ø12")
                Text("4200mm")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Bar 12 by 4200")

            let widget = Self.render(view)
            #expect(widget.accessibilityLabel() == "Bar 12 by 4200")
        }

        @Test("Ignoring children hides them without describing them")
        func testIgnoreChildren() {
            let view = HStack {
                Text("Ø12")
                Text("4200mm")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Bar")

            let widget = Self.render(view)
            #expect(widget.isAccessibilityElement())
            #expect(widget.accessibilityLabel() == "Bar")
            #expect(widget.accessibilityChildren()?.isEmpty == true)
        }

        @Test("Containing children keeps them in the AX tree")
        func testContainChildren() {
            let view = HStack {
                Text("Ø12")
                Text("4200mm")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Bar")

            let widget = Self.render(view)
            #expect(widget.isAccessibilityElement())
            #expect(widget.accessibilityLabel() == "Bar")
            #expect(widget.accessibilityChildren()?.isEmpty == false)
        }

        @Test("A labelled container is promoted so its label is announced")
        func testLabelledContainerIsPromoted() {
            let view = VStack {
                Text("Ø12")
            }
            .accessibilityLabel("Bar")

            let widget = Self.render(view)
            #expect(widget.isAccessibilityElement())
            #expect(widget.accessibilityRole() == .group)
            #expect(widget.accessibilityChildren()?.isEmpty == false)
        }

        @Test("A view without accessibility modifiers is left alone")
        func testUnmodifiedViewIsUntouched() {
            let widget = Self.render(VStack { Text("Ø12") })
            #expect(!widget.isAccessibilityElement())
            #expect(widget.accessibilityLabel() == nil)
        }

        /// Renders a view with an ``AppKitBackend`` and hands back the root
        /// `NSView` so that its accessibility state can be inspected.
        ///
        /// - Parameter view: The view to render.
        /// - Returns: The view's underlying `NSView`.
        private static func render<Content: View>(_ view: Content) -> NSView {
            let backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(400, 200),
                id: "window"
            )
            let environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            let node = ViewGraphNode(
                for: view,
                backend: backend,
                environment: environment
            )
            _ = node.computeLayout(
                proposedSize: ProposedViewSize(400, 200),
                environment: environment
            )
            _ = node.commit()
            return node.widget
        }
    #endif
}
