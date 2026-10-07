import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// Stands in for a platform player object (`AVPlayer`, `MediaPlayer`).
private final class FakePlatformPlayer {}

@Suite("Testing for VideoPlayer")
struct VideoPlayerTests {
    @MainActor
    @Test("VideoPlayer takes all the space it is offered")
    func fillsProposal() {
        let result = ViewGraphHelpers.computeLayout(
            of: VideoPlayer(player: nil),
            proposedSize: ProposedViewSize(1280, 720)
        )
        #expect(result.size == ViewSize(1280, 720))
    }

    @MainActor
    @Test("VideoPlayer asks for 16:9 where nothing is proposed")
    func idealSizeIsSixteenByNine() {
        let result = ViewGraphHelpers.computeLayout(of: VideoPlayer(player: nil))
        #expect(result.size == ViewSize(640, 360))
    }

    @MainActor
    @Test("VideoPlayer hands the app's own player and controls choice to the backend")
    func handsPlayerToBackend() throws {
        let player = FakePlatformPlayer()
        let node = ViewGraphHelpers.committedNode(
            for: VideoPlayer(player: player, showsPlaybackControls: false),
            proposedSize: ProposedViewSize(800, 450)
        )
        let widget = try #require(node.widget as? DummyBackend.VideoPlayer)
        #expect(widget.player === player)
        #expect(widget.showsPlaybackControls == false)
        #expect(widget.size == SIMD2(800, 450))
    }

    @MainActor
    @Test("VideoPlayer shows the platform's controls unless told otherwise")
    func showsControlsByDefault() throws {
        let node = ViewGraphHelpers.committedNode(
            for: VideoPlayer(player: FakePlatformPlayer()),
            proposedSize: ProposedViewSize(800, 450)
        )
        let widget = try #require(node.widget as? DummyBackend.VideoPlayer)
        #expect(widget.showsPlaybackControls)
    }

    @MainActor
    @Test("VideoPlayer follows a new player on update")
    func followsNewPlayer() throws {
        let first = FakePlatformPlayer(), second = FakePlatformPlayer()
        let node = ViewGraphHelpers.committedNode(
            for: VideoPlayer(player: first),
            proposedSize: ProposedViewSize(800, 450)
        )
        _ = node.computeLayout(
            with: VideoPlayer(player: second),
            proposedSize: ProposedViewSize(800, 450),
            environment: ViewGraphHelpers.environment
        )
        _ = node.commit()
        let widget = try #require(node.widget as? DummyBackend.VideoPlayer)
        #expect(widget.player === second)
        #expect(widget.updateCount == 2)
    }
}
