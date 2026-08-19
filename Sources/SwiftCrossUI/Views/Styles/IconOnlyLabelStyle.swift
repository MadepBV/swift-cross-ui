/// A label style that only shows the label's icon.
///
/// If the label has no icon to show (which is the case for the asset names
/// passed to ``Label/init(_:image:)``, since SwiftCrossUI has no asset
/// catalog), the label falls back to showing its title so that it never
/// renders as nothing at all. An empty label would leave an enclosing control
/// such as a ``Button`` with no clickable area. See ``Label`` for details.
public struct IconOnlyLabelStyle: LabelStyle {
    public nonisolated init() {}

    public func makeBody(configuration: Configuration) -> some View {
        if configuration.iconIsAvailable {
            configuration.icon
        } else {
            configuration.title
        }
    }
}

extension LabelStyle where Self == IconOnlyLabelStyle {
    /// A label style that only shows the label's icon.
    ///
    /// A label with no renderable icon falls back to its title. See
    /// ``IconOnlyLabelStyle`` for details.
    public static nonisolated var iconOnly: Self { Self() }
}
