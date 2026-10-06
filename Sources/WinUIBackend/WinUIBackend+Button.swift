import SwiftCrossUI
import WinUI
import UWP

extension WinUIBackend {
    public func createButton(
        wrapping widget: Widget
    ) -> Widget {
        let button = CustomButton()
        button.content = widget
        return button
    }

    public func updateButton(
        _ button: Widget,
        environment: EnvironmentValues,
        action: @escaping () -> Void
    ) {
        let button = button as! CustomButton
        button.action = action
        button.buttonStyle = environment.resolvedButtonStyle.kind
        button.prominentFill = environment.resolvedButtonIsProminent
            ? environment.prominentButtonFill.resolve(in: environment).uwpColor : nil
        button.borderShape = environment.buttonBorderShape
        button.enabled = environment.isEnabled
        switch environment.colorScheme {
            case .light:
                button.requestedTheme = .light
            case .dark:
                button.requestedTheme = .dark
        }
    }

    public func buttonPadding(in environment: EnvironmentValues) -> SIMD2<Int> {
        switch environment.resolvedButtonStyle.kind {
            case .bordered: measureBorderedButtonPadding()
            case .plain, .borderless: SIMD2(0, 0)
        }
    }

    public func defaultButtonStyle() -> any ButtonStyle { .bordered }

    func measureBorderedButtonPadding() -> SIMD2<Int> {
        if let borderedButtonPadding {
            return borderedButtonPadding
        }

        let dummyButton = Button()
        let placeholder = WinUI.Canvas()
        let placeholderSize = SIMD2<Double>(40, 40)
        placeholder.width = placeholderSize.x
        placeholder.height = placeholderSize.y
        dummyButton.content = placeholder

        let buttonSize = Self.naturalSize(of: dummyButton)

        let result = SIMD2(
            buttonSize.x - Int(placeholderSize.x),
            buttonSize.y - Int(placeholderSize.y)
        )

        borderedButtonPadding = result
        return result
    }
}

final class CustomButton: WinUI.Button {
    fileprivate var action: (() -> Void)?

    /// Runs the button's action as though it had been clicked.
    ///
    /// This is what a keyboard shortcut attached to the button (or to a
    /// container around it) invokes.
    func performClick() {
        guard enabled else { return }
        action?()
    }

    private var isPointerCaptured = false
    fileprivate var isHighlighted = false {
        didSet {
            buttonStyle.applyModifications(self)
        }
    }

    fileprivate var buttonStyle: ButtonStyle.Kind = .bordered {
        didSet {
            if buttonStyle != oldValue {
                updateButtonAppearance()
            }
        }
    }

    /// The fill of a prominent button (`.borderedProminent`, `.glassProminent`);
    /// nil keeps WinUI's standard button background.
    fileprivate var prominentFill: UWP.Color? {
        didSet {
            if prominentFill != oldValue {
                updateButtonAppearance()
            }
        }
    }

    /// The shape set by `buttonBorderShape(_:)`, applied to a bordered button's
    /// corners whenever it is resized.
    fileprivate var borderShape: ButtonBorderShape = .automatic {
        didSet {
            if borderShape != oldValue {
                updateButtonAppearance()
            }
        }
    }

    // Sadly we can't override isEnabled due to it not being an open property
    public var enabled: Bool = true {
        didSet {
            self.isEnabled = enabled

            if !enabled {
                isPointerCaptured = false
                isHighlighted = false
            }

            buttonStyle.applyModifications(self)
        }
    }

    override init() {
        super.init()
        padding = Thickness.null
        horizontalContentAlignment = WinUI.HorizontalAlignment.center
        verticalContentAlignment = WinUI.VerticalAlignment.center

        click.addHandler { [weak self] _, _ in
            guard let self else { return }
            self.action?()
        }
        sizeChanged.addHandler { [weak self] _, _ in
            guard let self, self.buttonStyle == .bordered, self.borderShape != .automatic else { return }
            self.applyBorderShape()
        }
    }

    /// Rounds a bordered button's corners to its ``borderShape``.
    fileprivate func applyBorderShape() {
        let size = SIMD2(actualWidth, actualHeight)
        if let radius = borderShape.cornerRadius(forSize: size) {
            cornerRadius = CornerRadius(topLeft: radius, topRight: radius, bottomRight: radius, bottomLeft: radius)
        } else {
            _ = try? clearValue(WinUI.Button.cornerRadiusProperty)
        }
    }

    override func onPointerPressed(_ e: PointerRoutedEventArgs!) throws {
        try super.onPointerPressed(e)
        isPointerCaptured = true
        isHighlighted = true
    }

    override func onPointerMoved(_ e: PointerRoutedEventArgs!) throws {
        try super.onPointerMoved(e)

        if isPointerCaptured {
            // Pointer position relative to the button.
            guard let currentPoint = try e.getCurrentPoint(self) else { return }
            let position = currentPoint.position

            let width = self.actualWidth
            let height = self.actualHeight

            // Apparently windows uses 0 <= x < actualWidth ¯\_(ツ)_/¯
            if
                (0..<width).contains(Double(position.x)),
                (0..<height).contains(Double(position.y))
            {
                isHighlighted = true
            } else {
                isHighlighted = false
            }
        }
    }

    override func onPointerReleased(_ event: PointerRoutedEventArgs!) throws {
        try super.onPointerReleased(event)
        isPointerCaptured = false
        isHighlighted = false
    }

    override func onPointerCaptureLost(_ event: PointerRoutedEventArgs!) throws {
        try super.onPointerCaptureLost(event)
        isPointerCaptured = false
        isHighlighted = false
    }

    override func onKeyDown(_ event: KeyRoutedEventArgs!) throws {
        try super.onKeyDown(event)

        let targetKey = event.key

        if [.space, .enter].contains(targetKey) {
            isHighlighted = true
        }
    }

    override func onKeyUp(_ event: KeyRoutedEventArgs!) throws {
        try super.onKeyUp(event)

        let targetKey = event.key

        if [.space, .enter].contains(targetKey) {
            isHighlighted = false
        }
    }

    override func onLostFocus(_ event: RoutedEventArgs!) throws {
        try super.onLostFocus(event)
        isPointerCaptured = false
        isHighlighted = false
    }

    private func updateButtonAppearance() {
        buttonStyle.applyModifications(self)
        buttonStyle.updateRenderedStyle(self)
    }
}

extension ButtonStyle.Kind {
    fileprivate func updateRenderedStyle(_ button: CustomButton) {
        guard let resources = button.resources else { return }

        switch self {
            case .bordered:
                _ = try? button.clearValue(WinUI.Button.backgroundProperty)
                _ = try? button.clearValue(WinUI.Button.borderBrushProperty)
                _ = try? button.clearValue(WinUI.Button.borderThicknessProperty)
                _ = try? button.clearValue(WinUI.Button.cornerRadiusProperty)

                _ = resources.remove("ButtonBackgroundPointerOver")
                _ = resources.remove("ButtonBackgroundPressed")
                _ = resources.remove("ButtonBackgroundDisabled")

                _ = resources.remove("ButtonBorderBrushPointerOver")
                _ = resources.remove("ButtonBorderBrushPressed")
                _ = resources.remove("ButtonBorderBrushDisabled")

                if let fill = button.prominentFill {
                    // A prominent button is filled with its tint in every state,
                    // a little translucent while hovered and pressed, as Fluent's
                    // accent button is.
                    func brush(_ alpha: Double) -> SolidColorBrush {
                        var color = fill
                        color.a = UInt8((Double(fill.a) * alpha).rounded())
                        return SolidColorBrush(color)
                    }
                    let transparentBrush = SolidColorBrush(UWP.Color.transparent)
                    button.background = brush(1)
                    button.borderBrush = transparentBrush
                    _ = resources.insert("ButtonBackgroundPointerOver", brush(0.9))
                    _ = resources.insert("ButtonBackgroundPressed", brush(0.8))
                    _ = resources.insert("ButtonBackgroundDisabled", brush(0.4))
                    _ = resources.insert("ButtonBorderBrushPointerOver", transparentBrush)
                    _ = resources.insert("ButtonBorderBrushPressed", transparentBrush)
                    _ = resources.insert("ButtonBorderBrushDisabled", transparentBrush)
                }
                button.applyBorderShape()
            case .plain, .borderless:
                let transparentBrush = SolidColorBrush(UWP.Color.transparent)
                button.background = transparentBrush
                button.borderBrush = transparentBrush
                button.borderThickness = Thickness.null
                button.cornerRadius = CornerRadius.null

                _ = resources.insert("ButtonBackgroundPointerOver", transparentBrush)
                _ = resources.insert("ButtonBackgroundPressed", transparentBrush)
                _ = resources.insert("ButtonBackgroundDisabled", transparentBrush)

                _ = resources.insert("ButtonBorderBrushPointerOver", transparentBrush)
                _ = resources.insert("ButtonBorderBrushPressed", transparentBrush)
                _ = resources.insert("ButtonBorderBrushDisabled", transparentBrush)
        }
    }

    fileprivate func applyModifications(_ button: CustomButton) {
        switch self {
            case .bordered: button.opacity = 1.0
            case .plain, .borderless:
                button.opacity = button.enabled
                    ? button.isHighlighted ? 0.7: 1.0
                    : 0.365
                // Why 36.5% opacity was chosen
                // https://github.com/microsoft/microsoft-ui-xaml/blob/fc2f821173298e8130fb5b143373ba70793bc251/src/controls/dev/CommonStyles/Common_themeresources_any.xaml#L8
                // 5D = 93 in base 10, 93 / 255 = 0.3647 ~ 0.365
        }
    }
}

extension UWP.Color {
    static let transparent: Self = UWP.Color(a: 0, r: 0, g: 0, b: 0)
}

extension WinUI.Thickness {
    static let null: Self = Thickness(left: 0, top: 0, right: 0, bottom: 0)
}

extension WinUI.CornerRadius {
    static let null: Self = CornerRadius(topLeft: 0, topRight: 0, bottomRight: 0, bottomLeft: 0)
}
