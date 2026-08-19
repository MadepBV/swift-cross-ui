/// A single key on the keyboard, used as the trigger of a
/// ``KeyboardShortcut``.
///
/// Key equivalents are expressed as characters, which lets you write the
/// common case as a literal:
///
/// ```swift
/// Button("Save") { save() }
///     .keyboardShortcut("s", modifiers: [.command])
/// ```
///
/// Keys without a printable representation (arrows, page up/down, and so on)
/// are available as named constants such as ``KeyEquivalent/upArrow`` and
/// ``KeyEquivalent/pageDown``. Their underlying characters match the values
/// used by AppKit's function key constants, which is also what SwiftUI uses,
/// so shortcut definitions can be copied across from a SwiftUI codebase
/// verbatim.
///
/// - Note: A key equivalent describes the *key*, not the *keystroke*. Write
///   `.keyboardShortcut("s", modifiers: [.command, .shift])` rather than
///   `.keyboardShortcut("S", modifiers: [.command])`; backends normalise the
///   character themselves when matching against platform key events.
public struct KeyEquivalent: Hashable, Sendable {
    /// The character that the key equivalent represents.
    public var character: Character

    /// Creates a key equivalent from a character.
    ///
    /// - Parameter character: The character that the key produces.
    public init(_ character: Character) {
        self.character = character
    }
}

extension KeyEquivalent {
    /// The up arrow key.
    public static let upArrow = KeyEquivalent("\u{F700}")
    /// The down arrow key.
    public static let downArrow = KeyEquivalent("\u{F701}")
    /// The left arrow key.
    public static let leftArrow = KeyEquivalent("\u{F702}")
    /// The right arrow key.
    public static let rightArrow = KeyEquivalent("\u{F703}")
    /// The clear key (found on the numeric keypad of full-size keyboards).
    public static let clear = KeyEquivalent("\u{F739}")
    /// The delete (backspace) key.
    public static let delete = KeyEquivalent("\u{8}")
    /// The forward delete key.
    public static let deleteForward = KeyEquivalent("\u{F728}")
    /// The end key.
    public static let end = KeyEquivalent("\u{F72B}")
    /// The escape key.
    public static let escape = KeyEquivalent("\u{1B}")
    /// The home key.
    public static let home = KeyEquivalent("\u{F729}")
    /// The page down key.
    public static let pageDown = KeyEquivalent("\u{F72D}")
    /// The page up key.
    public static let pageUp = KeyEquivalent("\u{F72C}")
    /// The return (enter) key.
    public static let `return` = KeyEquivalent("\u{D}")
    /// The space key.
    public static let space = KeyEquivalent(" ")
    /// The tab key.
    public static let tab = KeyEquivalent("\t")
}

extension KeyEquivalent: ExpressibleByExtendedGraphemeClusterLiteral {
    public typealias UnicodeScalarLiteralType = Character
    public typealias ExtendedGraphemeClusterLiteralType = Character

    public init(unicodeScalarLiteral value: Character) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: Character) {
        self.init(value)
    }
}

extension KeyEquivalent: CustomStringConvertible {
    public var description: String {
        switch self {
            case .upArrow: "up arrow"
            case .downArrow: "down arrow"
            case .leftArrow: "left arrow"
            case .rightArrow: "right arrow"
            case .clear: "clear"
            case .delete: "delete"
            case .deleteForward: "forward delete"
            case .end: "end"
            case .escape: "escape"
            case .home: "home"
            case .pageDown: "page down"
            case .pageUp: "page up"
            case .return: "return"
            case .space: "space"
            case .tab: "tab"
            default: String(character)
        }
    }
}
