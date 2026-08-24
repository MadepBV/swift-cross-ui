/// The environment in force while a view's menu items are being collected.
///
/// Menu content (``Menu``, ``View/contextMenu(menuItems:)``, alerts and the
/// application's ``Commands``) is turned into ``MenuItem``s by reading each
/// view's ``View/_asMenuItems``, whose default implementation reads `body`.
/// That happens outside the view graph, so nothing else would install a
/// view's `@Environment` values first — and a body such as ``Section``'s
/// (which reads `\.formStyle`) or ``Picker``'s (which reads the whole
/// environment) would trap.
///
/// Collection is therefore wrapped in ``withEnvironment(_:_:)`` wherever an
/// environment is at hand, and ``View/_asMenuItems``'s default runs
/// ``prepare(_:)`` on the view before touching its body, exactly as
/// ``PickerOptionCollector`` does for picker options.
@MainActor
enum MenuItemCollection {
    /// The environment installed on views before their bodies are read, or
    /// `nil` outside a collection that has one.
    private(set) static var environment: EnvironmentValues?

    /// Runs a collection with the given environment in force.
    ///
    /// - Parameters:
    ///   - environment: The environment to install on views whose bodies
    ///     get read.
    ///   - work: The collection to run.
    /// - Returns: Whatever `work` returns.
    static func withEnvironment<Result>(
        _ environment: EnvironmentValues,
        _ work: () throws -> Result
    ) rethrows -> Result {
        let previous = Self.environment
        Self.environment = environment
        defer { Self.environment = previous }
        return try work()
    }

    /// Installs the current collection environment on a view's dynamic
    /// properties, so that its `body` can be read.
    ///
    /// Does nothing outside a collection with an environment; a view whose
    /// body reads `@Environment` then traps as before, which is why every
    /// collection site passes one when it can.
    ///
    /// - Parameter view: The view about to have its body read.
    static func prepare<V: View>(_ view: V) {
        guard let environment else {
            return
        }
        DynamicPropertyUpdater(for: view).update(view, with: environment, previousValue: nil)
    }
}
