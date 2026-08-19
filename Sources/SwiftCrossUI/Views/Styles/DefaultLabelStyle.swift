/// A label style that resolves its appearance based on the label's context.
///
/// SwiftCrossUI currently resolves this to ``TitleAndIconLabelStyle`` in every
/// context, matching SwiftUI's behaviour outside of a handful of
/// Apple-specific containers.
public struct DefaultLabelStyle: LabelStyle {
    public nonisolated init() {}

    public func makeBody(configuration: Configuration) -> some View {
        TitleAndIconLabelStyle().makeBody(configuration: configuration)
    }
}

extension LabelStyle where Self == DefaultLabelStyle {
    /// A label style that resolves its appearance based on the label's
    /// context.
    ///
    /// SwiftCrossUI currently resolves this to ``LabelStyle/titleAndIcon`` in
    /// every context, matching SwiftUI's behaviour outside of a handful of
    /// Apple-specific containers.
    public static nonisolated var automatic: Self { Self() }
}
