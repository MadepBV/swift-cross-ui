/// A layout container that arranges its subviews in a vertical line.
///
/// SwiftUI ships this on macOS only, where each pane is separated from the
/// next by a divider the user can drag to redistribute height.
///
/// ```swift
/// VSplitView {
///     canvas
///     console
///         .frame(minHeight: 120)
/// }
/// ```
///
/// ## The dividers are not draggable
///
/// The panes are stacked and honour their own frame modifiers, but there are
/// no dividers between them and no way to resize them by dragging. See
/// ``HSplitView`` for why SwiftCrossUI's own ``SplitView`` cannot supply them;
/// the vertical case has the additional problem that every backend's
/// `createSplitView(leadingChild:trailingChild:)` is horizontal.
public struct VSplitView<Content: View>: View {
    /// The panes of the split view.
    private var content: Content

    /// Creates a vertical split view.
    ///
    /// - Parameter content: The panes of the split view.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
    }
}
