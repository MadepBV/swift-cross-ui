import Foundation

extension Text {
    /// Creates a text view that shows an image inline, SwiftUI's way of
    /// putting a symbol in a run of text (`Text(Image(systemName: "star.fill"))`).
    ///
    /// Backends draw a text view as a single platform label, which can't host
    /// a drawn symbol, so the symbol is written as the Unicode character that
    /// looks most like it (``inlineSymbolCharacters``): a filled circle
    /// becomes "●", a star "★", a checkmark "✓". The character takes the
    /// text's font and color, as SwiftUI's inline symbol does. A symbol with
    /// no such character, or a bitmap image, contributes nothing, so the
    /// surrounding words still read correctly.
    ///
    /// - Parameter image: The image to show inline.
    public init(_ image: Image) {
        self.init(image.systemSymbolName.flatMap(Self.inlineCharacter(forSymbol:)) ?? "")
    }

    /// The Unicode characters that stand in for SF Symbols inside text.
    ///
    /// A symbol with no entry of its own falls back to its name without a
    /// `.circle` or `.square` enclosure, then without `.fill`.
    public static let inlineSymbolCharacters: [String: String] = [
        "circle.fill": "\u{25CF}",
        "circle": "\u{25CB}",
        "square.fill": "\u{25A0}",
        "square": "\u{25A1}",
        "diamond.fill": "\u{25C6}",
        "diamond": "\u{25C7}",
        "triangle.fill": "\u{25B2}",
        "triangle": "\u{25B3}",
        "star.fill": "\u{2605}",
        "star": "\u{2606}",
        "heart.fill": "\u{2665}",
        "heart": "\u{2661}",
        "checkmark": "\u{2713}",
        "xmark": "\u{2715}",
        "plus": "+",
        "minus": "\u{2212}",
        "multiply": "\u{00D7}",
        "divide": "\u{00F7}",
        "equal": "=",
        "chevron.right": "\u{203A}",
        "chevron.left": "\u{2039}",
        "chevron.up": "\u{2303}",
        "chevron.down": "\u{2304}",
        "arrow.right": "\u{2192}",
        "arrow.left": "\u{2190}",
        "arrow.up": "\u{2191}",
        "arrow.down": "\u{2193}",
        "arrow.up.right": "\u{2197}",
        "play.fill": "\u{25B6}\u{FE0E}",
        "pause.fill": "\u{23F8}\u{FE0E}",
        "stop.fill": "\u{23F9}\u{FE0E}",
        "exclamationmark.triangle.fill": "\u{26A0}\u{FE0E}",
        "info.circle": "\u{24D8}",
        "bolt.fill": "\u{26A1}\u{FE0E}",
        "music.note": "\u{266A}",
        "ellipsis": "\u{2026}",
        "command": "\u{2318}",
        "option": "\u{2325}",
        "shift": "\u{21E7}",
        "control": "\u{2303}",
        "return": "\u{21A9}",
        "delete.left": "\u{232B}",
        "globe": "\u{1F310}\u{FE0E}",
    ]

    /// The character for a symbol, trying its base name when the variant
    /// has no entry of its own.
    static func inlineCharacter(forSymbol name: String) -> String? {
        // "star.circle.fill" tries itself, then "star.fill", then "star".
        var candidates = [name]
        for container in [".circle", ".square"] where name.contains(container) {
            candidates.append(name.replacingOccurrences(of: container, with: ""))
        }
        candidates += candidates.map { $0.replacingOccurrences(of: ".fill", with: "") }
        return candidates.lazy.compactMap { inlineSymbolCharacters[$0] }.first
    }
}

extension Text: CustomStringConvertible {
    /// The text's string, so that interpolating a ``Text`` into another
    /// (`Text("\(name)\(cursor)")`, SwiftUI's way of joining styled runs)
    /// writes its words rather than a debug description.
    ///
    /// The interpolated run's own styling is not kept: a text view is drawn
    /// as a single run with one font and color.
    public var description: String {
        string
    }
}
