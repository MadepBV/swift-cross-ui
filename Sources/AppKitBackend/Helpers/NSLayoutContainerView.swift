import AppKit

/// A view that only lays its children out and never receives events itself.
///
/// Every stack, `ZStack` layer, overlay and `GeometryReader` slot is one of
/// these. Its empty area used to hit-test as itself, which meant a full-size
/// layer in front of a canvas swallowed every click meant for the canvas.
/// Like SwiftUI's layout containers, it now lets clicks fall through to
/// whatever is behind it unless one of its own children claims them.
final class NSLayoutContainerView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}
