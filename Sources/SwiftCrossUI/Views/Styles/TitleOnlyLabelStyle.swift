/// A label style that only shows the label's title.
///
/// A label created without a title falls back to showing its icon, for the
/// same reason that ``IconOnlyLabelStyle`` falls back to the title: a label
/// that renders as nothing at all would leave an enclosing control unusable.
public struct TitleOnlyLabelStyle: LabelStyle {
    public nonisolated init() {}

    public func makeBody(configuration: Configuration) -> some View {
        if configuration.titleIsAvailable {
            configuration.title
        } else {
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TitleOnlyLabelStyle {
    /// A label style that only shows the label's title.
    public static nonisolated var titleOnly: Self { Self() }
}
