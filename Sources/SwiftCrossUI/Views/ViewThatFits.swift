/// A view that adapts to the available space by displaying the first of its
/// child views that fits.
///
/// The child views (referred to as candidates) get evaluated in the order that
/// they're declared in, and the first candidate whose ideal size fits within
/// the space proposed by the parent view gets displayed. If none of the
/// candidates fit, the last candidate gets displayed. Declare candidates in
/// order of preference.
///
/// Only the axes passed to ``ViewThatFits/init(in:content:)`` take part in the
/// fit test; the remaining axes are treated as unconstrained. The most common
/// usecase is degrading a dense row into a more compact layout once the row's
/// container gets too narrow;
///
/// ```swift
/// ViewThatFits(in: .horizontal) {
///     HStack {
///         Text("Diameter")
///         Spacer()
///         Text("12 mm")
///     }
///     VStack(alignment: .leading) {
///         Text("Diameter")
///         Text("12 mm")
///     }
/// }
/// ```
///
/// A candidate's ideal size is the size that it chooses when proposed an
/// unspecified size along the tested axes, which is why a candidate that would
/// happily squish itself into the proposed space (such as an ``HStack``
/// containing wrappable ``Text``) still gets rejected when its natural size is
/// too big.
///
/// - Note: All candidates get instantiated (and keep their state) for the whole
///   time that the ``ViewThatFits`` is on screen, but only the selected
///   candidate's widget is ever present in the widget hierarchy.
public struct ViewThatFits<Content: View>: TypeSafeView, View {
    /// The amount by which a candidate is allowed to exceed the proposed size
    /// while still counting as fitting.
    ///
    /// Sizes get rounded up to whole pixels before reaching the backend, so
    /// rejecting a candidate that only overflows by a floating point rounding
    /// error would cause a visible layout change for no visible reason.
    private static var fitTolerance: Double { 1e-6 }

    /// The candidate views.
    public var body: Content

    /// The axes along which candidates get tested.
    private var axes: Axis.Set

    /// Creates a view that displays the first of its child views that fits.
    ///
    /// - Parameters:
    ///   - axes: The axes along which candidates get tested. Axes that aren't
    ///     included are treated as unconstrained, meaning that they never cause
    ///     a candidate to get rejected. Defaults to both axes.
    ///   - content: The candidate views, in order of preference.
    public init(
        in axes: Axis.Set = [.horizontal, .vertical],
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        body = content()
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> ViewThatFitsChildren {
        ViewThatFitsChildren(
            // Goes through the default rather than reaching to `body`
            // directly: a `@ViewBuilder` closure containing an explicit
            // `return` opts out of the result builder, so `body` is not
            // necessarily a `TupleView`. Reaching past it would make each of
            // an unwrapped container's children a separate candidate. See
            // `View.bodyNeedsWrapping`.
            content: defaultChildren(
                backend: backend,
                snapshots: snapshots,
                environment: environment
            )
        )
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: ViewThatFitsChildren
    ) -> [LayoutSystem.LayoutableChild] {
        // Candidates must never get flattened into a parent stack's layout;
        // ``ViewThatFits`` displays exactly one of them.
        []
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: ViewThatFitsChildren,
        backend: Backend
    ) -> Backend.Widget {
        // The selected candidate's widget gets inserted during the first
        // commit, once we know which candidate fits.
        backend.createContainer()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: ViewThatFitsChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        if !(children.content is TupleViewChildren || children.content is EmptyViewChildren) {
            logger.warning(
                "ViewThatFits will not function correctly with non-TupleView content",
                metadata: [
                    "childrenType": "\(type(of: children.content))",
                    "contentType": "\(Content.self)",
                ]
            )
        }

        let candidates = defaultLayoutableChildren(
            backend: backend,
            children: children.content
        )

        guard let fallbackIndex = candidates.indices.last else {
            children.select(nil)
            return ViewLayoutResult(
                size: .zero,
                childResults: [],
                participateInStackLayoutsWhenEmpty: false
            )
        }

        // The fallback candidate gets displayed whether it fits or not, so
        // there's no point measuring it. Not measuring it also keeps its node
        // untouched (and therefore free of pending layouts) while an earlier
        // candidate is winning.
        let probeProposal = probeProposal(for: proposedSize)
        var selectedIndex = fallbackIndex
        for index in candidates.startIndex..<fallbackIndex {
            let idealSize = candidates[index].computeLayout(
                proposedSize: probeProposal,
                environment: environment
            ).size

            guard fits(idealSize, within: proposedSize) else {
                continue
            }

            selectedIndex = index
            break
        }

        children.select(selectedIndex)

        // Lay the winner out for real. This has to happen after probing so
        // that the winner's node ends up holding the layout that we want
        // committed (nodes only ever remember their most recent layout).
        return candidates[selectedIndex].computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: ViewThatFitsChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let candidates = defaultLayoutableChildren(
            backend: backend,
            children: children.content
        )

        if children.hasChangedSelection {
            backend.removeAllChildren(of: widget)
            if let selectedWidget = children.selectedWidget {
                backend.insert(selectedWidget.into(), into: widget, at: 0)
                backend.setPosition(ofChildAt: 0, in: widget, to: .zero)
            }
            children.hasChangedSelection = false
        }

        // Every candidate that got measured must get committed, not just the
        // one on screen. A node that has computed a layout without committing
        // it keeps serving that layout to subsequent measurements, so skipping
        // the rejected candidates would freeze their measured sizes (and
        // therefore the selection) until they happened to get displayed.
        for index in 0..<min(children.pendingCommitCount, candidates.count) {
            _ = candidates[index].commit()
        }
        children.pendingCommitCount = 0

        backend.setSize(of: widget, to: layout.size.vector)
    }

    /// Computes the proposal used to measure a candidate's ideal size.
    ///
    /// The tested axes get proposed an unspecified size so that candidates
    /// report their natural size instead of squishing themselves into the
    /// proposed space. The remaining axes get proposed as-is.
    ///
    /// - Parameter proposedSize: The size proposed by the parent view.
    /// - Returns: The size to propose to candidates while measuring them.
    private func probeProposal(for proposedSize: ProposedViewSize) -> ProposedViewSize {
        var proposal = proposedSize
        for axis in Axis.allCases where axes.contains(axis) {
            proposal[component: axis] = nil
        }
        return proposal
    }

    /// Checks whether a candidate's ideal size fits within the proposed size.
    ///
    /// Axes that aren't being tested, and tested axes that the parent left
    /// unspecified, are treated as unconstrained.
    ///
    /// - Parameters:
    ///   - idealSize: The candidate's ideal size.
    ///   - proposedSize: The size proposed by the parent view.
    /// - Returns: Whether the candidate fits or not.
    private func fits(_ idealSize: ViewSize, within proposedSize: ProposedViewSize) -> Bool {
        for axis in Axis.allCases where axes.contains(axis) {
            guard let availableLength = proposedSize[component: axis] else {
                continue
            }

            if idealSize[component: axis] > availableLength + Self.fitTolerance {
                return false
            }
        }
        return true
    }
}

/// Stores the view graph nodes of a ``ViewThatFits``'s candidates along with
/// the index of the candidate that's currently selected.
///
/// All candidates get their own node (and therefore their own widget and
/// state) so that measuring a candidate never requires re-creating it, but
/// only the selected candidate's widget gets added to the widget hierarchy.
class ViewThatFitsChildren: ViewGraphNodeChildren {
    /// The nodes of the candidate views. Ordered as declared.
    let content: any ViewGraphNodeChildren
    /// The index of the currently selected candidate. `nil` before the first
    /// layout has been computed, and when there are no candidates at all.
    var selectedIndex: Int?
    /// Whether the selected candidate has changed since the last commit.
    /// Initially `true` so that the first commit inserts the selected
    /// candidate's widget into the container.
    var hasChangedSelection = true
    /// The number of leading candidates that have had a layout computed since
    /// the last commit. Kept as a high water mark because the selection can
    /// change between two layout computations of a single update.
    var pendingCommitCount = 0

    /// The widget of the currently selected candidate (if any).
    var selectedWidget: AnyWidget? {
        guard let selectedIndex else {
            return nil
        }

        let widgets = content.widgets
        guard widgets.indices.contains(selectedIndex) else {
            return nil
        }
        return widgets[selectedIndex]
    }

    var widgets: [AnyWidget] {
        [selectedWidget].compactMap { widget in
            widget
        }
    }

    var erasedNodes: [ErasedViewGraphNode] {
        content.erasedNodes
    }

    /// Wraps the nodes of a ``ViewThatFits``'s candidates.
    ///
    /// - Parameter content: The nodes of the candidate views.
    init(content: any ViewGraphNodeChildren) {
        self.content = content
    }

    /// Selects the candidate to display, recording whether the selection
    /// changed and how many candidates now require committing.
    ///
    /// - Parameter index: The index of the selected candidate, or `nil` if
    ///   there are no candidates.
    func select(_ index: Int?) {
        if index != selectedIndex {
            selectedIndex = index
            hasChangedSelection = true
        }

        guard let index else {
            return
        }
        pendingCommitCount = max(pendingCommitCount, index + 1)
    }
}
