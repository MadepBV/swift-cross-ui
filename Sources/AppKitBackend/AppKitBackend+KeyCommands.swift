import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.KeyCommands {
    public func createKeyCommandTarget(wrapping child: Widget) -> Widget {
        let target = NSKeyCommandTarget()
        target.addSubview(child)
        child.leadingAnchor.constraint(equalTo: target.leadingAnchor).isActive = true
        child.topAnchor.constraint(equalTo: target.topAnchor).isActive = true
        child.translatesAutoresizingMaskIntoConstraints = false
        return target
    }

    public func updateKeyCommandTarget(
        _ target: Widget,
        isEnabled: Bool,
        environment: EnvironmentValues,
        handler: @escaping @MainActor (KeyCommandEvent) -> KeyCommandResult
    ) {
        let target = target as! NSKeyCommandTarget
        target.commandsEnabled = isEnabled && environment.isEnabled
        target.commands.update(isEnabled: target.commandsEnabled, handler: handler)
    }
}

final class NSKeyCommandTarget: NSView {
    let commands = KeyCommandDispatchState()
    var commandsEnabled = false
    override var acceptsFirstResponder: Bool { commandsEnabled }
    override var isFlipped: Bool { true }

    override func keyDown(with event: NSEvent) {
        // The local monitor has already offered this original event once. A
        // passive NSView does not implement Tab navigation itself, so preserve
        // the native key-view fallback when the command handler declined it.
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let navigationFlags: NSEvent.ModifierFlags = [.shift, .capsLock, .numericPad]
        if event.keyCode == 48, flags.subtracting(navigationFlags).isEmpty,
           let window {
            if flags.contains(.shift) { window.selectPreviousKeyView(self) }
            else { window.selectNextKeyView(self) }
            return
        }
        super.keyDown(with: event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { NSKeyCommandMonitor.shared.install() }
    }
}

/// One monitor, no target registry. Native first responder/hit testing selects
/// the scope, so neither its handler nor detached targets are retained globally.
@MainActor
final class NSKeyCommandMonitor {
    static let shared = NSKeyCommandMonitor()
    private var monitor: Any?

    func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { event in
            let carried = KeyCommandCarriedEvent(event: event)
            let handled = MainActor.assumeIsolated {
                Self.handle(carried.event)
            }
            return handled ? nil : event
        }
    }

    static func handle(_ event: NSEvent) -> Bool {
        guard let window = event.window else { return false }
        if event.type == .keyDown {
            guard window.isKeyWindow,
                  let target = window.firstResponder as? NSKeyCommandTarget,
                  target.window === window,
                  let command = appKitKeyCommand(from: event) else { return false }
            return target.commands.dispatch(
                command, hasNativeFocus: true, isAttached: target.window != nil
            ) == .handled
        }
        guard let content = window.contentView else { return false }
        // NSView.hitTest receives coordinates in its superview's space.
        let point = content.superview?.convert(event.locationInWindow, from: nil)
            ?? event.locationInWindow
        var current = content.hitTest(point)
        while let view = current {
            if let target = view as? NSKeyCommandTarget {
                if target.commandsEnabled { _ = window.makeFirstResponder(target) }
                break
            }
            // Image views are passive NSControls. Native interactive controls
            // and field editors retain their own input/focus/IME processing.
            if view is NSText || view is NSCustomButton
                || (view is NSControl && !(view is NSImageView)) { break }
            current = view.superview
        }
        // Pointer input continues unchanged to the existing gesture recognizers.
        return false
    }
}

private struct KeyCommandCarriedEvent: @unchecked Sendable {
    let event: NSEvent
}

func appKitKeyCommand(from event: NSEvent) -> KeyCommandEvent? {
    let usesCommandModifier = !event.modifierFlags.intersection([.command, .control]).isEmpty
    let produced = usesCommandModifier ? event.charactersIgnoringModifiers : event.characters
    guard let text = produced, text.count == 1,
          var character = text.first else { return nil }
    // AppKit represents backward Tab and backspace differently from the shared
    // named constants. Preserve Shift in modifiers when normalizing backtab.
    if character == "\u{19}" { character = KeyEquivalent.tab.character }
    if character == "\u{7f}" { character = KeyEquivalent.delete.character }
    var modifiers: EventModifiers = []
    if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
    if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
    // Option remains input metadata even when it produced a layout character.
    // The application may accept that character only in a specific context.
    if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
    if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
    if event.modifierFlags.contains(.capsLock) { modifiers.insert(.capsLock) }
    if event.modifierFlags.contains(.numericPad) { modifiers.insert(.numericPad) }
    return KeyCommandEvent(key: KeyEquivalent(character), modifiers: modifiers, isRepeat: event.isARepeat)
}
