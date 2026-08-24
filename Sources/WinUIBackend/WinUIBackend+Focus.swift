@_spi(Backends) import SwiftCrossUI
import UWP
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
        let accelerator = KeyboardShortcutRegistry.shared.accelerator(for: target)

        guard
            let shortcut,
            environment.isEnabled,
            let key = shortcut.key.virtualKey
        else {
            accelerator.isEnabled = false
            return
        }

        accelerator.key = key
        accelerator.modifiers = shortcut.modifiers.virtualKeyModifiers
        accelerator.isEnabled = true
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

    private var accelerators: [ObjectIdentifier: WinUI.KeyboardAccelerator] = [:]

    private init() {}

    /// Returns the accelerator attached to an element, creating and attaching
    /// one on first use.
    func accelerator(for element: WinUI.FrameworkElement) -> WinUI.KeyboardAccelerator {
        let key = ObjectIdentifier(element)
        if let existing = accelerators[key] {
            return existing
        }

        let accelerator = WinUI.KeyboardAccelerator()
        // When the shortcut fires, activate the wrapped control as though it
        // had been clicked. WinUI would only do that by itself for an
        // accelerator attached directly to a `Button`, and the target here is
        // usually a container around one.
        accelerator.invoked.addHandler { [weak element] _, args in
            guard let element else { return }
            if activatePrimaryAction(of: element) {
                args?.handled = true
            }
        }
        element.keyboardAccelerators.append(accelerator)
        accelerators[key] = accelerator
        return accelerator
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
    /// The Windows virtual key corresponding to this key equivalent, if one
    /// exists.
    var virtualKey: UWP.VirtualKey? {
        switch self {
            case .upArrow: return .up
            case .downArrow: return .down
            case .leftArrow: return .left
            case .rightArrow: return .right
            case .clear: return .clear
            case .delete: return .back
            case .deleteForward: return .delete
            case .end: return .end
            case .escape: return .escape
            case .home: return .home
            case .pageDown: return .pageDown
            case .pageUp: return .pageUp
            case .return: return .enter
            case .space: return .space
            case .tab: return .tab
            default: break
        }

        switch character.lowercased() {
            case "a": return .a
            case "b": return .b
            case "c": return .c
            case "d": return .d
            case "e": return .e
            case "f": return .f
            case "g": return .g
            case "h": return .h
            case "i": return .i
            case "j": return .j
            case "k": return .k
            case "l": return .l
            case "m": return .m
            case "n": return .n
            case "o": return .o
            case "p": return .p
            case "q": return .q
            case "r": return .r
            case "s": return .s
            case "t": return .t
            case "u": return .u
            case "v": return .v
            case "w": return .w
            case "x": return .x
            case "y": return .y
            case "z": return .z
            case "0": return .number0
            case "1": return .number1
            case "2": return .number2
            case "3": return .number3
            case "4": return .number4
            case "5": return .number5
            case "6": return .number6
            case "7": return .number7
            case "8": return .number8
            case "9": return .number9
            default: return nil
        }
    }
}
