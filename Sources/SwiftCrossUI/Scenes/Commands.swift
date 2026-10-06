/// A type that describes menu bar commands.
///
/// ``CommandMenu`` and ``CommandGroup`` are the primitive commands; a type of
/// your own conforms by composing them in its `body`, exactly as in SwiftUI,
/// and may read focused values to enable its items:
///
/// ```swift
/// struct EditorCommands: Commands {
///     @FocusedValue(\.document) private var document
///
///     var body: some Commands {
///         CommandMenu("Shape") {
///             Button("Mirror") { document?.mirror() }
///                 .disabled(document == nil)
///         }
///     }
/// }
/// ```
///
/// A type's `body` is read whenever the menu bar is rebuilt: when the scene
/// graph updates, and whenever a focused value changes.
@MainActor
public protocol Commands {
    /// The type of commands this type is made of.
    associatedtype Body: Commands

    /// The commands this type is made of.
    @CommandsBuilder
    var body: Body { get }

    /// The menus these commands contribute, in order.
    ///
    /// Implemented by SwiftCrossUI's primitive commands; the default reads
    /// ``body`` after installing the current environment on this value's
    /// dynamic properties. Don't implement it yourself.
    var _commandMenus: [CommandMenu] { get }
}

extension Commands {
    public var _commandMenus: [CommandMenu] {
        MenuItemCollection.prepareProperties(of: self)
        return body._commandMenus
    }
}

extension Commands where Body == Never {
    public var body: Never {
        fatalError("\(Self.self) is a primitive command and has no body")
    }
}

extension Never: Commands {
    public var _commandMenus: [CommandMenu] {
        []
    }
}

/// No commands.
public struct EmptyCommands: Commands {
    public typealias Body = Never

    /// Creates an empty set of commands.
    public init() {}

    public var _commandMenus: [CommandMenu] {
        []
    }
}

/// A list of commands, as built by ``CommandsBuilder``.
///
/// The commands are kept unevaluated, so that a type's `body` is read each
/// time the menu bar is rebuilt rather than once when the scene is built.
public struct _CommandsList: Commands {
    public typealias Body = Never

    /// The commands' menus, read on demand.
    let sources: [@MainActor () -> [CommandMenu]]

    public var _commandMenus: [CommandMenu] {
        sources.flatMap { $0() }
    }
}

/// The menus a scene's commands resolve to, as propagated up the scene graph.
public struct ResolvedCommands {
    /// No menus.
    public static var empty: ResolvedCommands {
        ResolvedCommands(sources: [])
    }

    /// The commands, outermost scene first, read on demand.
    var sources: [@MainActor () -> [CommandMenu]]

    /// Creates resolved commands from some commands.
    ///
    /// - Parameter commands: The commands.
    @MainActor
    init(_ commands: some Commands) {
        sources = [{ commands._commandMenus }]
    }

    /// Creates resolved commands from their sources.
    ///
    /// - Parameter sources: The sources.
    init(sources: [@MainActor () -> [CommandMenu]]) {
        self.sources = sources
    }

    /// Overlays `newCommands` onto `self`.
    ///
    /// If top-level menus in `newCommands` and `self` have conflicting names,
    /// the menus get merged, with the items from `self`'s menu first, followed
    /// by the items from `newCommands`'s menus.
    ///
    /// - Parameter newCommands: The commands to overlay.
    /// - Returns: The overlayed commands.
    public func overlayed(with newCommands: ResolvedCommands) -> ResolvedCommands {
        ResolvedCommands(sources: sources + newCommands.sources)
    }

    /// The menus, with menus of the same name merged into the first one.
    @MainActor
    var menus: [CommandMenu] {
        var menus: [CommandMenu] = []
        var indicesByName: [String: Int] = [:]
        for menu in sources.flatMap({ $0() }) {
            if let index = indicesByName[menu.name] {
                menus[index] = CommandMenu(name: menu.name, merging: [menus[index], menu])
            } else {
                indicesByName[menu.name] = menus.count
                menus.append(menu)
            }
        }
        return menus
    }

    /// Resolves the menus to a representation used by backends.
    @MainActor
    func resolve() -> [ResolvedMenu.Submenu] {
        menus.map { menu in
            menu.resolve()
        }
    }
}
