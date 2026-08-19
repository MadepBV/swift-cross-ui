/// A description of how a view appears and disappears as it is inserted into
/// or removed from the view hierarchy.
///
/// ## This type is inert
///
/// SwiftCrossUI has no animation system: there is no timeline, no interpolator
/// and no backend surface for driving a widget's opacity, offset or scale over
/// time. A transition therefore describes an intent that nothing ever plays
/// back. Views still appear and disappear exactly when their state says they
/// should — they simply do so immediately.
///
/// The vocabulary is provided in full, spelled the way SwiftUI spells it, so
/// that application source using transitions compiles unchanged and gains the
/// real behaviour for free once an animation system lands. Every value
/// constructed here is inspectable through ``AnyTransition/kind``, so the
/// eventual implementation has the author's intent to work from rather than
/// having to reintroduce the API.
///
/// ```swift
/// banner
///     .transition(.move(edge: .top).combined(with: .opacity))
/// ```
public struct AnyTransition: Sendable {
    /// The transition an ``AnyTransition`` describes.
    ///
    /// Recorded rather than executed. See the type-level discussion on
    /// ``AnyTransition`` for why.
    indirect enum Kind: Equatable, Sendable {
        /// No visual change on insertion or removal.
        case identity
        /// A fade between transparent and opaque.
        case opacity
        /// An insertion from the leading edge and a removal to the trailing
        /// edge.
        case slide
        /// A scale about `anchor`, growing from (or shrinking to) `scale`.
        case scale(scale: Double, anchor: UnitPoint)
        /// A slide in from, and back out to, a particular edge.
        case move(edge: Edge)
        /// A slide in from, and back out to, a relative offset.
        case offset(x: Double, y: Double)
        /// Two transitions applied at once.
        case combined(Kind, Kind)
    }

    /// The transition this value describes.
    let kind: Kind

    /// Creates a transition from its description.
    ///
    /// - Parameter kind: The transition to describe.
    init(kind: Kind) {
        self.kind = kind
    }

    /// A transition that has no visible effect.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public static let identity = AnyTransition(kind: .identity)

    /// A transition from transparent to opaque on insertion, and from opaque
    /// to transparent on removal.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public static let opacity = AnyTransition(kind: .opacity)

    /// A transition that inserts from the leading edge and removes to the
    /// trailing edge.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public static let slide = AnyTransition(kind: .slide)

    /// A transition that scales the view down to nothing on removal, and up
    /// from nothing on insertion.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public static let scale = AnyTransition(
        kind: .scale(scale: 0, anchor: .center)
    )

    /// A transition that scales the view between its natural size and the
    /// given scale factor.
    ///
    /// - Parameters:
    ///   - scale: The scale factor the view starts from when inserted, and
    ///     ends at when removed.
    ///   - anchor: The point the scale is applied about. Defaults to
    ///     ``UnitPoint/center``.
    /// - Returns: An inert description of the scale transition.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public static func scale(
        scale: Double = 0,
        anchor: UnitPoint = .center
    ) -> AnyTransition {
        AnyTransition(kind: .scale(scale: scale, anchor: anchor))
    }

    /// A transition that moves the view in from, and back out to, an edge of
    /// its container.
    ///
    /// - Parameter edge: The edge the view enters from and leaves towards.
    /// - Returns: An inert description of the move transition.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public static func move(edge: Edge) -> AnyTransition {
        AnyTransition(kind: .move(edge: edge))
    }

    /// A transition that moves the view in from, and back out to, an offset
    /// relative to its final position.
    ///
    /// - Parameters:
    ///   - x: The horizontal offset the view starts from when inserted.
    ///   - y: The vertical offset the view starts from when inserted.
    /// - Returns: An inert description of the offset transition.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public static func offset(
        x: Double = 0,
        y: Double = 0
    ) -> AnyTransition {
        AnyTransition(kind: .offset(x: x, y: y))
    }

    /// Combines this transition with another, so that both would apply at
    /// once.
    ///
    /// - Parameter other: The transition to apply alongside this one.
    /// - Returns: An inert description of both transitions together.
    ///
    /// - Note: Inert, as every transition is. See ``AnyTransition``.
    public func combined(with other: AnyTransition) -> AnyTransition {
        AnyTransition(kind: .combined(kind, other.kind))
    }
}
