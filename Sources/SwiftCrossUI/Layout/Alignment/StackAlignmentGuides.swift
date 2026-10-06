/// Places stack children on alignment guides, and merges the guides of a
/// stack's children into the stack's own layout result.
///
/// A stack aligns its children by size alone (see ``StackAlignment``) unless
/// its alignment is a custom or baseline guide, or a child has set the
/// stack's guide explicitly with
/// ``View/alignmentGuide(_:computeValue:)-(VerticalAlignment,_)``. Then each
/// child is offset so that its value for the guide lines up with the largest
/// such value among its siblings, as SwiftUI does.
struct StackAlignmentGuides {
    /// The guide the stack aligns its children on, if any.
    var key: AlignmentKey?
    /// The stack's main axis.
    var orientation: Orientation
    /// The stack's alignment by size, used when the guide doesn't apply.
    var alignment: StackAlignment

    /// Whether the children must be placed on their guide values.
    func usesGuides(_ results: [ViewLayoutResult]) -> Bool {
        guard let key else {
            return false
        }
        if !key.isEdgeOrCenter {
            return true
        }
        return results.contains { result in
            result.participatesInStackLayouts && result.alignmentGuides[key] != nil
        }
    }

    /// The extent of the stack across its main axis when its children are
    /// placed on their guide values: the largest distance from any child's
    /// guide to its leading edge plus the largest distance to its trailing
    /// edge.
    ///
    /// - Parameter results: The children's layout results.
    /// - Returns: The stack's perpendicular size, or `nil` when the children
    ///   aren't placed on guides.
    func guidedPerpendicularExtent(of results: [ViewLayoutResult]) -> Double? {
        guard let key, usesGuides(results) else {
            return nil
        }
        let perpendicular = orientation.perpendicular
        var before = 0.0
        var after = 0.0
        for result in results where result.participatesInStackLayouts {
            let guide = ViewDimensions(result).value(of: key)
            before = max(before, guide)
            after = max(after, result.size[component: perpendicular] - guide)
        }
        return before + after
    }

    /// The offset of each child across the stack's main axis.
    ///
    /// - Parameters:
    ///   - results: The children's layout results.
    ///   - extent: The stack's perpendicular size.
    /// - Returns: One offset per child; hidden children get zero.
    func perpendicularOffsets(of results: [ViewLayoutResult], extent: Double) -> [Double] {
        let perpendicular = orientation.perpendicular
        if let key, usesGuides(results) {
            let guides = results.map { ViewDimensions($0).value(of: key) }
            let maximum =
                zip(results, guides)
                .filter { $0.0.participatesInStackLayouts }
                .map(\.1)
                .max() ?? 0
            return guides.map { maximum - $0 }
        }
        return results.map { result in
            let inner = result.size[component: perpendicular]
            return switch alignment {
                case .leading: 0
                case .center: (extent - inner) / 2
                case .trailing: extent - inner
            }
        }
    }

    /// The stack's own explicit guides: for each guide some child has set,
    /// the first such child's value offset by that child's position.
    ///
    /// - Parameters:
    ///   - results: The children's layout results.
    ///   - spacing: The spacing between visible children.
    ///   - extent: The stack's perpendicular size.
    /// - Returns: The merged guides.
    func mergedGuides(
        of results: [ViewLayoutResult],
        spacing: Double,
        extent: Double
    ) -> [AlignmentKey: Double] {
        guard results.contains(where: { !$0.alignmentGuides.isEmpty }) else {
            return [:]
        }
        let offsets = perpendicularOffsets(of: results, extent: extent)
        var merged: [AlignmentKey: Double] = [:]
        var position = 0.0
        for (index, result) in results.enumerated() where result.participatesInStackLayouts {
            for (key, value) in result.alignmentGuides where merged[key] == nil {
                let alongMainAxis = key.axis.orientation == orientation
                merged[key] = value + (alongMainAxis ? position : offsets[index])
            }
            position += result.size[component: orientation] + spacing
        }
        return merged
    }
}

extension EnvironmentValues {
    /// The alignment guide placement for the stack currently being laid out.
    var stackAlignmentGuides: StackAlignmentGuides {
        StackAlignmentGuides(
            key: layoutAlignmentKey,
            orientation: layoutOrientation,
            alignment: layoutAlignment
        )
    }
}
