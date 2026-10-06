import Foundation

/// A collection of proxy values that represent the subviews of a layout
/// view.
public struct LayoutSubviews: RandomAccessCollection, Equatable {
    public typealias Element = LayoutSubview
    public typealias Index = Int
    public typealias SubSequence = LayoutSubviews

    private var storage: [LayoutSubview]
    private var range: Range<Int>

    init(_ subviews: [LayoutSubview]) {
        storage = subviews
        range = subviews.indices
    }

    private init(storage: [LayoutSubview], range: Range<Int>) {
        self.storage = storage
        self.range = range
    }

    public var startIndex: Int { range.lowerBound }
    public var endIndex: Int { range.upperBound }

    public subscript(index: Int) -> LayoutSubview {
        storage[index]
    }

    public subscript(bounds: Range<Int>) -> LayoutSubviews {
        LayoutSubviews(storage: storage, range: bounds)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage[lhs.range] == rhs.storage[rhs.range]
    }
}

/// A proxy that represents one subview of a layout.
@MainActor
public struct LayoutSubview: Equatable {
    /// The subview's index among the layout's subviews.
    let index: Int
    /// The subview's layout.
    let child: LayoutSystem.LayoutableChild
    /// The environment the subview is laid out in.
    let environment: EnvironmentValues
    /// Where the subview's placements and layout results are recorded.
    let recorder: LayoutRecorder

    init(
        index: Int,
        child: LayoutSystem.LayoutableChild,
        environment: EnvironmentValues,
        recorder: LayoutRecorder
    ) {
        self.index = index
        self.child = child
        self.environment = environment
        self.recorder = recorder
    }

    /// The subview's layout priority.
    public var priority: Double {
        recorder.results[index]?.preferences.layoutPriority ?? 0
    }

    /// Asks the subview for its size.
    ///
    /// - Parameter proposal: A proposed size for the subview.
    /// - Returns: The size that the subview chooses for itself.
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let size = layout(proposal).size
        return CGSize(width: size.width, height: size.height)
    }

    /// Asks the subview for its dimensions and alignment guides.
    ///
    /// - Parameter proposal: A proposed size for the subview.
    /// - Returns: The subview's dimensions at that proposal.
    public func dimensions(in proposal: ProposedViewSize) -> ViewDimensions {
        ViewDimensions(layout(proposal))
    }

    /// Assigns a position and proposed size to the subview.
    ///
    /// - Parameters:
    ///   - position: Where to place the anchor of the subview, in the
    ///     layout's coordinate space.
    ///   - anchor: The unit point of the subview to place at `position`.
    ///   - proposal: The size to propose to the subview.
    public func place(
        at position: CGPoint,
        anchor: UnitPoint = .topLeading,
        proposal: ProposedViewSize
    ) {
        recorder.placements[index] = LayoutRecorder.Placement(
            position: position,
            anchor: anchor,
            proposal: proposal
        )
    }

    /// Lays the subview out provisionally: the size it reports here only
    /// becomes final once it is placed.
    private func layout(_ proposal: ProposedViewSize) -> ViewLayoutResult {
        let result = child.computeLayout(
            proposedSize: proposal,
            environment: environment.with(\.allowLayoutCaching, true)
        )
        recorder.results[index] = result
        return result
    }

    public nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.index == rhs.index && lhs.recorder === rhs.recorder
    }
}

/// The placements and layout results of a custom layout's subviews during
/// one layout computation or commit.
@MainActor
final class LayoutRecorder {
    struct Placement {
        var position: CGPoint
        var anchor: UnitPoint
        var proposal: ProposedViewSize
    }

    /// The most recent layout result of each subview.
    var results: [Int: ViewLayoutResult] = [:]
    /// Where each subview was placed.
    var placements: [Int: Placement] = [:]
}
