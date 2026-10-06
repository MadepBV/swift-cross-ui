import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// The absolute frames of the leaf widgets (those with no children) under a
/// widget, in depth-first insertion order, which is the order of the views
/// that created them.
@MainActor
func leafFrames(
    of widget: DummyBackend.Widget,
    origin: SIMD2<Int> = .zero
) -> [(origin: SIMD2<Int>, size: SIMD2<Int>)] {
    if let container = widget as? DummyBackend.Container {
        return container.children.flatMap { child in
            leafFrames(of: child.widget, origin: origin &+ child.position)
        }
    }
    let children = widget.getChildren()
    if children.isEmpty {
        return [(origin, widget.size)]
    }
    return children.flatMap { leafFrames(of: $0, origin: origin) }
}

/// A view of a known size.
@MainActor
func block(_ width: Double, _ height: Double) -> some View {
    Color.blue.frame(width: width, height: height)
}
