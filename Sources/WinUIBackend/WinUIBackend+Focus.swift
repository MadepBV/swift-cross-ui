@_spi(Backends) import SwiftCrossUI
import UWP
import WinSDK
import WinUI
import WindowsFoundation

extension WinUIBackend: BackendFeatures.KeyboardShortcuts, BackendFeatures.Focus {}

// MARK: - Keyboard shortcuts

extension WinUIBackend {
    /// WinUI attaches accelerators to elements directly, so no wrapper element
    /// is needed.
    public func createKeyboardShortcutTarget(wrapping child: Widget) -> Widget {
        child
    }

    public func updateKeyboardShortcutTarget(
        _ target: Widget,
        shortcut: SwiftCrossUI.KeyboardShortcut?,
        environment: EnvironmentValues
    ) {
        // `KeyboardShortcutModifier` commits this unconditionally, and a
        // shortcut essentially never changes, so the three property writes
        // below are skipped when nothing about it moved.
        let entry = WidgetPropertyCache.shared.entry(for: target)
        let wanted = (shortcut: shortcut, isEnabled: environment.isEnabled)
        if let applied = entry.keyboardShortcut,
           applied.shortcut == wanted.shortcut,
           applied.isEnabled == wanted.isEnabled
        {
            return
        }
        entry.keyboardShortcut = wanted

        guard
            let shortcut,
            environment.isEnabled,
            let mapping = shortcut.key.virtualKeyMapping
        else {
            KeyboardShortcutRegistry.shared.disableAccelerator(for: target)
            return
        }

        KeyboardShortcutRegistry.shared.updateAccelerator(
            for: target,
            key: mapping.key,
            modifiers: shortcut.modifiers.union(mapping.modifiers).virtualKeyModifiers
        )
    }
}

/// Tracks the ``WinUI/KeyboardAccelerator`` attached to each shortcut target.
///
/// Accelerators are created once per element and then mutated in place.
/// Removing an accelerator from a `UIElement.keyboardAccelerators` vector
/// requires finding its index, so it's simpler and safer to keep the same
/// accelerator around and disable it when the shortcut goes away.
@MainActor
final class KeyboardShortcutRegistry {
    static let shared = KeyboardShortcutRegistry()

    @MainActor
    private final class Entry {
        weak var element: WinUI.FrameworkElement?
        let accelerator: WinUI.KeyboardAccelerator
        private var placementBeforeSuppression: WinUI.KeyboardAcceleratorPlacementMode?

        init(element: WinUI.FrameworkElement, accelerator: WinUI.KeyboardAccelerator) {
            self.element = element
            self.accelerator = accelerator
        }

        func suppressAutomaticTooltip() {
            guard let element, placementBeforeSuppression == nil else { return }
            placementBeforeSuppression = element.keyboardAcceleratorPlacementMode
            element.keyboardAcceleratorPlacementMode = .hidden
        }

        func restoreAutomaticTooltip() {
            guard let element, let placementBeforeSuppression else { return }
            element.keyboardAcceleratorPlacementMode = placementBeforeSuppression
            self.placementBeforeSuppression = nil
        }
    }

    private var entries: [ObjectIdentifier: Entry] = [:]
    private var registrationsUntilPruning = 64

    private init() {}

    private func existingEntry(for element: WinUI.FrameworkElement) -> Entry? {
        let identifier = ObjectIdentifier(element)
        guard let entry = entries[identifier] else { return nil }
        // A released Swift WinRT wrapper's address can be reused for a different
        // element. An identifier match alone must not reuse its accelerator.
        guard entry.element === element else {
            entries.removeValue(forKey: identifier)
            return nil
        }
        return entry
    }

    func disableAccelerator(for element: WinUI.FrameworkElement) {
        guard let entry = existingEntry(for: element) else { return }
        entry.accelerator.isEnabled = false
        entry.restoreAutomaticTooltip()
    }

    /// Configures shortcuts before attaching them to a potentially live tree.
    func updateAccelerator(
        for element: WinUI.FrameworkElement,
        key: UWP.VirtualKey,
        modifiers: UWP.VirtualKeyModifiers
    ) {
        let existing = existingEntry(for: element)
        let entry: Entry
        if let existing {
            entry = existing
        } else {
            // Amortize cleanup over registrations, not recurring view updates.
            // Dead targets must not keep their native accelerator/delegate alive.
            registrationsUntilPruning -= 1
            if registrationsUntilPruning == 0 {
                entries = entries.filter { $0.value.element != nil }
                registrationsUntilPruning = 64
            }
            let accelerator = WinUI.KeyboardAccelerator()
            entry = Entry(element: element, accelerator: accelerator)
            // The target is usually a container around the primary control.
            accelerator.invoked.addHandler { [weak element] _, args in
                guard let element else { return }
                if activatePrimaryAction(of: element) {
                    args?.handled = true
                }
            }
        }

        let accelerator = entry.accelerator
        accelerator.isEnabled = false
        let hasNativeLabel = WindowsKeyTranslation.hasWinUIAcceleratorLabel(
            for: UInt16(key.rawValue)
        )
        if !hasNativeLabel {
            // WinUI 1.5 fails fast while formatting some valid OEM key names
            // (microsoft/microsoft-ui-xaml#708). Hide only that display path;
            // the native accelerator still handles the original key/modifiers.
            entry.suppressAutomaticTooltip()
        }
        accelerator.key = key
        accelerator.modifiers = modifiers
        if hasNativeLabel {
            // Change the key while still hidden, then restore the target's
            // previous placement mode once formatting the key is safe again.
            entry.restoreAutomaticTooltip()
        }
        accelerator.isEnabled = true

        if existing == nil {
            // All properties, including tooltip suppression when required, are
            // settled before EnterImpl runs in an already-live element tree.
            element.keyboardAccelerators.append(accelerator)
            entries[ObjectIdentifier(element)] = entry
        }
    }
}

/// Performs the primary activation of the first control found in an element's
/// subtree, as a keyboard shortcut is expected to.
///
/// Buttons are clicked, checkboxes and switches are toggled. Other widgets
/// have no primary activation, in which case nothing happens.
///
/// - Parameter element: The element to search.
/// - Returns: Whether a control was activated.
@MainActor
private func activatePrimaryAction(of element: WinUI.FrameworkElement) -> Bool {
    var queue: [WinUI.FrameworkElement] = [element]
    while !queue.isEmpty {
        let next = queue.removeFirst()
        if let button = next as? CustomButton {
            button.performClick()
            return true
        } else if let checkbox = next as? WinUIBackend.CustomCheckBox {
            guard checkbox.isEnabled else { return false }
            checkbox.isChecked = !(checkbox.isChecked ?? false)
            return true
        } else if let toggleSwitch = next as? WinUI.ToggleSwitch {
            guard toggleSwitch.isEnabled else { return false }
            toggleSwitch.isOn = !toggleSwitch.isOn
            return true
        }

        if let panel = next as? WinUI.Panel {
            for index in 0..<panel.children.size {
                if let child = panel.children.getAt(index) as? WinUI.FrameworkElement {
                    queue.append(child)
                }
            }
        } else if let contentControl = next as? WinUI.ContentControl,
                  let content = contentControl.content as? WinUI.FrameworkElement
        {
            queue.append(content)
        }
    }
    return false
}

// MARK: - Focus

extension WinUIBackend {
    /// Focus is observed via routed events, which bubble, so the child can be
    /// used directly without a wrapper element.
    public func createFocusTarget(wrapping child: Widget) -> Widget {
        child
    }

    public func updateFocusTarget(
        _ target: Widget,
        isFocused: Bool,
        environment: EnvironmentValues,
        onFocusChange: @escaping (Bool) -> Void
    ) {
        let entry = FocusRegistry.shared.entry(for: target)
        entry.onFocusChange = onFocusChange
        entry.isEnabled = environment.isEnabled
        entry.applyDesiredFocus(isFocused)
    }
}

/// Tracks focus observation state for each focus target.
///
/// - Important: WinUI always keeps something focused within a window and gives
///   no supported way to clear focus programmatically, so setting a
///   ``SwiftCrossUI/FocusState`` back to `nil`/`false` does *not* move focus
///   away on this backend. The state to focus direction therefore only works
///   for *giving* focus; the focus to state direction is complete, because
///   `GotFocus` and `LostFocus` are reported for every focus change including
///   ones WinUI makes itself.
@MainActor
final class FocusRegistry {
    static let shared = FocusRegistry()

    /// Per-element focus state.
    ///
    /// Isolated explicitly: a nested type doesn't inherit the registry's
    /// isolation, and `applyDesiredFocus` walks the element tree.
    @MainActor
    final class Entry {
        /// Called when the platform changes the element's focus.
        var onFocusChange: ((Bool) -> Void)?
        /// Whether the element may take focus.
        var isEnabled = true
        /// The focus state most recently reported or applied.
        var lastKnownFocus = false
        /// The element being tracked.
        weak var element: WinUI.FrameworkElement?

        init(element: WinUI.FrameworkElement) {
            self.element = element
        }

        /// Moves focus onto the element if it's wanted and doesn't have it.
        func applyDesiredFocus(_ shouldFocus: Bool) {
            guard
                shouldFocus,
                isEnabled,
                !lastKnownFocus,
                let element,
                let control = firstFocusableControl(in: element)
            else {
                return
            }

            if (try? control.focus(WinUI.FocusState.programmatic)) == true {
                lastKnownFocus = true
            }
        }

        /// Reports a platform focus change, ignoring repeats.
        func reportFocus(_ hasFocus: Bool) {
            guard hasFocus != lastKnownFocus else { return }
            lastKnownFocus = hasFocus
            onFocusChange?(hasFocus)
        }
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    private init() {}

    /// Returns the entry for an element, registering routed event handlers on
    /// first use.
    func entry(for element: WinUI.FrameworkElement) -> Entry {
        let key = ObjectIdentifier(element)
        if let existing = entries[key] {
            return existing
        }

        let entry = Entry(element: element)
        entries[key] = entry

        // GotFocus and LostFocus bubble, so handlers on the target also cover
        // focus landing on any of its descendants.
        element.gotFocus.addHandler { [weak entry] _, _ in
            entry?.reportFocus(true)
        }
        element.lostFocus.addHandler { [weak entry] _, _ in
            entry?.reportFocus(false)
        }

        return entry
    }
}

/// Finds the first descendant (or the element itself) that can take focus.
///
/// Walks `Panel.children`, which is how the WinUI backend builds its
/// containers; controls such as `Button` hold their content elsewhere but are
/// themselves focusable, so the walk stops as soon as it reaches one.
@MainActor
private func firstFocusableControl(
    in element: WinUI.FrameworkElement
) -> WinUI.Control? {
    var queue: [WinUI.FrameworkElement] = [element]
    while !queue.isEmpty {
        let next = queue.removeFirst()
        if let control = next as? WinUI.Control, control.isTabStop {
            return control
        }
        guard let panel = next as? WinUI.Panel else { continue }
        for index in 0..<panel.children.size {
            if let child = panel.children.getAt(index) as? WinUI.FrameworkElement {
                queue.append(child)
            }
        }
    }
    return nil
}

// MARK: - Platform mapping

extension SwiftCrossUI.EventModifiers {
    /// The WinUI modifier mask corresponding to these modifiers.
    ///
    /// ``SwiftCrossUI/EventModifiers/command`` maps to Control, not the
    /// Windows key. That's deliberate: a shortcut written as
    /// `.keyboardShortcut("s", modifiers: [.command])` for macOS is Ctrl+S on
    /// Windows, which is what users of a ported app expect. The Windows key is
    /// reserved by the shell and can't be used for app shortcuts anyway.
    ///
    /// `VirtualKeyModifiers` is projected as a plain C enum rather than an
    /// `OptionSet`, so the flags are combined through their raw values.
    var virtualKeyModifiers: UWP.VirtualKeyModifiers {
        var rawValue = UWP.VirtualKeyModifiers.none.rawValue
        if contains(.command) || contains(.control) {
            rawValue |= UWP.VirtualKeyModifiers.control.rawValue
        }
        if contains(.option) {
            rawValue |= UWP.VirtualKeyModifiers.menu.rawValue
        }
        if contains(.shift) {
            rawValue |= UWP.VirtualKeyModifiers.shift.rawValue
        }
        return UWP.VirtualKeyModifiers(rawValue: rawValue)
    }
}

extension SwiftCrossUI.KeyEquivalent {
    /// Named keys have fixed virtual keys; printable keys depend on the
    /// current Windows layout. Required Shift/AltGr modifiers must accompany
    /// the key, including for digits on AZERTY keyboards.
    var virtualKeyMapping: (key: UWP.VirtualKey, modifiers: EventModifiers)? {
        let namedKey: UWP.VirtualKey?
        switch self {
            case .upArrow: namedKey = .up
            case .downArrow: namedKey = .down
            case .leftArrow: namedKey = .left
            case .rightArrow: namedKey = .right
            case .clear: namedKey = .clear
            case .delete: namedKey = .back
            case .deleteForward: namedKey = .delete
            case .end: namedKey = .end
            case .escape: namedKey = .escape
            case .home: namedKey = .home
            case .pageDown: namedKey = .pageDown
            case .pageUp: namedKey = .pageUp
            case .return: namedKey = .enter
            case .space: namedKey = .space
            case .tab: namedKey = .tab
            default: namedKey = nil
        }
        if let namedKey {
            return (namedKey, [])
        }
        guard let translation = WindowsKeyTranslation(
            character: character,
            scan: { VkKeyScanW($0) }
        ) else {
            return nil
        }
        return (
            UWP.VirtualKey(rawValue: .init(translation.virtualKey)),
            translation.modifiers
        )
    }
}
