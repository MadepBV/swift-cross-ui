import Foundation
import Testing

@testable @_spi(Backends) import SwiftCrossUI

/// Pins that views showing one picture file share one decode, and that a
/// rewritten file is decoded again.
@Suite("Decoded file image cache")
@MainActor
struct DecodedFileImageCacheTests {
    /// A 1 × 1 opaque red PNG.
    static let redPixel = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==")!
    /// A 2 × 1 PNG.
    static let twoPixels = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAYAAAD0In+KAAAADklEQVR4nGP4z8DwH4QBEfcD/ePF9e8AAAAASUVORK5CYII=")!

    private func storage(_ bytes: [UInt8]) -> UInt {
        bytes.withUnsafeBufferPointer { UInt(bitPattern: $0.baseAddress) }
    }

    @Test func sharesOneDecodePerFile() throws {
        DecodedFileImageCache.removeAll()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("scui-cache-\(UUID().uuidString).png")
        try Self.redPixel.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let first = try #require(DecodedFileImageCache.image(at: url, useFileExtension: true))
        let second = try #require(DecodedFileImageCache.image(at: url, useFileExtension: true))
        #expect(first.width == 1 && first.height == 1)
        #expect(storage(first.bytes) == storage(second.bytes))
    }

    @Test func decodesARewrittenFileAgain() throws {
        DecodedFileImageCache.removeAll()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("scui-cache-\(UUID().uuidString).png")
        try Self.redPixel.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let before = try #require(DecodedFileImageCache.image(at: url, useFileExtension: true))

        try Self.twoPixels.write(to: url)
        let after = try #require(DecodedFileImageCache.image(at: url, useFileExtension: true))
        #expect(before.width == 1)
        #expect(after.width == 2)
    }

    @Test func staysWithinItsByteLimit() throws {
        DecodedFileImageCache.removeAll()
        let limit = DecodedFileImageCache.byteLimit
        DecodedFileImageCache.byteLimit = 4
        defer { DecodedFileImageCache.byteLimit = limit; DecodedFileImageCache.removeAll() }
        var urls: [URL] = []
        for _ in 0..<3 {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("scui-cache-\(UUID().uuidString).png")
            try Self.redPixel.write(to: url)
            urls.append(url)
        }
        defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }
        let first = try #require(DecodedFileImageCache.image(at: urls[0], useFileExtension: true))
        _ = DecodedFileImageCache.image(at: urls[1], useFileExtension: true)
        // The first was evicted to make room, so it decodes into a new buffer.
        let again = try #require(DecodedFileImageCache.image(at: urls[0], useFileExtension: true))
        #expect(storage(first.bytes) != storage(again.bytes) || first.bytes.isEmpty)
    }
}
