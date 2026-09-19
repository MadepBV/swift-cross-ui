@_spi(Backends) import SwiftCrossUI
import UWP
import WinSDK
import WinUI
import WindowsFoundation

extension WinUIBackend: BackendFeatures.KeyCommands {
    public func createKeyCommandTarget(wrapping child: Widget) -> Widget {
        let target = WinUIKeyCommandTarget()
        target.background = WinUI.SolidColorBrush(UWP.Color(a: 0, r: 0, g: 0, b: 0))
        target.content = child
        target.horizontalContentAlignment = .stretch
        target.verticalContentAlignment = .stretch
        return target
    }

    public func updateKeyCommandTarget(
        _ target: Widget,
        isEnabled: Bool,
        environment: EnvironmentValues,
        handler: @escaping @MainActor (KeyCommandEvent) -> KeyCommandResult
    ) {
        let target = target as! WinUIKeyCommandTarget
        target.update(isEnabled: isEnabled && environment.isEnabled, handler: handler)
    }
}

/// A real Control gives passive Image/Canvas content a native focus target.
/// Command availability does not disable the child or alter its pointer routing.
@MainActor
final class WinUIKeyCommandTarget: WinUI.ContentControl {
    private var commands: KeyCommandDispatchState!
    private var commandsEnabled = false
    private var pointerFocusClaim: (id: UInt32, generation: UInt64)?
    private var pointerFocusGeneration: UInt64 = 0

    override init() {
        super.init()
        MainActor.assumeIsolated {
            commands = KeyCommandDispatchState()
            isTabStop = false
            pointerPressed.addHandler { [weak self] _, event in
                guard let self, let event, self.commandsEnabled else { return }
                // Do not steal focus from a native child control. Compare COM
                // identity, since routed sources may use a different Swift wrapper.
                var current = event.originalSource as? WinUI.DependencyObject
                while let node = current {
                    if node == (self as WinUI.DependencyObject) {
                        let pointerID = event.pointer.pointerId
                        guard self.pointerFocusClaim == nil
                            || self.pointerFocusClaim?.id == pointerID else { return }
                        if (try? self.focus(.pointer)) == true {
                            self.pointerFocusGeneration &+= 1
                            self.pointerFocusClaim = (pointerID, self.pointerFocusGeneration)
                        }
                        return
                    }
                    if node is WinUI.Control { return }
                    current = WinUI.VisualTreeHelper.getParent(node)
                }
            }
            pointerReleased.addHandler { [weak self] _, event in
                guard let self, let event else { return }
                self.finishPointerFocusClaim(for: event.pointer.pointerId)
            }
            pointerCaptureLost.addHandler { [weak self] _, event in
                guard let self, let event else { return }
                // A child drag recognizer can release capture during the same
                // PointerReleased route; keep the claim through that route.
                self.finishPointerFocusClaim(for: event.pointer.pointerId)
            }
            pointerExited.addHandler { [weak self] _, event in
                guard let self, let event,
                      self.pointerFocusClaim?.id == event.pointer.pointerId else { return }
                guard let point = try? event.getCurrentPoint(self) else {
                    self.pointerFocusClaim = nil
                    return
                }
                let x = Double(point.position.x), y = Double(point.position.y)
                // Child exits also route here. Clear only when the pointer has
                // actually left this scope, including uncaptured outside drags
                // whose release will never route through this target.
                if !x.isFinite || !y.isFinite || x < 0 || y < 0
                    || x >= self.actualWidth || y >= self.actualHeight {
                    self.pointerFocusClaim = nil
                }
            }
            pointerCanceled.addHandler { [weak self] _, event in
                guard let self, let event,
                      self.pointerFocusClaim?.id == event.pointer.pointerId else { return }
                self.pointerFocusClaim = nil
            }
            unloaded.addHandler { [weak self] _, _ in
                self?.pointerFocusClaim = nil
            }
            losingFocus.addHandler { [weak self] _, event in
                guard let self, let event, !event.handled,
                      self.commandsEnabled, self.isLoaded,
                      self.pointerFocusClaim != nil, event.focusState == .pointer,
                      let oldFocus = event.oldFocusedElement,
                      oldFocus == (self as WinUI.DependencyObject),
                      let newFocus = event.newFocusedElement,
                      newFocus is WinUI.ScrollViewer else { return }
                var ancestor = WinUI.VisualTreeHelper.getParent(self)
                while let node = ancestor {
                    if node == newFocus {
                        // ScrollViewer focuses itself on an unhandled release.
                        // Preserve this scope's just-acquired focus without
                        // swallowing pointer events or asserting focus later.
                        _ = try? event.tryCancel()
                        return
                    }
                    ancestor = WinUI.VisualTreeHelper.getParent(node)
                }
            }
        }
    }

    private func finishPointerFocusClaim(for pointerID: UInt32) {
        guard let claim = pointerFocusClaim, claim.id == pointerID else { return }
        guard let queue = dispatcherQueue else {
            pointerFocusClaim = nil
            return
        }
        // End the claim after the current native release finishes bubbling.
        // Generation matching prevents an old cleanup from clearing a newer
        // press. This callback only clears state; it never requests focus.
        let queued = (try? queue.tryEnqueue(.high) { [weak self] in
            MainActor.assumeIsolated {
                guard let self,
                      self.pointerFocusClaim?.generation == claim.generation else { return }
                self.pointerFocusClaim = nil
            }
        }) ?? false
        if !queued { pointerFocusClaim = nil }
    }

    func update(
        isEnabled: Bool,
        handler: @escaping @MainActor (KeyCommandEvent) -> KeyCommandResult
    ) {
        commandsEnabled = isEnabled
        if !isEnabled { pointerFocusClaim = nil }
        if isTabStop != isEnabled { isTabStop = isEnabled }
        commands.update(isEnabled: isEnabled, handler: handler)
    }

    override func onPreviewKeyDown(_ event: WinUI.KeyRoutedEventArgs!) throws {
        // WinRT projects this override as nonisolated. WinUI invokes it on the
        // owning UI thread; decide synchronously before continuing native input.
        let carried = KeyCommandCarriedNativeEvent(event: event)
        let handled = MainActor.assumeIsolated {
            consumePreviewKeyDown(carried.event)
        }
        if !handled {
            // Continue with this exact event, including disabled/ignored keys.
            try super.onPreviewKeyDown(event)
        }
    }

    private func consumePreviewKeyDown(_ event: WinUI.KeyRoutedEventArgs?) -> Bool {
        // Tunneling happens before native Tab traversal and control accelerators.
        // Exact native focus excludes descendant TextBox/RichEditBox/IME input.
        guard let event, !event.handled,
              commandsEnabled, isLoaded,
              let root = xamlRoot,
              let focused = WinUI.FocusManager.getFocusedElement(root) as? WinUI.DependencyObject,
              focused == (self as WinUI.DependencyObject),
              let command = makeKeyCommand(event),
              commands.dispatch(command, hasNativeFocus: true, isAttached: true) == .handled
        else { return false }
        event.handled = true
        return true
    }

}

// The event stays on its WinUI owning thread throughout assumeIsolated.
private struct KeyCommandCarriedNativeEvent: @unchecked Sendable {
    let event: WinUI.KeyRoutedEventArgs?
}

@MainActor
private func makeKeyCommand(_ event: WinUI.KeyRoutedEventArgs) -> KeyCommandEvent? {
    let virtualKey = UInt32(event.originalKey.rawValue)
    var state = [UInt8](repeating: 0, count: 256)
    guard GetKeyboardState(&state) else { return nil }
    // The Windows/Super key belongs to the shell, not semantic app Command.
    guard state[0x5b] & 0x80 == 0, state[0x5c] & 0x80 == 0 else { return nil }
    var modifiers: EventModifiers = []
    if state[0x10] & 0x80 != 0 { modifiers.insert(.shift) }
    if state[0x11] & 0x80 != 0 { modifiers.insert(.command) }
    if state[0x12] & 0x80 != 0 { modifiers.insert(.option) }
    if state[0x14] & 1 != 0 { modifiers.insert(.capsLock) }
    if (0x60...0x6f).contains(virtualKey) { modifiers.insert(.numericPad) }

    let named: KeyEquivalent?
    switch virtualKey {
        case 0x08: named = .delete
        case 0x09: named = .tab
        case 0x0c: named = .clear
        case 0x0d: named = .return
        case 0x1b: named = .escape
        case 0x20: named = .space
        case 0x21: named = .pageUp
        case 0x22: named = .pageDown
        case 0x23: named = .end
        case 0x24: named = .home
        case 0x25: named = .leftArrow
        case 0x26: named = .upArrow
        case 0x27: named = .rightArrow
        case 0x28: named = .downArrow
        case 0x2e: named = .deleteForward
        default: named = nil
    }
    if let named {
        return KeyCommandEvent(key: named, modifiers: modifiers, isRepeat: event.keyStatus.wasKeyDown)
    }
    // Modifier-only, IME processing, and packet events are not canvas commands.
    guard !(0x10...0x14).contains(virtualKey), virtualKey != 0xe5, virtualKey != 0xe7 else { return nil }
    let layout = GetKeyboardLayout(0)
    let rightAltPressed = state[0xa5] & 0x80 != 0
    return WindowsKeyCommandModifiers.event(
        virtualKey: UInt16(virtualKey), modifiers: modifiers,
        rightAltPressed: rightAltPressed, isRepeat: event.keyStatus.wasKeyDown,
        translate: { removingCommandModifiers in
            var translatedState = state
            if removingCommandModifiers {
                translatedState[0x11] = 0; translatedState[0xa2] = 0; translatedState[0xa3] = 0
                translatedState[0x12] = 0; translatedState[0xa4] = 0; translatedState[0xa5] = 0
            }
            var characters = [UInt16](repeating: 0, count: 8)
            let capacity = Int32(characters.count)
            let count = ToUnicodeEx(
                virtualKey, event.keyStatus.scanCode, &translatedState, &characters,
                capacity, 4, layout
            )
            // Flag 4 keeps the OS keyboard/dead-key state unchanged. A dead
            // key is distinct from an untranslated Ctrl+Alt command chord.
            if count < 0 { return .deadKey }
            guard count > 0, count <= Int32(characters.count) else { return .none }
            return .characters(String(decoding: characters.prefix(Int(count)), as: UTF16.self))
        },
        characterMapping: { WindowsKeyTranslation(character: $0, scan: { VkKeyScanExW($0, layout) }) }
    )
}
