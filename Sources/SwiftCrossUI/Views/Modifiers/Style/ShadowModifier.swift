import Foundation

extension View {
    /// Draws a shadow behind this view.
    ///
    /// - Note: Not drawn yet. A shadow needs the backend to blur a copy of
    ///   the view's rendered content (WinUI's `ThemeShadow` and AppKit's
    ///   `NSShadow` both work on native layers), and no backend exposes that
    ///   to SwiftCrossUI. The view keeps its layout, which a shadow never
    ///   affects, so only the depth cue is lost. Where a shadow carries
    ///   legibility (text over artwork), pair it with a scrim or a
    ///   ``View/background(_:in:fillStyle:)``.
    ///
    /// - Parameters:
    ///   - color: The shadow's colour.
    ///   - radius: The blur radius.
    ///   - x: The horizontal offset.
    ///   - y: The vertical offset.
    /// - Returns: The view.
    public func shadow(
        color: Color = Color(white: 0, opacity: 0.33),
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> some View {
        self
    }
}
