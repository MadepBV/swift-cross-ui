/// A container that groups views together without imposing a layout of its own.
///
/// A container decides which of its participants it publishes its
/// ``ContainerChildLayout`` to, and grouping containers are always among them —
/// that's what the marker is for. A container whose participants are otherwise
/// all ordinary views scopes publication to grouping containers alone
/// (``LazyVGrid`` does, proposing to everything else with the layout cleared)
/// so that an enclosing layout can't reach views that merely happen to have a
/// ``Group`` somewhere in their implementation. A container with a participant
/// view type of its own publishes more widely (``Grid`` does, because a
/// ``GridRow`` isn't a grouping container), and leans on the cursor to
/// recognise a participant whose subtree registered participants of its own.
///
/// Conformance alone isn't enough to take part; a grouping container must also
/// pass `participatesInParentLayout: true` when it lays its children out.
protocol GroupingContainer {}

/// A layout that an enclosing container performs on behalf of the grouping
/// containers nested inside it.
///
/// Containers such as ``ForEach`` and ``Group`` exist to group views together
/// without imposing a layout of their own, but they still own a container
/// widget and would otherwise lay their children out as a stack. That makes
/// them opaque to enclosing containers that need to treat each individual view
/// as a participant of their own layout — a grid, for example, wants every
/// item of a ``ForEach`` to occupy its own cell rather than the whole
/// ``ForEach`` occupying one cell.
///
/// When an enclosing container publishes a container child layout through
/// ``EnvironmentValues/containerChildLayout``, grouping containers hand each of
/// their children to it via ``addParticipant(_:environment:)`` instead of
/// laying them out themselves. Grouping containers opt into this by passing
/// `participatesInParentLayout: true` when they lay their children out through
/// ``LayoutSystem``; every other container keeps its normal stack behaviour,
/// and clears the published layout for its own children so that a ``ForEach``
/// nested inside a real container never joins the enclosing layout by
/// accident.
///
/// ## Coordinate spaces
///
/// Participants keep living inside the widget of whichever grouping container
/// produced them, so an enclosing layout can't position them directly. Instead
/// every grouping container that takes part adopts ``participantAreaSize`` and
/// is positioned at the origin of the enclosing layout's participant area.
/// Positions returned by ``commitNextParticipant(_:)`` are relative to that
/// same origin, which makes them equally valid inside any of those containers
/// and inside the enclosing container itself.
///
/// ## Ordering
///
/// Participants are added in layout order and committed in that same order, so
/// implementations can hold a simple cursor rather than identifying
/// participants. A participant that turns out to be another grouping container
/// registers its own participants during the call, which implementations
/// detect by checking whether the cursor moved.
@MainActor
protocol ContainerChildLayout: AnyObject {
    /// The size adopted by every grouping container whose children took part.
    ///
    /// This is the size of the area that participants are laid out in, not the
    /// size of the enclosing container (which may be larger, and may position
    /// the participant area within itself).
    var participantAreaSize: ViewSize { get }

    /// Hands one participant to the enclosing layout, computing its layout.
    ///
    /// Implementations decide what to propose, and may probe the participant
    /// more than once (a grid negotiating column widths needs a participant's
    /// minimum, ideal and maximum widths before it can propose a real size).
    /// Implementations must publish themselves on the environment that they
    /// propose with, so that a nested grouping container can take part too.
    ///
    /// - Parameters:
    ///   - participant: The participant to lay out.
    ///   - environment: The environment that the participant's container would
    ///     have proposed with.
    /// - Returns: The participant's computed layout.
    @discardableResult
    func addParticipant(
        _ participant: LayoutSystem.LayoutableChild,
        environment: EnvironmentValues
    ) -> ViewLayoutResult

    /// Commits the next participant, in the order that participants were added.
    ///
    /// - Parameter participant: The participant to commit.
    /// - Returns: The participant's committed layout, and its position relative
    ///   to the origin of the enclosing layout's participant area.
    func commitNextParticipant(
        _ participant: LayoutSystem.LayoutableChild
    ) -> (position: SIMD2<Int>, result: ViewLayoutResult)
}

extension EnvironmentValues {
    /// The layout that the innermost enclosing container wants grouping
    /// containers to hand their children to, if any.
    ///
    /// Only ``ForEach`` and ``Group`` read this. Containers that lay their own
    /// children out clear it before proposing to them, so it never reaches
    /// further than the grouping containers directly beneath the container that
    /// published it.
    var containerChildLayout: (any ContainerChildLayout)? {
        get { self[ContainerChildLayoutKey.self] }
        set { self[ContainerChildLayoutKey.self] = newValue }
    }
}

private struct ContainerChildLayoutKey: EnvironmentKey {
    static var defaultValue: (any ContainerChildLayout)? { nil }
}
