/// The shape of a bordered button's chrome.
///
/// Set with ``View/buttonBorderShape(_:)``.
public struct ButtonBorderShape: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case automatic
        case capsule
        case circle
        case roundedRectangle(radius: Double?)
    }

    var kind: Kind

    /// The platform's default shape.
    public static let automatic = ButtonBorderShape(kind: .automatic)
    /// A capsule.
    public static let capsule = ButtonBorderShape(kind: .capsule)
    /// A circle.
    public static let circle = ButtonBorderShape(kind: .circle)
    /// A rounded rectangle with the platform's radius.
    public static let roundedRectangle = ButtonBorderShape(
        kind: .roundedRectangle(radius: nil)
    )

    /// A rounded rectangle with the given radius.
    ///
    /// - Parameter radius: The corner radius.
    /// - Returns: The shape.
    public static func roundedRectangle(radius: Double) -> ButtonBorderShape {
        ButtonBorderShape(kind: .roundedRectangle(radius: radius))
    }

    /// The corner radius a backend gives a bordered button of `size` with
    /// this shape, or `nil` for the platform's own (``automatic``, and a
    /// rounded rectangle without a radius).
    public func cornerRadius(forSize size: SIMD2<Double>) -> Double? {
        switch kind {
            case .automatic, .roundedRectangle(radius: nil): nil
            case .capsule, .circle: max(0, min(size.x, size.y) / 2)
            case .roundedRectangle(let radius?): radius
        }
    }
}

/// The size of the controls in a view.
///
/// Set with ``View/controlSize(_:)``.
public enum ControlSize: Hashable, Sendable, CaseIterable {
    case mini
    case small
    case regular
    case large
    case extraLarge
}

extension EnvironmentValues {
    /// The button border shape set by ``View/buttonBorderShape(_:)``.
    @Entry public var buttonBorderShape: ButtonBorderShape = .automatic

    /// The control size set by ``View/controlSize(_:)``.
    @Entry public var controlSize: ControlSize = .regular
}

extension View {
    /// Sets the shape of the chrome of bordered buttons inside this view.
    ///
    /// - Note: Backends draw their platform's own button chrome and none
    ///   exposes its shape yet, so the value is recorded in the environment
    ///   (``EnvironmentValues/buttonBorderShape``) but bordered buttons keep
    ///   the platform's shape. A custom ``ButtonStyle`` can read it.
    ///
    /// - Parameter shape: The shape.
    /// - Returns: A view whose buttons use `shape`.
    public func buttonBorderShape(_ shape: ButtonBorderShape) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.buttonBorderShape, shape)
        }
    }

    /// Sets the size of the controls inside this view.
    ///
    /// Progress spinners draw at the requested size. Other controls keep the
    /// platform's standard metrics, which backends don't expose per size;
    /// the value is in ``EnvironmentValues/controlSize`` for views that adapt
    /// to it.
    ///
    /// - Parameter size: The control size.
    /// - Returns: A view whose controls use `size`.
    public func controlSize(_ size: ControlSize) -> some View {
        EnvironmentModifier(self) { environment in
            environment.with(\.controlSize, size)
        }
    }
}
