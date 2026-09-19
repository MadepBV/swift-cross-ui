import Testing
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing RGBA image uploads")
struct RGBAImageBufferTests {
    /// The existing scalar upload's output, deliberately expressed per byte.
    private func expected(_ source: [UInt8], count: Int) -> [UInt8] {
        var result = Array(source.prefix(count))
        for pixel in 0..<(count / 4) {
            let offset = pixel * 4
            if source[offset + 3] == 0 {
                result[offset] = 0
                result[offset + 1] = 0
                result[offset + 2] = 0
            } else {
                result[offset] = source[offset + 2]
                result[offset + 2] = source[offset]
            }
        }
        return result
    }

    @Test("Channels and partial alpha survive vector and scalar conversion")
    func channelAndAlphaConversion() {
        let source: [UInt8] = [
            255, 20, 40, 255,
            200, 150, 100, 0,
            101, 202, 33, 128,
            1, 2, 3, 1,
            21, 42, 63, 254,
        ]
        var destination = [UInt8](repeating: 99, count: source.count)
        let copied = source.withUnsafeBytes { input in
            destination.withUnsafeMutableBytes {
                RGBAImageBuffer.copyToBGRA(input, into: $0)
            }
        }
        #expect(copied == source.count)
        #expect(destination == [
            40, 20, 255, 255,
            0, 0, 0, 0,
            33, 202, 101, 128,
            3, 2, 1, 1,
            63, 42, 21, 254,
        ])
    }

    @Test("Unaligned source and destination slices preserve guard bytes")
    func unalignedSlicesAndTails() {
        let pixels = (0..<97).map { UInt8(truncatingIfNeeded: $0 * 31) }
        for sourceOffset in 0..<16 {
            for destinationOffset in 0..<16 {
                for count in [0, 1, 3, 4, 15, 16, 17, 31, 32, 63, 64, 97] {
                    let source = [UInt8](repeating: 0xab, count: sourceOffset) + pixels
                    let original = source
                    var destination = [UInt8](
                        repeating: 0xcd, count: destinationOffset + count + 16)
                    let copied = source.withUnsafeBytes { input in
                        destination.withUnsafeMutableBytes { output in
                            RGBAImageBuffer.copyToBGRA(
                                UnsafeRawBufferPointer(rebasing: input[sourceOffset..<(sourceOffset + count)]),
                                into: UnsafeMutableRawBufferPointer(rebasing: output[destinationOffset..<(destinationOffset + count)]))
                        }
                    }
                    #expect(copied == count)
                    #expect(source == original)
                    #expect(Array(destination[..<destinationOffset]) == [UInt8](repeating: 0xcd, count: destinationOffset))
                    #expect(Array(destination[destinationOffset..<(destinationOffset + count)]) == expected(pixels, count: count))
                    #expect(Array(destination[(destinationOffset + count)...]) == [UInt8](repeating: 0xcd, count: 16))
                }
            }
        }
    }

    @Test("The shorter buffer bounds every copy, including incomplete pixels")
    func shortBuffers() {
        for sourceCount in 0...35 {
            for destinationCount in 0...35 {
                let source = (0..<sourceCount).map { UInt8($0 * 7) }
                var destination = [UInt8](repeating: 0xef, count: destinationCount)
                let copied = source.withUnsafeBytes { input in
                    destination.withUnsafeMutableBytes {
                        RGBAImageBuffer.copyToBGRA(input, into: $0)
                    }
                }
                let count = min(sourceCount, destinationCount)
                #expect(copied == count)
                #expect(Array(destination.prefix(count)) == expected(source, count: count))
                #expect(Array(destination.dropFirst(count)) == [UInt8](repeating: 0xef, count: destinationCount - count))
            }
        }
    }
}
