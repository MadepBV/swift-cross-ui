/// A type that supplies the items of a toolbar.
///
/// Toolbar content is declared like view content, in a
/// ``ToolbarContentBuilder``: ``ToolbarItem``, ``ToolbarItemGroup`` and
/// ``ToolbarSpacer`` are the primitives, and a type of your own can conform by
/// composing them in its `body`, exactly as in SwiftUI:
///
/// ```swift
/// struct EditorToolbar: ToolbarContent {
///     var body: some ToolbarContent {
///         ToolbarItem(placement: .confirmationAction) {
///             Button("Done") { save() }
///         }
///     }
/// }
/// ```
@MainActor
public protocol ToolbarContent {
    /// The type of toolbar content that this content is made of.
    associatedtype Body: ToolbarContent

    /// The content this toolbar content is made of.
    @ToolbarContentBuilder
    var body: Body { get }

    /// The items that this content contributes to a bar, in order.
    ///
    /// Implemented by SwiftCrossUI's primitive toolbar content; the default
    /// reads ``body``. Don't implement it yourself.
    var _toolbarEntries: [_ToolbarEntry] { get }
}

extension ToolbarContent {
    public var _toolbarEntries: [_ToolbarEntry] {
        body._toolbarEntries
    }
}

extension ToolbarContent where Body == Never {
    public var body: Never {
        fatalError("\(Self.self) is primitive toolbar content and has no body")
    }
}

extension Never: ToolbarContent {
    public var _toolbarEntries: [_ToolbarEntry] {
        []
    }
}

/// One item that a toolbar declaration contributes to a bar.
///
/// Produced by the primitive ``ToolbarContent`` types and drawn by the bar of
/// the enclosing navigation container.
public struct _ToolbarEntry {
    /// What an entry draws.
    enum Kind {
        /// A view: a ``ToolbarItem``'s content, or a ``ToolbarItemGroup``'s.
        case view(AnyView)
        /// A ``ToolbarSpacer``; `nil` for a flexible one, otherwise its width.
        case spacer(Double?)
    }

    /// Where in the bar the entry goes.
    var placement: ToolbarItemPlacement

    /// What the entry draws.
    var kind: Kind
}

/// A list of toolbar content, as built by ``ToolbarContentBuilder``.
public struct _ToolbarContentList: ToolbarContent {
    public typealias Body = Never

    /// The entries of the content in the list, in order.
    public let _toolbarEntries: [_ToolbarEntry]

    /// Creates a list from the entries it holds.
    ///
    /// - Parameter entries: The entries, in order.
    init(_ entries: [_ToolbarEntry]) {
        self._toolbarEntries = entries
    }
}

/// A result builder for ``ToolbarContent``.
///
/// Accepts toolbar content and, as SwiftUI does, plain views, each of which
/// becomes an item with the ``ToolbarItemPlacement/automatic`` placement.
@MainActor
@resultBuilder
public enum ToolbarContentBuilder {
    public static func buildExpression(
        _ content: some ToolbarContent
    ) -> _ToolbarContentList {
        _ToolbarContentList(content._toolbarEntries)
    }

    public static func buildExpression(_ view: some View) -> _ToolbarContentList {
        _ToolbarContentList([
            _ToolbarEntry(placement: .automatic, kind: .view(AnyView(view)))
        ])
    }

    public static func buildBlock() -> _ToolbarContentList {
        _ToolbarContentList([])
    }

    public static func buildBlock(
        _ components: _ToolbarContentList...
    ) -> _ToolbarContentList {
        _ToolbarContentList(components.flatMap(\._toolbarEntries))
    }

    public static func buildOptional(
        _ component: _ToolbarContentList?
    ) -> _ToolbarContentList {
        component ?? _ToolbarContentList([])
    }

    public static func buildEither(
        first component: _ToolbarContentList
    ) -> _ToolbarContentList {
        component
    }

    public static func buildEither(
        second component: _ToolbarContentList
    ) -> _ToolbarContentList {
        component
    }

    public static func buildArray(
        _ components: [_ToolbarContentList]
    ) -> _ToolbarContentList {
        _ToolbarContentList(components.flatMap(\._toolbarEntries))
    }

    public static func buildLimitedAvailability(
        _ component: _ToolbarContentList
    ) -> _ToolbarContentList {
        component
    }
}
