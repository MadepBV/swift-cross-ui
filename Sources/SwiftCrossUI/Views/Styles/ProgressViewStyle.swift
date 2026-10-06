/// How a ``ProgressView`` shows progress.
///
/// Set with ``View/progressViewStyle(_:)``.
public struct ProgressViewStyle: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case automatic
        case linear
        case circular
    }

    let kind: Kind

    /// A bar for known progress, a spinner otherwise.
    public static let automatic = ProgressViewStyle(kind: .automatic)
    /// A bar, which runs indeterminately when progress is unknown.
    public static let linear = ProgressViewStyle(kind: .linear)
    /// A spinner.
    ///
    /// - Note: Backends draw only an indeterminate spinner, so a circular
    ///   view with a known value is drawn as a bar rather than hide the
    ///   value.
    public static let circular = ProgressViewStyle(kind: .circular)

    /// Whether to draw a bar (`true`) or a spinner (`false`).
    ///
    /// - Parameters:
    ///   - isBarByDefault: What the view would draw under ``automatic``.
    ///   - hasValue: Whether the view knows its progress.
    func kind(default isBarByDefault: Bool, hasValue: Bool) -> ProgressIndicatorKind {
        switch kind {
            case .automatic: isBarByDefault ? .bar : .spinner
            case .linear: .bar
            case .circular: hasValue ? .bar : .spinner
        }
    }
}

/// The two indicators backends draw.
enum ProgressIndicatorKind {
    case spinner
    case bar
}

extension ControlSize {
    /// How much larger than the platform's standard spinner a spinner of
    /// this size is, following AppKit's spinner sizes.
    var spinnerScale: Double {
        switch self {
            case .mini: 0.5
            case .small: 0.5
            case .regular: 1
            case .large: 1.25
            case .extraLarge: 1.5
        }
    }
}

extension EnvironmentValues {
    /// The progress view style set by ``View/progressViewStyle(_:)``.
    @Entry public var progressViewStyle: ProgressViewStyle = .automatic
}

extension View {
    /// Sets the style of the progress views inside this view.
    ///
    /// - Parameter style: `.linear`, `.circular` or `.automatic`.
    /// - Returns: A view whose progress views use `style`.
    public func progressViewStyle(_ style: ProgressViewStyle) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.progressViewStyle, style)
        }
    }
}
