/// Why a view's content is hidden behind placeholder shapes.
public struct RedactionReasons: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The content is a placeholder for data that is still loading.
    public static let placeholder = RedactionReasons(rawValue: 1 << 0)
    /// The content is private and hidden while the device is locked.
    public static let privacy = RedactionReasons(rawValue: 1 << 1)
    /// The content is stale and will be replaced.
    public static let invalidated = RedactionReasons(rawValue: 1 << 2)
}

extension EnvironmentValues {
    /// Why the content of the current view is redacted, if it is. Set by
    /// ``View/redacted(reason:)``.
    @Entry public var redactionReasons: RedactionReasons = []
}

extension View {
    /// Draws this view's content as a placeholder.
    ///
    /// ```swift
    /// ShelfRow(item: .sample)
    ///     .redacted(reason: .placeholder)
    /// ```
    ///
    /// SwiftUI replaces each glyph run with a rounded bar. SwiftCrossUI's
    /// text is drawn by the backend, which has no such mode, so for
    /// ``RedactionReasons/placeholder`` and ``RedactionReasons/privacy`` the
    /// content is drawn in the neutral placeholder fill (`.fill`) instead of
    /// its own colours: text and symbols keep their shape and size but read
    /// as faint silhouettes. Content that sets its own colour explicitly keeps
    /// it. Views can read ``EnvironmentValues/redactionReasons`` to adapt
    /// further.
    ///
    /// - Parameter reason: Why the content is redacted. An empty set shows
    ///   the content as is.
    /// - Returns: The redacted view.
    public func redacted(reason: RedactionReasons) -> some View {
        EnvironmentModifier(self) { environment in
            let reasons = environment.redactionReasons.union(reason)
            var environment = environment.with(\.redactionReasons, reasons)
            if !reasons.isDisjoint(with: [.placeholder, .privacy]) {
                environment = environment.with(
                    \.foregroundColor,
                    FillShapeStyle.primary._color
                )
            }
            return environment
        }
    }

    /// Shows this view's content even inside a redacted view.
    ///
    /// - Returns: The view, unredacted.
    public func unredacted() -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.redactionReasons, [])
        }
    }
}
