import Testing
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

@Suite("Focused key commands", .serialized)
@MainActor
struct KeyCommandTests {
    @Test("Key normalization retains shifted punctuation and repeat metadata")
    func normalization() {
        let letter = KeyCommandEvent(key: "M", modifiers: [.shift, .capsLock], isRepeat: true)
        #expect(letter.key == "m")
        #expect(letter.modifiers == [.shift, .capsLock])
        #expect(letter.isRepeat)
        #expect(KeyCommandEvent(key: "+", modifiers: .shift).key == "+")
        #expect(KeyCommandEvent(key: .tab).key == .tab)
    }

    @Test("Detached, unfocused and disabled scopes never invoke application code")
    func focusAndLifecycleGates() {
        let state = KeyCommandDispatchState()
        var calls = 0
        state.update(isEnabled: true) { _ in calls += 1; return .handled }
        let tab = KeyCommandEvent(key: .tab)
        #expect(state.dispatch(tab, hasNativeFocus: false, isAttached: true) == .ignored)
        #expect(state.dispatch(tab, hasNativeFocus: true, isAttached: false) == .ignored)
        #expect(calls == 0)
        state.update(isEnabled: false) { _ in calls += 1; return .handled }
        #expect(state.dispatch(tab, hasNativeFocus: true, isAttached: true) == .ignored)
        #expect(calls == 0)
    }

    @Test("A scope uses the latest handler and its actual handled result")
    func latestHandlerAndResult() {
        let state = KeyCommandDispatchState()
        var oldCalls = 0
        var latestCalls = 0
        state.update(isEnabled: true) { _ in oldCalls += 1; return .handled }
        state.update(isEnabled: true) { _ in latestCalls += 1; return .ignored }
        #expect(state.dispatch(KeyCommandEvent(key: .tab), hasNativeFocus: true, isAttached: true) == .ignored)
        #expect(oldCalls == 0)
        #expect(latestCalls == 1)
        state.update(isEnabled: true) { event in event.key == .escape ? .handled : .ignored }
        #expect(state.dispatch(KeyCommandEvent(key: .escape), hasNativeFocus: true, isAttached: true) == .handled)
    }

    @Test("Replacing or releasing a scope releases the previous handler capture")
    func handlerLifetime() {
        final class Capture {}
        var state: KeyCommandDispatchState? = KeyCommandDispatchState()
        weak var retained: Capture?
        do {
            let capture = Capture()
            retained = capture
            state?.update(isEnabled: true) { [capture] _ in
                _ = capture
                return .handled
            }
        }
        #expect(retained != nil)
        state?.update(isEnabled: false) { _ in .ignored }
        #expect(retained == nil)
        do {
            let capture = Capture()
            retained = capture
            state?.update(isEnabled: true) { [capture] _ in
                _ = capture
                return .ignored
            }
        }
        state = nil
        #expect(retained == nil)
    }

    @Test("AltGr normalization requires the actual layout character and native key")
    func altGrTextModifiers() {
        let mapping = WindowsKeyTranslation(character: "@", scan: { _ in Int16(0x0632) })
        let held: EventModifiers = [.command, .option, .shift]
        #expect(WindowsKeyCommandModifiers.removingAltGrTextModifiers(
            from: held, rightAltPressed: true, virtualKey: 0x32, characterMapping: mapping
        ) == .shift)
        #expect(WindowsKeyCommandModifiers.removingAltGrTextModifiers(
            from: held, rightAltPressed: false, virtualKey: 0x32, characterMapping: mapping
        ) == held)
        #expect(WindowsKeyCommandModifiers.removingAltGrTextModifiers(
            from: held, rightAltPressed: true, virtualKey: 0x4d, characterMapping: mapping
        ) == held)
        #expect(WindowsKeyCommandModifiers.removingAltGrTextModifiers(
            from: held, rightAltPressed: true, virtualKey: 0x32, characterMapping: nil
        ) == held)
    }

    @Test("Right Alt command chords fall back to base characters without becoming text")
    func rightAltCommandFallback() {
        for untranslated in [WindowsKeyCommandModifiers.Translation.none, .characters("m"), .characters("\r")] {
            var translations: [Bool] = []
            let event = WindowsKeyCommandModifiers.event(
                virtualKey: 0x4d, modifiers: [.command, .option], rightAltPressed: true,
                isRepeat: true, translate: { removing in
                    translations.append(removing)
                    return removing ? .characters("M") : untranslated
                }, characterMapping: { _ in WindowsKeyTranslation(character: "m", scan: { _ in 0x004d }) }
            )
            #expect(event == KeyCommandEvent(key: "m", modifiers: [.command, .option], isRepeat: true))
            #expect(translations == [false, true])
        }
    }

    @Test("Proven AltGr text never falls back, and dead keys never become commands")
    func altGrTextAndDeadKey() {
        var translations: [Bool] = []
        let event = WindowsKeyCommandModifiers.event(
            virtualKey: 0x32, modifiers: [.command, .option], rightAltPressed: true,
            isRepeat: false, translate: { removing in
                translations.append(removing)
                return .characters("@")
            }, characterMapping: { _ in WindowsKeyTranslation(character: "@", scan: { _ in 0x0632 }) }
        )
        #expect(event == KeyCommandEvent(key: "@"))
        #expect(translations == [false])
        translations = []
        let dead = WindowsKeyCommandModifiers.event(
            virtualKey: 0x4d, modifiers: [.command, .option], rightAltPressed: true,
            isRepeat: false, translate: { removing in
                translations.append(removing)
                return removing ? .characters("m") : .deadKey
            }, characterMapping: { _ in nil }
        )
        #expect(dead == nil)
        #expect(translations == [false])
    }

    #if canImport(AppKitBackend)
    @Test("AppKit preserves Option context alongside actual produced characters")
    func appKitOptionMetadata() throws {
        for text in ["@", "#", "°"] {
            let event = try #require(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: .option, timestamp: 1,
                windowNumber: 0, context: nil, characters: text,
                charactersIgnoringModifiers: "2", isARepeat: false, keyCode: 19
            ))
            let command = try #require(appKitKeyCommand(from: event))
            #expect(command.key.character == Character(text))
            #expect(command.modifiers == .option)
        }
        let mirror = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.command, .option], timestamp: 1,
            windowNumber: 0, context: nil, characters: "µ",
            charactersIgnoringModifiers: "m", isARepeat: false, keyCode: 46
        ))
        #expect(appKitKeyCommand(from: mirror) == KeyCommandEvent(key: "m", modifiers: [.command, .option]))
    }

    @Test(
        "Native AppKit Tab traversal and exact first-responder ownership",
        .enabled(
            if: ProcessInfo.processInfo.environment["SCUI_TEST_NATIVE_KEY_FOCUS"] == "1",
            "Requires an unlocked macOS desktop; opt in with SCUI_TEST_NATIVE_KEY_FOCUS=1"
        )
    )
    func appKitNativeFocusAndTabTraversal() async throws {
        let host = KeyCommandNativeTestHost()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        defer {
            // Keep the termination guard until this test's native window closes.
            window.close()
            host.restore()
        }
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
        let before = NSTextField(frame: NSRect(x: 10, y: 10, width: 150, height: 24))
        let target = NSKeyCommandTarget(frame: NSRect(x: 10, y: 45, width: 200, height: 70))
        let after = NSTextField(frame: NSRect(x: 10, y: 130, width: 150, height: 24))
        container.addSubview(before)
        container.addSubview(target)
        container.addSubview(after)
        window.contentView = container
        target.commandsEnabled = true
        var calls = 0
        target.commands.update(isEnabled: true) { _ in calls += 1; return .ignored }
        await host.orderAndActivate(window)
        try #require(window.isKeyWindow, "Native UI host readiness: \(KeyCommandNativeTestHost.status(window))")
        // Ordering the first window can build its initial native key loop even
        // when automatic later recalculation is disabled. Wire this test's
        // explicit order only after that native setup has completed.
        window.autorecalculatesKeyViewLoop = false
        before.nextKeyView = target
        target.nextKeyView = after
        after.nextKeyView = before
        try #require(target.nextValidKeyView === after)
        try #require(target.previousValidKeyView === before)
        for reverse in [false, true] {
            try #require(window.makeFirstResponder(target))
            let tab = try #require(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: reverse ? .shift : [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil,
                characters: reverse ? "\u{19}" : "\t", charactersIgnoringModifiers: reverse ? "\u{19}" : "\t",
                isARepeat: false, keyCode: 48
            ))
            try #require(tab.window === window)
            #expect(!NSKeyCommandMonitor.handle(tab))
            // Continue the same original event once after the monitor declined.
            // This is the native NSWindow route, not synthesized/reinjected input.
            window.sendEvent(tab)
            let expected = reverse ? before : after
            let fieldEditor = window.firstResponder as? NSText
            #expect(window.firstResponder === expected || (fieldEditor?.delegate as? NSView) === expected)
        }
        #expect(calls == 2)
        // Keep one host/window active through both native checks. Restoring
        // the CLI activation policy and deactivating between async test cases
        // can end its application event-loop lifetime before the next case.
        // No second activation/readiness await or native loop is introduced.
        try verifyAppKitNativeFocus(in: window)
    }

    /// Shares the already-key owned window with the preceding original-event
    /// traversal check. Replacing only its test content exercises a fresh scope
    /// and nested editor without reopening an application lifecycle.
    private func verifyAppKitNativeFocus(in window: NSWindow) throws {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
        let target = NSKeyCommandTarget(frame: NSRect(x: 0, y: 0, width: 200, height: 150))
        let field = NSTextField(frame: NSRect(x: 10, y: 10, width: 150, height: 24))
        container.addSubview(target)
        target.addSubview(field)
        window.contentView = container
        target.commandsEnabled = true
        var calls = 0
        target.commands.update(isEnabled: true) { _ in calls += 1; return .handled }
        try #require(window.isKeyWindow, "Native UI host readiness: \(KeyCommandNativeTestHost.status(window))")
        #expect(window.makeFirstResponder(target))
        #expect(window.firstResponder === target)
        let tab = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, characters: "\t",
            charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48
        ))
        try #require(tab.window === window, "The native event must target the owned test window")
        #expect(NSKeyCommandMonitor.handle(tab))
        #expect(calls == 1)
        #expect(window.makeFirstResponder(field))
        #expect(window.firstResponder !== target)
        #expect(!NSKeyCommandMonitor.handle(tab))
        #expect(calls == 1)
        #expect(window.makeFirstResponder(target))
        target.commands.update(isEnabled: false) { _ in calls += 1; return .handled }
        #expect(!NSKeyCommandMonitor.handle(tab))
        #expect(calls == 1)
        target.removeFromSuperview()
        #expect(!NSKeyCommandMonitor.handle(tab))
        #expect(calls == 1)
    }
    #endif
}

#if canImport(AppKitBackend)
/// CLI Swift Testing does not run NSApplication's normal launch sequence. These
/// UI tests own launch setup and await readiness on the runner's main loop.
/// No production focus predicate is substituted or weakened.
@MainActor
private final class KeyCommandNativeTestHost {
    private static var didFinishLaunching = false
    private let app: NSApplication
    private let previousDelegate: (any NSApplicationDelegate)?
    private let previousPolicy: NSApplication.ActivationPolicy
    private let wasActive: Bool
    private weak var previousKeyWindow: NSWindow?
    private var restored = false
    // The CLI runner owns process lifetime while this test's window is open.
    private let applicationDelegate = KeyCommandNativeTestDelegate()

    init() {
        let app = NSApplication.shared
        self.app = app
        previousDelegate = app.delegate
        previousPolicy = app.activationPolicy()
        wasActive = app.isActive
        previousKeyWindow = app.keyWindow
        app.delegate = applicationDelegate
    }

    func orderAndActivate(_ window: NSWindow) async {
        _ = app.setActivationPolicy(.regular)
        if !Self.didFinishLaunching {
            app.finishLaunching()
            Self.didFinishLaunching = true
        }
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        let deadline = Date(timeIntervalSinceNow: 3)
        while Date() < deadline {
            if app.isActive && window.isKeyWindow { return }
            // AppKit activation requires consuming its queued native events.
            // Poll an already available, bounded batch without entering a
            // blocking AppKit run loop inside Swift Testing's async main loop.
            for _ in 0..<16 {
                guard let event = app.nextEvent(
                    matching: .any, until: .distantPast,
                    inMode: .default, dequeue: true
                ) else { break }
                app.sendEvent(event)
            }
            // Let the existing runtime loop receive new activation events and
            // service test continuations between batches.
            try? await Task.sleep(for: .milliseconds(10))
            if app.isActive && !window.isKeyWindow { window.makeKey() }
        }
    }

    func restore() {
        guard !restored else { return }
        restored = true
        _ = app.setActivationPolicy(previousPolicy)
        if wasActive, app.isActive, let previousKeyWindow, previousKeyWindow.isVisible {
            previousKeyWindow.makeKey()
        } else if !wasActive, app.isActive {
            app.deactivate()
        }
        app.delegate = previousDelegate
        #expect((app.delegate as AnyObject?) === (previousDelegate as AnyObject?))
        #expect(app.activationPolicy() == previousPolicy)
    }

    static func status(_ window: NSWindow) -> String {
        "active=\(NSApp.isActive), visible=\(window.isVisible), canBecomeKey=\(window.canBecomeKey), key=\(window.isKeyWindow), number=\(window.windowNumber)"
    }
}

@MainActor
private final class KeyCommandNativeTestDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateCancel
    }
}

#endif
