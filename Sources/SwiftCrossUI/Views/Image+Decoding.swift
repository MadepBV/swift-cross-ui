import Foundation
import ImageFormats

/// Straight-alpha sRGB pixels, the form every backend draws.
///
/// Apps that decode pictures themselves (downloaded artwork, say) keep this
/// instead of a `CGImage` on platforms without Core Graphics, and show it with
/// ``Image/init(decorative:scale:orientation:)-(RasterImage,_,_)``.
public typealias RasterImage = ImageFormats.Image<RGBA>

extension ImageFormats.Image where Pixel == RGBA {
    /// Decodes PNG, JPEG or WebP bytes, scaled down so that neither side
    /// exceeds `maximumPixelSize`.
    ///
    /// This is the counterpart of ImageIO's thumbnail decoding where ImageIO
    /// doesn't exist. The format is detected from the bytes. Downscaling picks
    /// the nearest source pixel, which keeps the cost proportional to the
    /// output size.
    ///
    /// - Parameters:
    ///   - data: The encoded picture.
    ///   - maximumPixelSize: The longest side allowed, in pixels.
    /// - Returns: The picture, or `nil` if the bytes aren't a supported format.
    public init?(decoding data: Data, maximumPixelSize: Int) {
        guard let decoded = try? Self.load(from: [UInt8](data)) else {
            return nil
        }
        self = decoded.scaledDown(toFit: maximumPixelSize)
    }

    /// A copy whose longest side is at most `maximumPixelSize`, or the image
    /// itself if it's already that small.
    public func scaledDown(toFit maximumPixelSize: Int) -> Self {
        let longest = Swift.max(width, height)
        guard maximumPixelSize > 0, longest > maximumPixelSize else {
            return self
        }
        let factor = Double(maximumPixelSize) / Double(longest)
        let newWidth = Swift.max(1, Int((Double(width) * factor).rounded()))
        let newHeight = Swift.max(1, Int((Double(height) * factor).rounded()))
        var output = [UInt8](repeating: 0, count: newWidth * newHeight * 4)
        bytes.withUnsafeBufferPointer { source in
            output.withUnsafeMutableBufferPointer { target in
                for y in 0..<newHeight {
                    let sourceRow = Swift.min(height - 1, y * height / newHeight) * width
                    for x in 0..<newWidth {
                        let from = (sourceRow + Swift.min(width - 1, x * width / newWidth)) * 4
                        let to = (y * newWidth + x) * 4
                        target[to] = source[from]
                        target[to + 1] = source[from + 1]
                        target[to + 2] = source[from + 2]
                        target[to + 3] = source[from + 3]
                    }
                }
            }
        }
        return Self(width: newWidth, height: newHeight, bytes: output)
    }
}

extension Image {
    /// Creates an image from decoded pixels that carry no accessibility
    /// meaning, spelled like SwiftUI's `CGImage` initializer so call sites
    /// read the same on every platform.
    ///
    /// - Parameters:
    ///   - image: The pixels to show.
    ///   - scale: Accepted for source compatibility; see
    ///     ``Image/init(decorative:scale:orientation:)``.
    ///   - orientation: Accepted for source compatibility; drawn upright.
    public init(
        decorative image: RasterImage,
        scale: Double,
        orientation: Orientation = .up
    ) {
        self.init(image)
    }
}
