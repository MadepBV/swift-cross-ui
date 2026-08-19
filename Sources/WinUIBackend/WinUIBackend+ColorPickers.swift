@_spi(Backends) import SwiftCrossUI
import UWP
import WinUI

extension WinUIBackend: BackendFeatures.ColorPickers {
    public func createColorPicker() -> Widget {
        CustomColorPicker()
    }

    public func updateColorPicker(
        _ colorPicker: Widget,
        color: Color.Resolved,
        supportsOpacity: Bool,
        environment: EnvironmentValues,
        onChange: @escaping (Color.Resolved) -> Void
    ) {
        guard let picker = colorPicker as? CustomColorPicker else {
            return
        }

        picker.changeHandler = onChange
        picker.picker.isAlphaEnabled = supportsOpacity
        picker.isEnabled = environment.isEnabled
        environment.apply(to: picker)

        // Only write the colour back when it actually differs, so that we don't
        // fight the user while they're dragging inside the flyout.
        if picker.resolvedColor != color {
            picker.setColorWithoutNotifying(color.uwpColor)
        }
    }
}

/// A button showing the current colour, which opens WinUI's `ColorPicker` in a
/// flyout when clicked.
///
/// WinUI's `ColorPicker` is a large panel rather than a compact control, so
/// putting it in a flyout is the only way to make it usable inline.
@MainActor
final class CustomColorPicker: WinUI.Button {
    /// The edge length of the colour swatch shown on the button.
    private static let swatchSize = 20.0

    /// Called whenever the user picks a different colour.
    var changeHandler: ((Color.Resolved) -> Void)?

    /// The picker shown inside the flyout.
    let picker = WinUI.ColorPicker()

    /// The swatch showing the currently selected colour.
    private let swatch = WinUI.Grid()

    /// Keeps the colour-changed subscription alive.
    private var colorChangedEvent: EventCleanup?

    /// Set while SwiftCrossUI is writing the colour, so that programmatic
    /// updates don't get reported back as user edits.
    private var isUpdatingProgrammatically = false

    /// The picker's colour in SwiftCrossUI's representation.
    var resolvedColor: Color.Resolved {
        Color.Resolved(uwpColor: picker.color)
    }

    override init() {
        super.init()

        swatch.width = Self.swatchSize
        swatch.height = Self.swatchSize
        content = swatch

        let flyout = WinUI.Flyout()
        flyout.content = picker
        self.flyout = flyout

        colorChangedEvent = picker.colorChanged.addHandler { [unowned self] _, change in
            guard let change, !self.isUpdatingProgrammatically else {
                return
            }
            self.updateSwatch(change.newColor)
            self.changeHandler?(Color.Resolved(uwpColor: change.newColor))
        }
    }

    deinit {
        colorChangedEvent?.dispose()
    }

    /// Sets the picker's colour without invoking ``changeHandler``.
    ///
    /// - Parameter newColor: The colour to display.
    func setColorWithoutNotifying(_ newColor: UWP.Color) {
        isUpdatingProgrammatically = true
        picker.color = newColor
        updateSwatch(newColor)
        isUpdatingProgrammatically = false
    }

    /// Repaints the swatch shown on the button.
    ///
    /// - Parameter newColor: The colour to paint it.
    private func updateSwatch(_ newColor: UWP.Color) {
        swatch.background = WinUI.SolidColorBrush(newColor)
    }
}
