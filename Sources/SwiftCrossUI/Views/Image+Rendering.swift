import Foundation
import ImageFormats

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

extension Image {
    /// The quality of the scaling applied to a resized image.
    public enum Interpolation: Hashable, Sendable {
        /// No interpolation: each pixel becomes a block of pixels.
        case none
        /// Low-quality, fast interpolation.
        case low
        /// Medium-quality interpolation.
        case medium
        /// High-quality, slower interpolation.
        case high
    }

    /// Sets the quality of the scaling applied to this image when it's
    /// resized.
    ///
    /// - Note: Backends choose their own scaling filter (bilinear or better
    ///   on AppKit and WinUI) and none exposes a per-image setting yet, so
    ///   the requested quality isn't applied. An image drawn with `.none`,
    ///   such as a QR code, stays legible because it's scaled smoothly rather
    ///   than with hard pixel edges.
    ///
    /// - Parameter interpolation: The quality to scale with.
    /// - Returns: The image.
    public func interpolation(_ interpolation: Interpolation) -> Image {
        self
    }

    /// Sets whether this image is antialiased when it's resized.
    ///
    /// - Note: Not applied, for the reason given in
    ///   ``Image/interpolation(_:)``.
    ///
    /// - Parameter isAntialiased: Whether to antialias the image.
    /// - Returns: The image.
    public func antialiased(_ isAntialiased: Bool) -> Image {
        self
    }
}

#if canImport(CoreGraphics)
    extension Image {
        /// Creates an image from a Core Graphics image that carries no
        /// accessibility meaning.
        ///
        /// The pixels are copied once, into the sRGB buffer every backend
        /// draws, so the image looks the same as it does in SwiftUI.
        ///
        /// - Note: Only on platforms with Core Graphics. Elsewhere decode with
        ///   ``Image/init(_:)-(ImageFormats.Image<RGBA>)`` instead.
        ///
        /// - Parameters:
        ///   - cgImage: The image to show.
        ///   - scale: The image's pixels per point. Accepted for source
        ///     compatibility: SwiftCrossUI sizes a resizable image by its
        ///     frame, and draws a fixed-size one at its pixel size.
        ///   - orientation: Accepted for source compatibility; the image is
        ///     drawn upright.
        public init(
            decorative cgImage: CGImage,
            scale: CGFloat,
            orientation: Orientation = .up
        ) {
            self.init(Self.rgbaImage(from: cgImage))
        }

        /// Creates a labelled image from a Core Graphics image.
        ///
        /// - Parameters:
        ///   - cgImage: The image to show.
        ///   - scale: See ``Image/init(decorative:scale:orientation:)``.
        ///   - orientation: See ``Image/init(decorative:scale:orientation:)``.
        ///   - label: The image's accessibility label. Apply
        ///     `accessibilityLabel(_:)` to announce it; SwiftCrossUI's images
        ///     carry no label of their own.
        public init(
            _ cgImage: CGImage,
            scale: CGFloat,
            orientation: Orientation = .up,
            label: Text
        ) {
            self.init(Self.rgbaImage(from: cgImage))
        }

        /// Copies a Core Graphics image into straight-alpha sRGB RGBA bytes.
        ///
        /// - Parameter cgImage: The image to copy.
        /// - Returns: The copied pixels, or an empty image if Core Graphics
        ///   can't draw it.
        static func rgbaImage(from cgImage: CGImage) -> ImageFormats.Image<RGBA> {
            let width = cgImage.width
            let height = cgImage.height
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
                guard
                    let space = CGColorSpace(name: CGColorSpace.sRGB),
                    let context = CGContext(
                        data: buffer.baseAddress,
                        width: width,
                        height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: width * 4,
                        space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    )
                else {
                    return false
                }
                context.draw(
                    cgImage,
                    in: CGRect(x: 0, y: 0, width: width, height: height)
                )
                return true
            }
            guard drawn else {
                return ImageFormats.Image<RGBA>(width: 0, height: 0, bytes: [])
            }

            // Core Graphics only draws premultiplied RGBA; backends expect
            // straight alpha.
            for offset in stride(from: 0, to: bytes.count, by: 4) {
                let alpha = UInt16(bytes[offset + 3])
                guard alpha != 0, alpha != 255 else {
                    continue
                }
                for channel in 0..<3 {
                    let value = UInt16(bytes[offset + channel]) * 255 / alpha
                    bytes[offset + channel] = UInt8(min(value, 255))
                }
            }
            return ImageFormats.Image<RGBA>(width: width, height: height, bytes: bytes)
        }
    }
#endif

extension Image {
    /// The orientation of an image's pixels.
    ///
    /// Accepted by ``Image/init(decorative:scale:orientation:)`` for source
    /// compatibility; SwiftCrossUI draws images upright.
    public enum Orientation: UInt8, Hashable, Sendable, CaseIterable {
        case up
        case upMirrored
        case down
        case downMirrored
        case left
        case leftMirrored
        case right
        case rightMirrored
    }
}
