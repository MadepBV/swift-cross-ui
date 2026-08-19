import Foundation
import ImageFormats

/// A view that displays an image.
///
/// ## System images
///
/// ``Image/init(systemName:)`` takes an Apple SF Symbol name so that SwiftUI
/// source compiles unchanged on every platform:
///
/// ```swift
/// Image(systemName: "square.and.arrow.up")
///     .foregroundColor(.blue)
/// ```
///
/// SF Symbols are an Apple-only font, so the name is resolved through the
/// environment's ``EnvironmentValues/symbolProvider``. By default that's
/// ``LucideSymbolProvider``, which draws bundled [Lucide](https://lucide.dev)
/// vector geometry. Symbols are drawn with the current foreground colour, and
/// size themselves from the current font unless ``resizable()`` is used.
///
/// ## See Also
///
/// - ``SymbolProvider``
/// - ``View/symbolProvider(_:)``
public struct Image: Sendable {
    /// How much larger a symbol is than the point size of the current font.
    ///
    /// SF Symbols are drawn slightly taller than their font's point size so
    /// that they optically match the text beside them; this approximates the
    /// same relationship.
    private static let symbolSizeRelativeToFont = 1.2

    /// Whether the image is resizable.
    private var isResizable = false
    /// The source of the image.
    private var source: Source

    enum Source: Equatable {
        case url(URL, useFileExtension: Bool)
        case image(ImageFormats.Image<RGBA>)
        case systemName(String)
    }

    /// Creates an image view.
    ///
    /// `png`, `jpg`, and `webp` are supported.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to display.
    ///   - useFileExtension: If `true`, the file extension is used to determine
    ///     the file type, otherwise the first few ('magic') bytes of the file
    ///     are used.
    public init(_ url: URL, useFileExtension: Bool = true) {
        source = .url(url, useFileExtension: useFileExtension)
    }

    /// Displays an image from raw pixel data.
    ///
    /// - Parameter image: The image data to display.
    public init(_ image: ImageFormats.Image<RGBA>) {
        source = .image(image)
    }

    /// Creates an image view showing a system symbol.
    ///
    /// The name is an Apple SF Symbol name, such as `"trash"` or
    /// `"square.and.arrow.up"`. On platforms without SF Symbols the name is
    /// resolved by the environment's ``EnvironmentValues/symbolProvider``,
    /// which by default draws an equivalent bundled Lucide icon.
    ///
    /// A name the provider doesn't recognise draws a generic placeholder
    /// rather than a guess, so a missing symbol is visible rather than
    /// misleading.
    ///
    /// - Parameter systemName: The name of the system symbol to display.
    public init(systemName: String) {
        source = .systemName(systemName)
    }

    /// Makes the image resize to fit the available space.
    public func resizable() -> Self {
        var image = self
        image.isResizable = true
        return image
    }

    init(_ source: Source, resizable: Bool) {
        self.source = source
        self.isResizable = resizable
    }

    /// Builds the request used to resolve this image's symbol, if it has one.
    ///
    /// - Parameter environment: The environment the image is being shown in.
    /// - Returns: A resolution request, or `nil` for non-symbol images.
    @MainActor
    private func symbolRequest(
        in environment: EnvironmentValues
    ) -> SymbolRenderRequest? {
        guard case .systemName(let name) = source else {
            return nil
        }
        return SymbolRenderRequest(
            name: name,
            pointSize: environment.resolvedFont.pointSize
                * Self.symbolSizeRelativeToFont,
            scaleFactor: environment.windowScaleFactor,
            color: environment.suggestedForegroundColor
        )
    }
}

extension Image: View {
    public var body: some View { return EmptyView() }
}

extension Image: TypeSafeView {
    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: ImageChildren
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> ImageChildren {
        ImageChildren(backend: backend)
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: ImageChildren,
        backend: Backend
    ) -> Backend.Widget {
        children.container.into()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: ImageChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        resolveContent(children: children, environment: environment)

        let idealSize: ViewSize?
        switch children.content {
            case .image(let image):
                idealSize = ViewSize(
                    Double(image.width),
                    Double(image.height)
                )
            case .geometry:
                let side =
                    children.cachedSymbolRequest?.pointSize
                    ?? environment.resolvedFont.pointSize
                idealSize = ViewSize(side, side)
            case .none:
                idealSize = nil
        }

        let size: ViewSize
        if let idealSize {
            if isResizable {
                size = proposedSize.replacingUnspecifiedDimensions(
                    by: idealSize
                )
            } else {
                size = idealSize
            }
        } else {
            size = .zero
        }

        return ViewLayoutResult.leafView(size: size)
    }

    /// Loads or resolves this image's content into `children` if it's stale.
    ///
    /// - Parameters:
    ///   - children: The image's persistent storage.
    ///   - environment: The environment the image is being shown in.
    @MainActor
    private func resolveContent(
        children: ImageChildren,
        environment: EnvironmentValues
    ) {
        let request = symbolRequest(in: environment)
        guard
            source != children.cachedImageSource
                || request != children.cachedSymbolRequest
        else {
            return
        }

        children.cachedImageSource = source
        children.cachedSymbolRequest = request
        children.contentChanged = true

        switch source {
            case .url(let url, let useFileExtension):
                children.content = Self.loadContent(
                    fromURL: url,
                    useFileExtension: useFileExtension
                )
            case .image(let sourceImage):
                children.content = .image(sourceImage)
            case .systemName:
                guard let request else {
                    children.content = .none
                    return
                }
                switch environment.symbolProvider.resolve(request) {
                    case .geometry(let geometry):
                        children.content = .geometry(geometry)
                    case .image(let image):
                        children.content = .image(image)
                    case nil:
                        children.content = .none
                }
        }
    }

    /// Loads image data from a URL.
    ///
    /// - Parameters:
    ///   - url: The URL to load from.
    ///   - useFileExtension: Whether to use the file extension rather than the
    ///     file's magic bytes to determine its format.
    /// - Returns: The loaded content, or ``ImageChildren/Content/none`` if the
    ///   file couldn't be read or decoded.
    private static func loadContent(
        fromURL url: URL,
        useFileExtension: Bool
    ) -> ImageChildren.Content {
        // TODO: Propagate these errors somewhere. Maybe even just as trace
        //   log messages.
        guard let data = try? Data(contentsOf: url) else {
            return .none
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

        guard let image else {
            return .none
        }
        return .image(image)
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: ImageChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = layout.size.vector
        let hasResized = children.cachedDisplaySize != size
        children.cachedDisplaySize = size

        switch children.content {
            case .image(let image):
                commitImage(
                    image,
                    children: children,
                    size: size,
                    hasResized: hasResized,
                    environment: environment,
                    backend: backend
                )
            case .geometry(let geometry):
                commitSymbol(
                    geometry,
                    children: children,
                    size: size,
                    environment: environment,
                    backend: backend
                )
            case .none:
                children.detachAll(backend: backend)
        }

        children.contentChanged = false
        children.lastScaleFactor = environment.windowScaleFactor
        backend.setSize(of: children.container.into(), to: size)
    }

    /// Draws raster content into the image widget.
    @MainActor
    private func commitImage<Backend: BaseAppBackend>(
        _ image: ImageFormats.Image<RGBA>,
        children: ImageChildren,
        size: SIMD2<Int>,
        hasResized: Bool,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        if children.isSymbolAttached {
            children.detachAll(backend: backend)
        }

        let scaleFactorChanged =
            backend.requiresImageUpdateOnScaleFactorChange
            && children.lastScaleFactor != environment.windowScaleFactor
        if children.contentChanged || hasResized || scaleFactorChanged {
            backend.updateImageView(
                children.imageWidget.into(),
                rgbaData: image.bytes,
                width: image.width,
                height: image.height,
                targetWidth: size.x,
                targetHeight: size.y,
                dataHasChanged: children.contentChanged,
                environment: environment
            )
        }

        if !children.isImageAttached {
            backend.insert(
                children.imageWidget.into(),
                into: children.container.into(),
                at: 0
            )
            backend.setPosition(
                ofChildAt: 0,
                in: children.container.into(),
                to: .zero
            )
            children.isImageAttached = true
        }
        backend.setSize(of: children.imageWidget.into(), to: size)
    }

    /// Draws vector symbol geometry into a backend path widget.
    ///
    /// Rendering paths requires ``BackendFeatures/Paths``. Every shipping
    /// backend implements it, but rather than trapping on one that doesn't,
    /// the symbol is simply left undrawn.
    @MainActor
    private func commitSymbol<Backend: BaseAppBackend>(
        _ geometry: SymbolGeometry,
        children: ImageChildren,
        size: SIMD2<Int>,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        if children.isImageAttached {
            children.detachAll(backend: backend)
        }

        guard
            let pathsBackend = backend as? any BaseAppBackend
                & BackendFeatures.Paths
        else {
            return
        }
        Self.drawSymbol(
            geometry,
            children: children,
            size: size,
            environment: environment,
            backend: pathsBackend
        )
    }

    /// Draws symbol geometry using a backend that supports paths.
    ///
    /// Split out from ``commitSymbol(_:children:size:environment:backend:)``
    /// so that the existential path backend can be opened into a generic
    /// parameter.
    @MainActor
    private static func drawSymbol<
        Backend: BaseAppBackend & BackendFeatures.Paths
    >(
        _ geometry: SymbolGeometry,
        children: ImageChildren,
        size: SIMD2<Int>,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let container: Backend.Widget = children.container.into()
        let widget: Backend.Widget
        let backendPath: Backend.Path
        if let existing = children.symbolWidget,
            let existingPath = children.symbolPath as? Backend.Path
        {
            widget = existing.into()
            backendPath = existingPath
        } else {
            widget = backend.createPathWidget()
            backendPath = backend.createPath()
            children.symbolWidget = AnyWidget(widget)
            children.symbolPath = backendPath
            children.oldSymbolPath = nil
        }

        let bounds = Path.Rect(
            x: 0,
            y: 0,
            width: Double(size.x),
            height: Double(size.y)
        )
        let path = geometry.path(in: bounds)
        let pointsChanged = children.oldSymbolPath?.actions != path.actions
        children.oldSymbolPath = path

        backend.updatePath(
            backendPath,
            path,
            bounds: bounds,
            pointsChanged: pointsChanged,
            environment: environment
        )
        backend.setSize(of: widget, to: size)

        let tint = environment.suggestedForegroundColor.resolve(in: environment)
        let clear = Color.clear.resolve(in: environment)
        backend.renderPath(
            backendPath,
            container: widget,
            strokeColor: geometry.rendering == .stroked ? tint : clear,
            fillColor: geometry.rendering == .filled ? tint : clear,
            overrideStrokeStyle: geometry.strokeStyle(in: bounds)
        )

        if !children.isSymbolAttached {
            backend.insert(widget, into: container, at: 0)
            backend.setPosition(ofChildAt: 0, in: container, to: .zero)
            children.isSymbolAttached = true
        }
    }
}

/// Image's persistent storage. Only exposed with the `package` access level
/// in order for backends to implement the `Image.inspect(_:_:)` modifier.
@_spi(Backends) public class ImageChildren: ViewGraphNodeChildren {
    /// What an image resolved to, once its source was loaded.
    enum Content {
        /// Nothing to draw.
        case none
        /// Raster pixel data to hand to the backend's image view.
        case image(ImageFormats.Image<RGBA>)
        /// Vector geometry to draw with the backend's path support.
        case geometry(SymbolGeometry)
    }

    /// The resolved content of the image.
    var content: Content = .none
    /// The source the resolved content was loaded from.
    var cachedImageSource: Image.Source? = nil
    /// The request the resolved symbol content was produced for.
    var cachedSymbolRequest: SymbolRenderRequest? = nil
    /// The size the content was last laid out at.
    var cachedDisplaySize: SIMD2<Int> = .zero
    /// Whether ``content`` changed since the last commit.
    var contentChanged = false
    /// The window scale factor at the last commit.
    var lastScaleFactor: Double = 1

    /// The widget everything else is nested inside.
    var container: AnyWidget
    /// The backend image view used for raster content.
    public var imageWidget: AnyWidget
    /// Whether ``imageWidget`` is currently in the container.
    var isImageAttached = false

    /// The backend path widget used for vector symbols, once one is needed.
    var symbolWidget: AnyWidget? = nil
    /// The backend path drawn into ``symbolWidget``.
    var symbolPath: Any? = nil
    /// The path last drawn, used to skip redundant geometry uploads.
    var oldSymbolPath: Path? = nil
    /// Whether ``symbolWidget`` is currently in the container.
    var isSymbolAttached = false

    init<Backend: BaseAppBackend>(backend: Backend) {
        container = AnyWidget(backend.createContainer())
        imageWidget = AnyWidget(backend.createImageView())
    }

    /// Empties the container.
    ///
    /// Backends only offer bulk child removal, and the container never holds
    /// more than one child anyway, so switching between raster and vector
    /// content goes via this.
    @MainActor
    func detachAll<Backend: BaseAppBackend>(backend: Backend) {
        guard isImageAttached || isSymbolAttached else {
            return
        }
        backend.removeAllChildren(of: container.into())
        isImageAttached = false
        isSymbolAttached = false
        oldSymbolPath = nil
    }

    public var widgets: [AnyWidget] = []
    public var erasedNodes: [ErasedViewGraphNode] = []
}
