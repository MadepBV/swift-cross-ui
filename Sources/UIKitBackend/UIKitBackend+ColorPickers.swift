@_spi(Backends) import SwiftCrossUI
import UIKit

extension UIKitBackend: BackendFeatures.ColorPickers {
    public func createColorPicker() -> Widget {
        #if os(tvOS)
            // tvOS has no colour picker of any kind.
            return createContainer()
        #else
            if #available(iOS 14, macCatalyst 14, *) {
                let widget = ColorPickerWidget(child: UIColorWell())
                widget.startObservingChanges()
                return widget
            }
            return createContainer()
        #endif
    }

    public func updateColorPicker(
        _ colorPicker: Widget,
        color: Color.Resolved,
        supportsOpacity: Bool,
        environment: EnvironmentValues,
        onChange: @escaping (Color.Resolved) -> Void
    ) {
        #if !os(tvOS)
            if #available(iOS 14, macCatalyst 14, *) {
                guard let widget = colorPicker as? ColorPickerWidget else {
                    return
                }
                widget.changeHandler = onChange
                widget.child.supportsAlpha = supportsOpacity
                widget.child.isEnabled = environment.isEnabled

                // Only write the colour back when it actually differs, so that
                // we don't fight the user while they're picking.
                if widget.resolvedColor != color {
                    widget.child.selectedColor = UIColor(
                        red: CGFloat(color.red),
                        green: CGFloat(color.green),
                        blue: CGFloat(color.blue),
                        alpha: supportsOpacity ? CGFloat(color.opacity) : 1
                    )
                }
            }
        #endif
    }
}

#if !os(tvOS)
    /// A widget wrapping a `UIColorWell`.
    @available(iOS 14, macCatalyst 14, *)
    final class ColorPickerWidget: WrapperWidget<UIColorWell> {
        /// Called whenever the user picks a different colour.
        var changeHandler: ((Color.Resolved) -> Void)?

        /// Whether the change action has already been attached.
        private var isObservingChanges = false

        /// The well's colour in SwiftCrossUI's representation.
        var resolvedColor: Color.Resolved {
            guard let selectedColor = child.selectedColor else {
                return Color.Resolved(red: 0, green: 0, blue: 0, opacity: 1)
            }

            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            selectedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            return Color.Resolved(
                red: Float(red),
                green: Float(green),
                blue: Float(blue),
                opacity: Float(alpha)
            )
        }

        /// Starts reporting the user's colour choices to ``changeHandler``.
        ///
        /// A closure-based `UIAction` is used rather than a target/action pair
        /// because `@objc` members aren't available to subclasses of a generic
        /// class.
        func startObservingChanges() {
            guard !isObservingChanges else {
                return
            }
            isObservingChanges = true

            let action = UIAction { [weak self] _ in
                guard let self else {
                    return
                }
                self.changeHandler?(self.resolvedColor)
            }
            child.addAction(action, for: .valueChanged)
        }
    }
#endif
