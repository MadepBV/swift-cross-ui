/// An action that refreshes the content of a view, installed with
/// ``View/refreshable(action:)``.
///
/// Read it from the environment to offer a refresh of your own:
///
/// ```swift
/// struct RefreshButton: View {
///     @Environment(\.refresh) private var refresh
///
///     var body: some View {
///         if let refresh {
///             Button("Refresh") { Task { await refresh() } }
///                 .keyboardShortcut("r")
///         }
///     }
/// }
/// ```
public struct RefreshAction: Sendable {
    private let action: @Sendable () async -> Void

    init(action: @escaping @Sendable () async -> Void) {
        self.action = action
    }

    /// Refreshes the content, returning when the refresh has finished.
    public func callAsFunction() async {
        await action()
    }
}

extension EnvironmentValues {
    /// The refresh action of the nearest ``View/refreshable(action:)``, or
    /// `nil` when nothing above this view is refreshable.
    @Entry public var refresh: RefreshAction? = nil
}

extension View {
    /// Makes this view's content refreshable.
    ///
    /// ```swift
    /// List(items) { item in Row(item) }
    ///     .refreshable { await model.reload() }
    /// ```
    ///
    /// The action is put in the environment as ``EnvironmentValues/refresh``,
    /// where SwiftUI puts it too. SwiftUI's own refresh gesture is a pull
    /// past the top of a scroll view on iOS; the Mac has no refresh gesture,
    /// and neither do SwiftCrossUI's desktop backends, so on the desktop the
    /// action runs when a view reads it from the environment and calls it,
    /// such as a Refresh button or menu command. No backend draws a pull-to-
    /// refresh control yet.
    ///
    /// - Parameter action: Refreshes the content; the refresh is over when it
    ///   returns.
    /// - Returns: A view whose descendants can refresh it.
    public func refreshable(action: @escaping @Sendable () async -> Void) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.refresh, RefreshAction(action: action))
        }
    }
}
