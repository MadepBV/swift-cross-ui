extension View {
    /// Presents content over the whole window while `isPresented` is true.
    ///
    /// The content covers this view and fills it, which for an app's root view is the window, as SwiftUI's cover
    /// fills the screen; the view underneath stays mounted. `onDismiss` runs when the content goes away.
    ///
    /// - Parameters:
    ///   - isPresented: Whether the content is presented.
    ///   - onDismiss: Run when the content is dismissed.
    ///   - content: The content to present.
    @available(macOS, unavailable)
    public func fullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onDisappear { onDismiss?() }
            }
        }
    }
}
