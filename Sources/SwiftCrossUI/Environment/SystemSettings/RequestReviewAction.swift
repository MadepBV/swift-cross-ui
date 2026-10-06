/// An action that asks the system to show its prompt for rating the app.
///
/// Read it with `@Environment(\.requestReview)` and call it as a function.
///
/// Calling it does nothing: the platforms SwiftCrossUI's desktop backends run
/// on have no system rating prompt (SwiftUI's comes from the App Store's
/// `SKStoreReviewController`). Apple's guidance is that the prompt may not
/// appear anyway, so apps must not depend on it.
@MainActor
public struct RequestReviewAction {
    nonisolated init() {}

    /// Asks for a rating prompt. Does nothing; see ``RequestReviewAction``.
    public func callAsFunction() {}
}
