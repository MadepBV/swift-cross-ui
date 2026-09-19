import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.GenericContainers {
    public func createContainer() -> Widget {
        let container = NSLayoutContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }

    public func removeAllChildren(of container: Widget) {
        container.subviews = []
        ViewGeometryCache.invalidateChildPositions(of: container)
    }

    public func insert(_ child: Widget, into container: Widget, at index: Int) {
        container.subviews.insert(child, at: index)
        child.translatesAutoresizingMaskIntoConstraints = false
        ViewGeometryCache.invalidateChildPositions(of: container)
    }

    public func swap(childAt firstIndex: Int, withChildAt secondIndex: Int, in container: NSView) {
        assert(
            container.subviews.indices.contains(firstIndex)
                && container.subviews.indices.contains(secondIndex),
            """
            attempted to swap container child out of bounds; container count \
            = \(container.subviews.count); firstIndex = \(firstIndex); \
            secondIndex = \(secondIndex)
            """
        )

        container.subviews.swapAt(firstIndex, secondIndex)
    }

    public func setPosition(ofChildAt index: Int, in container: Widget, to position: SIMD2<Int>) {
        assert(
            container.subviews.indices.contains(index),
            """
            attempted to set position of non-existent container child; container \
            count = \(container.subviews.count); index = \(index); position = \
            \(position)
            """
        )

        // Each of the two searches below walks every constraint on the
        // container, so positioning a container's children is quadratic in the
        // number of children — and a commit repositions every child of every
        // container, almost all of which land where they already were. The
        // position is remembered against the container and index rather than
        // the child, and invalidated wherever the children are rearranged.
        let entry = ViewGeometryCache.entry(for: container)
        if entry.childPositions[index] == position {
            return
        }
        entry.childPositions[index] = position

        let child = container.subviews[index]

        var foundConstraint = false
        for constraint in container.constraints {
            if constraint.firstAnchor === child.leftAnchor
                && constraint.secondAnchor === container.leftAnchor
            {
                constraint.constant = CGFloat(position.x)
                foundConstraint = true
                break
            }
        }

        if !foundConstraint {
            let constraint = child.leftAnchor.constraint(
                equalTo: container.leftAnchor,
                constant: CGFloat(position.x)
            )
            constraint.isActive = true
        }

        foundConstraint = false
        for constraint in container.constraints {
            if constraint.firstAnchor === child.topAnchor
                && constraint.secondAnchor === container.topAnchor
            {
                constraint.constant = CGFloat(position.y)
                foundConstraint = true
                break
            }
        }

        if !foundConstraint {
            child.topAnchor.constraint(
                equalTo: container.topAnchor,
                constant: CGFloat(position.y)
            ).isActive = true
        }
    }

    public func remove(childAt index: Int, from container: Widget) {
        container.subviews.remove(at: index)
        ViewGeometryCache.invalidateChildPositions(of: container)
    }
}
