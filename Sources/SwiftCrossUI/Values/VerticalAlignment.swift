import Foundation

/// Alignment of items layed out along the vertical axis.
///
/// As in SwiftUI this is a struct rather than an enum, so that apps can define
/// their own guides with ``init(_:)``. Code that switches over a vertical
/// alignment therefore needs a `default` case.
public struct VerticalAlignment: Hashable, Sendable {
    /// Top alignment.
    public static let top = Self(TopAlignmentID.self)
    /// Center alignment.
    public static let center = Self(VerticalCenterAlignmentID.self)
    /// Bottom alignment.
    public static let bottom = Self(BottomAlignmentID.self)
    /// A guide that marks the top-most text baseline in a view.
    ///
    /// - Note: Views don't report text baselines in SwiftCrossUI, so this
    ///   resolves to a view's bottom edge unless a view sets it with
    ///   ``View/alignmentGuide(_:computeValue:)-(VerticalAlignment,_)``.
    public static let firstTextBaseline = Self(FirstTextBaselineAlignmentID.self)
    /// A guide that marks the bottom-most text baseline in a view.
    ///
    /// - Note: See ``firstTextBaseline``.
    public static let lastTextBaseline = Self(LastTextBaselineAlignmentID.self)

    /// The guide's identity.
    let key: AlignmentKey

    /// Creates a custom vertical alignment of the specified type.
    ///
    /// - Parameter id: The type that defines the guide's default value.
    public init(_ id: any AlignmentID.Type) {
        key = AlignmentKey(id, axis: .vertical)
    }

    /// Whether the alignment is one of the three edge-and-centre guides that
    /// the stack layout places by size alone.
    var isEdgeOrCenter: Bool {
        self == .top || self == .center || self == .bottom
    }

    /// Converts this value to a ``StackAlignment``.
    ///
    /// Other guides map to ``StackAlignment/center``; stacks place children
    /// on them using the guides' values instead (see `AlignmentKey`).
    var asStackAlignment: StackAlignment {
        if self == .top {
            .leading
        } else if self == .bottom {
            .trailing
        } else {
            .center
        }
    }

    /// Gets the position of a child of a given height in a frame of a given
    /// height using the alignment.
    /// - Parameter childHeight: The height of the child.
    /// - Parameter frameHeight: The height of the frame.
    /// - Returns: The position of the child.
    func position(ofChild childHeight: Double, in frameHeight: Double) -> Double {
        key.defaultValue(in: ViewDimensions(size: ViewSize(0, frameHeight)))
            - key.defaultValue(in: ViewDimensions(size: ViewSize(0, childHeight)))
    }
}
