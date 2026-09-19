import Foundation

public struct PreferenceValues: Sendable {
    /// The default preferences.
    public static let `default` = PreferenceValues(
        onOpenURL: nil,
        presentationDetents: nil,
        presentationCornerRadius: nil,
        presentationDragIndicatorVisibility: nil,
        presentationBackground: nil,
        interactiveDismissDisabled: nil,
        windowDismissBehavior: nil,
        onWindowCloseRequested: nil,
        preferredWindowMinimizeBehavior: nil,
        windowResizeBehavior: nil,
        layoutPriority: defaultLayoutPriority
    )

    static let defaultLayoutPriority = 0.0

    public var onOpenURL: (@Sendable @MainActor (URL) -> Void)?

    /// The available detents for a sheet presentation. Applies to enclosing sheets.
    public var presentationDetents: [PresentationDetent]?

    /// The corner radius for a sheet presentation. Applies to enclosing sheets.
    public var presentationCornerRadius: Double?

    /// The drag indicator visibility for a sheet presentation. Applies to enclosing sheets.
    public var presentationDragIndicatorVisibility: Visibility?

    /// The background color for enclosing sheets.
    public var presentationBackground: Color?

    /// Sets the preferred color scheme for the nearest enclosing presentation.
    public var preferredColorScheme: ColorScheme?

    /// Controls whether the user can interactively dismiss enclosing sheets.
    public var interactiveDismissDisabled: Bool?

    /// Controls whether the user can close the enclosing window.
    public var windowDismissBehavior: WindowInteractionBehavior?

    /// Asynchronous authorization before the enclosing window closes.
    public var onWindowCloseRequested: (@MainActor @Sendable () async -> Bool)?

    /// Controls whether the user can minimize the enclosing window.
    public var preferredWindowMinimizeBehavior: WindowInteractionBehavior?

    /// Controls whether the user can resize the enclosing window.
    public var windowResizeBehavior: WindowInteractionBehavior?

    /// The number of columns that the view spans when it's used as a cell of
    /// a ``Grid``. Consumed by the enclosing ``GridRow``.
    var gridCellColumns: Int?

    /// The layout priority of the view.
    var layoutPriority: Double

    /// Returns a copy of the preferences with the specified property set to the
    /// provided new value.
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the property to set.
    ///   - newValue: The new value of the property.
    /// - Returns: A copy of the preferences with the specified property set to
    ///   `newValue`.
    public func with<T>(_ keyPath: WritableKeyPath<Self, T>, _ newValue: T) -> Self {
        var preferences = self
        preferences[keyPath: keyPath] = newValue
        return preferences
    }
}

extension PreferenceValues {
    init(merging children: [PreferenceValues]) {
        self.init(mergingResults: [], childPreferences: children, overlay: nil)
    }

    /// Merges the preferences of a view's children, plus an optional overlay
    /// contributed by the view itself.
    ///
    /// This runs once per container per layout computation, which is the
    /// hottest allocation site in the layout system, so it merges in a single
    /// pass rather than by building one throwaway array per property. The
    /// two child sources are kept separate (rather than concatenated) for the
    /// same reason: ``ViewLayoutResult`` has layout results, not preferences,
    /// and mapping them into an array first is exactly the allocation being
    /// avoided.
    ///
    /// - Parameters:
    ///   - results: Child layout results whose preferences take part in the
    ///     merge, in order.
    ///   - childPreferences: Additional child preferences, merged after
    ///     `results`.
    ///   - overlay: The view's own preferences, merged last.
    init(
        mergingResults results: [ViewLayoutResult],
        childPreferences: [PreferenceValues] = [],
        overlay: PreferenceValues?
    ) {
        self = .default

        var handlers: [@Sendable @MainActor (URL) -> Void] = []
        var childCount = 0
        var firstChildLayoutPriority = Self.defaultLayoutPriority

        // For presentation modifiers, take the outer-most value (using child
        // ordering to break ties), which is what taking the first non-nil in
        // order amounts to.
        func merge(_ child: PreferenceValues) {
            if childCount == 0 {
                firstChildLayoutPriority = child.layoutPriority
            }
            childCount += 1

            if let handler = child.onOpenURL {
                handlers.append(handler)
            }
            if presentationDetents == nil {
                presentationDetents = child.presentationDetents
            }
            if presentationCornerRadius == nil {
                presentationCornerRadius = child.presentationCornerRadius
            }
            if presentationDragIndicatorVisibility == nil {
                presentationDragIndicatorVisibility = child.presentationDragIndicatorVisibility
            }
            if presentationBackground == nil {
                presentationBackground = child.presentationBackground
            }
            if preferredColorScheme == nil {
                preferredColorScheme = child.preferredColorScheme
            }
            if interactiveDismissDisabled == nil {
                interactiveDismissDisabled = child.interactiveDismissDisabled
            }
            if windowDismissBehavior == nil {
                windowDismissBehavior = child.windowDismissBehavior
            }
            if onWindowCloseRequested == nil {
                onWindowCloseRequested = child.onWindowCloseRequested
            }
            if preferredWindowMinimizeBehavior == nil {
                preferredWindowMinimizeBehavior = child.preferredWindowMinimizeBehavior
            }
            if windowResizeBehavior == nil {
                windowResizeBehavior = child.windowResizeBehavior
            }
            if gridCellColumns == nil {
                gridCellColumns = child.gridCellColumns
            }
        }

        for result in results {
            merge(result.preferences)
        }
        for child in childPreferences {
            merge(child)
        }
        if let overlay {
            merge(overlay)
        }

        if !handlers.isEmpty {
            let mergedHandlers = handlers
            onOpenURL = { url in
                for handler in mergedHandlers {
                    handler(url)
                }
            }
        }

        layoutPriority = childCount == 1 ? firstChildLayoutPriority : Self.defaultLayoutPriority
    }
}
