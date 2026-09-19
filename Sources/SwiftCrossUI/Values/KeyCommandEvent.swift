/// A key-down command delivered to a passive view's native keyboard focus scope.
/// This is not a text input or IME composition API.
public struct KeyCommandEvent: Equatable, Sendable {
    /// Named keys use `KeyEquivalent` constants. Printable keys preserve the
    /// active layout's shifted character; letters are normalized to lowercase.
    public let key: KeyEquivalent
    /// Command is the platform's application-command modifier: Command on macOS
    /// and Control on Windows. Shift remains present for shifted characters.
    public let modifiers: EventModifiers
    public let isRepeat: Bool

    public init(key: KeyEquivalent, modifiers: EventModifiers = [], isRepeat: Bool = false) {
        let normalized = String(key.character).lowercased()
        self.key = normalized.count == 1 ? KeyEquivalent(normalized.first!) : key
        self.modifiers = modifiers
        self.isRepeat = isRepeat
    }
}

/// Whether a focused view consumed the original native key event.
public enum KeyCommandResult: Equatable, Sendable {
    case handled
    /// Keep processing the original event, including native Tab traversal.
    case ignored
}

/// Mutable handler state owned by one native focus target, with no global
/// registration or queued delivery. Shared by backend implementations.
@_spi(Backends)
@MainActor
public final class KeyCommandDispatchState {
    private var isEnabled = false
    private var handler: (@MainActor (KeyCommandEvent) -> KeyCommandResult)?

    public init() {}

    public func update(
        isEnabled: Bool,
        handler: @escaping @MainActor (KeyCommandEvent) -> KeyCommandResult
    ) {
        self.isEnabled = isEnabled
        self.handler = handler
    }

    public func dispatch(
        _ event: KeyCommandEvent,
        hasNativeFocus: Bool,
        isAttached: Bool
    ) -> KeyCommandResult {
        guard isEnabled, isAttached, hasNativeFocus else { return .ignored }
        return handler?(event) ?? .ignored
    }
}
