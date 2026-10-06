import Foundation

/// A type that you use to create a custom alignment guide.
///
/// ```swift
/// extension VerticalAlignment {
///     private enum ControlCenter: AlignmentID {
///         static func defaultValue(in context: ViewDimensions) -> CGFloat {
///             context[VerticalAlignment.center]
///         }
///     }
///
///     static let controlCenter = VerticalAlignment(ControlCenter.self)
/// }
/// ```
///
/// Stacks aligned on a custom guide line their children up on the value each
/// child reports for it: the value set with
/// ``View/alignmentGuide(_:computeValue:)-(VerticalAlignment,_)`` where there
/// is one, and ``defaultValue(in:)`` otherwise.
public protocol AlignmentID {
    /// The value of the corresponding guide in the given context, when not
    /// otherwise set in that context.
    ///
    /// - Parameter context: The dimensions of the view being aligned.
    /// - Returns: The guide's offset from the view's top (for a vertical
    ///   guide) or leading edge (for a horizontal guide).
    static func defaultValue(in context: ViewDimensions) -> CGFloat
}

/// An alignment guide's identity, shared by ``HorizontalAlignment`` and
/// ``VerticalAlignment`` so that the layout system can treat both alike.
///
/// `@unchecked Sendable` because its only non-`Sendable` field is a
/// metatype, which is immutable and only ever used to call a static method
/// that takes and returns plain values.
struct AlignmentKey: Hashable, @unchecked Sendable {
    /// The type that defines the guide.
    let id: any AlignmentID.Type
    /// The axis along which the guide is measured.
    let axis: Axis

    init(_ id: any AlignmentID.Type, axis: Axis) {
        self.id = id
        self.axis = axis
    }

    /// The guide's value for a view that hasn't set it explicitly.
    func defaultValue(in dimensions: ViewDimensions) -> Double {
        Double(id.defaultValue(in: dimensions))
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        ObjectIdentifier(lhs.id) == ObjectIdentifier(rhs.id) && lhs.axis == rhs.axis
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(id))
        hasher.combine(axis)
    }
}

/// The built-in guides. Each one is defined by its default value alone.
enum TopAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { 0 }
}

enum VerticalCenterAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context.height / 2 }
}

enum BottomAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context.height }
}

/// SwiftCrossUI's views don't report text baselines, so a view's first and
/// last baselines default to its bottom edge, which is SwiftUI's default for
/// any view that has no text. Text of equal size therefore still lines up
/// exactly; text of mixed sizes lines up on its bottoms rather than on its
/// baselines (off by the difference in the fonts' descents).
enum FirstTextBaselineAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context.height }
}

/// See ``FirstTextBaselineAlignmentID``.
enum LastTextBaselineAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context.height }
}

enum LeadingAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { 0 }
}

enum HorizontalCenterAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context.width / 2 }
}

enum TrailingAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { context.width }
}

extension AlignmentKey {
    /// Whether the guide is a view's leading, trailing, top or bottom edge or
    /// its centre, which stacks can place children on by size alone unless a
    /// child sets the guide explicitly.
    var isEdgeOrCenter: Bool {
        let id = ObjectIdentifier(self.id)
        return id == ObjectIdentifier(TopAlignmentID.self)
            || id == ObjectIdentifier(VerticalCenterAlignmentID.self)
            || id == ObjectIdentifier(BottomAlignmentID.self)
            || id == ObjectIdentifier(LeadingAlignmentID.self)
            || id == ObjectIdentifier(HorizontalCenterAlignmentID.self)
            || id == ObjectIdentifier(TrailingAlignmentID.self)
    }
}
