import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKit
    @testable import AppKitBackend
#endif

/// A class to put in, and read back from, the environment.
private final class EnvironmentModel {}

/// Counts how often an accessibility action ran, and in which direction.
@MainActor
private final class ActionLog {
    var entries: [String] = []
}

@Suite("Testing for SwiftUI's accessibility, presentation and text vocabulary")
@MainActor
struct SwiftUIVocabularyTests {
    // MARK: Accessibility

    @Test("Custom content and actions merge, the inner modifier winning per key")
    func customContentAndActionsMerge() {
        let inner = BackendFeatures.AccessibilityProperties(
            customContent: [.init(id: "status", label: "Status", value: "Inner", isHighImportance: true)],
            actions: [.init(kind: .named("Remove")) {}]
        )
        let outer = BackendFeatures.AccessibilityProperties(
            customContent: [
                .init(id: "status", label: "Status", value: "Outer", isHighImportance: true),
                .init(id: "match", label: "Match", value: "Great", isHighImportance: false),
            ],
            actions: [.init(kind: .named("Remove")) {}, .init(kind: .increment) {}]
        )

        let merged = inner.merging(outer)
        #expect(merged.customContent.map(\.value) == ["Inner", "Great"])
        #expect(merged.actions.map(\.name) == ["Remove", "Increment"])
        #expect(!merged.isEmpty)
    }

    @Test("High-importance custom content is folded into the hint")
    func customContentFoldsIntoHint() {
        let properties = BackendFeatures.AccessibilityProperties(
            hint: "Opens the title",
            customContent: [
                .init(id: "match", label: "Match", value: "Great match", isHighImportance: true),
                .init(id: "extra", label: "Extra", value: "Hidden", isHighImportance: false),
            ]
        )
        #expect(properties.hintIncludingCustomContent == "Match: Great match. Opens the title")
        #expect(BackendFeatures.AccessibilityProperties().hintIncludingCustomContent == nil)
    }

    @Test("An announcement reaches the registered backend with its priority")
    func announcementIsDelivered() {
        var events: [AccessibilityNotificationEvent] = []
        let previous = AccessibilityNotificationCenter.deliver
        AccessibilityNotificationCenter.deliver = { events.append($0) }
        defer { AccessibilityNotificationCenter.deliver = previous }

        AccessibilityNotification.Announcement("Download finished").post()
        AccessibilityNotification.LayoutChanged().post()
        AccessibilityNotification.PageScrolled("Page 2 of 5").post()

        #expect(events == [
            .announcement("Download finished", priority: .default),
            .layoutChanged,
            .pageScrolled("Page 2 of 5"),
        ])
    }

    @Test("Posting without a supporting backend does nothing")
    func postingWithoutBackendIsANoOp() {
        let previous = AccessibilityNotificationCenter.deliver
        AccessibilityNotificationCenter.register(DummyBackend())
        defer { AccessibilityNotificationCenter.deliver = previous }

        #expect(AccessibilityNotificationCenter.deliver == nil)
        AccessibilityNotification.Announcement("Nobody listens").post()
    }

    #if canImport(AppKitBackend)
        @Test("Named and adjustable actions become NSAccessibility custom actions")
        func actionsBecomeCustomActions() throws {
            let log = ActionLog()
            let view = Text("Tag")
                .accessibilityAction(named: "Remove") { log.entries.append("remove") }
                .accessibilityAdjustableAction { direction in
                    log.entries.append(direction == .increment ? "up" : "down")
                }

            let widget = Self.render(view)
            let actions = try #require(widget.accessibilityCustomActions())
            #expect(actions.map(\.name) == ["Remove", "Increment", "Decrement"])

            for action in actions {
                _ = action.handler?()
            }
            #expect(log.entries == ["remove", "up", "down"])
        }

        @Test("Custom content reaches the help text VoiceOver reads")
        func customContentReachesHelp() {
            let key = AccessibilityCustomContentKey("Status", id: "status")
            let view = Text("Card")
                .accessibilityCustomContent(key, Text("In your library"), importance: .high)
                .accessibilityHint("Opens the title")

            let widget = Self.render(view)
            #expect(widget.accessibilityHelp() == "Status: In your library. Opens the title")
        }

        @Test("A hint that isn't enabled isn't exposed")
        func disabledHintIsLeftOut() {
            let enabled = Self.render(Text("Play").accessibilityHint("Busy", isEnabled: true))
            let disabled = Self.render(Text("Play").accessibilityHint("Busy", isEnabled: false))
            #expect(enabled.accessibilityHelp() == "Busy")
            #expect(disabled.accessibilityHelp() == nil)
        }

        private static func render<Content: View>(_ view: Content) -> NSView {
            let backend = AppKitBackend()
            let window = backend.createWindow(withDefaultSize: SIMD2(400, 200), id: "window")
            let environment = EnvironmentValues(backend: backend).with(\.window, window)
            let node = ViewGraphNode(for: view, backend: backend, environment: environment)
            _ = node.computeLayout(proposedSize: ProposedViewSize(400, 200), environment: environment)
            _ = node.commit()
            return node.widget
        }
    #endif

    // MARK: Scene phase and environment

    @Test("Scene phases are ordered as SwiftUI orders them")
    func scenePhasesAreOrdered() {
        #expect(ScenePhase.background < .inactive)
        #expect(ScenePhase.inactive < .active)
        #expect(ScenePhase.background != .inactive)
    }

    @Test("An optional environment object reads nil when absent and the object when present")
    func optionalEnvironmentObject() {
        let property = Environment<EnvironmentModel?>(EnvironmentModel.self)
        let environment = ViewGraphHelpers.environment

        property.update(with: environment, previousValue: nil)
        #expect(property.wrappedValue == nil)

        let model = EnvironmentModel()
        var withModel = environment
        withModel[observable: EnvironmentModel.self] = model
        property.update(with: withModel, previousValue: nil)
        #expect(property.wrappedValue === model)
    }

    // MARK: Dialogs

    @Test("A presenting dialog is shown only while its data is present")
    func presentingDialogNeedsData() {
        let source = PresentationSource(true)

        let withoutData = Text.presentation(source.binding, while: false)
        #expect(!withoutData.wrappedValue)

        let withData = Text.presentation(source.binding, while: true)
        #expect(withData.wrappedValue)
        withData.wrappedValue = false
        #expect(!source.isPresented)
    }

    @Test("A dialog's builder reads buttons out of ForEach and modified buttons")
    func dialogBuilderAcceptsViews() {
        let titles = ["Teaser", "Trailer"]
        let actions = Self.dialogActions {
            ForEach(titles, id: \.self) { title in
                Button(title) {}
                    .accessibilityAddTraits(.isSelected)
            }
            Button("Cancel", role: .cancel) {}
        }
        #expect(actions.map(\.label) == ["Teaser", "Trailer", "Cancel"])
    }

    @Test("Dialog messages are read through if/else branches")
    func dialogMessageThroughConditionals() {
        @ViewBuilder func message(_ reported: Bool) -> some View {
            if reported {
                Text("Already reported")
            } else {
                Text("Something went wrong")
            }
        }
        #expect(ConfirmationDialogModifierView<EmptyView>.string(ofMessage: message(true)) == "Already reported")
        #expect(ConfirmationDialogModifierView<EmptyView>.string(ofMessage: message(false)) == "Something went wrong")
    }

    private static func dialogActions(
        @ConfirmationDialogActionsBuilder _ actions: () -> [ConfirmationDialogAction]
    ) -> [ConfirmationDialogAction] {
        actions()
    }

    // MARK: Text

    @Test("Date styles format against a fixed moment")
    func dateStylesFormat() {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let later = now.addingTimeInterval(2 * 3600 + 23 * 60 + 5)
        #expect(Text.DateStyle.timer.format(later, relativeTo: now) == "2:23:05")
        #expect(Text.DateStyle.timer.format(now.addingTimeInterval(65), relativeTo: now) == "1:05")
        #expect(Text.DateStyle.offset.format(now.addingTimeInterval(-7200), relativeTo: now).hasPrefix("-"))
        #expect(Text.DateStyle.offset.format(later, relativeTo: now).hasPrefix("+"))
        #expect(!Text.DateStyle.relative.format(later, relativeTo: now).isEmpty)
    }

    @Test("An inline symbol is written as its Unicode look-alike")
    func inlineSymbols() {
        #expect(Text(Image(systemName: "circle.fill")).string == "\u{25CF}")
        #expect(Text(Image(systemName: "star.circle.fill")).string == "\u{2605}")
        #expect(Text(Image(systemName: "no.such.symbol")).string == "")
    }

    @Test("Interpolating a Text writes its words")
    func textInterpolation() {
        let cursor = Text("\u{25CF}")
        #expect("Loading\(cursor)" == "Loading\u{25CF}")
    }

    // MARK: Layout and presentation

    @Test("A hidden view keeps its layout")
    func hiddenKeepsLayout() {
        let visible = Color.blue.frame(width: 80, height: 30)
        let hidden = Color.blue.frame(width: 80, height: 30).hidden()
        #expect(
            ViewGraphHelpers.computeLayout(of: visible).size
                == ViewGraphHelpers.computeLayout(of: hidden).size
        )
    }

    @Test("A badge shows a count after the view, and none for zero")
    func badgeShowsCount() {
        let backend = ViewGraphHelpers.self
        let withCount = backend.committedNode(for: Text("Activity").badge(3))
        let withoutCount = backend.committedNode(for: Text("Activity").badge(0))
        #expect(Self.texts(in: withCount.widget) == ["Activity", "3"])
        #expect(Self.texts(in: withoutCount.widget) == ["Activity"])
    }

    @Test("Presentation sizing proposes form and page sizes, fitting chosen axes")
    func presentationSizingProposals() {
        #expect(PresentationSizing.automatic.proposal == .unspecified)
        #expect(PresentationSizing.form.proposal == ProposedViewSize(580, 640))
        #expect(
            PresentationSizing.form.fitted(horizontal: false, vertical: true).proposal
                == ProposedViewSize(580, nil)
        )
        #expect(PresentationSizing.page.fitted(horizontal: true, vertical: true).proposal == .unspecified)
    }

    @Test("A refreshable view puts its action in the environment")
    func refreshablePutsActionInEnvironment() async {
        let probe = RefreshProbe()
        let ran = RefreshFlag()
        _ = ViewGraphHelpers.committedNode(
            for: RefreshReader(probe: probe).refreshable { await ran.set() }
        )
        let refresh = try? #require(probe.action)
        await refresh?()
        #expect(await ran.value)
    }

    private static func texts(in widget: DummyBackend.Widget) -> [String] {
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

/// Records the refresh action a view reads from its environment.
@MainActor
private final class RefreshProbe {
    var action: RefreshAction?
}

/// Whether a refresh ran.
private actor RefreshFlag {
    var value = false
    func set() { value = true }
}

/// Reads the environment's refresh action into a probe.
private struct RefreshReader: View {
    let probe: RefreshProbe
    @Environment(\.refresh) private var refresh

    var body: some View {
        probe.action = refresh
        return Text("Content")
    }
}
