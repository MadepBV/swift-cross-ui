/// A form style with a leading label column.
///
/// SwiftCrossUI currently renders this identically to ``AutomaticFormStyle``.
/// Use ``LabeledContent`` within the form's rows to line labels up in a
/// column.
public struct ColumnsFormStyle: FormStyle, _BuiltinFormStyle {
    public nonisolated init() {}

    package nonisolated var formMetrics: FormMetrics { .automatic }

    public func makeBody(configuration: Configuration) -> some View {
        makeBuiltinBody(configuration: configuration)
    }
}

extension FormStyle where Self == ColumnsFormStyle {
    /// A form style with a leading label column.
    ///
    /// SwiftCrossUI currently renders this identically to
    /// ``FormStyle/automatic``. Use ``LabeledContent`` within the form's rows
    /// to line labels up in a column.
    public static nonisolated var columns: Self { Self() }
}
