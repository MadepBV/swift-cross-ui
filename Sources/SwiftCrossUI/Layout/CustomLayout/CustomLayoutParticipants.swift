import Foundation

/// Collects, measures and places the participants of a custom ``Layout``.
///
/// A layout's subviews are its content's views with any ``ForEach`` or
/// ``Group`` flattened into their individual views, as in SwiftUI. Grouping
/// containers are made to hand their children over through the
/// ``ContainerChildLayout`` mechanism (see that protocol for the coordinate
/// space conventions); every other view is a participant itself.
@MainActor
final class CustomLayoutParticipants: ContainerChildLayout {
    /// One subview of the layout.
    struct Participant {
        var child: LayoutSystem.LayoutableChild
        /// The environment to lay the participant out in.
        var environment: EnvironmentValues
    }

    /// The layout's subviews, in order.
    private(set) var participants: [Participant] = []
    /// The proposal that grouping containers' children are measured with
    /// while being collected.
    private var collectionProposal: ProposedViewSize = .unspecified
    /// The layout's size; grouping containers adopt it as their own.
    var participantAreaSize: ViewSize = .zero
    /// The proposal the layout itself was last given.
    var lastProposal: ProposedViewSize = .unspecified
    /// The cache made for the last size computation, reused for placement.
    var cache: Any?

    /// Where each participant was placed, by participant index, during the
    /// current commit.
    private var placements: [Int: LayoutRecorder.Placement] = [:]
    /// The bounds the participants are placed in during the current commit.
    private var bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0, height: 0))
    /// The next participant to commit.
    private var commitCursor = 0

    /// Creates an empty set of participants. Nonisolated so that a view can
    /// hold one in its state's initial value.
    nonisolated init() {}

    /// Gathers the layout's subviews from its content's children.
    ///
    /// - Parameters:
    ///   - children: The content's layoutable children.
    ///   - environment: The environment the layout is laid out in.
    func collect(
        from children: [LayoutSystem.LayoutableChild],
        environment: EnvironmentValues
    ) {
        let hasGroupingContainers = children.contains(where: \.isGroupingContainer)

        // A grouping container only hands its children over while computing
        // its layout, and the view graph skips that computation whenever a
        // node is proposed the same size twice in a row. Collecting with two
        // differently shaped proposals guarantees that the second one always
        // runs, whatever the previous pass ended on (`LazyVGrid` does the
        // same).
        let proposals: [ProposedViewSize] =
            hasGroupingContainers ? [.zero, .unspecified] : [.unspecified]
        for proposal in proposals {
            participants = []
            collectionProposal = proposal
            for child in children {
                addParticipant(child, environment: environment)
            }
        }
    }

    @discardableResult
    func addParticipant(
        _ participant: LayoutSystem.LayoutableChild,
        environment: EnvironmentValues
    ) -> ViewLayoutResult {
        guard participant.isGroupingContainer else {
            participants.append(
                Participant(
                    child: participant,
                    environment: environment.with(\.containerChildLayout, nil)
                )
            )
            // Measured on demand by the layout, through its subviews.
            return .leafView(size: .zero)
        }

        // The participant registers its own children with this layout.
        return participant.computeLayout(
            proposedSize: collectionProposal,
            environment:
                environment
                .with(\.containerChildLayout, self)
                .with(\.allowLayoutCaching, false)
        )
    }

    /// Prepares to hand out the positions the layout chose.
    ///
    /// - Parameters:
    ///   - placements: Where each participant was placed, by index.
    ///   - bounds: The bounds the participants were placed in.
    func beginCommit(placements: [Int: LayoutRecorder.Placement], bounds: CGRect) {
        self.placements = placements
        self.bounds = bounds
        commitCursor = 0
    }

    func commitNextParticipant(
        _ participant: LayoutSystem.LayoutableChild
    ) -> (position: SIMD2<Int>, result: ViewLayoutResult) {
        if participant.isGroupingContainer {
            // A nested grouping container commits its own participants
            // through this layout, and covers the whole participant area.
            return (.zero, participant.commit())
        }

        let index = commitCursor
        commitCursor += 1
        guard index < participants.count else {
            return (.zero, participant.commit())
        }

        // An unplaced subview is centred in the layout's bounds.
        let placement =
            placements[index]
            ?? LayoutRecorder.Placement(
                position: CGPoint(
                    x: bounds.origin.x + bounds.size.width / 2,
                    y: bounds.origin.y + bounds.size.height / 2
                ),
                anchor: .center,
                proposal: .unspecified
            )

        // The placement's proposal is the participant's final one.
        _ = participant.computeLayout(
            proposedSize: placement.proposal,
            environment: participants[index].environment
        )
        let result = participant.commit()
        let x = Double(placement.position.x) - placement.anchor.x * result.size.width
        let y = Double(placement.position.y) - placement.anchor.y * result.size.height
        return (Position(x, y).vector, result)
    }
}
