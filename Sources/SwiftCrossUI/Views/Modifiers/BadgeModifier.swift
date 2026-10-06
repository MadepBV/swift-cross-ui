extension View {
    /// Shows a count after this view, as SwiftUI does for a list row, a tab
    /// or a toolbar item.
    ///
    /// ```swift
    /// NavigationLink("Activity", value: Destination.activity)
    ///     .badge(activeRequests)
    /// ```
    ///
    /// A count of zero shows no badge, as in SwiftUI. The badge is drawn as
    /// SwiftUI draws a list row's badge on the Mac: secondary text after the
    /// row's content, read out after its label.
    ///
    /// - Parameter count: The count to show.
    /// - Returns: The view with its badge.
    public func badge(_ count: Int) -> some View {
        badge(count == 0 ? nil : Text("\(count)"))
    }

    /// Shows a piece of text after this view as a badge, or none when
    /// `label` is `nil`. See ``View/badge(_:)-(Int)``.
    ///
    /// - Parameter label: The badge's text.
    /// - Returns: The view with its badge.
    public func badge(_ label: Text?) -> some View {
        HStack(spacing: 8) {
            self
            if let label {
                label
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    /// Shows a string after this view as a badge, or none when `label` is
    /// `nil`. See ``View/badge(_:)-(Int)``.
    ///
    /// - Parameter label: The badge's text.
    /// - Returns: The view with its badge.
    public func badge<S: StringProtocol>(_ label: S?) -> some View {
        badge(label.map { Text(String($0)) })
    }
}
