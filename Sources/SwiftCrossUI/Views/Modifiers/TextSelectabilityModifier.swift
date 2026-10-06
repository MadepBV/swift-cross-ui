/// Whether the user can select the text in a view.
///
/// Passed to ``View/textSelection(_:)`` as `.enabled` or `.disabled`.
public struct TextSelectability: Hashable, Sendable {
    let isEnabled: Bool

    /// The text can be selected and copied.
    public static let enabled = TextSelectability(isEnabled: true)
    /// The text can't be selected.
    public static let disabled = TextSelectability(isEnabled: false)
}

extension View {
    /// Sets whether the user can select the text inside this view.
    ///
    /// SwiftUI's spelling of ``View/textSelectionEnabled(_:)``.
    ///
    /// - Parameter selectability: `.enabled` or `.disabled`.
    /// - Returns: A view whose text is selectable or not.
    public func textSelection(_ selectability: TextSelectability) -> some View {
        textSelectionEnabled(selectability.isEnabled)
    }
}
