import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.KeyboardShortcuts, BackendFeatures.Focus {}

// MARK: - Keyboard shortcuts

extension AppKitBackend {
    public func createKeyboardShortcutTarget(wrapping child: Widget) -> Widget {
        let container = NSKeyboardShortcutTarget()
        container.addSubview(child)
        child.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        child.topAnchor.constraint(equalTo: container.topAnchor)
            .isActive = true
        child.translatesAutoresizingMaskIntoConstraints = false
        return container
    }

    public func updateKeyboardShortcutTarget(
        _ target: Widget,
        shortcut: KeyboardShortcut?,
        environment: EnvironmentValues
    ) {
        guard let target = target as? NSKeyboardShortcutTarget else { return }
        target.isEnabled = environment.isEnabled
        target.shortcut = shortcut
    }
}

/// A container that activates its content when a keyboard shortcut is pressed.
///
/// Two mechanisms are used, depending on what's inside:
///
/// - When the content is a real `NSButton` (which is what
///   `createSimpleButton()` produces), the shortcut is installed as the
///   button's `keyEquivalent`. That's the native AppKit path: it's scoped to
///   the key window through `NSWindow.performKeyEquivalent(with:)`, and it
///   gives `.defaultAction` buttons their blue default-button appearance for
///   free.
/// - Otherwise (most notably SwiftCrossUI's own `NSCustomButton`, which is an
///   `NSView` rather than an `NSButton`) the target registers with
///   ``KeyboardShortcutMonitor``, which runs a single app-wide `NSEvent` local
///   monitor.
final class NSKeyboardShortcutTarget: NSView {
    /// The shortcut currently attached, if any.
    var shortcut: KeyboardShortcut? {
        didSet {
            guard shortcut != oldValue else { return }
            applyShortcut()
        }
    }

    /// Whether the shortcut is allowed to fire.
    var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            applyShortcut()
        }
    }

    /// The `NSButton` the shortcut was installed on natively, if any.
    private weak var nativeButton: NSButton?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyShortcut()
    }

    // NB: There's deliberately no `deinit` unregistering from
    // `KeyboardShortcutMonitor`. Its target table holds weak references and
    // drops deallocated targets by itself, and `deinit` isn't guaranteed to
    // run on the main actor, so asserting main actor isolation there would
    // risk trapping.

    /// Installs the current shortcut using whichever mechanism suits the
    /// content, tearing down the other one.
    private func applyShortcut() {
        clearNativeShortcut()

        guard let shortcut, isEnabled else {
            KeyboardShortcutMonitor.shared.unregister(self)
            return
        }

        if let button = activationTarget as? NSButton {
            button.keyEquivalent = String(shortcut.key.character)
            button.keyEquivalentModifierMask = shortcut.modifiers.nsModifierFlags
            nativeButton = button
            KeyboardShortcutMonitor.shared.unregister(self)
        } else {
            KeyboardShortcutMonitor.shared.register(self)
        }
    }

    /// Removes a previously installed native key equivalent.
    private func clearNativeShortcut() {
        guard let nativeButton else { return }
        nativeButton.keyEquivalent = ""
        nativeButton.keyEquivalentModifierMask = []
        self.nativeButton = nil
    }

    /// Whether the given event should fire this target's shortcut.
    func matches(_ event: NSEvent) -> Bool {
        guard
            let shortcut,
            isEnabled,
            let window,
            window.isKeyWindow
        else {
            return false
        }

        // A shortcut without a command-class modifier would otherwise swallow
        // ordinary typing, so ignore it while a text view is being edited.
        // Keys that macOS itself treats as commands (return, escape, the
        // arrows, and so on) are exempt, because triggering the default button
        // from a text field is exactly the expected behaviour.
        if !shortcut.usesCommandClassModifier, !shortcut.key.isCommandKey,
           window.isEditingText
        {
            return false
        }

        return shortcut.matches(event)
    }

    /// Activates the content, as though the user had clicked it.
    func activate() {
        guard let target = activationTarget else { return }
        if let button = target as? NSCustomButton {
            // `NSCustomButton` keeps its action private; its accessibility
            // press is the supported way to trigger it from outside.
            _ = button.accessibilityPerformPress()
        } else if let button = target as? NSButton {
            button.performClick(nil)
        } else if let control = target as? NSControl {
            _ = control.sendAction(control.action, to: control.target)
        }
    }

    /// The nearest descendant that has a primary action.
    private var activationTarget: NSView? {
        var queue = subviews
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if next is NSCustomButton || next is NSButton || next is NSControl {
                return next
            }
            queue.append(contentsOf: next.subviews)
        }
        return nil
    }
}

/// A single app-wide `NSEvent` local monitor that dispatches keyboard
/// shortcuts to registered targets.
///
/// One monitor for the whole app is much cheaper than one per shortcut, and it
/// gives a single well-defined place to decide whether an event is consumed.
@MainActor
final class KeyboardShortcutMonitor {
    static let shared = KeyboardShortcutMonitor()

    /// Registered targets, held weakly so that targets removed from the view
    /// hierarchy don't leak.
    private let targets = NSHashTable<NSKeyboardShortcutTarget>.weakObjects()
    private var monitor: Any?

    private init() {}

    /// Starts routing key events to a target.
    func register(_ target: NSKeyboardShortcutTarget) {
        targets.add(target)
        startMonitoring()
    }

    /// Stops routing key events to a target.
    func unregister(_ target: NSKeyboardShortcutTarget) {
        targets.remove(target)
    }

    private func startMonitoring() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Local monitors always run on the main thread, but the handler
            // isn't declared as main actor isolated, so the event has to be
            // carried across the boundary by hand.
            let carried = CarriedEvent(event: event)
            let consumed = MainActor.assumeIsolated {
                KeyboardShortcutMonitor.shared.handle(carried.event)
            }
            return consumed ? nil : event
        }
    }

    /// Dispatches an event to the first matching target.
    ///
    /// - Returns: Whether the event was consumed.
    private func handle(_ event: NSEvent) -> Bool {
        for target in targets.allObjects where target.matches(event) {
            target.activate()
            return true
        }
        return false
    }
}

/// Carries a non-`Sendable` `NSEvent` into a main actor isolated closure.
///
/// Safe because `NSEvent` local monitors are only ever invoked on the main
/// thread, so the event never actually crosses threads.
private struct CarriedEvent: @unchecked Sendable {
    let event: NSEvent
}

// MARK: - Focus

extension AppKitBackend {
    public func createFocusTarget(wrapping child: Widget) -> Widget {
        let container = NSFocusTarget()
        container.addSubview(child)
        child.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        child.topAnchor.constraint(equalTo: container.topAnchor)
            .isActive = true
        child.translatesAutoresizingMaskIntoConstraints = false
        return container
    }

    public func updateFocusTarget(
        _ target: Widget,
        isFocused: Bool,
        environment: EnvironmentValues,
        onFocusChange: @escaping (Bool) -> Void
    ) {
        guard let target = target as? NSFocusTarget else { return }
        target.onFocusChange = onFocusChange
        target.isEnabled = environment.isEnabled
        target.setDesiredFocus(isFocused)
    }
}

/// A container that drives and observes its content's first responder status.
///
/// Focus is genuinely bidirectional here:
///
/// - Writing to a `FocusState` reaches ``setDesiredFocus(_:)``, which calls
///   `NSWindow.makeFirstResponder(_:)`.
/// - AppKit has no first-responder-changed notification, so the target watches
///   `NSWindow.didUpdateNotification` (posted once per event loop pass for
///   each window that needs updating) and reports transitions back. That is
///   the conventional way to track the first responder on macOS.
final class NSFocusTarget: NSView {
    /// Called when the platform changes this target's focus.
    var onFocusChange: ((Bool) -> Void)?

    /// Whether the content may take focus at all.
    var isEnabled = true

    /// The focus state most recently requested by the bound `FocusState`.
    private var desiredFocus = false

    /// The focus state most recently reported (or applied), used to suppress
    /// duplicate and self-inflicted notifications.
    private var lastKnownFocus = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observeWindowUpdates()
        // The view may only now have gained a window, so a focus request made
        // before it was installed can finally be honoured.
        applyDesiredFocus()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Records the desired focus state and tries to apply it.
    func setDesiredFocus(_ shouldFocus: Bool) {
        desiredFocus = shouldFocus
        applyDesiredFocus()
    }

    private func observeWindowUpdates() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSWindow.didUpdateNotification,
            object: nil
        )
        guard let window else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidUpdate),
            name: NSWindow.didUpdateNotification,
            object: window
        )
    }

    @objc
    private func windowDidUpdate(_ notification: Notification) {
        let hasFocus = currentlyHasFocus
        guard hasFocus != lastKnownFocus else { return }
        lastKnownFocus = hasFocus
        onFocusChange?(hasFocus)
    }

    /// Moves platform focus to match ``desiredFocus``.
    ///
    /// `lastKnownFocus` is refreshed straight afterwards so that the resulting
    /// `NSWindow.didUpdateNotification` isn't mistaken for a user-driven focus
    /// change, which would otherwise bounce the value back into the binding.
    private func applyDesiredFocus() {
        guard let window else { return }

        let hasFocus = currentlyHasFocus
        lastKnownFocus = hasFocus

        if desiredFocus {
            guard !hasFocus, isEnabled, let view = firstFocusableView else { return }
            _ = window.makeFirstResponder(view)
        } else if hasFocus {
            _ = window.makeFirstResponder(nil)
        }

        lastKnownFocus = currentlyHasFocus
    }

    /// Whether the content currently holds keyboard focus.
    private var currentlyHasFocus: Bool {
        guard
            let window,
            let responder = window.firstResponder as? NSView
        else {
            return false
        }

        if responder.isDescendant(of: self) {
            return true
        }

        // An editable NSTextField hands focus to the window's shared field
        // editor, so the first responder is an NSText owned by the window
        // rather than a descendant of ours. Its delegate is the control that's
        // being edited.
        if
            let fieldEditor = responder as? NSText,
            let delegate = fieldEditor.delegate as? NSView,
            delegate.isDescendant(of: self)
        {
            return true
        }

        return false
    }

    /// The nearest descendant that will accept first responder status.
    private var firstFocusableView: NSView? {
        var queue = subviews
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if next.acceptsFirstResponder {
                return next
            }
            queue.append(contentsOf: next.subviews)
        }
        return nil
    }
}

// MARK: - Platform mapping

extension EventModifiers {
    /// The AppKit modifier mask corresponding to these modifiers.
    var nsModifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.command) {
            flags.insert(.command)
        }
        if contains(.option) {
            flags.insert(.option)
        }
        if contains(.control) {
            flags.insert(.control)
        }
        if contains(.shift) {
            flags.insert(.shift)
        }
        if contains(.capsLock) {
            flags.insert(.capsLock)
        }
        if contains(.numericPad) {
            flags.insert(.numericPad)
        }
        return flags
    }
}

extension KeyEquivalent {
    /// Whether macOS treats this key as a command rather than as text input.
    ///
    /// Control characters (return, tab, escape, delete) and the function key
    /// range that AppKit reserves for arrows, page up/down and friends.
    var isCommandKey: Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        return scalar.value < 0x20 || scalar.value == 0x7F || scalar.value >= 0xF700
    }
}

extension KeyboardShortcut {
    /// Whether the shortcut includes a modifier that makes it a command rather
    /// than ordinary typing.
    var usesCommandClassModifier: Bool {
        !modifiers.intersection([.command, .control, .option]).isEmpty
    }

    /// Whether a key event should trigger this shortcut.
    func matches(_ event: NSEvent) -> Bool {
        // Only compare the modifiers that matter. Caps lock and the numeric
        // pad flag are frequently set incidentally, so they're only compared
        // when the shortcut actually asks for them.
        var mask: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        if modifiers.contains(.capsLock) {
            mask.insert(.capsLock)
        }
        if modifiers.contains(.numericPad) {
            mask.insert(.numericPad)
        }

        guard event.modifierFlags.intersection(mask) == modifiers.nsModifierFlags else {
            return false
        }
        guard let pressed = event.charactersIgnoringModifiers?.first else {
            return false
        }
        // `charactersIgnoringModifiers` still applies shift, so compare
        // case-insensitively; the shift requirement is already covered above.
        return pressed.lowercased() == key.character.lowercased()
    }
}

extension NSWindow {
    /// Whether the window's first responder is editing text.
    var isEditingText: Bool {
        firstResponder is NSText
    }
}
