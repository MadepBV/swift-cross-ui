import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.ColorPickers {
    public func createColorPicker() -> Widget {
        NSCustomColorWell()
    }

    public func updateColorPicker(
        _ colorPicker: Widget,
        color: Color.Resolved,
        supportsOpacity: Bool,
        environment: EnvironmentValues,
        onChange: @escaping (Color.Resolved) -> Void
    ) {
        guard let colorWell = colorPicker as? NSCustomColorWell else {
            return
        }

        colorWell.isEnabled = environment.isEnabled
        colorWell.showsAlpha = supportsOpacity
        colorWell.changeHandler = onChange

        // Only write the colour back when it actually differs, so that we don't
        // fight the shared colour panel while the user is dragging in it.
        let newColor = NSColor(
            srgbRed: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: supportsOpacity ? CGFloat(color.opacity) : 1
        )
        if colorWell.resolvedColor != color {
            colorWell.setColorWithoutNotifying(newColor)
        }
    }
}

/// An `NSColorWell` that reports colour changes back to SwiftCrossUI.
final class NSCustomColorWell: NSColorWell {
    /// The size AppKit's colour wells are drawn at by default. `NSColorWell`
    /// has no intrinsic content size of its own, so SwiftCrossUI needs one
    /// supplied here in order to lay the control out.
    private static let defaultSize = NSSize(width: 44, height: 23)

    /// Called whenever the user picks a different colour.
    var changeHandler: ((Color.Resolved) -> Void)?

    /// Whether the shared colour panel should offer an opacity control while
    /// this well is active.
    var showsAlpha = true

    /// Set while SwiftCrossUI is writing the colour, so that programmatic
    /// updates don't get reported back as user edits.
    private var isUpdatingProgrammatically = false

    override var intrinsicContentSize: NSSize {
        Self.defaultSize
    }

    /// This well's colour in SwiftCrossUI's representation.
    var resolvedColor: Color.Resolved {
        guard let srgb = color.usingColorSpace(.sRGB) else {
            return Color.Resolved(red: 0, green: 0, blue: 0, opacity: 1)
        }
        return Color.Resolved(
            red: Float(srgb.redComponent),
            green: Float(srgb.greenComponent),
            blue: Float(srgb.blueComponent),
            opacity: Float(srgb.alphaComponent)
        )
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(colorChanged)
    }

    convenience init() {
        self.init(frame: NSRect(origin: .zero, size: Self.defaultSize))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func activate(_ exclusive: Bool) {
        // The shared colour panel is what actually shows the opacity slider, so
        // its configuration has to happen as the well is activated.
        NSColorPanel.shared.showsAlpha = showsAlpha
        super.activate(exclusive)
    }

    /// Sets the well's colour without invoking ``changeHandler``.
    ///
    /// - Parameter newColor: The colour to display.
    func setColorWithoutNotifying(_ newColor: NSColor) {
        isUpdatingProgrammatically = true
        color = newColor
        isUpdatingProgrammatically = false
    }

    @objc
    private func colorChanged() {
        guard !isUpdatingProgrammatically else {
            return
        }
        changeHandler?(resolvedColor)
    }
}
