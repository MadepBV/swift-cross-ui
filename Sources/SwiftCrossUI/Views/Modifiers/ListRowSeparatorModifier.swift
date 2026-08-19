extension VerticalEdge {
    /// An efficient set of ``VerticalEdge``s.
    ///
    /// Declared here rather than alongside ``VerticalEdge`` because
    /// ``SwiftCrossUI/View/listRowSeparator(_:edges:)`` is the only API that
    /// takes one.
    public struct Set: OptionSet, Hashable, Sendable {
        public let rawValue: Int8

        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }

        /// Creates a set holding a single edge.
        ///
        /// - Parameter edge: The edge the set holds.
        public init(_ edge: VerticalEdge) {
            self.rawValue = 1 << edge.rawValue
        }

        /// The top edge.
        public static let top = Set(.top)
        /// The bottom edge.
        public static let bottom = Set(.bottom)

        /// Both edges.
        public static let all: Set = [.top, .bottom]
    }
}

extension View {
    /// Sets the visibility of the separators drawn around this row of a
    /// ``List``.
    ///
    /// ```swift
    /// List {
    ///     emptyState
    ///         .listRowSeparator(.hidden)
    /// }
    /// ```
    ///
    /// - Note: This is a no-op. No SwiftCrossUI backend exposes control over
    ///   the separators of its list widget, and a row-built ``List`` draws none
    ///   in the first place, so nothing acts on the request. The visibility is
    ///   recorded in the environment (as ``EnvironmentValues/listRowSeparator``)
    ///   so that a backend which grows the ability can read it without the API
    ///   changing shape, and so that the modifier is testable; it changes
    ///   nothing that's rendered today.
    ///
    /// - Parameters:
    ///   - visibility: Whether the row's separators should be drawn.
    ///   - edges: The edges of the row the visibility applies to.
    /// - Returns: A view carrying the requested separator visibility.
    public func listRowSeparator(
        _ visibility: Visibility,
        edges: VerticalEdge.Set = .all
    ) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(
                \.listRowSeparator,
                ListRowSeparator(visibility: visibility, edges: edges)
            )
        }
    }
}

/// The separator visibility requested by
/// ``SwiftCrossUI/View/listRowSeparator(_:edges:)``.
public struct ListRowSeparator: Hashable, Sendable {
    /// Whether the separators should be drawn.
    public var visibility: Visibility
    /// The edges the visibility applies to.
    public var edges: VerticalEdge.Set

    /// Creates a separator visibility request.
    ///
    /// - Parameters:
    ///   - visibility: Whether the separators should be drawn.
    ///   - edges: The edges the visibility applies to.
    public init(visibility: Visibility, edges: VerticalEdge.Set) {
        self.visibility = visibility
        self.edges = edges
    }
}

extension EnvironmentValues {
    /// The separator visibility requested by the innermost enclosing
    /// ``SwiftCrossUI/View/listRowSeparator(_:edges:)``.
    ///
    /// `nil` when no row has asked for anything, which is also what every
    /// backend does with it today. See that modifier for why.
    @Entry public var listRowSeparator: ListRowSeparator? = nil
}
