import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A source of truth for a presentation's `isPresented` state, standing in for
/// the `@State` property that an app would usually use.
final class PresentationSource {
    var isPresented: Bool

    var binding: Binding<Bool> {
        Binding(
            get: { self.isPresented },
            set: { newValue in self.isPresented = newValue }
        )
    }

    init(_ isPresented: Bool) {
        self.isPresented = isPresented
    }
}

/// A source of truth for a ``ColorPicker``'s selection.
final class ColorSource {
    var color: Color

    var binding: Binding<Color> {
        Binding(
            get: { self.color },
            set: { newValue in self.color = newValue }
        )
    }

    init(_ color: Color) {
        self.color = color
    }
}

@Suite("Testing for confirmation dialogs, context menus, colour pickers, and safe area insets")
struct PresentationAndControlsTests {
    /// The size proposed to every view under test.
    static let proposal = ProposedViewSize(400, 300)

    /// The height of the primary content used by the safe area inset tests.
    static let contentHeight = 200.0

    /// The height of the inset content used by the safe area inset tests.
    static let insetHeight = 40.0

    /// The width of the inset content used by the safe area inset tests.
    static let insetWidth = 100.0

    let backend: DummyBackend
    let window: DummyBackend.Window
    let environment: EnvironmentValues

    @MainActor
    init() {
        backend = DummyBackend()
        window = backend.createWindow(withDefaultSize: nil, id: "window")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
    }

    // MARK: Confirmation dialogs

    @MainActor
    @Test("Confirmation dialog actions builder reads labels and roles from buttons")
    func confirmationDialogActionsCarryRoles() {
        let actions = Self.buildActions {
            Button("Delete") {}.role(.destructive)
            Button("Keep") {}
            Button("Cancel") {}.role(.cancel)
        }

        #expect(actions.map(\.label) == ["Delete", "Keep", "Cancel"])
        #expect(actions.map(\.role) == [.destructive, nil, .cancel])
    }

    @MainActor
    @Test("Confirmation dialog actions builder defaults to a single OK action")
    func confirmationDialogActionsDefaultToOK() {
        let actions = Self.buildActions {}

        #expect(actions.count == 1)
        #expect(actions[0].label == "OK")
        #expect(actions[0].role == nil)
    }

    @MainActor
    @Test("Confirmation dialog actions builder supports conditionals")
    func confirmationDialogActionsSupportConditionals() {
        let includeReset = true
        let actions = Self.buildActions {
            ConfirmationDialogAction.destructive("Delete")
            if includeReset {
                ConfirmationDialogAction.destructive("Reset")
            }
            ConfirmationDialogAction.cancel()
        }

        #expect(actions.map(\.label) == ["Delete", "Reset", "Cancel"])
    }

    @MainActor
    @Test("Confirmation dialog actions run the action of the button they came from")
    func confirmationDialogActionsRunTheirButtonsAction() {
        let source = PresentationSource(false)
        let actions = Self.buildActions {
            Button("Delete") { source.isPresented = true }.role(.destructive)
        }

        actions[0].action()

        #expect(source.isPresented)
    }

    @MainActor
    @Test("Confirmation dialog is transparent to layout")
    func confirmationDialogDoesNotAffectLayout() {
        let source = PresentationSource(true)
        let plain = Color.blue.frame(width: 120, height: 60)
        let withDialog = Color.blue
            .frame(width: 120, height: 60)
            .confirmationDialog("Delete placement?", isPresented: source.binding) {
                Button("Delete") {}.role(.destructive)
                Button("Cancel") {}.role(.cancel)
            } message: {
                Text("This can't be undone.")
            }

        #expect(computeLayout(of: plain).size == computeLayout(of: withDialog).size)
    }

    @MainActor
    @Test("Confirmation dialog degrades gracefully on a backend without alerts")
    func confirmationDialogDegradesGracefully() {
        // DummyBackend implements neither `ConfirmationDialogs` nor `Alerts`,
        // so presenting a dialog must be a no-op rather than a trap.
        let source = PresentationSource(true)
        let view = Text("Content")
            .confirmationDialog("Reset preset?", isPresented: source.binding) {
                Button("Reset") {}.role(.destructive)
            }

        let node = committedNode(for: view)

        #expect(texts(in: node.widget) == ["Content"])
        #expect(source.isPresented)
    }

    // MARK: Context menus

    @MainActor
    @Test("Context menu is transparent to layout")
    func contextMenuDoesNotAffectLayout() {
        let plain = Color.blue.frame(width: 120, height: 60)
        let withMenu = Color.blue
            .frame(width: 120, height: 60)
            .contextMenu {
                Button("Duplicate") {}
                Divider()
                Button("Delete") {}
            }

        #expect(computeLayout(of: plain).size == computeLayout(of: withMenu).size)
    }

    @MainActor
    @Test("Context menu degrades to the plain view on a backend without context menus")
    func contextMenuDegradesGracefully() {
        let view = Text("Row").contextMenu {
            Button("Delete") {}
        }

        // The widget must be the child's own widget, unwrapped, because
        // DummyBackend doesn't implement `ContextMenus`.
        let node = committedNode(for: view)

        #expect(node.widget is DummyBackend.TextView)
    }

    // MARK: Colour pickers

    @MainActor
    @Test("ColorPicker shows its label on a backend without colour pickers")
    func colorPickerShowsLabel() {
        let source = ColorSource(.blue)
        let view = ColorPicker("Layer colour", selection: source.binding)

        let node = committedNode(for: view)

        #expect(texts(in: node.widget) == ["Layer colour"])
    }

    @MainActor
    @Test("ColorPicker without colour picker support takes no space of its own")
    func colorPickerDegradesGracefully() {
        let source = ColorSource(.blue)
        let labelOnly = Text("Layer colour")
        let picker = ColorPicker("Layer colour", selection: source.binding)

        let labelHeight = computeLayout(of: labelOnly).size.height
        let pickerHeight = computeLayout(of: picker).size.height

        #expect(pickerHeight == labelHeight)
    }

    // MARK: Safe area insets

    @MainActor
    @Test("safeAreaInset stacks the inset content below the primary content")
    func safeAreaInsetStacksVertically() {
        let view = Color.blue
            .frame(height: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .bottom) {
                Color.red.frame(
                    width: PresentationAndControlsTests.insetWidth,
                    height: PresentationAndControlsTests.insetHeight
                )
            }

        let result = computeLayout(of: view)

        #expect(
            result.size.height
                == PresentationAndControlsTests.contentHeight
                + PresentationAndControlsTests.insetHeight
        )
    }

    @MainActor
    @Test("safeAreaInset withholds the inset's thickness from the content's proposal")
    func safeAreaInsetShrinksContentProposal() {
        // A view that fills whatever height it's proposed reveals how much of
        // the proposal reached it.
        let view = Color.blue
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                Color.red.frame(height: PresentationAndControlsTests.insetHeight)
            }

        let node = committedNode(for: view)
        let container = node.widget as! DummyBackend.Container

        #expect(
            container.children[0].widget.size.y
                == Int(
                    PresentationAndControlsTests.proposal.height!
                        - PresentationAndControlsTests.insetHeight
                )
        )
    }

    @MainActor
    @Test("safeAreaInset spacing adds to the total height")
    func safeAreaInsetSpacingCountsTowardsHeight() {
        let spacing = 12.0
        let withoutSpacing = Color.blue
            .frame(height: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .bottom) {
                Color.red.frame(height: PresentationAndControlsTests.insetHeight)
            }
        let withSpacing = Color.blue
            .frame(height: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .bottom, spacing: spacing) {
                Color.red.frame(height: PresentationAndControlsTests.insetHeight)
            }

        let difference =
            computeLayout(of: withSpacing).size.height
                - computeLayout(of: withoutSpacing).size.height

        #expect(difference == spacing)
    }

    @MainActor
    @Test("safeAreaInset positions a bottom inset below the content")
    func safeAreaInsetPositionsBottomInset() {
        let view = Color.blue
            .frame(height: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .bottom) {
                Color.red.frame(
                    width: PresentationAndControlsTests.insetWidth,
                    height: PresentationAndControlsTests.insetHeight
                )
            }

        let node = committedNode(for: view)
        let container = node.widget as! DummyBackend.Container

        #expect(container.children[0].position.y == 0)
        #expect(
            container.children[1].position.y
                == Int(PresentationAndControlsTests.contentHeight)
        )
    }

    @MainActor
    @Test("safeAreaInset positions a top inset above the content")
    func safeAreaInsetPositionsTopInset() {
        let view = Color.blue
            .frame(height: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .top) {
                Color.red.frame(height: PresentationAndControlsTests.insetHeight)
            }

        let node = committedNode(for: view)
        let container = node.widget as! DummyBackend.Container

        #expect(container.children[1].position.y == 0)
        #expect(
            container.children[0].position.y
                == Int(PresentationAndControlsTests.insetHeight)
        )
    }

    @MainActor
    @Test("safeAreaInset honours its alignment for the inset content")
    func safeAreaInsetHonoursAlignment() {
        let leading = Color.blue
            .frame(width: 300, height: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .bottom, alignment: .leading) {
                Color.red.frame(
                    width: PresentationAndControlsTests.insetWidth,
                    height: PresentationAndControlsTests.insetHeight
                )
            }
        let trailing = Color.blue
            .frame(width: 300, height: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                Color.red.frame(
                    width: PresentationAndControlsTests.insetWidth,
                    height: PresentationAndControlsTests.insetHeight
                )
            }

        let leadingContainer =
            committedNode(for: leading).widget as! DummyBackend.Container
        let trailingContainer =
            committedNode(for: trailing).widget as! DummyBackend.Container

        #expect(leadingContainer.children[1].position.x == 0)
        #expect(
            trailingContainer.children[1].position.x
                == Int(300 - PresentationAndControlsTests.insetWidth)
        )
    }

    @MainActor
    @Test("safeAreaInset stacks horizontally for leading and trailing edges")
    func safeAreaInsetStacksHorizontally() {
        let view = Color.blue
            .frame(width: PresentationAndControlsTests.contentHeight)
            .safeAreaInset(edge: .trailing) {
                Color.red.frame(width: PresentationAndControlsTests.insetWidth)
            }

        let result = computeLayout(of: view)

        #expect(
            result.size.width
                == PresentationAndControlsTests.contentHeight
                + PresentationAndControlsTests.insetWidth
        )
    }

    // MARK: Helpers

    /// Runs an actions builder closure, so that the builder can be tested
    /// without presenting a dialog.
    ///
    /// - Parameter actions: The actions.
    /// - Returns: The built actions.
    @MainActor
    static func buildActions(
        @ConfirmationDialogActionsBuilder _ actions: () -> [ConfirmationDialogAction]
    ) -> [ConfirmationDialogAction] {
        actions()
    }

    @MainActor
    func computeLayout<V: View>(
        of view: V,
        proposedSize: ProposedViewSize = PresentationAndControlsTests.proposal
    ) -> ViewLayoutResult {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        return node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }

    @MainActor
    func committedNode<V: View>(
        for view: V,
        proposedSize: ProposedViewSize = PresentationAndControlsTests.proposal
    ) -> ViewGraphNode<V, DummyBackend> {
        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        _ = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        return node
    }

    /// Collects the content of every text widget in a widget hierarchy.
    @MainActor
    func texts(in widget: DummyBackend.Widget) -> [String] {
        var result: [String] = []
        if let textView = widget as? DummyBackend.TextView {
            result.append(textView.content)
        }
        for child in widget.getChildren() {
            result += texts(in: child)
        }
        return result
    }
}
