extension DummyBackend {
    public class ScrollContainer: Widget {
        public var child: Widget
        public var hasVerticalScrollBar = false
        public var hasHorizontalScrollBar = false
        public var bouncesVertically = false
        public var bouncesHorizontally = false
        /// How far the container is scrolled, from its content's top-leading
        /// corner.
        public var scrollOffset = SIMD2<Double>.zero
        /// Whether the last programmatic scroll asked to be animated.
        public var lastScrollWasAnimated = false
        /// What SwiftCrossUI runs when the user scrolls; tests call it after
        /// moving ``scrollOffset`` to stand in for the user.
        public var scrollChangeHandler: (@MainActor () -> Void)?

        public init(child: Widget) {
            self.child = child
        }

        public override func getChildren() -> [Widget] {
            [child]
        }
    }
}
