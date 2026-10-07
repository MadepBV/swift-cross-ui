extension BackendFeatures {
    /// Backend methods for video players.
    ///
    /// These are used by ``VideoPlayer``. The backend presents a player object
    /// the app owns, in the platform's own video surface with the platform's
    /// own playback controls; it never drives playback itself.
    @MainActor
    public protocol VideoPlayers: Core {
        /// Creates a video surface with the platform's playback controls.
        ///
        /// - Returns: A video player widget showing no player yet.
        func createVideoPlayer() -> Widget

        /// Shows a player in a video player widget.
        ///
        /// Called on every update, so a backend should skip work when nothing
        /// changed. A player of a kind the backend does not present, or `nil`,
        /// leaves the surface empty.
        ///
        /// - Parameters:
        ///   - videoPlayer: The video player widget.
        ///   - player: The platform's player object: an `AVPlayer` for the
        ///     Apple backends, a `Windows.Media.Playback.MediaPlayer` for
        ///     WinUIBackend.
        ///   - showsPlaybackControls: Whether the platform's own transport
        ///     controls are shown over the video.
        ///   - environment: The current environment.
        func updateVideoPlayer(
            _ videoPlayer: Widget,
            player: AnyObject?,
            showsPlaybackControls: Bool,
            environment: EnvironmentValues
        )
    }
}
