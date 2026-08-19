extension View {
    /// Sets the style for forms within this view.
    ///
    /// The style is read by every ``Form`` and ``Section`` beneath this view,
    /// so apply it to the form itself (or to a common ancestor of several
    /// forms).
    ///
    /// ```swift
    /// Form {
    ///     Section("Drafting parameters") {
    ///         Toggle("Snap to grid", active: $snapToGrid)
    ///     }
    /// }
    /// .formStyle(.grouped)
    /// ```
    ///
    /// - Parameter style: The form style to use.
    /// - Returns: A view whose descendant forms and sections use `style`.
    ///
    /// ## See Also
    ///
    /// - ``FormStyle``
    public func formStyle(_ style: any FormStyle) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.formStyle, style)
        }
    }
}

extension EnvironmentValues {
    /// The display style used by ``Form`` and ``Section``.
    ///
    /// Set this with ``View/formStyle(_:)`` rather than mutating the
    /// environment directly.
    @Entry public var formStyle: any FormStyle = .automatic
}
