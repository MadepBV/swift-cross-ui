/// A view type that compares itself against its previous value and prevents
/// its child updating if its new value is the same as its old value.
///
/// In SwiftUI this is purely a performance hint: an equal value skips its
/// body's evaluation, and the result on screen is the same either way.
/// SwiftCrossUI doesn't skip the evaluation, as every view's dynamic
/// properties have to be updated on each pass; the content is laid out and
/// rendered exactly as it would be without the wrapper. The `@Observable`
/// values the body reads are tracked per view in any case, which is what
/// SwiftUI apps usually reach for `equatable()` to approximate.
public struct EquatableView<Content: View & Equatable>: View {
    /// The view to compare.
    public var content: Content

    /// Creates a new view that compares itself against its previous value.
    ///
    /// - Parameter content: The view to compare.
    public init(content: Content) {
        self.content = content
    }

    public var body: Content {
        return content
    }
}

extension View where Self: Equatable {
    /// Prevents the view from updating its child view when its new value is
    /// the same as its old value.
    ///
    /// See ``EquatableView`` for how this behaves in SwiftCrossUI.
    ///
    /// - Returns: The view, wrapped.
    public func equatable() -> EquatableView<Self> {
        EquatableView(content: self)
    }
}
