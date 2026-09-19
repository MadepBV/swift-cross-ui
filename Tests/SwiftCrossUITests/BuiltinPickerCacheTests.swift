import Testing
@_spi(Backends) @testable import SwiftCrossUI
#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend

@Suite("Built-in picker cache invalidation")
@MainActor
struct BuiltinPickerCacheTests {
    @Test("Menu pickers shrink to the pane without replacing or remeasuring the native control")
    func menuWidthFollowsPaneWhilePreservingNativeState() throws {
        let popup = ProvisionalSizePopup()
        popup.reportedSize = NSSize(width: 380, height: 32)
        let fixture = NativePickerFixture(options: ["A long selected option", "Second"], popup: popup)
        let first = fixture.layout(proposal: ProposedViewSize(220, 80))
        #expect(first.size == ViewSize(220, 32))
        fixture.view.commit(fixture.widget, children: fixture.children, layout: first,
            environment: fixture.environment, backend: fixture.backend)
        // AppKit commits dimensions as constraints; these controls are not
        // installed in a window for this layout/identity regression.
        for widget in [popup, fixture.widget] {
            let width = try #require(widget.constraints.first {
                $0.firstAnchor === widget.widthAnchor && $0.isActive
            })
            #expect(width.constant == 220)
        }
        let measurements = popup.measurements
        #expect(fixture.layout(proposal: ProposedViewSize(340, 80)).size == ViewSize(340, 32))
        #expect(fixture.layout(proposal: ProposedViewSize(500, 80)).size == ViewSize(380, 32))
        #expect(fixture.layout(proposal: ProposedViewSize(nil, 80)).size == ViewSize(380, 32))
        #expect(fixture.layout(proposal: ProposedViewSize(.infinity, 80)).size == ViewSize(380, 32))
        #expect(popup.measurements == measurements)
        #expect(try fixture.popup() === popup)
        #expect(popup.indexOfSelectedItem == 0)
        #expect(fixture.model.writes == 0)
    }

    @Test("Minimum-width probes stay nonnegative and preserve intrinsic height",
        arguments: [0.0, -20.0])
    func menuMinimumWidthProbe(width: Double) {
        let popup = ProvisionalSizePopup()
        popup.reportedSize = NSSize(width: 380, height: 32)
        let fixture = NativePickerFixture(popup: popup)
        #expect(fixture.layout(proposal: ProposedViewSize(width, 0)).size == ViewSize(0, 32))
        #expect(fixture.children.naturalSize == SIMD2(380, 32))
        #expect(fixture.model.writes == 0)
    }

    @Test("Visible-option picker styles retain their intrinsic widths",
        arguments: [BackendPickerStyle.radioGroup, .segmented])
    func otherStylesKeepVisibleOptions(style: BackendPickerStyle) throws {
        let fixture = NativePickerFixture(options: ["First option", "Second option"])
        fixture.view.style = style
        let result = fixture.layout(proposal: ProposedViewSize(1, 80))
        #expect(result.size == ViewSize(try #require(fixture.children.naturalSize)))
        #expect(fixture.model.writes == 0)
    }

    @Test("A populated picker remeasures provisional zero dimensions after native loading",
        arguments: [NSSize.zero, NSSize(width: 0, height: 120), NSSize(width: 163, height: 0)])
    func provisionalNativeSizeRecovers(size: NSSize) throws {
        // Model the real WinUI first-load report with an actual native control:
        // the options, selection and environment remain unchanged throughout.
        let popup = ProvisionalSizePopup()
        popup.reportedSize = size
        let fixture = NativePickerFixture(options: ["First", "Second"], popup: popup)
        let initial = fixture.layout()
        #expect(initial.size == ViewSize(Double(size.width), Double(size.height)))
        popup.reportedSize = NSSize(width: 163, height: 120)
        let realized = fixture.layout()
        #expect(realized.size == ViewSize(163, 120))
        let measurements = popup.measurements
        for _ in 0..<3 { _ = fixture.layout() }
        #expect(popup.measurements == measurements)
        #expect(fixture.model.writes == 0)
    }

    @Test("An empty picker keeps a legitimate zero until its options change")
    func emptyZeroIsCachedUntilOptionsChange() throws {
        let popup = ProvisionalSizePopup()
        let fixture = NativePickerFixture(options: [], popup: popup)
        #expect(fixture.layout().size == .zero)
        let measurements = popup.measurements
        for _ in 0..<3 { _ = fixture.layout() }
        #expect(popup.measurements == measurements)
        fixture.view.options = ["Now populated"]
        popup.reportedSize = NSSize(width: 120, height: 32)
        #expect(fixture.layout().size == ViewSize(120, 32))
        #expect(popup.measurements > measurements)
        #expect(fixture.model.writes == 0)
    }

    @Test("The no-intrinsic-size sentinel stays cached while layout follows its proposal")
    func proposalDependentSentinelRemainsSupported() throws {
        let popup = ProvisionalSizePopup()
        popup.reportedSize = NSSize(width: -1, height: -1)
        let fixture = NativePickerFixture(options: ["First"], popup: popup)
        let first = fixture.layout()
        let measurements = popup.measurements
        let second = fixture.layout()
        #expect(second.size.width == first.size.width + 1)
        #expect(second.size.height == 80)
        #expect(popup.measurements == measurements)
        #expect(fixture.model.writes == 0)
    }

    @Test("An unchanged option list follows disabled-to-enabled transitions")
    func enabledStateRefreshesWithoutChangingOptions() throws {
        let fixture = NativePickerFixture()
        fixture.environment.isEnabled = false
        _ = fixture.layout()
        let popup = try fixture.popup()
        #expect(!popup.isEnabled)
        fixture.environment.isEnabled = true
        _ = fixture.layout()
        #expect(popup.isEnabled)
        fixture.environment.isEnabled = false
        _ = fixture.layout()
        #expect(!popup.isEnabled)
        #expect(fixture.model.writes == 0)
    }

    @Test("Changing the font refreshes native titles and their measured size")
    func fontRefreshesWithoutChangingOptions() throws {
        let fixture = NativePickerFixture(options: ["A moderately wide option"])
        fixture.environment.font = .system(size: 11)
        let first = fixture.layout()
        let popup = try fixture.popup()
        let initialFont = try #require(popup.item(at: 0)?.attributedTitle?
            .attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        #expect(initialFont.pointSize == 11)
        fixture.environment.font = .system(size: 28)
        let changed = fixture.layout()
        let updatedFont = try #require(popup.item(at: 0)?.attributedTitle?
            .attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        #expect(updatedFont.pointSize == 28)
        let fresh = fixture.backend.naturalSize(of: popup)
        #expect(changed.size == ViewSize(fresh))
        #expect(changed.size.width > first.size.width)
        #expect(fixture.model.writes == 0)
    }

    @Test("Growing options replaces the cached native width")
    func growingOptionsRemeasures() throws {
        let fixture = NativePickerFixture(options: ["Short"])
        let first = fixture.layout()
        fixture.view.options.append("A substantially longer option that needs more horizontal space")
        fixture.model.value = 1
        let changed = fixture.layout()
        let popup = try fixture.popup()
        #expect(popup.numberOfItems == 2)
        #expect(popup.indexOfSelectedItem == 1)
        #expect(changed.size == ViewSize(fixture.backend.naturalSize(of: popup)))
        #expect(changed.size.width > first.size.width)
        #expect(fixture.model.writes == 0)
    }

    @Test("Renaming an option without changing the count replaces the cached width")
    func renamedOptionRemeasures() throws {
        let fixture = NativePickerFixture(options: ["Short"])
        let first = fixture.layout()
        fixture.view.options = ["A substantially longer replacement title"]
        let changed = fixture.layout()
        let popup = try fixture.popup()
        #expect(popup.item(at: 0)?.attributedTitle?.string == fixture.view.options[0])
        #expect(changed.size == ViewSize(fixture.backend.naturalSize(of: popup)))
        #expect(changed.size.width > first.size.width)
        #expect(fixture.model.writes == 0)
    }

    @Test("Selection-dependent native sizes are remeasured for selection and nil changes")
    func selectedLabelRemeasures() throws {
        // AppKit can size a popup to its widest menu item, whereas WinUI's
        // unloaded fallback sizes its selected label. This real AppKit control
        // supplies the latter intrinsic-size policy using AppKit text metrics.
        let popup = SelectedLabelPopup()
        let fixture = NativePickerFixture(
            options: ["Short", "A substantially longer selected option"], popup: popup)
        let first = fixture.layout()
        fixture.model.value = 1
        let changed = fixture.layout()
        #expect(popup.indexOfSelectedItem == 1)
        #expect(changed.size == ViewSize(fixture.backend.naturalSize(of: popup)))
        #expect(changed.size.width > first.size.width)
        fixture.model.value = nil
        let cleared = fixture.layout()
        #expect(popup.indexOfSelectedItem == -1)
        #expect(cleared.size == ViewSize(fixture.backend.naturalSize(of: popup)))
        #expect(cleared.size.width < changed.size.width)
        #expect(fixture.model.writes == 0)
    }

    @Test("Foreground and alignment changes reach existing native menu items")
    func textAppearanceRefreshes() throws {
        let fixture = NativePickerFixture()
        fixture.environment.foregroundColor = .red
        fixture.environment.multilineTextAlignment = .leading
        _ = fixture.layout()
        let popup = try fixture.popup()
        let initialTitle = try #require(popup.item(at: 0)?.attributedTitle)
        let initialColor = try #require(initialTitle.attribute(.foregroundColor,
            at: 0, effectiveRange: nil) as? NSColor)
        fixture.environment.foregroundColor = .blue
        fixture.environment.multilineTextAlignment = .trailing
        _ = fixture.layout()
        let title = try #require(popup.item(at: 0)?.attributedTitle)
        let color = try #require(title.attribute(.foregroundColor,
            at: 0, effectiveRange: nil) as? NSColor)
        let paragraph = try #require(title.attribute(.paragraphStyle,
            at: 0, effectiveRange: nil) as? NSParagraphStyle)
        #expect(!color.isEqual(initialColor))
        #expect(paragraph.alignment == .right)
        #expect(fixture.model.writes == 0)
    }

    @Test("An inherited foreground follows the color scheme with unchanged options")
    func inheritedForegroundFollowsTheme() throws {
        let fixture = NativePickerFixture()
        fixture.environment.foregroundColor = nil
        fixture.environment.colorScheme = .light
        _ = fixture.layout()
        let popup = try fixture.popup()
        // An inherited foreground is handed to AppKit as the semantic
        // `NSColor.textColor`, which is the same object in both schemes; it's
        // the popup's appearance that makes it resolve differently.
        let light = try #require(popup.item(at: 0)?.attributedTitle?
            .attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor)
        #expect(light == NSColor.textColor)
        #expect(popup.appearance?.name == .aqua)
        fixture.environment.colorScheme = .dark
        _ = fixture.layout()
        let dark = try #require(popup.item(at: 0)?.attributedTitle?
            .attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor)
        #expect(dark == NSColor.textColor)
        #expect(popup.appearance?.name == .darkAqua)
        #expect(fixture.model.writes == 0)
    }

    @Test("Repeated layout probes and unrelated environment changes do not rewrite items")
    func unchangedAppearanceReusesNativeItems() throws {
        let popup = SelectedLabelPopup()
        let fixture = NativePickerFixture(options: ["Short"], popup: popup)
        _ = fixture.layout()
        let menu = try #require(popup.menu)
        let original = try #require(menu.item(at: 0)?.attributedTitle)
        let item = RecordingMenuItem(title: "", action: nil, keyEquivalent: "")
        item.attributedTitle = original
        menu.removeItem(at: 0)
        menu.addItem(item)
        popup.selectItem(at: 0)
        item.titleWrites = 0
        popup.measurements = 0
        fixture.environment.layoutSpacing += 7
        fixture.environment.layoutAlignment = .leading
        for _ in 0..<3 { _ = fixture.layout() }
        #expect(item.titleWrites == 0)
        #expect(popup.measurements == 0)
        #expect(fixture.model.writes == 0)
        // This control really detects an update, rather than silently missing it.
        fixture.environment.font = .system(size: 27)
        _ = fixture.layout()
        #expect(item.titleWrites > 0)
        #expect(popup.measurements > 0)
    }
}

@MainActor
private final class NativePickerFixture {
    final class Model {
        var value: Int? = 0
        var writes = 0
    }
    let backend: AppKitBackend
    let model: Model
    var environment: EnvironmentValues
    var view: _BuiltinPickerImplementation
    let children: BuiltinPickerChildren
    let widget: NSView
    // Cache tests measure intrinsic-size invalidation. Narrow pane behavior
    // is tested with explicit proposals above.
    private var proposalWidth = 2_000

    init(options: [String] = ["First", "Second"], popup: NSPopUpButton? = nil) {
        let backend = AppKitBackend()
        let model = Model()
        let environment = EnvironmentValues(backend: backend)
        let view = _BuiltinPickerImplementation(style: .menu, options: options,
            selectedIndex: Binding { model.value } set: { model.value = $0; model.writes += 1 })
        let children = view.children(backend: backend, snapshots: nil, environment: environment)
        let widget = view.asWidget(children, backend: backend)
        self.backend = backend
        self.model = model
        self.environment = environment
        self.view = view
        self.children = children
        self.widget = widget
        if let popup {
            children.picker = AnyWidget(popup)
            backend.insert(popup, into: widget, at: 0)
        }
    }

    func popup() throws -> NSPopUpButton {
        try #require(children.picker?.widget as? NSPopUpButton)
    }

    func layout(proposal: ProposedViewSize? = nil) -> ViewLayoutResult {
        proposalWidth += 1
        return view.computeLayout(widget, children: children,
            proposedSize: proposal ?? ProposedViewSize(Double(proposalWidth), 80),
            environment: environment, backend: backend)
    }
}

@MainActor
private final class ProvisionalSizePopup: NSPopUpButton {
    var reportedSize = NSSize.zero
    var measurements = 0
    override var intrinsicContentSize: NSSize {
        measurements += 1
        return reportedSize
    }
}

@MainActor
private final class SelectedLabelPopup: NSPopUpButton {
    var measurements = 0
    override var intrinsicContentSize: NSSize {
        measurements += 1
        let text = selectedItem?.attributedTitle?.size() ?? .zero
        return NSSize(width: text.width + 50, height: max(32, text.height + 12))
    }
}

private final class RecordingMenuItem: NSMenuItem {
    var titleWrites = 0
    override var attributedTitle: NSAttributedString? {
        didSet { titleWrites += 1 }
    }
}
#endif
