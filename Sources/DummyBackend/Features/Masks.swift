@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.Masks {
    public func createMaskContainer(content: Widget, mask: Widget) -> Widget {
        let container = MaskContainer()
        container.children = [(content, .zero)]
        container.mask = mask
        return container
    }

    public func updateMaskContainer(
        _ container: Widget,
        size: SIMD2<Int>,
        maskOrigin: SIMD2<Int>,
        maskSize: SIMD2<Int>
    ) {
        let container = container as! MaskContainer
        container.size = size
        container.maskOrigin = maskOrigin
    }
}

extension DummyBackend {
    /// A container whose content draws through its mask. The mask isn't one
    /// of its children: it's never drawn.
    public final class MaskContainer: Container {
        public var mask: Widget?
        public var maskOrigin = SIMD2<Int>.zero
    }
}
