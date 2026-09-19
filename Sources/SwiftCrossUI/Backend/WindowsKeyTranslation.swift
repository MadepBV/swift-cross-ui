/// A printable key's virtual key and required modifiers on a Windows layout.
///
/// Kept independent of WinRT so backend tests can exercise US, AZERTY and
/// AltGr layouts without changing the machine's active keyboard layout.
@_spi(Backends)
public struct WindowsKeyTranslation: Equatable, Sendable {
    public let virtualKey: UInt16
    public let modifiers: EventModifiers

    /// Decodes the result of `VkKeyScanW`: the virtual key is in the low byte
    /// and Shift/Control/Alt are bits 0/1/2 of the high byte. A result of -1
    /// means the layout cannot produce the character.
    public init?(character: Character, scan: (UInt16) -> Int16) {
        // KeyEquivalent describes a key, with letter case expressed through
        // explicit modifiers. Do not turn an uppercase spelling into Shift.
        let units = Array(character.lowercased().utf16)
        guard units.count == 1 else { return nil }
        let result = scan(units[0])
        guard result != -1 else { return nil }
        let bits = UInt16(bitPattern: result)
        let shiftState = bits >> 8
        // Hankaku and driver-defined states cannot be represented by a
        // KeyboardAccelerator. Refuse instead of activating the wrong key.
        guard shiftState & ~UInt16(7) == 0, bits & 0xff != 0 else { return nil }
        virtualKey = bits & 0xff
        var modifiers: EventModifiers = []
        if shiftState & 1 != 0 { modifiers.insert(.shift) }
        if shiftState & 2 != 0 { modifiers.insert(.control) }
        if shiftState & 4 != 0 { modifiers.insert(.option) }
        self.modifiers = modifiers
    }

    /// Whether WinUI 1.5 can generate a localized native accelerator label.
    ///
    /// This is independent of whether the virtual key can be dispatched. Some
    /// valid OEM keys fail fast in the older runtime's display-name switch.
    /// Keep those shortcuts native, but suppress their automatic tooltip.
    /// Source: microsoft-ui-xaml 1.5-preview1, GetResourceStringIdFromVirtualKey
    /// (a7cc34079da375f3380a09d1eb75870a700923c2).
    public static func hasWinUIAcceleratorLabel(for virtualKey: UInt16) -> Bool {
        switch virtualKey {
            case 0x00...0x06, 0x08...0x09, 0x0c...0x0d,
                 0x10...0x39, 0x41...0x5d, 0x5f...0x91,
                 0xa0...0xac, 0xbb, 0xc3...0xda:
                true
            default:
                false
        }
    }
}
