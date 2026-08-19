/// A button style that ships with SwiftCrossUI, and therefore has a native
/// appearance that backends know how to draw.
///
/// Mirrors the way ``_BuiltinFormStyle`` lets ``Section`` recognise the form
/// styles it can match its metrics to. A style defined outside of
/// SwiftCrossUI doesn't conform, so ``ButtonStyle/kind`` reports
/// ``ButtonStyleKind/plain`` for it and the backend draws no chrome.
package protocol _BuiltinButtonStyle {
    /// The chrome that backends should draw for this style.
    var builtinKind: ButtonStyleKind { get }
}
