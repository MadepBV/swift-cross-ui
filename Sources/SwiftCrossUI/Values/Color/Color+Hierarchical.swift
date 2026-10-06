extension Color {
    /// A level in the hierarchy of foreground content.
    ///
    /// Each level is the current foreground colour at a lower opacity, so
    /// relative emphasis survives whatever colour the foreground is. The
    /// opacities follow Apple's label colours (`secondaryLabel` and friends).
    enum HierarchicalLevel: Int, Sendable, Hashable, CaseIterable {
        case primary
        case secondary
        case tertiary
        case quaternary
        case quinary

        /// The opacity this level applies to the foreground colour.
        var opacity: Double {
            switch self {
                case .primary: 1
                case .secondary: 0.6
                case .tertiary: 0.3
                case .quaternary: 0.18
                case .quinary: 0.1
            }
        }
    }

    /// The current foreground style.
    ///
    /// Inside `.foregroundStyle(.orange)` this is orange; with no foreground
    /// style set it is the colour scheme's label colour. In SwiftUI the
    /// same spelling at a `ShapeStyle` parameter is `HierarchicalShapeStyle`;
    /// SwiftCrossUI folds the hierarchy into ``Color`` so that every call site
    /// (whether it takes a `Color` or any ``ShapeStyle``) reads the same.
    public static let primary = Color(representation: .hierarchical(.primary))

    /// The current foreground style at secondary emphasis.
    ///
    /// `.foregroundStyle(.secondary)` dims whatever foreground colour the
    /// surrounding hierarchy chose, exactly as in SwiftUI, rather than always
    /// being a fixed grey.
    public static let secondary = Color(representation: .hierarchical(.secondary))

    /// The current foreground style at tertiary emphasis.
    public static let tertiary = Color(representation: .hierarchical(.tertiary))

    /// The current foreground style at quaternary emphasis.
    public static let quaternary = Color(representation: .hierarchical(.quaternary))

    /// The current foreground style at quinary emphasis.
    public static let quinary = Color(representation: .hierarchical(.quinary))

    /// The tint of the enclosing view hierarchy, set with ``View/tint(_:)``.
    ///
    /// Falls back to ``Color/accentColor`` where no tint is set.
    public static let tint = Color(representation: .tint)

    /// The app's accent colour.
    ///
    /// SwiftUI reads this from the app's asset catalogue. SwiftCrossUI has no
    /// asset catalogue, so it is the platform-tailored system blue, which is
    /// what an app without a configured accent gets on Apple platforms too.
    public static let accentColor = Color.system(.blue)

    /// Whether this colour is a level of the environment's foreground colour.
    var refersToForeground: Bool {
        switch representation {
            case .hierarchical: true
            case .rgb, .system, .tint: false
            case .adaptive(let light, let dark):
                light.refersToForeground || dark.refersToForeground
        }
    }

    /// Whether this colour can only be resolved relative to another colour in
    /// the environment (the foreground or the tint).
    var dependsOnEnvironmentStyle: Bool {
        switch representation {
            case .hierarchical, .tint: true
            case .rgb, .system: false
            case .adaptive(let light, let dark):
                light.dependsOnEnvironmentStyle || dark.dependsOnEnvironmentStyle
        }
    }

    /// The colour hierarchical levels are derived from in `environment`.
    @MainActor
    static func hierarchicalBase(in environment: EnvironmentValues) -> Color {
        // A foreground that is itself hierarchical was stored without an
        // outer style to bind to (see `bindingStyle(in:)`), so it derives from
        // the label colour, as it does in SwiftUI at the root of a hierarchy.
        // A tinted foreground is fine: the tint never resolves through the
        // foreground (see `tintBase(in:)`), so this cannot cycle.
        if let foreground = environment.foregroundColor,
            !foreground.refersToForeground
        {
            return foreground
        }
        return environment.colorScheme.defaultForegroundColor
    }

    /// The colour ``Color/tint`` stands for in `environment`.
    @MainActor
    static func tintBase(in environment: EnvironmentValues) -> Color {
        if let tint = environment.tintColor, !tint.dependsOnEnvironmentStyle {
            return tint
        }
        return .accentColor
    }

    /// Binds a colour that refers to the environment's own styles to the
    /// styles in effect *outside* the view setting it.
    ///
    /// `.foregroundStyle(.secondary)` inside `.foregroundStyle(.orange)`
    /// means "orange at secondary emphasis". Once the inner modifier has
    /// replaced the foreground colour, the orange is gone from the
    /// environment, so the reference is resolved here, while the outer value
    /// is still available.
    ///
    /// - Parameter environment: The environment outside the modifier.
    /// - Returns: A colour that no longer refers to the foreground it is about
    ///   to replace.
    func bindingStyle(in environment: EnvironmentValues) -> Color {
        switch representation {
            case .hierarchical(let level):
                guard let outer = environment.foregroundColor else {
                    // Nothing to bind to: resolves against the label colour.
                    return self
                }
                return outer.bindingStyle(in: environment)
                    .opacity(level.opacity * opacityMultiplier)
            case .tint:
                // The tint lives in its own environment value, which the
                // foreground never replaces, so it can resolve where it's used.
                return self
            case .adaptive(let light, let dark):
                return Color(
                    representation: .adaptive(
                        light: light.bindingStyle(in: environment),
                        dark: dark.bindingStyle(in: environment)
                    ),
                    opacityMultiplier: opacityMultiplier
                )
            case .rgb, .system:
                return self
        }
    }
}
