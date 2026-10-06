import Foundation

/// A container that arranges its content with a ``Layout``.
///
/// Created by ``Layout/callAsFunction(_:)``. The built-in stack layouts
/// (``HStackLayout``, ``VStackLayout`` and ``ZStackLayout``, directly or
/// through ``AnyLayout``) are laid out exactly as the matching stack view
/// would lay them out, so switching an ``AnyLayout`` between them behaves
/// like switching between stacks, except that the content keeps its identity
/// and state.
struct LayoutView<L: Layout, Content: View>: View {
    var layout: L
    var body: Content

    /// Persists the participants between layout and commit.
    struct Storage {
        var participants = CustomLayoutParticipants()
    }

    @State private var storage = Storage()

    init(layout: L, content: Content) {
        self.layout = layout
        body = content
    }

    /// The stack view that lays the content out, if the layout is one of
    /// the built-in stack layouts.
    private var stackLayout: (any BuiltinStackLayout)? {
        if let anyLayout = layout as? AnyLayout {
            return anyLayout.base as? any BuiltinStackLayout
        }
        return layout as? any BuiltinStackLayout
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: any ViewGraphNodeChildren
    ) -> [LayoutSystem.LayoutableChild] {
        var layoutableChildren = defaultLayoutableChildren(backend: backend, children: children)
        LayoutSystem.markGroupingContainers(&layoutableChildren, using: children)
        return layoutableChildren
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        for (index, child) in children.widgets(for: backend).enumerated() {
            backend.insert(child, into: container, at: index)
        }
        return container
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        if let stackLayout {
            return stackLayout.computeStackLayout(
                content: body,
                widget: widget,
                children: children,
                proposedSize: proposedSize,
                environment: environment,
                backend: backend
            )
        }

        let participants = storage.participants
        participants.collect(
            from: layoutableChildren(backend: backend, children: children),
            environment: environment
        )

        let recorder = LayoutRecorder()
        let subviews = makeSubviews(participants: participants, recorder: recorder)
        var cache = layout.makeCache(subviews: subviews)
        let size = layout.sizeThatFits(
            proposal: proposedSize,
            subviews: subviews,
            cache: &cache
        )
        participants.cache = cache
        participants.lastProposal = proposedSize
        participants.participantAreaSize = ViewSize(Double(size.width), Double(size.height))

        return ViewLayoutResult(
            size: participants.participantAreaSize,
            childResults: recorder.results.sorted { $0.key < $1.key }.map(\.value)
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout result: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        if let stackLayout {
            stackLayout.commitStackLayout(
                content: body,
                widget: widget,
                children: children,
                layout: result,
                environment: environment,
                backend: backend
            )
            return
        }

        backend.setSize(of: widget, to: result.size.vector)

        let participants = storage.participants
        let recorder = LayoutRecorder()
        let subviews = makeSubviews(participants: participants, recorder: recorder)
        var cache = participants.cache as? L.Cache ?? layout.makeCache(subviews: subviews)
        let bounds = CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: CGSize(width: result.size.width, height: result.size.height)
        )
        layout.placeSubviews(
            in: bounds,
            proposal: participants.lastProposal,
            subviews: subviews,
            cache: &cache
        )
        participants.cache = cache

        participants.beginCommit(placements: recorder.placements, bounds: bounds)
        let topLevelChildren = layoutableChildren(backend: backend, children: children)
        for (index, child) in topLevelChildren.enumerated() {
            if child.isGroupingContainer {
                // Commits its children through `participants`, and covers the
                // whole layout.
                _ = child.commit()
                backend.setPosition(ofChildAt: index, in: widget, to: .zero)
            } else {
                let placement = participants.commitNextParticipant(child)
                backend.setPosition(ofChildAt: index, in: widget, to: placement.position)
            }
        }
    }

    /// Creates the proxies the layout sees for its participants.
    private func makeSubviews(
        participants: CustomLayoutParticipants,
        recorder: LayoutRecorder
    ) -> LayoutSubviews {
        LayoutSubviews(
            participants.participants.enumerated().map { index, participant in
                LayoutSubview(
                    index: index,
                    child: participant.child,
                    environment: participant.environment,
                    recorder: recorder
                )
            }
        )
    }
}
