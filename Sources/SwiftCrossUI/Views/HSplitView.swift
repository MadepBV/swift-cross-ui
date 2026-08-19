/// A layout container that arranges its subviews in a horizontal line.
///
/// SwiftUI ships this on macOS only, where each pane is separated from the
/// next by a divider the user can drag to redistribute width.
///
/// ```swift
/// HSplitView {
///     familySidebar
///         .frame(minWidth: 140, idealWidth: 160)
///     resultList
///         .frame(minWidth: 190, idealWidth: 220)
///     detail
///         .frame(minWidth: 380, maxWidth: .infinity)
/// }
/// ```
///
/// ## The dividers are not draggable
///
/// The panes are laid out side by side and honour their own frame modifiers,
/// but there are no dividers between them and no way to resize them by
/// dragging.
///
/// SwiftCrossUI's own draggable split is ``SplitView``, which every backend
/// implements as `createSplitView(leadingChild:trailingChild:)` — a
/// *two*-pane widget with a single divider, driven by
/// ``NavigationSplitView``. Two things stop `HSplitView` being expressed in
/// terms of it:
///
/// - Arity. Nesting two-pane splits would give the three-pane layout above,
///   but reaching the individual panes means decomposing whatever
///   ``ViewBuilder`` produced, and a `TupleView`'s children are only reachable
///   at statically known arities. There is no N-pane backend call to target
///   instead.
/// - Semantics. ``SplitView`` is a sidebar/detail split: it forces the
///   ``ListStyle/sidebar`` list style onto its leading pane and reports
///   sidebar width bounds to the backend. `HSplitView` panes are peers.
///
/// Real support needs an N-pane split in the backend protocol — on AppKit an
/// `NSSplitView` with one `NSSplitViewItem` per pane, which is what SwiftUI
/// itself uses.
public struct HSplitView<Content: View>: View {
    /// The panes of the split view.
    private var content: Content

    /// Creates a horizontal split view.
    ///
    /// - Parameter content: The panes of the split view.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 0) {
            content
        }
    }
}
