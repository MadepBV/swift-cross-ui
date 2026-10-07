import Foundation
import ImageFormats

extension Image {
    /// The file types searched for a named image, in order.
    static let resourceExtensions = ["png", "jpg", "jpeg", "webp"]

    /// Creates an image from a named image resource.
    ///
    /// SwiftUI reads the name from an asset catalog. SwiftCrossUI has no
    /// asset catalog (Xcode compiles catalogs into a format only Apple
    /// platforms read), so it looks for an image file of that name among the
    /// bundle's resources instead: `name.png`, then `.jpg`, `.jpeg` and
    /// `.webp`. Ship the images as plain resources (for example with
    /// `resources: [.copy("Images")]` in a package manifest) and the call
    /// site stays as it is.
    ///
    /// A name with no matching file draws nothing, at zero size, rather than
    /// a guess.
    ///
    /// - Parameters:
    ///   - name: The resource's name, without an extension.
    ///   - bundle: The bundle to search. `nil` searches the main bundle.
    public init(_ name: String, bundle: Bundle? = nil) {
        if let url = Self.resourceURL(named: name, in: bundle) {
            self.init(url)
        } else {
            self.init(ImageFormats.Image<RGBA>(width: 0, height: 0, bytes: []))
        }
    }

    /// Creates a named image resource that carries no accessibility meaning.
    ///
    /// See ``Image/init(_:bundle:)`` for how the name is resolved.
    ///
    /// - Parameters:
    ///   - name: The resource's name, without an extension.
    ///   - bundle: The bundle to search. `nil` searches the main bundle.
    public init(decorative name: String, bundle: Bundle? = nil) {
        self.init(name, bundle: bundle)
    }

    /// The URL of the first image file called `name` in `bundle`, or, with
    /// no bundle, in the main bundle and then in the resource bundles SwiftPM
    /// copies beside an executable (`<package>_<target>.resources` on Windows
    /// and Linux, `.bundle` on macOS) — where an app's own target puts the
    /// images it ships, since that is not the main bundle there.
    public static func resourceURL(named name: String, in bundle: Bundle?) -> URL? {
        if let bundle {
            return resourceURL(named: name, inOnly: bundle)
        }
        // A view's body names its picture on every evaluation, and each
        // lookup below is a file-system probe per extension and bundle, so
        // the answer for the default bundles is remembered.
        if let known = defaultBundleURLs.withLock({ $0[name] }) {
            return known
        }
        var found: URL?
        for candidate in [Bundle.main] + siblingResourceBundles {
            if let url = resourceURL(named: name, inOnly: candidate) {
                found = url
                break
            }
        }
        defaultBundleURLs.withLock { $0[name] = .some(found) }
        return found
    }

    /// Resolved names in the default bundles, including names that resolve to
    /// nothing. Bundled resources don't change while an app runs.
    private static let defaultBundleURLs = ResourceURLCache()

    /// The SwiftPM resource bundles in the executable's directory, read once.
    private static let siblingResourceBundles: [Bundle] = {
        guard let directory = Bundle.main.executableURL?.deletingLastPathComponent(),
            let entries = try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil)
        else {
            return []
        }
        return entries
            .filter { ["resources", "bundle"].contains($0.pathExtension) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { Bundle(url: $0) }
    }()

    private static func resourceURL(named name: String, inOnly bundle: Bundle) -> URL? {
        for fileExtension in resourceExtensions {
            if let url = bundle.url(forResource: name, withExtension: fileExtension) {
                return url
            }
        }
        return nil
    }
}

/// A lock-guarded name → URL table, usable from any isolation because
/// `Image.init(_:bundle:)` is nonisolated.
final class ResourceURLCache: @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [String: URL?] = [:]

    func withLock<T>(_ body: (inout [String: URL?]) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&urls)
    }
}
