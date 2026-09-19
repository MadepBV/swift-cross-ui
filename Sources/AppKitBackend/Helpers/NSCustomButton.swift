import AppKit
import SwiftCrossUI

public final class NSCustomButton: NSView {
    var action: (() -> Void)?
    var button: NSButtonBackground?
    var buttonStyle: ButtonStyle.Kind = .bordered {
        didSet { updateButtonAppearance() }
    }

    /// The role of the ``SwiftCrossUI/Button`` this view backs, if it has one.
    ///
    /// AppKit can only express ``SwiftCrossUI/ButtonRole/destructive``, and
    /// only from macOS 11 onwards. ``SwiftCrossUI/ButtonRole/cancel`` has no
    /// AppKit equivalent for a standalone button (it's meaningful inside
    /// dialogs, which have their own backend methods), so it's stored but not
    /// rendered.
    var role: ButtonRole? {
        didSet { updateDestructiveAction() }
    }

    /// Whether the underlying `NSButton` is marked as performing a destructive
    /// action.
    ///
    /// Always `false` before macOS 11, which has no way to express it, and
    /// while the style in use has no native button background to mark.
    var rendersAsDestructive: Bool {
        guard #available(macOS 11, *) else {
            return false
        }
        return button?.hasDestructiveAction ?? false
    }

    var isEnabled = true {
        didSet {
            if !isEnabled {
                isPressed = false
                isHighlighted = false
            }
            buttonStyle.applyModifications(to: self)
            needsDisplay = true
        }
    }

    // Whether left mousebutton is pressed on this view.
    private var isPressed = false

    private var highlightResetWorkItem: DispatchWorkItem?

    public var isHighlighted = false {
        didSet {
            buttonStyle.applyModifications(to: self)
            needsDisplay = true
        }
    }

    override public func accessibilityRole() -> NSAccessibility.Role? {
        .button
    }

    override public func accessibilityActionNames() -> [NSAccessibility.Action] {
        return [.press]
    }

    override public func accessibilityPerformPress() -> Bool {
        guard isEnabled else { return false }
        self.action?()
        return true
    }

    override public func accessibilityLabel() -> String? {
        // Automatically uses the label text of a Button("") {} as accessibilityLabel.
        // This should be improved via a future .accessibilityLabel(_:) modifier.
        // The ViewBuilder button init is not covered by this current solution.
        (subviews.first as? NSTextField)?.stringValue
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override public var acceptsFirstResponder: Bool {
        // Even though its called FullKeyboardAccess, it's actually
        // the "Keyboard navigation" setting.
        isEnabled && NSApplication.shared.isFullKeyboardAccessEnabled
    }

    override public var focusRingMaskBounds: NSRect { bounds }

    override public func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { noteFocusRingMaskChanged() }
        return ok
    }

    override public func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        if ok { noteFocusRingMaskChanged() }
        return ok
    }

    override public func drawFocusRingMask() {
        guard isEnabled else { return }
        buttonStyle.drawFocusRingMask(on: self)
    }

    override public func keyDown(with event: NSEvent) {
        guard
            isEnabled,
            (event.charactersIgnoringModifiers ?? "") == " "
        else {
            super.keyDown(with: event)
            return
        }

        highlightResetWorkItem?.cancel()
        isHighlighted = true
        action?()

        // Task with Task.sleep could be used in the future,
        // it has a min version requirement of macOS 13.
        let workItem = DispatchWorkItem { [weak self] in
            self?.isHighlighted = false
        }
        highlightResetWorkItem = workItem

        // 0.1 highlight duration is an estimate of what it feels like.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    override public func viewWillMove(toWindow newWindow: NSWindow?) {
        // Reset internal state when moved (or potentially re-used in the future).
        if newWindow == nil {
            highlightResetWorkItem?.cancel()
            isHighlighted = false
            isPressed = false
        }
    }

    override public func mouseDown(with _: NSEvent) {
        guard isEnabled else { return }

        isPressed = true
        isHighlighted = true
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isEnabled else { return }

        let pointInView = convert(event.locationInWindow, from: nil)

        if isPressed && bounds.contains(pointInView) {
            isHighlighted = true
        } else {
            isHighlighted = false
        }
    }

    override public func mouseUp(with event: NSEvent) {
        guard isEnabled else { return }

        let pointInView = self.convert(event.locationInWindow, from: nil)

        if bounds.contains(pointInView) {
            action?()
        }

        isPressed = false
        isHighlighted = false
    }

    private func updateButtonAppearance() {
        buttonStyle.applyModifications(to: self)
        noteFocusRingMaskChanged()
        self.needsDisplay = true
    }

    /// Tells AppKit whether the button performs a destructive action.
    private func updateDestructiveAction() {
        guard #available(macOS 11, *), let button else {
            return
        }
        let isDestructive = role?.kind == .destructive
        guard button.hasDestructiveAction != isDestructive else {
            return
        }
        button.hasDestructiveAction = isDestructive
        needsDisplay = true
    }

    func setupButton() {
        guard self.button == nil else { return }
        let button = NSButtonBackground()
        self.button = button

        button.title = ""
        button.isBordered = true
        button.bezelStyle = .flexiblePush

        button.translatesAutoresizingMaskIntoConstraints = false

        addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // The background is recreated whenever a style that needs one comes
        // back into use, so the role has to be applied to the new instance.
        updateDestructiveAction()
    }

    func removeButton() {
        self.button?.removeFromSuperview()
        self.button = nil
    }

    func addAndSetupLabel(_ child: NSView) {
        addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.centerXAnchor.constraint(equalTo: centerXAnchor),
            child.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
