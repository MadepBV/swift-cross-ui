@_spi(Backends) import SwiftCrossUI
import UWP
import WinUI

extension WinUIBackend: BackendFeatures.ConfirmationDialogs {
    /// The colour used to mark destructive actions.
    ///
    /// Windows has no native destructive button style, so a red accent is the
    /// closest widely-understood equivalent.
    private static let destructiveColor = UWP.Color(a: 255, r: 196, g: 43, b: 28)

    /// The colour used for text on top of ``destructiveColor``.
    private static let destructiveForegroundColor = UWP.Color(a: 255, r: 255, g: 255, b: 255)

    public func updateConfirmationDialog(
        _ dialog: Alert,
        title: String,
        titleVisibility: SwiftCrossUI.Visibility,
        message: String?,
        actions: [ConfirmationDialogAction],
        environment: EnvironmentValues
    ) {
        if titleVisibility == .hidden {
            dialog.title = nil
            dialog.content = message ?? title
        } else {
            dialog.title = title
            dialog.content = message
        }

        switch environment.colorScheme {
            case .light:
                dialog.requestedTheme = .light
            case .dark:
                dialog.requestedTheme = .dark
        }

        // `ContentDialog` has exactly three button slots and no way to reorder
        // them, and its close button is the one that Escape and light dismissal
        // activate. A cancelling action therefore has to go in the close slot
        // regardless of where the author declared it, and
        // `confirmationDialogActionIndex(forResponse:actions:)` undoes the
        // reordering afterwards.
        let slots = Self.actionSlots(for: actions)
        if actions.count > slots.count {
            logger.warning(
                """
                WinUI's ContentDialog supports at most \(slots.count) actions; \
                ignoring \(actions.count - slots.count) of them
                """
            )
        }

        dialog.primaryButtonText = slots[0].map { index in actions[index].label } ?? ""
        dialog.secondaryButtonText = slots[1].map { index in actions[index].label } ?? ""
        dialog.closeButtonText = slots[2].map { index in actions[index].label } ?? ""

        dialog.defaultButton = slots[0] == nil ? .close : .primary

        // The default (primary) button is the one that picks up the accent
        // style, so recolouring the accent resources within this dialog is the
        // only way to make a destructive action look destructive.
        if let primary = slots[0], actions[primary].role == .destructive {
            let background = SolidColorBrush(Self.destructiveColor)
            let foreground = SolidColorBrush(Self.destructiveForegroundColor)
            for key in [
                "AccentButtonBackground",
                "AccentButtonBackgroundPointerOver",
                "AccentButtonBackgroundPressed"
            ]
            {
                _ = dialog.resources.insert(key, background)
            }
            for key in [
                "AccentButtonForeground",
                "AccentButtonForegroundPointerOver",
                "AccentButtonForegroundPressed"
            ]
            {
                _ = dialog.resources.insert(key, foreground)
            }
        }
    }

    public func confirmationDialogActionIndex(
        forResponse response: Int,
        actions: [ConfirmationDialogAction]
    ) -> Int? {
        let slots = Self.actionSlots(for: actions)
        guard slots.indices.contains(response) else {
            return nil
        }
        return slots[response]
    }

    /// Assigns actions to `ContentDialog`'s three button slots.
    ///
    /// The slots are, in order, primary, secondary, and close. A cancelling
    /// action always claims the close slot, because that's the slot Escape and
    /// light dismissal activate.
    ///
    /// - Parameter actions: The dialog's actions.
    /// - Returns: An index into `actions` for each slot, or `nil` for slots
    ///   that should stay empty.
    private static func actionSlots(
        for actions: [ConfirmationDialogAction]
    ) -> [Int?] {
        var uncancelled: [Int] = []
        var cancelled: Int?

        for (index, action) in actions.enumerated() {
            if action.role == .cancel && cancelled == nil {
                cancelled = index
            } else {
                uncancelled.append(index)
            }
        }

        var slots: [Int?] = [nil, nil, nil]
        if uncancelled.count > 0 {
            slots[0] = uncancelled[0]
        }
        if uncancelled.count > 1 {
            slots[1] = uncancelled[1]
        }
        if let cancelled {
            slots[2] = cancelled
        } else if uncancelled.count > 2 {
            slots[2] = uncancelled[2]
        }
        return slots
    }
}
