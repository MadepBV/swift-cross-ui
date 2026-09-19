extension View {
    /// Binds this view's identity to the given value.
    ///
    /// Keeping the same value preserves the view's state across updates.
    /// Changing the value replaces the view and its descendants, resetting
    /// their state to the initial values of the new view.
    ///
    /// This is useful for an editor whose local draft belongs to one selected
    /// model: `Editor(model: selection).id(selection.id)`.
    ///
    /// - Parameter id: The identity of this view and its descendants.
    public func id<ID: Hashable>(_ id: ID) -> some View {
        // Reuse ForEach's keyed node lifecycle and layout participation. A
        // single item changes identity exactly when its child must be replaced.
        ForEach(CollectionOfOne(id), id: \.self) { _ in self }
    }
}
