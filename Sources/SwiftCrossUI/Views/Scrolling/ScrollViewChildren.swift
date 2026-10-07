/// The children of a ``ScrollView``, and what it remembers between updates.
class ScrollViewChildren<Content: View>: ViewGraphNodeChildren {
    var children: TupleView1<VStack<Content>>.Children
    var innerContainer: AnyWidget

    var hasVerticalScrollBar = false
    var hasHorizontalScrollBar = false

    /// The views this scroll view can scroll to, and the means to scroll it.
    let scrollTargets = ScrollTargetRegistry()

    /// The origin of ``CoordinateSpace/scrollView`` for the content: this
    /// scroll view's visible region.
    let coordinateSpaceAnchor = CoordinateSpaceAnchor()

    /// The views in lazy containers inside this scroll view that wait to be
    /// scrolled near before they appear.
    lazy var lazyAppearance = LazyAppearanceRegistry(anchor: coordinateSpaceAnchor)

    /// The margins around the content, as of the last layout.
    var contentMargins = ScrollContentMargins()

    /// The identity of the last scroll request carried out.
    var lastScrollRequest: AnyHashable?

    /// The size of the visible region when the last scroll request was
    /// carried out.
    var lastScrollRequestViewport: SIMD2<Double>?

    /// The values last reported to each scroll geometry observer.
    var reportedGeometryValues: [Any] = []

    /// The identities last reported to each scroll target visibility
    /// observer.
    var reportedVisibleTargets: [[AnyHashable]] = []

    var child: AnyViewGraphNode<VStack<Content>> {
        children.child0
    }

    var widgets: [AnyWidget] {
        // The implementation of this property doesn't really matter. It doesn't
        // really have a reason to get used anywhere.
        children.widgets
    }

    var erasedNodes: [ErasedViewGraphNode] {
        children.erasedNodes
    }

    init<Backend: BaseAppBackend>(
        wrapping children: TupleView1<VStack<Content>>.Children,
        backend: Backend
    ) {
        self.children = children
        let innerContainer = backend.createContainer()
        backend.insert(children.child0.widget.into(), into: innerContainer, at: 0)
        self.innerContainer = AnyWidget(innerContainer)
    }
}
