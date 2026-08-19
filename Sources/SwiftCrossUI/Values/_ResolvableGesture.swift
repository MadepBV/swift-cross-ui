/// A gesture that ships with SwiftCrossUI, and therefore reduces to a kind
/// that ``BackendFeatures/PointerGestures`` knows how to recognize.
///
/// Mirrors the way ``_BuiltinFormStyle`` marks the form styles that
/// ``Section`` can match its metrics to. A type that conforms to ``Gesture``
/// from outside SwiftCrossUI doesn't conform to this, so ``View/gesture(_:)``
/// has nothing to attach and leaves the view untouched.
package protocol _ResolvableGesture: Gesture {
    /// The concrete kind of gesture this reduces to.
    var _resolved: ResolvedGesture { get }
}
