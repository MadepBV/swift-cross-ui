/// A Liquid Glass material, applied with ``View/glassEffect(_:in:)``.
///
/// Liquid Glass refracts and lenses the content behind it, which only Apple's
/// compositor does. SwiftCrossUI draws glass as its nearest flat
/// counterpart: a translucent neutral (or tinted) fill with a hairline edge,
/// the shape Fluent uses for layered surfaces on Windows.
public struct Glass: Hashable, Sendable {
    /// How the glass is drawn.
    enum Variant: Hashable, Sendable {
        case regular
        case clear
        case identity
    }

    var variant: Variant
    var tint: Color?
    var isInteractive = false

    /// The standard glass material.
    public static let regular = Glass(variant: .regular)
    /// A more transparent glass, for use over rich media.
    public static let clear = Glass(variant: .clear)
    /// No glass: content draws as it would without the effect.
    public static let identity = Glass(variant: .identity)

    /// This glass, tinted.
    ///
    /// - Parameter color: The tint. `nil` removes it.
    /// - Returns: The tinted glass.
    public func tint(_ color: Color?) -> Glass {
        var glass = self
        glass.tint = color
        return glass
    }

    /// This glass, reacting to the pointer and touches.
    ///
    /// - Note: The reaction is a press-and-highlight animation, which
    ///   SwiftCrossUI doesn't draw; the setting is kept so the call site reads
    ///   as in SwiftUI.
    ///
    /// - Parameter isEnabled: Whether the glass is interactive.
    /// - Returns: The glass.
    public func interactive(_ isEnabled: Bool = true) -> Glass {
        var glass = self
        glass.isInteractive = isEnabled
        return glass
    }

    /// The fill drawn for this glass, or `nil` for ``identity``.
    var fill: Color? {
        switch variant {
            case .identity:
                return nil
            case .regular, .clear:
                let opacity = variant == .regular ? 0.6 : 0.3
                if let tint {
                    return tint.opacity(opacity)
                }
                return Color.adaptive(
                    light: Color(white: 0.98, opacity: opacity),
                    dark: Color(white: 0.2, opacity: opacity)
                )
        }
    }

    /// The hairline drawn around this glass.
    static let edge = Color.adaptive(
        light: Color(white: 0.0, opacity: 0.08),
        dark: Color(white: 1.0, opacity: 0.12)
    )
}

extension View {
    /// Places this view on Liquid Glass in the given shape.
    ///
    /// ```swift
    /// TextField("Ask", text: $question)
    ///     .padding()
    ///     .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
    /// ```
    ///
    /// See ``Glass`` for how glass is drawn off Apple platforms.
    ///
    /// - Parameters:
    ///   - glass: The glass to use.
    ///   - shape: The shape of the glass behind the view.
    /// - Returns: The view on glass.
    public func glassEffect<GlassShape: Shape>(
        _ glass: Glass = .regular,
        in shape: GlassShape
    ) -> some View {
        let fill = glass.fill
        return
            self
            .background {
                if let fill {
                    shape.fill(fill)
                    shape.stroke(Glass.edge, lineWidth: 1)
                }
            }
    }

    /// Places this view on Liquid Glass in a capsule.
    ///
    /// - Parameter glass: The glass to use.
    /// - Returns: The view on glass.
    public func glassEffect(_ glass: Glass = .regular) -> some View {
        glassEffect(glass, in: Capsule())
    }

    /// Extends this view's appearance under the safe areas beside it, such as
    /// under a sidebar.
    ///
    /// - Note: No effect: the mirrored, blurred extension is drawn by Apple's
    ///   compositor, and SwiftCrossUI's desktop windows have no safe areas for
    ///   content to extend under.
    ///
    /// - Returns: The view.
    public func backgroundExtensionEffect() -> some View {
        self
    }
}

/// A container that lets the glass of the views inside it blend and morph
/// together.
///
/// SwiftCrossUI draws each view's glass separately (see ``Glass``), so the
/// container lays its content out as a ``Group`` would. `spacing` is accepted
/// for source compatibility: it is the distance at which Apple's glass shapes
/// merge, not a layout spacing.
public struct GlassEffectContainer<Content: View>: View {
    private let content: Content

    /// Creates a glass container.
    ///
    /// - Parameters:
    ///   - spacing: The distance at which glass shapes merge on Apple
    ///     platforms. Not a layout spacing.
    ///   - content: The views inside the container.
    public init(spacing: Double? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
    }
}
