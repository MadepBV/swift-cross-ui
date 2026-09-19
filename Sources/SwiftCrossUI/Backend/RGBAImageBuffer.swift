/// Pixel conversion shared by backends that present RGBA images as BGRA.
@_spi(Backends)
public enum RGBAImageBuffer {
    /// Copies RGBA pixels to a BGRA destination in one pass.
    ///
    /// Fully transparent pixels are normalized to transparent black, matching
    /// the XAML image upload convention. Other alpha values are preserved.
    /// The source and destination must not overlap. Neither buffer needs to
    /// have a particular alignment. Bytes after the last complete pixel are
    /// copied unchanged, and bytes outside the shorter buffer are untouched.
    ///
    /// - Returns: The number of bytes copied.
    @discardableResult
    public static func copyToBGRA(
        _ source: UnsafeRawBufferPointer,
        into destination: UnsafeMutableRawBufferPointer
    ) -> Int {
        let byteCount = min(source.count, destination.count)
        guard byteCount > 0,
              let sourceBase = source.baseAddress,
              let destinationBase = destination.baseAddress
        else { return 0 }

        let pixelByteCount = byteCount - byteCount % 4
        var offset = 0
        #if _endian(little)
        // Four pixels at once. Unaligned loads/stores are deliberate: WinRT
        // and slices of an image buffer do not promise SIMD alignment.
        let keepGreenAndAlpha = SIMD4<UInt32>(repeating: 0xff00ff00)
        let red = SIMD4<UInt32>(repeating: 0x000000ff)
        let alpha = SIMD4<UInt32>(repeating: 0xff000000)
        while offset + 16 <= pixelByteCount {
            let rgba = sourceBase.loadUnaligned(
                fromByteOffset: offset, as: SIMD4<UInt32>.self)
            let bgra = (rgba & keepGreenAndAlpha)
                | ((rgba & red) &<< 16) | ((rgba &>> 16) & red)
            let normalized = bgra.replacing(
                with: SIMD4<UInt32>(repeating: 0),
                where: (rgba & alpha) .== SIMD4<UInt32>(repeating: 0))
            destinationBase.storeBytes(
                of: normalized, toByteOffset: offset, as: SIMD4<UInt32>.self)
            offset += 16
        }
        #endif

        while offset < pixelByteCount {
            let alpha = source[offset + 3]
            destination[offset] = alpha == 0 ? 0 : source[offset + 2]
            destination[offset + 1] = alpha == 0 ? 0 : source[offset + 1]
            destination[offset + 2] = alpha == 0 ? 0 : source[offset]
            destination[offset + 3] = alpha
            offset += 4
        }
        while offset < byteCount {
            destination[offset] = source[offset]
            offset += 1
        }
        return byteCount
    }
}
