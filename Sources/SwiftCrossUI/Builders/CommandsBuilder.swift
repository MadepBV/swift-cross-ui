/// A result builder for ``Commands``.
///
/// Combines commands with `if`, `if let`, `switch` and `#if`, as SwiftUI's
/// does.
@MainActor
@resultBuilder
public struct CommandsBuilder {
    public static func buildExpression(_ commands: some Commands) -> _CommandsList {
        _CommandsList(sources: [{ commands._commandMenus }])
    }

    public static func buildBlock() -> _CommandsList {
        _CommandsList(sources: [])
    }

    public static func buildBlock(_ components: _CommandsList...) -> _CommandsList {
        _CommandsList(sources: components.flatMap(\.sources))
    }

    public static func buildOptional(_ component: _CommandsList?) -> _CommandsList {
        component ?? _CommandsList(sources: [])
    }

    public static func buildEither(first component: _CommandsList) -> _CommandsList {
        component
    }

    public static func buildEither(second component: _CommandsList) -> _CommandsList {
        component
    }

    public static func buildLimitedAvailability(_ component: _CommandsList) -> _CommandsList {
        component
    }
}
