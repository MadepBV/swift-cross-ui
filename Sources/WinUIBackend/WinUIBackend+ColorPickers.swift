@_spi(Backends) import SwiftCrossUI
import UWP
import WinUI

extension WinUIBackend: BackendFeatures.ColorPickers {
    public func createColorPicker() -> Widget {
        CustomColorPicker()
    }

    public func updateColorPicker(
        _ colorPicker: Widget,
        color: SwiftCrossUI.Color.Resolved,
        supportsOpacity: Bool,
        environment: EnvironmentValues,
        onChange: @escaping (SwiftCrossUI.Color.Resolved) -> Void
    ) {
        guard let picker = colorPicker as? CustomColorPicker else {
            return
        }

        picker.changeHandler = onChange
        picker.setSupportsOpacity(supportsOpacity)
        environment.apply(to: picker)

        // Only write the colour back when it actually differs, so that we don't
        // fight the user while they're dragging a slider in the flyout.
        if picker.currentColor != color {
            picker.setColorWithoutNotifying(color)
        }
    }
}

/// A button showing the current colour, which opens a flyout of channel
/// sliders when clicked.
///
/// WinUI 3 has a `ColorPicker` control, but swift-winui 0.2 doesn't project
/// it, so the flyout is built out of the controls that are projected: one
/// `Slider` per channel. Sliders run from 0 to 255 so that the values read
/// like the hex colours designers are used to.
@MainActor
final class CustomColorPicker: WinUI.Button {
    /// The edge length of the colour swatch shown on the button.
    private static let swatchSize = 20.0

    /// The width of each channel slider in the flyout.
    private static let sliderWidth = 220.0

    /// Called whenever the user picks a different colour.
    var changeHandler: ((SwiftCrossUI.Color.Resolved) -> Void)?

    /// The colour currently shown.
    private(set) var currentColor = SwiftCrossUI.Color.Resolved(red: 0.0, green: 0.0, blue: 0.0)

    /// The swatch showing the currently selected colour.
    private let swatch = WinUI.Grid()

    private let redSlider = WinUI.Slider()
    private let greenSlider = WinUI.Slider()
    private let blueSlider = WinUI.Slider()
    private let opacitySlider = WinUI.Slider()

    /// Set while SwiftCrossUI is writing the colour, so that programmatic
    /// updates don't get reported back as user edits.
    private var isUpdatingProgrammatically = false

    override init() {
        super.init()

        // `init()` overrides a nonisolated WinRT initializer and so is itself
        // nonisolated; the isolated set-up (static sizes, the slider handlers,
        // the swatch) runs from an isolated method instead. WinUI creates and
        // drives this control on the UI thread, which is the main actor.
        MainActor.assumeIsolated {
            configure()
        }
    }

    /// Builds the swatch and the flyout of sliders.
    private func configure() {
        swatch.width = Self.swatchSize
        swatch.height = Self.swatchSize
        content = swatch

        let panel = WinUI.StackPanel()
        panel.orientation = .vertical
        panel.spacing = 4.0

        for (slider, label) in [
            (redSlider, "Red"),
            (greenSlider, "Green"),
            (blueSlider, "Blue"),
            (opacitySlider, "Opacity"),
        ] {
            slider.minimum = 0.0
            slider.maximum = 255.0
            slider.stepFrequency = 1.0
            slider.width = Self.sliderWidth
            slider.header = label
            slider.valueChanged.addHandler { [weak self] _, _ in
                self?.sliderChanged()
            }
            panel.children.append(slider)
        }

        let flyout = WinUI.Flyout()
        flyout.content = panel
        self.flyout = flyout

        updateSwatch()
    }

    /// Shows or hides the opacity slider.
    ///
    /// - Parameter supportsOpacity: Whether the user may edit the opacity.
    func setSupportsOpacity(_ supportsOpacity: Bool) {
        opacitySlider.visibility = supportsOpacity ? .visible : .collapsed
    }

    /// Sets the displayed colour without invoking ``changeHandler``.
    ///
    /// - Parameter newColor: The colour to display.
    func setColorWithoutNotifying(_ newColor: SwiftCrossUI.Color.Resolved) {
        isUpdatingProgrammatically = true
        currentColor = newColor
        redSlider.value = Self.sliderValue(for: newColor.red)
        greenSlider.value = Self.sliderValue(for: newColor.green)
        blueSlider.value = Self.sliderValue(for: newColor.blue)
        opacitySlider.value = Self.sliderValue(for: newColor.opacity)
        updateSwatch()
        isUpdatingProgrammatically = false
    }

    /// Reads the sliders back into a colour and reports it.
    private func sliderChanged() {
        guard !isUpdatingProgrammatically else {
            return
        }
        let opacity: Float =
            opacitySlider.visibility == .visible
                ? Self.channel(for: opacitySlider.value)
                : currentColor.opacity
        let newColor = SwiftCrossUI.Color.Resolved(
            red: Self.channel(for: redSlider.value),
            green: Self.channel(for: greenSlider.value),
            blue: Self.channel(for: blueSlider.value),
            opacity: opacity
        )
        guard newColor != currentColor else {
            return
        }
        currentColor = newColor
        updateSwatch()
        changeHandler?(newColor)
    }

    /// Repaints the swatch shown on the button.
    private func updateSwatch() {
        swatch.background = WinUI.SolidColorBrush(currentColor.uwpColor)
    }

    /// Converts a 0...1 channel into a 0...255 slider value.
    private static func sliderValue(for channel: Float) -> Double {
        (Double(min(max(channel, 0.0), 1.0)) * 255.0).rounded()
    }

    /// Converts a 0...255 slider value into a 0...1 channel.
    private static func channel(for sliderValue: Double) -> Float {
        Float(min(max(sliderValue, 0.0), 255.0) / 255.0)
    }
}
