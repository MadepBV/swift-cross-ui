extension BackendFeatures.AccessibilityProperties {
    /// A labelled detail about a widget, such as a card's rating or
    /// availability, that assistive technologies offer alongside its label.
    ///
    /// The backend-facing counterpart of
    /// ``View/accessibilityCustomContent(_:_:importance:)``.
    public struct CustomContent: Equatable, Sendable {
        /// Identifies the entry, so that a modifier closer to the view
        /// replaces an outer one with the same key.
        public var id: String
        /// What the detail is, e.g. "Rating".
        public var label: String
        /// The detail itself, e.g. "4 stars".
        public var value: String
        /// Whether assistive technologies read the detail automatically,
        /// right after the widget's label, rather than only on request.
        public var isHighImportance: Bool

        /// Creates an entry.
        public init(id: String, label: String, value: String, isHighImportance: Bool) {
            self.id = id
            self.label = label
            self.value = value
            self.isHighImportance = isHighImportance
        }
    }

    /// An action an assistive technology can perform on a widget.
    ///
    /// Two actions are equal when they are of the same kind: the handler is a
    /// closure, and it's replaced on every update anyway, so comparing it
    /// would only defeat the backends' "nothing changed" checks.
    public struct Action: Equatable, Sendable {
        /// What the action does.
        public enum Kind: Hashable, Sendable {
            /// The widget's primary action, as if it had been clicked.
            case `default`
            /// Dismisses the widget or backs out of it.
            case escape
            /// The app's most important action at this moment.
            case magicTap
            /// Increases the widget's value by one step.
            case increment
            /// Decreases the widget's value by one step.
            case decrement
            /// An app-defined action with a user-visible name.
            case named(String)
        }

        /// What the action does.
        public var kind: Kind
        /// Performs the action.
        public var handler: @MainActor @Sendable () -> Void

        /// Creates an action.
        public init(kind: Kind, handler: @escaping @MainActor @Sendable () -> Void) {
            self.kind = kind
            self.handler = handler
        }

        /// The name an assistive technology reads out for the action, for
        /// backends that expose every action as a named custom action.
        public var name: String {
            switch kind {
                case .default: "Activate"
                case .escape: "Dismiss"
                case .magicTap: "Magic Tap"
                case .increment: "Increment"
                case .decrement: "Decrement"
                case .named(let name): name
            }
        }

        public static func == (lhs: Action, rhs: Action) -> Bool {
            lhs.kind == rhs.kind
        }
    }

    /// The high-importance custom content, written out as sentences, for
    /// backends that have no custom-content API and append it to the widget's
    /// description instead (`"Match: Great match. Status: In your library."`).
    ///
    /// `nil` when there is no high-importance content.
    public var customContentDescription: String? {
        let sentences = customContent
            .filter(\.isHighImportance)
            .map { "\($0.label): \($0.value)" }
        guard !sentences.isEmpty else {
            return nil
        }
        return sentences.joined(separator: ". ")
    }

    /// The hint with the high-importance custom content appended, for
    /// backends that fold custom content into the help text.
    public var hintIncludingCustomContent: String? {
        switch (hint, customContentDescription) {
            case (let hint?, let content?): "\(content). \(hint)"
            case (let hint?, nil): hint
            case (nil, let content?): content
            case (nil, nil): nil
        }
    }
}
