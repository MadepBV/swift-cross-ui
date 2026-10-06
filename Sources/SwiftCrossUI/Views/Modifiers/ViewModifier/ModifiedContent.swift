/// A value with a modifier applied to it.
///
/// - Note: SwiftUI names the generic parameters `Content` and `Modifier`.
///   SwiftCrossUI's ``View`` protocol already uses `Content` as the name of
///   its body's associated type, so the first parameter is called `Wrapped`
///   here; the type is spelled identically at every call site.
public struct ModifiedContent<Wrapped, Modifier> {
    /// The content that the modifier transforms into a new view or new
    /// view modifier.
    public var content: Wrapped

    /// The view modifier.
    public var modifier: Modifier

    /// A structure that the defines the content and modifier needed to
    /// produce a new view or view modifier.
    ///
    /// - Parameters:
    ///   - content: The content that the modifier changes.
    ///   - modifier: The modifier to apply to the content.
    public init(content: Wrapped, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
}

extension ModifiedContent: View where Wrapped: View, Modifier: ViewModifier {
    /// The modifier's body applied to the content.
    ///
    /// Evaluated as this view's body, so the modifier's dynamic properties are
    /// updated by the view graph beforehand (see `DynamicPropertyUpdater`),
    /// and its observable reads are tracked like any other body's.
    public var body: Modifier.Body {
        return modifier.body(content: _ViewModifier_Content(content))
    }
}

extension ModifiedContent: ViewModifier where Wrapped: ViewModifier, Modifier: ViewModifier {
    /// Applies `content` (the first modifier) and then `modifier` (the second).
    ///
    /// - Parameter content: The view being modified.
    /// - Returns: The view with both modifiers applied.
    public func body(content view: _ViewModifier_Content<Self>) -> some View {
        let inner = self.content.body(content: _ViewModifier_Content<Wrapped>(erased: view.body))
        return modifier.body(content: _ViewModifier_Content<Modifier>(inner))
    }
}

extension ViewModifier {
    /// Returns a new modifier that is the result of concatenating `self` with
    /// `modifier`.
    ///
    /// - Parameter modifier: The modifier to apply after this one.
    /// - Returns: The combined modifier.
    public func concat<T>(_ modifier: T) -> ModifiedContent<Self, T> {
        ModifiedContent(content: self, modifier: modifier)
    }
}

/// An empty, or identity, modifier, used during development to switch
/// modifiers at compile time.
public struct EmptyModifier: ViewModifier {
    /// The identity modifier.
    public static let identity = EmptyModifier()

    public init() {}

    public func body(content: Content) -> Content {
        return content
    }
}
