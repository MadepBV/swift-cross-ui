extension View {
    /// Adds a search field to the enclosing navigation container's bar,
    /// bound to `text`.
    ///
    /// Filter what the view shows by `text`; the field updates it on every
    /// keystroke. Submitting the field (Return or Enter) runs the actions
    /// installed with ``View/onSubmit(of:_:)`` and ``SubmitTriggers/search``
    /// around this view. Outside any navigation container the view draws a
    /// bar of its own, holding just the field.
    ///
    /// - Parameters:
    ///   - text: The search text.
    ///   - placement: Where the field goes; see ``SearchFieldPlacement``.
    ///   - prompt: The field's placeholder.
    /// - Returns: A searchable view.
    public func searchable(
        text: Binding<String>,
        placement: SearchFieldPlacement = .automatic,
        prompt: String
    ) -> some View {
        SearchableModifier(text: text, placement: placement, prompt: prompt, content: self)
    }

    /// Adds a search field to the enclosing navigation container's bar,
    /// bound to `text`, with a text view as its placeholder.
    ///
    /// Only the text's string is used.
    ///
    /// - Parameters:
    ///   - text: The search text.
    ///   - placement: Where the field goes; see ``SearchFieldPlacement``.
    ///   - prompt: The field's placeholder, or `nil` for the default "Search".
    /// - Returns: A searchable view.
    public func searchable(
        text: Binding<String>,
        placement: SearchFieldPlacement = .automatic,
        prompt: Text? = nil
    ) -> some View {
        searchable(
            text: text,
            placement: placement,
            prompt: prompt?.string ?? SearchableModifier<Self>.defaultPrompt
        )
    }
}

/// Contributes a search field to the enclosing navigation container's bar.
struct SearchableModifier<Content: View>: View {
    /// The placeholder of a field that wasn't given one.
    static var defaultPrompt: String { "Search" }

    /// The search text.
    var text: Binding<String>
    /// Where the field goes.
    var placement: SearchFieldPlacement
    /// The field's placeholder.
    var prompt: String
    /// The modified view.
    var content: Content

    @Environment(\.onSearchSubmit) private var onSearchSubmit

    var body: some View {
        NavigationChromeContributor(
            contribution: .search(
                SearchFieldContribution(
                    text: text,
                    placement: placement,
                    prompt: prompt,
                    onSubmit: onSearchSubmit
                )
            ),
            hostsWhenAlone: true,
            content: content
        )
    }
}
