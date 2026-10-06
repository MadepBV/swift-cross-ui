/// A modifier that you apply to a view or another view modifier, producing a
/// different version of the original value.
///
/// Adopt this protocol to package a reusable set of modifiers, then apply it
/// with ``View/modifier(_:)``:
///
/// ```swift
/// struct Card: ViewModifier {
///     @State private var isHighlighted = false
///
///     func body(content: Content) -> some View {
///         content
///             .padding(12)
///             .onHover { isHighlighted = $0 }
///     }
/// }
///
/// Text("Hello").modifier(Card())
/// ```
///
/// As in SwiftUI, a modifier is a full participant in the view graph: its
/// `@State`, `@Environment` and other dynamic properties behave exactly as
/// they would on a ``View``, and its ``body(content:)`` is re-evaluated
/// whenever any of them, or any `@Observable` value it reads, changes.
@MainActor
@preconcurrency
public protocol ViewModifier {
    /// The type of view produced by ``body(content:)``.
    associatedtype Body: View

    /// The content view handed to ``body(content:)``.
    typealias Content = _ViewModifier_Content<Self>

    /// Produces the modified view.
    ///
    /// - Parameter content: The view being modified.
    /// - Returns: The modified view.
    @ViewBuilder func body(content: Content) -> Body
}

/// The view a ``ViewModifier`` receives as its content.
///
/// SwiftUI makes this an opaque placeholder; SwiftCrossUI erases the modified
/// view to ``AnyView`` so that a modifier's body can be written without
/// naming the concrete type of the view it is applied to. The erased view is
/// the very same value each update, so it keeps its view graph node (and
/// therefore its state) for as long as its type doesn't change.
public struct _ViewModifier_Content<Modifier: ViewModifier>: View {
    public var body: AnyView

    init(_ content: some View) {
        body = AnyView(content)
    }

    init(erased content: AnyView) {
        body = content
    }
}

extension View {
    /// Applies a modifier to this view and returns the result.
    ///
    /// - Parameter modifier: The modifier to apply.
    /// - Returns: The modified view.
    public func modifier<Modifier>(_ modifier: Modifier) -> ModifiedContent<Self, Modifier> {
        ModifiedContent(content: self, modifier: modifier)
    }
}
