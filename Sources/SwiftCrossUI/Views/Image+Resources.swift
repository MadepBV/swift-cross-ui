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
        if let url = Self.resourceURL(named: name, in: bundle ?? .main) {
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

    /// The URL of the first image file called `name` in `bundle`.
    static func resourceURL(named name: String, in bundle: Bundle) -> URL? {
        for fileExtension in resourceExtensions {
            if let url = bundle.url(forResource: name, withExtension: fileExtension) {
                return url
            }
        }
        return nil
    }
}
