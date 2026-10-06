/// A type that supplies the tabs of a ``TabView``.
///
/// ``Tab`` is the primitive tab content; a ``TabContentBuilder`` combines tabs
/// with `if`, `if let`, `switch`, `for` and `#if`, as SwiftUI's does.
///
/// ## Differences from SwiftUI
///
/// SwiftUI's protocol also has a `body`, which lets an app compose tab content
/// of its own. SwiftCrossUI's tab content is always built from ``Tab``s.
@MainActor
public protocol TabContent<TabValue> {
    /// The type of value that identifies each tab.
    associatedtype TabValue: Hashable

    /// The tabs this content contributes to a ``TabView``, in order.
    ///
    /// Don't implement this yourself.
    var _tabs: [_TabItem<TabValue>] { get }
}

/// One tab of a ``TabView``, as contributed by a ``Tab``.
public struct _TabItem<Value: Hashable> {
    /// The tab's title.
    var title: String
    /// The name of the tab's symbol, if it has one.
    var systemImage: String?
    /// The value that selects the tab.
    var value: Value
    /// The tab's role.
    var role: TabRole?
    /// Builds the tab's content.
    var content: @MainActor () -> AnyView
}

/// A list of tabs, as built by ``TabContentBuilder``.
public struct _TabContentList<TabValue: Hashable>: TabContent {
    public let _tabs: [_TabItem<TabValue>]

    /// Creates a list from the tabs it holds.
    ///
    /// - Parameter tabs: The tabs, in order.
    init(_ tabs: [_TabItem<TabValue>]) {
        self._tabs = tabs
    }
}

/// A result builder for the tabs of a ``TabView``.
@MainActor
@resultBuilder
public enum TabContentBuilder<TabValue: Hashable> {
    public static func buildExpression(
        _ content: some TabContent<TabValue>
    ) -> _TabContentList<TabValue> {
        _TabContentList(content._tabs)
    }

    public static func buildBlock() -> _TabContentList<TabValue> {
        _TabContentList([])
    }

    public static func buildBlock(
        _ components: _TabContentList<TabValue>...
    ) -> _TabContentList<TabValue> {
        _TabContentList(components.flatMap(\._tabs))
    }

    public static func buildOptional(
        _ component: _TabContentList<TabValue>?
    ) -> _TabContentList<TabValue> {
        component ?? _TabContentList([])
    }

    public static func buildEither(
        first component: _TabContentList<TabValue>
    ) -> _TabContentList<TabValue> {
        component
    }

    public static func buildEither(
        second component: _TabContentList<TabValue>
    ) -> _TabContentList<TabValue> {
        component
    }

    public static func buildArray(
        _ components: [_TabContentList<TabValue>]
    ) -> _TabContentList<TabValue> {
        _TabContentList(components.flatMap(\._tabs))
    }

    public static func buildLimitedAvailability(
        _ component: _TabContentList<TabValue>
    ) -> _TabContentList<TabValue> {
        component
    }
}
