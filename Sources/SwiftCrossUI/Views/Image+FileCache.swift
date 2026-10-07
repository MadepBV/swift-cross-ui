import Foundation
import ImageFormats

/// Pictures decoded from files, shared by every image view showing the same
/// file.
///
/// An `Image(url)` (and `Image(name)`, which resolves to a file) used to read
/// and decode its file in the first layout of every view that showed it, on
/// the main thread. A grid of cards built from a handful of bundled pictures
/// decoded the same full-size PNG once per card — tens of megabytes of pixels
/// per screen, each card holding its own copy. Here one decode serves them
/// all, and because the cached pixels are one array, every view hands the
/// backend the same buffer, which a backend can recognise and share.
///
/// The cache is keyed by the file's path, size and modification date, so a
/// file rewritten on disk is decoded again. It is bounded by the bytes of the
/// pixels it holds and evicts the least recently used picture first; a view
/// keeps its own reference to what it shows, so eviction never blanks one.
@MainActor
enum DecodedFileImageCache {
    struct Key: Hashable {
        var path: String
        var useFileExtension: Bool
        var fileSize: Int
        var modified: Date?
    }

    /// The most pixel bytes kept for views that may appear later.
    static var byteLimit = 96 * 1_024 * 1_024

    private static var entries: [Key: (image: ImageFormats.Image<RGBA>, lastUse: UInt64)] = [:]
    private static var bytes = 0
    private static var clock: UInt64 = 0

    /// The decoded picture at a file URL, from the cache or freshly decoded.
    ///
    /// - Returns: The picture, or `nil` if the file can't be read or decoded.
    static func image(at url: URL, useFileExtension: Bool) -> ImageFormats.Image<RGBA>? {
        let path = url.path
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        let key = Key(
            path: path,
            useFileExtension: useFileExtension,
            fileSize: (attributes?[.size] as? NSNumber)?.intValue ?? -1,
            modified: attributes?[.modificationDate] as? Date
        )
        clock &+= 1
        if let entry = entries[key] {
            entries[key] = (entry.image, clock)
            return entry.image
        }
        guard let image = decode(url, useFileExtension: useFileExtension) else {
            return nil
        }
        store(image, for: key)
        return image
    }

    /// Empties the cache. For tests.
    static func removeAll() {
        entries.removeAll()
        bytes = 0
    }

    private static func store(_ image: ImageFormats.Image<RGBA>, for key: Key) {
        let cost = image.bytes.count
        guard cost <= byteLimit else { return }
        entries[key] = (image, clock)
        bytes += cost
        while bytes > byteLimit, let oldest = entries.min(by: { $0.value.lastUse < $1.value.lastUse }) {
            entries[oldest.key] = nil
            bytes -= oldest.value.image.bytes.count
        }
    }

    private static func decode(_ url: URL, useFileExtension: Bool) -> ImageFormats.Image<RGBA>? {
        let started = DispatchTime.now().uptimeNanoseconds
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        let bytes = Array(data)
        let image: ImageFormats.Image<RGBA>?
        if useFileExtension {
            image = try? ImageFormats.Image<RGBA>.load(
                from: bytes,
                usingFileExtension: url.pathExtension
            )
        } else {
            image = try? ImageFormats.Image<RGBA>.load(from: bytes)
        }
        PerformanceRecorder.imageDecoded(
            what: "url:\(url.lastPathComponent)", width: image?.width ?? 0, height: image?.height ?? 0,
            nanoseconds: DispatchTime.now().uptimeNanoseconds &- started)
        return image
    }
}
