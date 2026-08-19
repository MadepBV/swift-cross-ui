/// The form style that reflects the platform's default.
///
/// Lays the form out as a plain vertical stack of rows, leaving the
/// surrounding view hierarchy in charge of insetting the form.
public struct AutomaticFormStyle: FormStyle, _BuiltinFormStyle {
    public nonisolated init() {}

    package nonisolated var formMetrics: FormMetrics { .automatic }

    public func makeBody(configuration: Configuration) -> some View {
        makeBuiltinBody(configuration: configuration)
    }
}

extension FormStyle where Self == AutomaticFormStyle {
    /// The form style that reflects the platform's default.
    ///
    /// Lays the form out as a plain vertical stack of rows, leaving the
    /// surrounding view hierarchy in charge of insetting the form.
    public static nonisolated var automatic: Self { Self() }
}
