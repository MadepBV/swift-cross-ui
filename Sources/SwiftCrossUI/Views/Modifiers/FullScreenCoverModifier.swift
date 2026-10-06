extension View {
    /// Presents content over the whole window while `isPresented` is true.
    ///
    /// - Note: Desktop backends have no separate full-screen presentation, so
    ///   the content is presented the way ``View/sheet(isPresented:onDismiss:content:)``
    ///   presents it.
    ///
    /// - Parameters:
    ///   - isPresented: Whether the content is presented.
    ///   - onDismiss: Run when the viewer dismisses it.
    ///   - content: The content to present.
    @available(macOS, unavailable)
    public func fullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
    }
}
