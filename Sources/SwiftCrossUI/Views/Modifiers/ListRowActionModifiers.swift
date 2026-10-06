import Foundation


extension View {
    /// Adds actions that the user reveals by swiping a list row.
    ///
    /// Desktop backends have no swipe gesture on list rows, so SwiftCrossUI
    /// offers the same actions where desktop users look for them: in the
    /// row's context menu (a right-click, or a long press on touch screens).
    ///
    /// - Parameters:
    ///   - edge: The edge the row would be swiped from; doesn't change the
    ///     context menu.
    ///   - allowsFullSwipe: Whether a full swipe performs the first action;
    ///     there's no swipe to complete, so it has no effect.
    ///   - content: The actions, usually ``Button``s.
    /// - Returns: A row whose context menu offers the actions.
    public func swipeActions<Actions: View>(
        edge: HorizontalEdge = .trailing,
        allowsFullSwipe: Bool = true,
        @ViewBuilder content: () -> Actions
    ) -> some View {
        contextMenu(menuItems: content)
    }

    /// Sets the background of a list row.
    ///
    /// Purely cosmetic, and without effect: SwiftCrossUI's list rows draw no
    /// background of their own (only the backend's selection highlight), so
    /// the row's content, and whatever is behind the list, already show.
    ///
    /// - Parameter view: The background.
    /// - Returns: This view, unchanged.
    public func listRowBackground<Background: View>(_ view: Background?) -> some View {
        self
    }

    /// Sets the insets around a list row's content.
    ///
    /// Purely cosmetic, and without effect: rows in a ``Form`` section are
    /// laid out by the section, with one padding for all of its rows, and a
    /// selectable ``List`` gives every row the same padding the platform's
    /// list widget needs, so a single row has no insets of its own to
    /// change. To make a row's content reach further, give the content a
    /// negative padding or a frame of its own.
    ///
    /// - Parameter insets: The insets, or `nil` for the default.
    /// - Returns: This view, unchanged.
    public func listRowInsets(_ insets: EdgeInsets?) -> some View {
        self
    }
}

extension ForEach {
    /// Lets the user reorder the elements of this collection in a list.
    ///
    /// Without effect so far: no backend's list supports reordering rows by
    /// dragging yet, so `action` is never called. Offer a way to reorder that
    /// doesn't need dragging (Move Up and Move Down buttons, say) alongside it.
    ///
    /// - Parameter action: Moves the elements at the given offsets to before
    ///   the given offset, or `nil` to disallow reordering.
    /// - Returns: This view, unchanged.
    public func onMove(perform action: ((IndexSet, Int) -> Void)?) -> Self {
        self
    }

    /// Lets the user delete elements of this collection in a list.
    ///
    /// Without effect so far: no backend's list offers a delete gesture yet,
    /// so `action` is never called.
    ///
    /// - Parameter action: Deletes the elements at the given offsets, or
    ///   `nil` to disallow deleting.
    /// - Returns: This view, unchanged.
    public func onDelete(perform action: ((IndexSet) -> Void)?) -> Self {
        self
    }
}
