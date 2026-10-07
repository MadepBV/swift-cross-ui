/// A view that shows the video of the platform's own media player, with the
/// platform's own playback controls, as SwiftUI's `VideoPlayer` does with an
/// `AVPlayer`.
///
/// The app owns the player and drives playback through it; this view only
/// presents it. `player` is the player object of the platform the backend draws
/// with: an `AVPlayer` for AppKitBackend, a `Windows.Media.Playback.MediaPlayer`
/// for WinUIBackend. A player of another kind, or `nil`, shows an empty video
/// surface. The view takes all the space it is offered.
///
/// Backends that don't implement ``BackendFeatures/VideoPlayers`` show an
/// empty area of the same size.
@available(tvOS, unavailable)
public struct VideoPlayer: ElementaryView {
    /// The size the player asks for when its parent proposes none: 16:9.
    static let idealSize = ViewSize(640, 360)

    var player: AnyObject?
    var showsPlaybackControls: Bool

    /// Creates a view that shows a platform player.
    ///
    /// - Parameters:
    ///   - player: The platform's player object, or `nil` for none yet.
    ///   - showsPlaybackControls: Whether the platform's own transport
    ///     controls are shown over the video. The default is `true`.
    public init(player: AnyObject?, showsPlaybackControls: Bool = true) {
        self.player = player
        self.showsPlaybackControls = showsPlaybackControls
    }

    func asWidget<Backend: BaseAppBackend>(backend: Backend) -> Backend.Widget {
        // A manual cast rather than @CastBackend, so that backends without
        // video support degrade to an empty widget instead of trapping.
        guard let videoBackend = backend as? any BaseAppBackend & BackendFeatures.VideoPlayers else {
            logger.warnOnce("VideoPlayer is unsupported by the current backend; showing an empty area")
            return backend.createContainer()
        }
        return Self.createPlayer(backend: videoBackend) as! Backend.Widget
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        let size = proposedSize.replacingUnspecifiedDimensions(by: Self.idealSize)
        return ViewLayoutResult.leafView(size: size).with(\.isNeverFocusable, false)
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        if let videoBackend = backend as? any BaseAppBackend & BackendFeatures.VideoPlayers {
            Self.updatePlayer(
                widget,
                player: player,
                showsPlaybackControls: showsPlaybackControls,
                environment: environment,
                backend: videoBackend
            )
        }
        backend.setSize(of: widget, to: layout.size.vector)
    }

    // Type-erased at the boundary so that the backend's associated widget type
    // can be recovered by the generic parameter.

    private static func createPlayer<Backend: BaseAppBackend & BackendFeatures.VideoPlayers>(
        backend: Backend
    ) -> Any {
        backend.createVideoPlayer()
    }

    private static func updatePlayer<Backend: BaseAppBackend & BackendFeatures.VideoPlayers>(
        _ widget: Any,
        player: AnyObject?,
        showsPlaybackControls: Bool,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.updateVideoPlayer(
            widget as! Backend.Widget,
            player: player,
            showsPlaybackControls: showsPlaybackControls,
            environment: environment
        )
    }
}
