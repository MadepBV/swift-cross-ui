import Testing
@_spi(Backends) import SwiftCrossUI

@Suite("Windows printable keyboard shortcuts")
struct WindowsKeyTranslationTests {
    @Test("Canvas punctuation is mapped through the keyboard layout", arguments: [
        ("=", UInt16(0xbb)), ("-", UInt16(0xbd)), ("/", UInt16(0xbf)),
        (",", UInt16(0xbc)), ("[", UInt16(0xdb)), ("]", UInt16(0xdd)),
        (".", UInt16(0xbe))
    ])
    func punctuation(character: String, key: UInt16) {
        var requested: UInt16?
        let translation = WindowsKeyTranslation(character: character.first!) {
            requested = $0
            return Int16(key)
        }
        #expect(requested == character.utf16.first)
        #expect(translation?.virtualKey == key)
        #expect(translation?.modifiers == [])
    }

    @Test("AZERTY digit shortcuts retain the layout's required Shift")
    func azertyDigits() {
        let translation = WindowsKeyTranslation(character: "9") { _ in 0x0139 }
        #expect(translation?.virtualKey == 0x39)
        #expect(translation?.modifiers == [.shift])
        #expect(translation?.modifiers.union(.command) == [.shift, .command])
    }

    @Test("AltGr punctuation retains both Control and Alt")
    func altGrPunctuation() {
        let translation = WindowsKeyTranslation(character: "[") { _ in 0x0635 }
        #expect(translation?.virtualKey == 0x35)
        #expect(translation?.modifiers == [.control, .option])
    }

    @Test("Letter case is expressed by explicit shortcut modifiers")
    func uppercaseKey() {
        var requested: UInt16?
        let translation = WindowsKeyTranslation(character: "S") {
            requested = $0
            return 0x53
        }
        #expect(requested == 0x73)
        #expect(translation?.virtualKey == 0x53)
        #expect(translation?.modifiers == [])
    }

    @Test("Unsupported layouts and modifier states do not activate another key",
          arguments: [Int16(-1), 0x0841, 0x1041, 0x0000])
    func unsupportedScan(result: Int16) {
        #expect(WindowsKeyTranslation(character: "a") { _ in result } == nil)
    }

    @Test("Unrepresentable graphemes do not query the native one-unit API")
    func unrepresentableGrapheme() {
        var scanned = false
        let translation = WindowsKeyTranslation(character: "😀") { _ in
            scanned = true
            return 0x41
        }
        #expect(translation == nil)
        #expect(!scanned)
    }

    @Test("Named, letter, digit and supported OEM labels stay native", arguments: [
        UInt16(0x08), 0x09, 0x0c, 0x0d, 0x1b, 0x20, 0x21, 0x22,
        0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x2e,
        0x30, 0x39, 0x41, 0x5a, 0x70, 0x87, 0xbb
    ])
    func nativeAcceleratorLabel(key: UInt16) {
        #expect(WindowsKeyTranslation.hasWinUIAcceleratorLabel(for: key))
    }

    @Test("Unsafe OEM labels are hidden without rejecting their shortcuts", arguments: [
        UInt16(0xba), 0xbc, 0xbd, 0xbe, 0xbf, 0xc0,
        0xdb, 0xdc, 0xdd, 0xde, 0xdf, 0xe2
    ])
    func unsupportedOEMLabel(key: UInt16) {
        let translation = WindowsKeyTranslation(character: ",") { _ in Int16(key) }
        #expect(translation?.virtualKey == key)
        #expect(!WindowsKeyTranslation.hasWinUIAcceleratorLabel(for: key))
    }

    @Test("An AltGr symbol on a digit keeps its safe native label")
    func altGrNativeLabel() {
        let translation = WindowsKeyTranslation(character: "[") { _ in 0x0635 }
        #expect(translation?.modifiers == [.control, .option])
        #expect(WindowsKeyTranslation.hasWinUIAcceleratorLabel(for: translation!.virtualKey))
    }

    @Test("Unknown virtual keys do not enter native label generation", arguments: [
        UInt16(0x07), 0x0a, 0x0b, 0x0e, 0x0f, 0x3a, 0x40,
        0x5e, 0x92, 0x9f, 0xad, 0xba, 0xc2, 0xdb, 0xff, 0xffff
    ])
    func unknownAcceleratorLabel(key: UInt16) {
        #expect(!WindowsKeyTranslation.hasWinUIAcceleratorLabel(for: key))
    }
}
