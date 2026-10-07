import CWinRT
import Foundation
@_spi(Backends) import SwiftCrossUI
import WinAppSDK
import WindowsFoundation
import WinUI

// MARK: - Masks

// WinUI 3 has no `UIElement.OpacityMask`. A mask container draws its content
// and its mask through composition instead: both sit in a canvas made fully
// transparent, which still lays them out and hit-tests them, and a sprite
// visual on the container paints the content's rendering through the mask's
// rendering with a `CompositionMaskBrush`. Each rendering comes from a
// `CompositionVisualSurface` of the element's visual, which draws that
// visual's own subtree without the transparent canvas around it.
extension WinUIBackend: BackendFeatures.Masks {
    public func createMaskContainer(content: Widget, mask: Widget) -> Widget {
        let container = WinUI.Canvas()
        let hidden = WinUI.Canvas()
        hidden.opacity = 0
        hidden.children.append(content)
        hidden.children.append(mask)
        container.children.append(hidden)
        MaskCompositionRegistry.shared.install(on: container, content: content, mask: mask)
        return container
    }

    public func updateMaskContainer(
        _ container: Widget,
        size: SIMD2<Int>,
        maskOrigin: SIMD2<Int>,
        maskSize: SIMD2<Int>
    ) {
        setSize(of: container, to: size)
        let canvas = container as! WinUI.Canvas
        if let hidden = canvas.children.getAt(0) as? WinUI.Canvas {
            setSize(of: hidden, to: size)
            if let mask = hidden.children.getAt(1) {
                WinUI.Canvas.setLeft(mask, Double(maskOrigin.x))
                WinUI.Canvas.setTop(mask, Double(maskOrigin.y))
            }
        }
        MaskCompositionRegistry.shared.update(
            container,
            size: size,
            maskOrigin: maskOrigin,
            maskSize: maskSize
        )
    }
}

/// The composition objects behind each mask container.
@MainActor
final class MaskCompositionRegistry {
    static let shared = MaskCompositionRegistry()

    final class Composition {
        let sprite: WinAppSDK.SpriteVisual
        let contentSurface: WinAppSDK.CompositionVisualSurface
        let maskSurface: WinAppSDK.CompositionVisualSurface
        let maskBrush: WinAppSDK.CompositionSurfaceBrush

        init(
            sprite: WinAppSDK.SpriteVisual,
            contentSurface: WinAppSDK.CompositionVisualSurface,
            maskSurface: WinAppSDK.CompositionVisualSurface,
            maskBrush: WinAppSDK.CompositionSurfaceBrush
        ) {
            self.sprite = sprite
            self.contentSurface = contentSurface
            self.maskSurface = maskSurface
            self.maskBrush = maskBrush
        }
    }

    private struct Entry {
        weak var container: WinUI.FrameworkElement?
        let composition: Composition
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    private init() {}

    func install(on container: WinUI.Canvas, content: WinUI.FrameworkElement, mask: WinUI.FrameworkElement) {
        entries = entries.filter { _, entry in entry.container != nil }
        do {
            guard let contentVisual = try content.getVisualInternal(),
                  let maskVisual = try mask.getVisualInternal(),
                  let compositor = contentVisual.compositor
            else {
                throw MaskCompositionError.noVisual
            }
            let contentSurface = try compositor.createVisualSurface()!
            contentSurface.sourceVisual = contentVisual
            let maskSurface = try compositor.createVisualSurface()!
            maskSurface.sourceVisual = maskVisual

            let contentBrush = try compositor.createSurfaceBrush(contentSurface)!
            contentBrush.stretch = .none
            contentBrush.horizontalAlignmentRatio = 0
            contentBrush.verticalAlignmentRatio = 0
            let maskBrush = try compositor.createSurfaceBrush(maskSurface)!
            maskBrush.stretch = .none
            maskBrush.horizontalAlignmentRatio = 0
            maskBrush.verticalAlignmentRatio = 0

            let masked = try compositor.createMaskBrush()!
            masked.source = contentBrush
            masked.mask = maskBrush
            let sprite = try compositor.createSpriteVisual()!
            sprite.brush = masked
            try ElementCompositionPreview.statics.setElementChildVisual(container, sprite)

            entries[ObjectIdentifier(container)] = Entry(
                container: container,
                composition: Composition(
                    sprite: sprite,
                    contentSurface: contentSurface,
                    maskSurface: maskSurface,
                    maskBrush: maskBrush
                )
            )
        } catch {
            logger.warning("failed to compose a mask; the content draws unmasked")
            // The content stays visible rather than vanishing with its
            // transparent canvas.
            (container.children.getAt(0) as? WinUI.UIElement)?.opacity = 1
        }
    }

    func update(_ container: WinUI.FrameworkElement, size: SIMD2<Int>, maskOrigin: SIMD2<Int>, maskSize: SIMD2<Int>) {
        guard let entry = entries[ObjectIdentifier(container)], entry.container === container else {
            return
        }
        let composition = entry.composition
        let size = WindowsFoundation.Vector2(x: Float(size.x), y: Float(size.y))
        composition.sprite.size = size
        composition.contentSurface.sourceSize = size
        composition.maskSurface.sourceSize = WindowsFoundation.Vector2(x: Float(maskSize.x), y: Float(maskSize.y))
        composition.maskBrush.offset = WindowsFoundation.Vector2(x: Float(maskOrigin.x), y: Float(maskOrigin.y))
    }
}

private enum MaskCompositionError: Error {
    case noVisual
}

/// `Microsoft.UI.Xaml.Hosting.ElementCompositionPreview`, which the WinUI
/// projection leaves out: only `SetElementChildVisual` is needed, to show a
/// composition visual on top of an element's own content.
final class ElementCompositionPreview: WindowsFoundation.IInspectable {
    override public class var IID: WindowsFoundation.IID {
        IID___x_ABI_CMicrosoft_CUI_CXaml_CHosting_CIElementCompositionPreviewStatics
    }

    nonisolated(unsafe) static let statics: ElementCompositionPreview = try! RoGetActivationFactory(
        HString("Microsoft.UI.Xaml.Hosting.ElementCompositionPreview")
    )

    func setElementChildVisual(_ element: WinUI.UIElement, _ visual: WinAppSDK.Visual?) throws {
        _ = try perform(as: __x_ABI_CMicrosoft_CUI_CXaml_CHosting_CIElementCompositionPreviewStatics.self) { pThis in
            try CHECKED(pThis.pointee.lpVtbl.pointee.SetElementChildVisual(pThis, RawPointer(element), RawPointer(visual)))
        }
    }
}
