import Foundation
@_spi(Backends) import SwiftCrossUI
import UWP
import WinSDK

extension WinUIBackend: BackendFeatures.AccessibilityPreferences {
    /// Windows' Settings › Accessibility › Visual effects › Animation
    /// effects, inverted.
    public var prefersReducedMotion: Bool {
        !UWP.UISettings().animationsEnabled
    }

    /// Whether Narrator, or any other screen reader that announces itself
    /// to the system, is running.
    public var isScreenReaderRunning: Bool {
        var isRunning: WindowsBool = false
        guard SystemParametersInfoW(UINT(SPI_GETSCREENREADER), 0, &isRunning, 0).boolValue else {
            return false
        }
        return isRunning.boolValue
    }

    /// Windows has no system switch-access technology to detect.
    public var isSwitchControlRunning: Bool {
        false
    }

    /// Windows' Settings › Accessibility › Text size (1 to 2.25).
    public var preferredTextScaleFactor: Double {
        UWP.UISettings().textScaleFactor
    }
}
