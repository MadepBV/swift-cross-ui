/// Separates AltGr layout text from application-command modifiers without
/// changing keyboard state. The backend supplies the active layout mapping.
@_spi(Backends)
public enum WindowsKeyCommandModifiers {
    /// The outcomes of a non-mutating `ToUnicodeEx` call. A dead key must be
    /// distinguished from an untranslated command chord, which can use its
    /// base character after command modifiers are removed from the copied state.
    public enum Translation: Equatable, Sendable {
        case characters(String)
        case none
        case deadKey
    }

    /// Resolves one printable key without treating right Alt as proof of AltGr.
    /// `translate(true)` removes Ctrl/Alt from a copy of the keyboard state;
    /// the actual OS keyboard/dead-key state must remain unchanged in both calls.
    public static func event(
        virtualKey: UInt16,
        modifiers: EventModifiers,
        rightAltPressed: Bool,
        isRepeat: Bool,
        translate: (_ removingCommandModifiers: Bool) -> Translation,
        characterMapping: (Character) -> WindowsKeyTranslation?
    ) -> KeyCommandEvent? {
        if rightAltPressed, modifiers.isSuperset(of: [.command, .option]) {
            switch translate(false) {
                case .deadKey:
                    return nil
                case .none:
                    break
                case .characters(let text):
                    guard let character = singlePrintableCharacter(text) else {
                        // Some layouts return a C0 code for Ctrl+RightAlt.
                        // It is not text; resolve its base command key below.
                        if text.unicodeScalars.count == 1,
                           let scalar = text.unicodeScalars.first,
                           scalar.value < 0x20 || scalar.value == 0x7f { break }
                        return nil
                    }
                    let textModifiers = removingAltGrTextModifiers(
                        from: modifiers, rightAltPressed: true, virtualKey: virtualKey,
                        characterMapping: characterMapping(character)
                    )
                    if textModifiers != modifiers {
                        return KeyCommandEvent(
                            key: KeyEquivalent(character), modifiers: textModifiers, isRepeat: isRepeat
                        )
                    }
            }
        }
        // An ordinary Ctrl+RightAlt command is still a command. Its actual
        // translation may be empty or a different character on this layout.
        // Clear command modifiers in a copied state just as for left-Alt chords.
        guard case .characters(let text) = translate(modifiers.contains(.command)),
              let character = singlePrintableCharacter(text) else { return nil }
        return KeyCommandEvent(key: KeyEquivalent(character), modifiers: modifiers, isRepeat: isRepeat)
    }

    private static func singlePrintableCharacter(_ text: String) -> Character? {
        guard text.count == 1, let character = text.first,
              character.unicodeScalars.allSatisfy({ $0.value >= 0x20 && $0.value != 0x7f })
        else { return nil }
        return character
    }

    public static func removingAltGrTextModifiers(
        from modifiers: EventModifiers,
        rightAltPressed: Bool,
        virtualKey: UInt16,
        characterMapping: WindowsKeyTranslation?
    ) -> EventModifiers {
        guard rightAltPressed,
              modifiers.isSuperset(of: [.command, .option]),
              let characterMapping,
              characterMapping.virtualKey == virtualKey,
              characterMapping.modifiers.isSuperset(of: [.control, .option])
        else { return modifiers }
        return modifiers.subtracting([.command, .option])
    }
}
