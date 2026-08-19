/// The properties of a form, handed to a ``FormStyle`` so that it can lay the
/// form out.
///
/// A style never constructs a configuration itself; ``Form`` builds one and
/// passes it to ``FormStyle/makeBody(configuration:)``.
///
/// ## See Also
///
/// - ``FormStyle``
/// - ``Form``
public struct FormStyleConfiguration {
    /// A type-erased view of a form's rows.
    public struct Content: View {
        /// The form's rows, with their type erased.
        private var erasedContent: AnyView

        @ViewBuilder
        public var body: some View {
            erasedContent
        }

        /// Erases a form's rows.
        ///
        /// - Parameter content: The views making up the form's rows.
        package init(_ content: some View) {
            erasedContent = AnyView(content)
        }
    }

    /// A view that represents the form's rows.
    public var content: Content

    /// Creates a configuration describing a form.
    ///
    /// - Parameter content: A view that represents the form's rows.
    package init(content: Content) {
        self.content = content
    }
}
