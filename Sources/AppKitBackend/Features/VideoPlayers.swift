import AVFoundation
import AVKit
import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.VideoPlayers {
    public func createVideoPlayer() -> Widget {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .floating
        playerView.videoGravity = .resizeAspect
        playerView.showsFullScreenToggleButton = true
        return playerView
    }

    public func updateVideoPlayer(
        _ videoPlayer: Widget,
        player: AnyObject?,
        showsPlaybackControls: Bool,
        environment: EnvironmentValues
    ) {
        let playerView = videoPlayer as! AVPlayerView
        let avPlayer = player as? AVPlayer
        if playerView.player !== avPlayer {
            playerView.player = avPlayer
        }
        let style: AVPlayerViewControlsStyle = showsPlaybackControls ? .floating : .none
        if playerView.controlsStyle != style {
            playerView.controlsStyle = style
        }
    }
}
