import CGtk
import Foundation
import Gtk
@_spi(Backends) import SwiftCrossUI

/// The colour chooser dialogs that are currently on screen.
///
/// GTK keeps the underlying window alive on its own, but the Swift wrapper has
/// to be kept alive too, otherwise it deinitializes and disconnects the
/// `response` signal handler out from under the dialog.
@MainActor
private var activeColorChoosers: [ObjectIdentifier: Gtk.Dialog] = [:]

extension GtkBackend: BackendFeatures.ColorPickers {
    /// The response id that `GtkColorChooserDialog`'s accept button emits.
    ///
    /// `GTK_RESPONSE_OK` is `-5`, and GTK response ids arrive here as the
    /// zero-extended unsigned reinterpretation of that value (the same
    /// treatment ``GtkBackend/showAlert(_:window:responseHandler:)`` gives
    /// `GTK_RESPONSE_DELETE_EVENT`).
    private static let okResponse = Int(UInt32(bitPattern: Int32(-5)))

    /// The title shown on the colour chooser dialog.
    private static let chooserTitle = "Select a Colour"

    public func createColorPicker() -> Widget {
        // GTK 4 has no compact colour control that this backend can wrap: the
        // Gtk module doesn't bind `GtkColorButton`, and binding one would mean
        // adding a widget wrapper (with its own signal registration) to the Gtk
        // target. A button that opens `GtkColorChooserDialog` is the same
        // interaction, built only from widgets this backend already owns.
        createSimpleButton()
    }

    public func updateColorPicker(
        _ colorPicker: Widget,
        color: Color.Resolved,
        supportsOpacity: Bool,
        environment: EnvironmentValues,
        onChange: @escaping (Color.Resolved) -> Void
    ) {
        updateSimpleButton(
            colorPicker,
            label: Self.label(for: color, includingOpacity: supportsOpacity),
            environment: environment,
            action: { [weak self] in
                self?.presentColorChooser(
                    initialColor: color,
                    supportsOpacity: supportsOpacity,
                    onChange: onChange
                )
            }
        )
    }

    /// Shows a modal colour chooser and reports the user's choice.
    ///
    /// - Parameters:
    ///   - initialColor: The colour to select when the chooser opens.
    ///   - supportsOpacity: Whether the chooser should offer an opacity
    ///     control.
    ///   - onChange: Called with the chosen colour if the user accepts.
    private func presentColorChooser(
        initialColor: Color.Resolved,
        supportsOpacity: Bool,
        onChange: @escaping (Color.Resolved) -> Void
    ) {
        guard let pointer = gtk_color_chooser_dialog_new(Self.chooserTitle, nil) else {
            logger.warning("GtkBackend failed to create a colour chooser dialog")
            return
        }

        let dialog = Gtk.Dialog(pointer)
        let chooser = dialog.opaquePointer

        gtk_color_chooser_set_use_alpha(chooser, supportsOpacity ? 1 : 0)
        var rgba = initialColor.gtkColor.gdkColor
        gtk_color_chooser_set_rgba(chooser, &rgba)

        activeColorChoosers[ObjectIdentifier(dialog)] = dialog

        dialog.response = { dialog, responseId in
            defer {
                dialog.destroy()
                activeColorChoosers[ObjectIdentifier(dialog)] = nil
            }

            guard responseId == Self.okResponse else {
                return
            }

            var chosen = GdkRGBA()
            gtk_color_chooser_get_rgba(dialog.opaquePointer, &chosen)
            onChange(
                Color.Resolved(
                    red: Float(chosen.red),
                    green: Float(chosen.green),
                    blue: Float(chosen.blue),
                    opacity: supportsOpacity ? Float(chosen.alpha) : 1
                )
            )
        }

        dialog.isModal = true
        if let window = windows.first {
            dialog.setTransient(for: window)
        }
        dialog.show()
    }

    /// Builds the label shown on the picker's button.
    ///
    /// - Parameters:
    ///   - color: The currently selected colour.
    ///   - includingOpacity: Whether to include the opacity component.
    /// - Returns: The colour as an uppercase hex string.
    private static func label(
        for color: Color.Resolved,
        includingOpacity: Bool
    ) -> String {
        func component(_ value: Float) -> String {
            let byte = UInt8(max(0, min(1, value)) * 255)
            return String(format: "%02X", byte)
        }

        let base = "#\(component(color.red))\(component(color.green))\(component(color.blue))"
        guard includingOpacity else {
            return base
        }
        return base + component(color.opacity)
    }
}
