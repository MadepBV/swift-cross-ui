extension DummyBackend {
    public class Container: Widget {
        public var children: [(widget: Widget, position: SIMD2<Int>)] = []

        /// The children on screen: a child hidden through `WidgetVisibility`
        /// (a dormant page) is left out, as a collapsed element is out of a
        /// real backend's visual tree. `children` still lists every one.
        public override func getChildren() -> [Widget] {
            children.compactMap { $0.widget.isHidden ? nil : $0.widget }
        }
    }
}
