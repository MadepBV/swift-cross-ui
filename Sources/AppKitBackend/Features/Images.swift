import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.Images {
    public var requiresImageUpdateOnScaleFactorChange: Bool { false }

    public func createImageView() -> Widget {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleAxesIndependently
        return imageView
    }

    public func updateImageView(
        _ imageView: Widget,
        rgbaData: [UInt8],
        width: Int,
        height: Int,
        targetWidth: Int,
        targetHeight: Int,
        dataHasChanged: Bool,
        environment: EnvironmentValues
    ) {
        guard dataHasChanged else {
            return
        }

        let imageView = imageView as! NSImageView
        // An empty bitmap has no context to draw into; it shows nothing.
        guard width > 0, height > 0 else {
            imageView.image = nil
            return
        }
        var rgbaData = rgbaData
        let context = CGContext(
            data: &rgbaData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let cgImage = context?.makeImage() else {
            imageView.image = nil
            return
        }

        imageView.image = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}
