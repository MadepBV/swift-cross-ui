@_spi(Backends) import SwiftCrossUI
import UWP
import WinUI

/// SwiftUI's segmented picker: a row of mutually exclusive segments.
///
/// WinUI 3's `SelectorBar` would be the native control, but swift-winui 0.2
/// doesn't project it, so the row is built from `ToggleButton`s. The checked
/// button takes the theme's accent fill (the toggle button template's own
/// checked state); the others are drawn flat so the row reads as one control.
///
/// Selection is exclusive: clicking a segment selects it and unchecks the
/// rest, and clicking the selected segment leaves it selected, exactly as a
/// segmented control behaves.
@MainActor
final class CustomSegmentedPicker: WinUI.StackPanel {
    /// Called when the user picks a different segment.
    var onChangeSelection: ((Int?) -> Void)?

    /// The segment titles, in order.
    private(set) var options: [String] = []

    /// The selected segment, if any.
    private(set) var selectedIndex: Int?

    /// One button per option.
    private var buttons: [WinUI.ToggleButton] = []

    /// The environment the segments were last styled for.
    private var environment: EnvironmentValues?

    override init() {
        super.init()
        // WinRT properties only; the isolated set-up happens in `setOptions`,
        // because an overriding `init()` is nonisolated.
        orientation = .horizontal
        spacing = 2.0
    }

    /// Replaces the segments when the titles changed, and restyles them.
    ///
    /// - Parameters:
    ///   - newOptions: The segment titles.
    ///   - environment: The environment to style the segments for.
    func setOptions(_ newOptions: [String], environment: EnvironmentValues) {
        self.environment = environment

        if newOptions != options {
            options = newOptions
            children.clear()
            buttons = []
            for (index, title) in newOptions.enumerated() {
                let button = WinUI.ToggleButton()
                let block = WinUI.TextBlock()
                block.text = title
                button.content = block
                button.click.addHandler { [weak self] _, _ in
                    self?.segmentClicked(index)
                }
                children.append(button)
                buttons.append(button)
            }
            if let selectedIndex, !buttons.indices.contains(selectedIndex) {
                self.selectedIndex = nil
            }
        }

        applyAppearance()
    }

    /// Selects a segment without reporting it as a user change.
    ///
    /// - Parameter index: The segment to select, or `nil` for none.
    func setSelectedIndex(_ index: Int?) {
        let resolved = index.flatMap { buttons.indices.contains($0) ? $0 : nil }
        guard resolved != selectedIndex else {
            return
        }
        selectedIndex = resolved
        applyAppearance()
    }

    /// The row's natural size: the segments side by side.
    func naturalSize() -> SIMD2<Int> {
        var width = 0
        var height = 0
        for button in buttons {
            let size = WinUIBackend.naturalSize(of: button)
            width += size.x
            height = max(height, size.y)
        }
        if buttons.count > 1 {
            width += Int(spacing) * (buttons.count - 1)
        }
        return SIMD2(width, height)
    }

    /// Makes the row exclusive again after WinUI toggled a clicked button.
    private func segmentClicked(_ index: Int) {
        guard index != selectedIndex else {
            // Clicking the selected segment keeps it selected.
            applyAppearance()
            return
        }
        selectedIndex = index
        applyAppearance()
        onChangeSelection?(index)
    }

    /// Checks the selected segment and styles every segment for the
    /// environment.
    private func applyAppearance() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            button.isChecked = isSelected

            guard let environment else {
                continue
            }
            environment.apply(to: button)
            if let block = button.content as? WinUI.TextBlock {
                environment.apply(to: block)
                if isSelected {
                    // Fluent's text-on-accent colour: white on the light
                    // theme's accent, black on the dark theme's lighter one.
                    let onAccent: UWP.Color = switch environment.colorScheme {
                        case .light: UWP.Color(a: 255, r: 255, g: 255, b: 255)
                        case .dark: UWP.Color(a: 255, r: 0, g: 0, b: 0)
                    }
                    block.foreground = WinUI.SolidColorBrush(onAccent)
                }
            }

            if isSelected {
                // Let the template's checked state paint the accent fill.
                _ = try? button.clearValue(WinUI.Control.backgroundProperty)
            } else {
                button.background = WinUI.SolidColorBrush(UWP.Color.transparent)
            }
        }
    }
}
