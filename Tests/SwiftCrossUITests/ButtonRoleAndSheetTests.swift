import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit

    @testable import AppKitBackend
#endif

/// A stand-in for the `@State` property an app would drive an item-based
/// presentation with.
final class ItemSource<Item> {
    /// The currently selected item, if any.
    var item: Item?

    /// A binding to ``ItemSource/item``.
    var binding: Binding<Item?> {
        Binding(
            get: { self.item },
            set: { newValue in self.item = newValue }
        )
    }

    /// Creates a source holding an item.
    ///
    /// - Parameter item: The initial item.
    init(_ item: Item?) {
        self.item = item
    }
}

/// A mutable box, so that tests can record what happened inside a closure that
/// the view graph owns.
final class Recorder<Value> {
    /// The recorded value.
    var value: Value

    /// Creates a recorder.
    ///
    /// - Parameter value: The initial value.
    init(_ value: Value) {
        self.value = value
    }
}

/// An identifiable value to present sheets for.
struct SheetItem: Identifiable, Equatable {
    /// The item's identity.
    var id: Int
    /// A human readable name, used to check that content receives the right
    /// item.
    var name: String
}

@Suite("Testing for button roles and item-based sheets")
struct ButtonRoleAndSheetTests {
    /// The size proposed to every view under test.
    static let proposal = ProposedViewSize(400, 300)

    // MARK: Button roles

    @MainActor
    @Test("Button takes a destructive role in its title initialiser")
    func titleButtonTakesDestructiveRole() {
        let button = Button("Delete", role: .destructive) {}

        #expect(button.role == .destructive)
    }

    @MainActor
    @Test("Button takes a cancel role in its title initialiser")
    func titleButtonTakesCancelRole() {
        let button = Button("Cancel", role: .cancel) {}

        #expect(button.role == .cancel)
    }

    @MainActor
    @Test("Button without a role has none")
    func titleButtonWithoutRoleHasNone() {
        let button = Button("Save") {}

        #expect(button.role == nil)
    }

    @MainActor
    @Test("Button keeps its action when given a role")
    func roleDoesNotDisturbTheAction() {
        let recorder = Recorder(false)
        let button = Button("Delete", role: .destructive) { recorder.value = true }

        button.action()

        #expect(recorder.value)
    }

    @MainActor
    @Test("View-builder Button takes a role")
    func viewBuilderButtonTakesRole() {
        let button = Button(role: .destructive) {} label: {
            Text("Delete")
        }

        #expect(button.role == .destructive)
    }

    @MainActor
    @Test("Existing Button spellings still compile unambiguously")
    func existingSpellingsRemainUnambiguous() {
        // Each of these compiled before `role:` existed, so each must still
        // resolve to exactly one initialiser now that it does.
        let plainTitle = Button("Save")
        let titleWithAction = Button("Save") {}
        let labelOnly = Button {
            Text("Save")
        }
        let actionAndLabel = Button(action: {}) {
            Text("Save")
        }

        #expect(plainTitle.role == nil)
        #expect(titleWithAction.role == nil)
        #expect(labelOnly.role == nil)
        #expect(actionAndLabel.role == nil)
    }

    @MainActor
    @Test("ButtonRole and the confirmation dialog's role coexist")
    func buttonRoleCoexistsWithDialogRole() {
        // `ButtonRole` must not shadow `ConfirmationDialogAction.Role`, which
        // the confirmation dialog's `Button.role(_:)` still takes.
        let roled = Button("Delete", role: .destructive) {}
        let dialogAction = Button("Delete") {}.role(.destructive)

        #expect(roled.role == .destructive)
        #expect(dialogAction.role == .destructive)
    }

    @MainActor
    @Test("Button hands its role to the backend through the environment")
    func roleReachesTheBackendEnvironment() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)

        #expect(environment.buttonRole == nil)
        #expect(environment.with(\.buttonRole, .destructive).buttonRole == .destructive)
        #expect(environment.with(\.buttonRole, .cancel).buttonRole == .cancel)
    }

    @MainActor
    @Test("A destructive Button tints its label with the system warning colour")
    func destructiveButtonTintsItsLabel() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)

        let tinted = Button<TupleView1<Text>>.labelEnvironment(
            role: .destructive,
            environment: environment,
            backend: backend
        )

        #expect(tinted.foregroundColor == Color.system(.red))
    }

    @MainActor
    @Test("A cancelling Button doesn't tint its label")
    func cancelButtonDoesNotTintItsLabel() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)

        let plain = Button<TupleView1<Text>>.labelEnvironment(
            role: nil,
            environment: environment,
            backend: backend
        )
        let cancelling = Button<TupleView1<Text>>.labelEnvironment(
            role: .cancel,
            environment: environment,
            backend: backend
        )

        #expect(cancelling.foregroundColor == plain.foregroundColor)
    }

    @MainActor
    @Test("An explicit foreground colour beats the destructive tint")
    func explicitForegroundColorWinsOverRole() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)
            .with(\.foregroundColor, .blue)

        let tinted = Button<TupleView1<Text>>.labelEnvironment(
            role: .destructive,
            environment: environment,
            backend: backend
        )

        #expect(tinted.foregroundColor == Color.blue)
    }

    @MainActor
    @Test("A disabled destructive Button keeps the backend's dimming")
    func disabledDestructiveButtonKeepsBackendDimming() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)
            .with(\.isEnabled, false)

        let dimmed = Button<TupleView1<Text>>.labelEnvironment(
            role: nil,
            environment: environment,
            backend: backend
        )
        let destructive = Button<TupleView1<Text>>.labelEnvironment(
            role: .destructive,
            environment: environment,
            backend: backend
        )

        #expect(destructive.foregroundColor == dimmed.foregroundColor)
    }

    #if canImport(AppKitBackend)
        @MainActor
        @Test("A destructive Button is marked destructive in AppKit")
        func destructiveButtonReachesAppKit() {
            guard #available(macOS 11, *) else {
                return
            }

            let button = Self.renderButton(Button("Delete", role: .destructive) {})

            #expect(button.rendersAsDestructive)
        }

        @MainActor
        @Test("A role-less Button isn't marked destructive in AppKit")
        func plainButtonIsNotDestructiveInAppKit() {
            guard #available(macOS 11, *) else {
                return
            }

            let button = Self.renderButton(Button("Save") {})

            #expect(!button.rendersAsDestructive)
        }

        @MainActor
        @Test("A cancelling Button isn't marked destructive in AppKit")
        func cancelButtonIsNotDestructiveInAppKit() {
            guard #available(macOS 11, *) else {
                return
            }

            let button = Self.renderButton(Button("Cancel", role: .cancel) {})

            #expect(button.role == .cancel)
            #expect(!button.rendersAsDestructive)
        }

        @MainActor
        @Test("A view-builder Button's role reaches AppKit too")
        func viewBuilderRoleReachesAppKit() {
            guard #available(macOS 11, *) else {
                return
            }

            let button = Self.renderButton(
                Button(role: .destructive) {} label: {
                    Text("Delete")
                }
            )

            #expect(button.rendersAsDestructive)
        }
    #endif

    // MARK: Presentation bindings

    @MainActor
    @Test("A presenting binding is true exactly while its item is non-nil")
    func presentingBindingFollowsItsItem() {
        let source = ItemSource(SheetItem(id: 1, name: "Anchor"))
        let isPresented = Binding<Bool>.presenting(source.binding)

        #expect(isPresented.wrappedValue)

        source.item = nil

        #expect(!isPresented.wrappedValue)
    }

    @MainActor
    @Test("Setting a presenting binding to false clears its item")
    func presentingBindingClearsItsItem() {
        let source = ItemSource(SheetItem(id: 1, name: "Anchor"))
        let isPresented = Binding<Bool>.presenting(source.binding)

        isPresented.wrappedValue = false

        #expect(source.item == nil)
    }

    @MainActor
    @Test("Setting a presenting binding to true does nothing")
    func presentingBindingIgnoresBeingSetToTrue() {
        let source = ItemSource<SheetItem>(nil)
        let isPresented = Binding<Bool>.presenting(source.binding)

        isPresented.wrappedValue = true

        #expect(source.item == nil)
        #expect(!isPresented.wrappedValue)
    }

    // MARK: Item-based sheets

    #if canImport(AppKitBackend)
        @MainActor
        @Test("An item-based sheet isn't presented while its item is nil")
        func itemSheetStaysHiddenWhileItemIsNil() {
            let source = ItemSource<SheetItem>(nil)
            let harness = SheetHarness {
                Text("Content")
                    .sheet(item: source.binding) { item in
                        Text(item.name)
                    }
            }

            harness.render()

            #expect(harness.presentedSheet == nil)
        }

        @MainActor
        @Test("An item-based sheet presents once its item is non-nil")
        func itemSheetPresentsForNonNilItem() {
            let source = ItemSource<SheetItem>(nil)
            let harness = SheetHarness {
                Text("Content")
                    .sheet(item: source.binding) { item in
                        Text(item.name)
                    }
            }

            harness.render()
            source.item = SheetItem(id: 7, name: "Anchor")
            harness.render()

            #expect(harness.presentedSheet != nil)
        }

        @MainActor
        @Test("An item-based sheet hands its content the unwrapped item")
        func itemSheetContentReceivesTheItem() {
            let expected = SheetItem(id: 7, name: "Anchor")
            let source = ItemSource(expected)
            let received = Recorder<[SheetItem]>([])
            let harness = SheetHarness {
                Text("Content")
                    .sheet(item: source.binding) { item in
                        received.value.append(item)
                        return Text(item.name)
                    }
            }

            harness.render()

            #expect(!received.value.isEmpty)
            #expect(Set(received.value.map(\.id)) == [expected.id])
            #expect(received.value.first == expected)
        }

        @MainActor
        @Test("Dismissing an item-based sheet nils its binding")
        func itemSheetDismissalClearsTheBinding() {
            let source = ItemSource(SheetItem(id: 7, name: "Anchor"))
            let harness = SheetHarness {
                Text("Content")
                    .sheet(item: source.binding) { item in
                        Text(item.name)
                    }
            }

            harness.render()
            let sheet = harness.presentedSheet

            // This is precisely what `NSCustomSheet` calls when the user
            // dismisses the sheet.
            sheet?.onDismiss?()

            #expect(sheet != nil)
            #expect(source.item == nil)
        }

        @MainActor
        @Test("An item-based sheet runs onDismiss before clearing its binding")
        func itemSheetRunsOnDismissBeforeClearing() {
            let source = ItemSource(SheetItem(id: 7, name: "Anchor"))
            let itemWhenDismissed = Recorder<SheetItem?>(nil)
            let harness = SheetHarness {
                Text("Content")
                    .sheet(
                        item: source.binding,
                        onDismiss: { itemWhenDismissed.value = source.item }
                    ) { item in
                        Text(item.name)
                    }
            }

            harness.render()
            harness.presentedSheet?.onDismiss?()

            #expect(itemWhenDismissed.value == SheetItem(id: 7, name: "Anchor"))
            #expect(source.item == nil)
        }

        @MainActor
        @Test("Clearing the item dismisses an item-based sheet")
        func clearingTheItemDismissesTheSheet() {
            let source = ItemSource(SheetItem(id: 7, name: "Anchor"))
            let harness = SheetHarness {
                Text("Content")
                    .sheet(item: source.binding) { item in
                        Text(item.name)
                    }
            }

            harness.render()
            #expect(harness.presentedSheet != nil)

            source.item = nil
            harness.render()

            #expect(harness.presentedSheet == nil)
        }

        @MainActor
        @Test("An item-based sheet is transparent to layout")
        func itemSheetDoesNotAffectLayout() {
            let source = ItemSource(SheetItem(id: 7, name: "Anchor"))
            let plain = SheetHarness {
                Color.blue.frame(width: 120, height: 60)
            }
            let withSheet = SheetHarness {
                Color.blue
                    .frame(width: 120, height: 60)
                    .sheet(item: source.binding) { item in
                        Text(item.name)
                    }
            }

            #expect(plain.render().size == withSheet.render().size)
        }

        @MainActor
        @Test("Both sheet spellings can be applied to the same view")
        func bothSheetSpellingsCoexist() {
            let item = ItemSource(SheetItem(id: 7, name: "Anchor"))
            let flag = Recorder(false)
            let isPresented = Binding(
                get: { flag.value },
                set: { newValue in flag.value = newValue }
            )
            let harness = SheetHarness {
                Text("Content")
                    .sheet(isPresented: isPresented) {
                        Text("Flag sheet")
                    }
                    .sheet(item: item.binding) { sheetItem in
                        Text(sheetItem.name)
                    }
            }

            harness.render()

            #expect(harness.presentedSheet != nil)
        }
    #endif

    // MARK: Helpers

    #if canImport(AppKitBackend)
        /// Renders a button with ``AppKitBackend`` and hands back the `NSView`
        /// that backs it.
        ///
        /// - Parameter button: The button to render.
        /// - Returns: The button's backing view.
        @MainActor
        static func renderButton<Label: View>(
            _ button: Button<Label>
        ) -> NSCustomButton {
            let backend = AppKitBackend()
            let window = backend.createWindow(
                withDefaultSize: SIMD2(400, 300),
                id: "window"
            )
            let environment = EnvironmentValues(backend: backend)
                .with(\.window, window)
            let node = ViewGraphNode(
                for: button,
                backend: backend,
                environment: environment
            )
            _ = node.computeLayout(
                proposedSize: ButtonRoleAndSheetTests.proposal,
                environment: environment
            )
            _ = node.commit()
            return node.widget as! NSCustomButton
        }
    #endif
}

#if canImport(AppKitBackend)
    /// Renders a view with ``AppKitBackend`` into a real window and re-renders
    /// it on demand, so that tests can watch a sheet come and go as state
    /// changes.
    ///
    /// ``SheetModifier`` traps on backends that don't implement
    /// ``BackendFeatures/Sheets``, so `DummyBackend` can't be used here.
    @MainActor
    final class SheetHarness<Content: View> {
        /// The backend rendering the view.
        let backend: AppKitBackend
        /// The window the view lives in.
        let window: NSCustomWindow
        /// The sheet currently presented on ``SheetHarness/window``, if any.
        var presentedSheet: NSCustomSheet? { window.nestedSheet }

        /// The environment the view is rendered with.
        private let environment: EnvironmentValues
        /// The view's node in the view graph.
        private let node: ViewGraphNode<Content, AppKitBackend>
        /// Recomputes the view from the test's current state.
        private let makeView: () -> Content

        /// Renders a view for the first time.
        ///
        /// - Parameter makeView: Recomputes the view from the test's current
        ///   state. Called once per render, exactly as the view graph would.
        init(_ makeView: @escaping () -> Content) {
            backend = AppKitBackend()
            window = backend.createWindow(
                withDefaultSize: SIMD2(400, 300),
                id: "window"
            )
            environment = EnvironmentValues(backend: backend).with(\.window, window)
            self.makeView = makeView
            node = ViewGraphNode(
                for: makeView(),
                backend: backend,
                environment: environment
            )
            backend.setChild(ofWindow: window, to: node.widget)
        }

        /// Recomputes and commits the view's layout, picking up any state
        /// changes the test has made since the last render.
        ///
        /// - Returns: The result of laying the view out.
        @discardableResult
        func render() -> ViewLayoutResult {
            _ = node.computeLayout(
                with: makeView(),
                proposedSize: ButtonRoleAndSheetTests.proposal,
                environment: environment
            )
            return node.commit()
        }
    }
#endif
