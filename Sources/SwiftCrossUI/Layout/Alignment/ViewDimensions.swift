import Foundation

/// A view's size and alignment guides in its own coordinate space.
///
/// Handed to ``AlignmentID/defaultValue(in:)`` and to the closures given to
/// ``View/alignmentGuide(_:computeValue:)-(VerticalAlignment,_)``.
public struct ViewDimensions: Equatable {
    /// The view's width.
    public var width: CGFloat { CGFloat(size.width) }
    /// The view's height.
    public var height: CGFloat { CGFloat(size.height) }

    /// The view's size.
    let size: ViewSize
    /// The guides the view (or one of its descendants) has set explicitly.
    let explicitGuides: [AlignmentKey: Double]

    init(size: ViewSize, explicitGuides: [AlignmentKey: Double] = [:]) {
        self.size = size
        self.explicitGuides = explicitGuides
    }

    init(_ result: ViewLayoutResult) {
        self.init(size: result.size, explicitGuides: result.alignmentGuides)
    }

    /// The value of the given guide: the explicit value if set, otherwise
    /// the guide's default.
    func value(of key: AlignmentKey) -> Double {
        explicitGuides[key] ?? key.defaultValue(in: self)
    }

    /// Gets the value of the given horizontal guide.
    public subscript(guide: HorizontalAlignment) -> CGFloat {
        CGFloat(value(of: guide.key))
    }

    /// Gets the value of the given vertical guide.
    public subscript(guide: VerticalAlignment) -> CGFloat {
        CGFloat(value(of: guide.key))
    }

    /// Gets the explicit value of the given horizontal alignment guide, if
    /// one has been set.
    public subscript(explicit guide: HorizontalAlignment) -> CGFloat? {
        explicitGuides[guide.key].map { CGFloat($0) }
    }

    /// Gets the explicit value of the given vertical alignment guide, if one
    /// has been set.
    public subscript(explicit guide: VerticalAlignment) -> CGFloat? {
        explicitGuides[guide.key].map { CGFloat($0) }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.size == rhs.size && lhs.explicitGuides == rhs.explicitGuides
    }
}
