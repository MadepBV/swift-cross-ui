extension View {
    /// Associates a transition with this view, describing how it would appear
    /// and disappear as it is inserted into or removed from the hierarchy.
    ///
    /// ## This modifier is inert
    ///
    /// SwiftCrossUI has no animation system, so there is nothing to play the
    /// transition back: the view still appears and disappears exactly when its
    /// state says it should, it simply does so immediately. The modifier
    /// exists so that application source written against SwiftUI compiles
    /// unchanged, and so that the author's intent is recorded rather than
    /// deleted. See ``AnyTransition`` for the whole picture.
    ///
    /// ```swift
    /// if isUnlocked {
    ///     banner
    ///         .transition(.move(edge: .top).combined(with: .opacity))
    /// }
    /// ```
    ///
    /// - Parameter transition: The transition to associate with the view.
    /// - Returns: The view, unchanged.
    public func transition(_ transition: AnyTransition) -> some View {
        self
    }
}
