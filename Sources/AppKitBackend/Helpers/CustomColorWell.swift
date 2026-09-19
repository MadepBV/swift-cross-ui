import AppKit

final class CustomColorWell: NSColorWell {
    init() {
        super.init(frame: .zero)

        self.target = self
        self.action = #selector(onColorChanged)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used for this view")
    }

    private var opacity: CGFloat = 1.0

    var supportsOpacity = true {
        didSet {
            if #available(macOS 14, *) {
                super.supportsAlpha = supportsOpacity
            }
        }
    }

    override var color: NSColor {
        get {
            let color = super.color
            if !supportsOpacity {
                return color.withAlphaComponent(opacity)
            }
            return color
        }
        set {
            opacity = newValue.alphaComponent
            super.color = newValue
        }
    }

    /// The size AppKit's color wells are drawn at by default, used when
    /// `NSColorWell` doesn't report an intrinsic size of its own. SwiftCrossUI
    /// lays the control out from its intrinsic size, so it needs one.
    private static let fallbackSize = NSSize(width: 44, height: 23)

    override var intrinsicContentSize: NSSize {
        let size = super.intrinsicContentSize
        return NSSize(
            width: size.width == NSView.noIntrinsicMetric ? Self.fallbackSize.width : size.width,
            height: size.height == NSView.noIntrinsicMetric
                ? Self.fallbackSize.height : size.height
        )
    }

    override func activate(_ exclusive: Bool) {
        // Before macOS 14 there's no `supportsAlpha`; the shared color panel is
        // what shows the opacity slider, so it's configured as the well is
        // activated.
        NSColorPanel.shared.showsAlpha = supportsOpacity
        super.activate(exclusive)
    }

    var onChange: ((NSColor) -> Void)?

    @objc func onColorChanged() {
        onChange?(color)
    }
}
