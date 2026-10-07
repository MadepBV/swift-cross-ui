extension DummyBackend {
    public class VideoPlayer: Widget {
        /// The player the view last presented.
        public weak var player: AnyObject?
        public var showsPlaybackControls = true
        /// How many times the view handed its player over.
        public var updateCount = 0
    }
}
