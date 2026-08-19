/// The properties of a button, handed to a ``ButtonStyle`` so that it can
/// decorate it.
///
/// A style never constructs a configuration itself; ``Button`` builds one and
/// passes it to ``ButtonStyle/makeBody(configuration:)``.
///
/// ## See Also
///
/// - ``ButtonStyle``
/// - ``Button``
public struct ButtonStyleConfiguration {
    /// A type-erased view of a button's label.
    public struct Label: View {
        /// The button's label, with its type erased.
        private var erasedLabel: AnyView

        @ViewBuilder
        public var body: some View {
            erasedLabel
        }

        /// Erases a button's label.
        ///
        /// - Parameter label: The view used as the button's label.
        package init(_ label: some View) {
            erasedLabel = AnyView(label)
        }
    }

    /// A view that describes the effect of pressing the button.
    public var label: Label

    /// The button's role, if it has one.
    ///
    /// See ``ButtonRole`` for what a role means.
    public var role: ButtonRole?

    /// Whether the button is currently being pressed.
    ///
    /// - Important: This is always `false` in SwiftCrossUI. No backend
    ///   reports a button's press state to the view layer — backends draw the
    ///   pressed appearance of the built-in styles themselves — so a custom
    ///   style cannot react to presses yet.
    public var isPressed: Bool

    /// Creates a configuration describing a button.
    ///
    /// - Parameters:
    ///   - label: A view that describes the effect of pressing the button.
    ///   - role: The button's role, if it has one.
    ///   - isPressed: Whether the button is currently being pressed.
    package init(label: Label, role: ButtonRole?, isPressed: Bool) {
        self.label = label
        self.role = role
        self.isPressed = isPressed
    }
}
