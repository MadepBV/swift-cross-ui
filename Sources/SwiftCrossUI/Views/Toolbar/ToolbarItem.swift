/// A single item in a toolbar.
///
/// ```swift
/// .toolbar {
///     ToolbarItem(placement: .cancellationAction) {
///         Button("Cancel") { dismiss() }
///     }
/// }
/// ```
public struct ToolbarItem<ID, Content: View>: ToolbarContent {
    public typealias Body = Never

    /// Where in the bar the item goes.
    var placement: ToolbarItemPlacement

    /// The item's content.
    var content: Content

    public var _toolbarEntries: [_ToolbarEntry] {
        [_ToolbarEntry(placement: placement, kind: .view(AnyView(content)))]
    }
}

extension ToolbarItem where ID == () {
    /// Creates a toolbar item.
    ///
    /// - Parameters:
    ///   - placement: Where in the bar the item goes.
    ///   - content: The item's content.
    public init(
        placement: ToolbarItemPlacement = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.content = content()
    }
}

extension ToolbarItem where ID == String {
    /// Creates a toolbar item with an identifier.
    ///
    /// SwiftUI uses the identifier for toolbars that the user can customize;
    /// SwiftCrossUI's bars aren't customizable, so it's only kept for source
    /// compatibility.
    ///
    /// - Parameters:
    ///   - id: The item's identifier.
    ///   - placement: Where in the bar the item goes.
    ///   - content: The item's content.
    public init(
        id: String,
        placement: ToolbarItemPlacement = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.content = content()
    }
}

/// A group of toolbar items that share a placement.
///
/// ```swift
/// .toolbar {
///     ToolbarItemGroup(placement: .primaryAction) {
///         Button("Share") { share() }
///         Button("Delete") { delete() }
///     }
/// }
/// ```
public struct ToolbarItemGroup<Content: View>: ToolbarContent {
    public typealias Body = Never

    /// Where in the bar the group goes.
    var placement: ToolbarItemPlacement

    /// The group's items.
    var content: Content

    /// Creates a group of toolbar items.
    ///
    /// - Parameters:
    ///   - placement: Where in the bar the items go.
    ///   - content: The items.
    public init(
        placement: ToolbarItemPlacement = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.content = content()
    }

    public var _toolbarEntries: [_ToolbarEntry] {
        [_ToolbarEntry(placement: placement, kind: .view(AnyView(content)))]
    }
}

/// Space between toolbar items.
///
/// A flexible spacer pushes the items after it to the far end of their
/// region; a fixed one separates two items by the standard spacing.
public struct ToolbarSpacer: ToolbarContent {
    public typealias Body = Never

    /// The kinds of space a ``ToolbarSpacer`` can take.
    public struct SpacerSizing: Hashable, Sendable {
        /// The fixed width, or `nil` for a flexible spacer.
        let width: Double?

        /// Space that grows to fill the room available.
        public static let flexible = SpacerSizing(width: nil)
        /// The standard space between two groups of items.
        public static let fixed = SpacerSizing(width: 12)
    }

    /// How much space to take.
    var sizing: SpacerSizing

    /// Where in the bar the space goes.
    var placement: ToolbarItemPlacement

    /// Creates a toolbar spacer.
    ///
    /// - Parameters:
    ///   - sizing: How much space to take.
    ///   - placement: Where in the bar the space goes.
    public init(
        _ sizing: SpacerSizing = .fixed,
        placement: ToolbarItemPlacement = .automatic
    ) {
        self.sizing = sizing
        self.placement = placement
    }

    public var _toolbarEntries: [_ToolbarEntry] {
        [_ToolbarEntry(placement: placement, kind: .spacer(sizing.width))]
    }
}
