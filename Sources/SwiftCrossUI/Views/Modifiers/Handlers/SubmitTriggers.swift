/// The kinds of field whose submission ``View/onSubmit(of:_:)`` responds to.
public struct SubmitTriggers: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Text fields and secure fields.
    public static let text = SubmitTriggers(rawValue: 1 << 0)
    /// The search field of
    /// ``View/searchable(text:placement:prompt:)-(_,_,String)``.
    public static let search = SubmitTriggers(rawValue: 1 << 1)
}

extension EnvironmentValues {
    /// What to do when the user submits a search field, set by
    /// ``View/onSubmit(of:_:)`` and read by
    /// ``View/searchable(text:placement:prompt:)-(_,_,String)``.
    @Entry var onSearchSubmit: (@MainActor @Sendable () -> Void)? = nil
}

extension View {
    /// Adds an action to perform when the user submits a field of the given
    /// kinds within this view.
    ///
    /// ``SubmitTriggers/text`` behaves as ``View/onSubmit(perform:)``;
    /// ``SubmitTriggers/search`` responds to the search field that
    /// ``View/searchable(text:placement:prompt:)-(_,_,String)`` adds inside
    /// this view. Outer actions run before inner ones.
    ///
    /// - Parameters:
    ///   - triggers: The kinds of field to respond to.
    ///   - action: The action to perform.
    /// - Returns: A view that performs `action` on submission.
    public func onSubmit(
        of triggers: SubmitTriggers = .text,
        _ action: @escaping () -> Void
    ) -> some View {
        EnvironmentModifier(self) { environment in
            var environment = environment
            if triggers.contains(.text) {
                let outer = environment.onSubmit
                environment.onSubmit = {
                    outer?()
                    action()
                }
            }
            if triggers.contains(.search) {
                let outer = environment.onSearchSubmit
                environment.onSearchSubmit = {
                    outer?()
                    action()
                }
            }
            return environment
        }
    }
}
