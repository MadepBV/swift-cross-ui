import Foundation

/// Text that has been resolved against a ``GraphicsContext``'s environment,
/// ready to be measured and drawn inside a ``Canvas``.
///
/// Obtain a value of this type by calling
/// ``GraphicsContext/resolve(_:)``. Resolving text captures the font and
/// foreground style that were in effect at the moment of resolution — the
/// ``Text``'s own attributes where it has them, and the context's otherwise —
/// so a resolved value can be measured and drawn repeatedly without re-reading
/// the environment.
///
/// ```swift
/// Canvas { context, size in
///     var label = context.resolve(Text("N12"))
///     label.shading = .color(.blue)
///     context.draw(label, at: CGPoint(x: size.width / 2, y: 0))
/// }
/// ```
///
/// - Note: For SwiftUI source compatibility this type is also reachable as
///   ``GraphicsContext/ResolvedText``.
///
/// ## Limitations
///
/// Unlike SwiftUI's `GraphicsContext.ResolvedText`, this type does not expose
/// baseline metrics, because no SwiftCrossUI backend currently reports them.
/// See ``GraphicsContext/draw(_:at:anchor:)`` for the limitations that apply
/// when resolved text is actually drawn.
public struct ResolvedText {
    /// A function that measures a string within a target size.
    ///
    /// The measurement is supplied by ``Canvas`` at draw time because text
    /// measurement requires a live backend. It is `nil` for contexts that were
    /// created without a backend (such as in tests), in which case
    /// ``measure(in:)`` reports a zero size.
    typealias Measurement = (String, CGSize) -> CGSize

    /// The string that gets drawn.
    public let string: String

    /// The shading used to draw the text.
    ///
    /// Only the color component of the shading is honoured; see
    /// ``GraphicsContext/Shading`` for details.
    public var shading: GraphicsContext.Shading

    /// The font that the text was resolved with, if the context had one.
    ///
    /// `nil` means "whatever font the canvas inherited from its environment".
    ///
    /// Attributes set on the ``Text`` itself — ``Text/fontWeight(_:)``,
    /// ``Text/bold(_:)``, ``Text/italic(_:)``, ``Text/monospaced(_:)`` — are
    /// baked into this font's overlay by ``GraphicsContext/resolve(_:)``, so
    /// this single value carries the whole of the text's typography.
    let font: Font?

    /// The measurement function captured at resolution time.
    let measurement: Measurement?

    /// Creates resolved text.
    ///
    /// - Parameters:
    ///   - string: The string to draw.
    ///   - shading: The shading to draw the string with.
    ///   - font: The font to draw the string with, if overridden.
    ///   - measurement: The measurement function to back ``measure(in:)``.
    init(
        string: String,
        shading: GraphicsContext.Shading,
        font: Font?,
        measurement: Measurement?
    ) {
        self.string = string
        self.shading = shading
        self.font = font
        self.measurement = measurement
    }

    /// Measures the text, laying it out within the given size.
    ///
    /// Pass `CGSize(width: .infinity, height: .infinity)` (or any non-finite
    /// dimension) to measure the text without constraining it in that
    /// dimension.
    ///
    /// - Parameter targetSize: The size to lay the text out within.
    /// - Returns: The size that the text occupies, or a zero size if this text
    ///   was resolved by a context that has no backend attached.
    public func measure(in targetSize: CGSize) -> CGSize {
        guard let measurement else {
            return CGSize(width: 0.0, height: 0.0)
        }
        return measurement(string, targetSize)
    }
}
