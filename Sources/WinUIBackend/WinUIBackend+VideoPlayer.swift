@_spi(Backends) import SwiftCrossUI
import UWP
import WinAppSDK
import WinUI

extension WinUIBackend: BackendFeatures.VideoPlayers {
    public func createVideoPlayer() -> Widget {
        // WinUI's own media element with its `MediaTransportControls`: play and pause, the seek bar, skipping,
        // volume, captions (the player's text tracks) and full window. Not subclassed: its constructor queries the
        // object it is building, which a Swift subclass cannot answer before its own initialiser has run.
        let element = WinUI.MediaPlayerElement()
        element.stretch = .uniform
        element.areTransportControlsEnabled = true
        if let controls = element.transportControls {
            // Across the whole video, as in the system's own players; left to themselves they took their desired
            // width, centred, under a parent that measures without bounds.
            controls.horizontalAlignment = .stretch
            controls.verticalAlignment = .stretch
            controls.isZoomButtonVisible = false
            controls.isCompact = false
            controls.isSkipBackwardButtonVisible = true
            controls.isSkipBackwardEnabled = true
            controls.isSkipForwardButtonVisible = true
            controls.isSkipForwardEnabled = true
        }
        let state = VideoPlayerElementState()
        state.fullWindowCallback = try? element.registerPropertyChangedCallback(MediaPlayerElement.isFullWindowProperty) {
            [weak self] sender, _ in
            guard let element = sender as? WinUI.MediaPlayerElement else { return }
            logger.warning("video player full window", metadata: ["isFullWindow": "\(element.isFullWindow)"])
            self?.setFullScreen(element.isFullWindow)
        }
        VideoPlayerElementState.states[ObjectIdentifier(element)] = state
        return element
    }

    public func updateVideoPlayer(
        _ videoPlayer: Widget,
        player: AnyObject?,
        showsPlaybackControls: Bool,
        environment: EnvironmentValues
    ) {
        let element = videoPlayer as! WinUI.MediaPlayerElement
        let state = VideoPlayerElementState.states[ObjectIdentifier(element)] ?? VideoPlayerElementState()
        VideoPlayerElementState.states[ObjectIdentifier(element)] = state
        let mediaPlayer = player as? UWP.MediaPlayer
        // Compared by identity: each read of `mediaPlayer` returns a new wrapper.
        if mediaPlayer !== state.presentedPlayer || !state.hasPresented {
            state.presentedPlayer = mediaPlayer
            state.hasPresented = true
            try? element.setMediaPlayer(mediaPlayer)
        }
        if state.showsControls != showsPlaybackControls {
            state.showsControls = showsPlaybackControls
            element.areTransportControlsEnabled = showsPlaybackControls
        }
    }

    /// The transport controls' full-window button fills the window with the video; the window itself then takes the
    /// whole screen, as a video player's full screen does, and returns when the button is pressed again.
    private func setFullScreen(_ isFullScreen: Bool) {
        guard let window = windows.first(where: \.isActive) ?? windows.first else { return }
        try? window.cachedAppWindow.setPresenter(isFullScreen ? .fullScreen : .overlapped)
    }
}

/// What the backend remembers about a media element between updates.
@MainActor final class VideoPlayerElementState {
    static var states: [ObjectIdentifier: VideoPlayerElementState] = [:]

    weak var presentedPlayer: UWP.MediaPlayer?
    var hasPresented = false
    var showsControls: Bool?
    var fullWindowCallback: Int64?
}
