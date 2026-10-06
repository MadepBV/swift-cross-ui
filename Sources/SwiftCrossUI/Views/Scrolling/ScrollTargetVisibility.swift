/// One ``View/onScrollTargetVisibilityChange(idType:threshold:_:)`` around a
/// scroll view.
struct ScrollTargetVisibilityObserver {
    /// The type of identity the observer reports.
    var idType: Any.Type
    /// How much of a view must be visible for it to count, from 0 to 1.
    var threshold: Double
    /// Reports the visible identities, of the observer's type, given the ones
    /// reported last time, and returns the ones to remember.
    var report: @MainActor ([AnyHashable], [AnyHashable]?) -> [AnyHashable]
}

extension EnvironmentValues {
    /// The scroll target visibility observers around a scroll view. Scroll
    /// views take them out of their content's environment.
    @Entry var scrollTargetVisibilityObservers: [ScrollTargetVisibilityObserver] = []
}

extension View {
    /// Adds an action to perform when the identified views visible in the
    /// scroll view within this view change.
    ///
    /// The views are the scroll view's identified views (``ForEach``
    /// elements and views with ``View/id(_:)``) whose identity is an `ID`,
    /// in order. Visibility is measured each time the scroll view is laid
    /// out, as ``View/onScrollGeometryChange(for:of:action:)``'s geometry is,
    /// so the user's own scrolling isn't reflected until the next layout.
    ///
    /// - Parameters:
    ///   - idType: The type of identity to report.
    ///   - threshold: How much of a view must be visible for it to count,
    ///     from 0 to 1.
    ///   - action: Performed with the visible identities when they change.
    /// - Returns: A view that observes which of its scroll view's views are
    ///   visible.
    public func onScrollTargetVisibilityChange<ID: Hashable>(
        idType: ID.Type,
        threshold: Double = 0.5,
        _ action: @escaping ([ID]) -> Void
    ) -> some View {
        let observer = ScrollTargetVisibilityObserver(
            idType: ID.self,
            threshold: threshold
        ) { visible, previous in
            if visible != previous {
                let ids = visible.compactMap { $0.base as? ID }
                Task { @MainActor in
                    action(ids)
                }
            }
            return visible
        }
        return EnvironmentModifier(self) { environment in
            environment.with(
                \.scrollTargetVisibilityObservers,
                environment.scrollTargetVisibilityObservers + [observer]
            )
        }
    }
}

extension ScrollTargetRegistry {
    /// The identities of the registered views of a type that are visible
    /// enough, in registration order.
    ///
    /// - Parameters:
    ///   - idType: The type of identity.
    ///   - threshold: How much of a view must be visible, from 0 to 1.
    /// - Returns: The identities.
    func visibleTargets(ofType idType: Any.Type, threshold: Double) -> [AnyHashable] {
        guard let controller else {
            return []
        }
        let offset = controller.currentOffset()
        let viewportEnd = offset + controller.viewportSize
        return targets.compactMap { target in
            guard type(of: target.id.base) == idType,
                  let frame = controller.frame(target.widget)
            else {
                return nil
            }
            var visibleFraction = 1.0
            for axis in 0..<2 where frame.size[axis] > 0 {
                let start = max(frame.origin[axis], offset[axis])
                let end = min(frame.origin[axis] + frame.size[axis], viewportEnd[axis])
                visibleFraction *= max(0, end - start) / frame.size[axis]
            }
            return visibleFraction >= threshold && visibleFraction > 0 ? target.id : nil
        }
    }
}
