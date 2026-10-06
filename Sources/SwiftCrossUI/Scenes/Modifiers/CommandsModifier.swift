extension Scene {
    /// Adds menu commands to this scene.
    ///
    /// The commands will typically be displayed in the system's global menu bar
    /// if it has one, or in individual windows' menu bars otherwise.
    ///
    /// - Parameter commands: The commands to add.
    @MainActor
    public func commands<Content: Commands>(
        @CommandsBuilder _ commands: () -> Content
    ) -> some Scene {
        CommandsModifier(content: self, commands: ResolvedCommands(commands()))
    }
}

struct CommandsModifier<Content: Scene>: Scene {
    typealias Node = CommandsModifierNode<Content>

    var content: Content
    var commands: ResolvedCommands

    init(content: Content, commands: ResolvedCommands) {
        self.content = content
        self.commands = commands
    }
}

final class CommandsModifierNode<Content: Scene>: SceneGraphNode {
    typealias NodeScene = CommandsModifier<Content>

    var commands: ResolvedCommands
    var contentNode: Content.Node

    init<Backend: BaseAppBackend>(
        from scene: NodeScene,
        backend: Backend,
        environment: EnvironmentValues
    ) {
        self.commands = scene.commands
        self.contentNode = Content.Node(
            from: scene.content,
            backend: backend,
            environment: environment
        )
    }

    func updateNode(
        _ newScene: NodeScene?,
        environment: EnvironmentValues
    ) -> SceneNodeUpdateResult {
        if let newScene {
            self.commands = newScene.commands
        }

        var result = contentNode.updateNode(newScene?.content, environment: environment)
        result.preferences.commands = result.preferences.commands.overlayed(with: commands)
        return result
    }

    func update<Backend: BaseAppBackend>(
        backend: Backend,
        environment: EnvironmentValues
    ) {
        contentNode.update(
            backend: backend,
            environment: environment
        )
    }
}
