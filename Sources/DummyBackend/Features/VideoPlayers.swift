@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.VideoPlayers {
    public func createVideoPlayer() -> Widget {
        VideoPlayer()
    }

    public func updateVideoPlayer(
        _ videoPlayer: Widget,
        player: AnyObject?,
        showsPlaybackControls: Bool,
        environment: EnvironmentValues
    ) {
        record("updateVideoPlayer")
        let videoPlayer = videoPlayer as! VideoPlayer
        videoPlayer.player = player
        videoPlayer.showsPlaybackControls = showsPlaybackControls
        videoPlayer.updateCount += 1
    }
}
