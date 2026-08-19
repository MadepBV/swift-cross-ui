/// A form style that visually groups each ``Section``'s rows together and
/// insets the form's content.
///
/// This is the closest match to the grouped forms that macOS uses for settings
/// windows and inspectors.
public struct GroupedFormStyle: FormStyle, _BuiltinFormStyle {
    public nonisolated init() {}

    package nonisolated var formMetrics: FormMetrics { .grouped }

    public func makeBody(configuration: Configuration) -> some View {
        makeBuiltinBody(configuration: configuration)
    }
}

extension FormStyle where Self == GroupedFormStyle {
    /// A form style that visually groups each ``Section``'s rows together and
    /// insets the form's content.
    ///
    /// This is the closest match to the grouped forms that macOS uses for
    /// settings windows and inspectors.
    public static nonisolated var grouped: Self { Self() }
}
