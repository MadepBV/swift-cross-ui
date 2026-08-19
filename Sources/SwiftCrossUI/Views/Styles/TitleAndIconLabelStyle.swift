/// A label style that shows both the title and the icon, with the icon
/// leading the title.
///
/// A label that can only render one of its two parts shows that part on its
/// own; see ``LabelStyleConfiguration/iconIsAvailable``.
public struct TitleAndIconLabelStyle: LabelStyle {
    public nonisolated init() {}

    /// The amount of spacing between a label's icon and its title.
    ///
    /// Deliberately tighter than the default stack spacing so that an icon and
    /// its title read as a single unit rather than as two adjacent views.
    private static var iconSpacing: Int { 5 }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Self.iconSpacing) {
            if configuration.iconIsAvailable {
                configuration.icon
            }
            if configuration.titleIsAvailable {
                configuration.title
            }
        }
    }
}

extension LabelStyle where Self == TitleAndIconLabelStyle {
    /// A label style that shows both the title and the icon, with the icon
    /// leading the title.
    public static nonisolated var titleAndIcon: Self { Self() }
}
