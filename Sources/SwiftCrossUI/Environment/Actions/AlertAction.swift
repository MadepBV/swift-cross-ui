/// An alert action button.
///
/// Only backends should interface with this type directly. This exists to avoid
/// having to expose internal details of ``Button``, since breaking `Button`'s
/// API would have much more wide-reaching impacts than breaking this
/// single-purpose API.
///
/// The action isn't `@Sendable`, because it's already confined to the main
/// actor and can only have come from a ``Button``, whose action isn't
/// `@Sendable` either. Requiring it here would reject the plain
/// `@escaping () -> Void` callbacks that applications hand to buttons without
/// buying any safety in return.
///
/// # See Also
/// - ``View/alert(_:isPresented:actions:)``
public struct AlertAction {
    /// The default alert action.
    ///
    /// Consists of a button labeled "OK" with no action (other than dismissing
    /// the alert, which is implicit).
    public static var `default`: AlertAction {
        AlertAction(label: "OK", action: {})
    }

    /// The button's label.
    public var label: String
    /// The button's action.
    public var action: @MainActor () -> Void
}
