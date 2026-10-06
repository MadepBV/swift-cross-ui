/// A type that replaces a button's whole interaction and appearance.
///
/// Where a ``ButtonStyle`` decorates a button's label and leaves the button
/// to handle clicks, a primitive style builds the control itself and calls
/// ``PrimitiveButtonStyleConfiguration/trigger()`` when it decides the button
/// was activated, exactly as in SwiftUI:
///
/// ```swift
/// struct ConfirmingButtonStyle: PrimitiveButtonStyle {
///     func makeBody(configuration: Configuration) -> some View {
///         Button(role: configuration.role) {
///             configuration.trigger()
///         } label: {
///             configuration.label.bold()
///         }
///         .buttonStyle(.bordered)
///     }
/// }
/// ```
///
/// Apply it with ``View/buttonStyle(_:)-(PrimitiveButtonStyle)``. Buttons the
/// style creates inside its body see the button style that was in effect
/// outside it, so the style doesn't apply to itself.
///
/// - Note: The button keeps a chromeless native button around the style's
///   body, which takes no action of its own; activating the style's control
///   is what triggers the button. It means one extra (inert) focus stop with
///   keyboard navigation.
@MainActor
public protocol PrimitiveButtonStyle: Sendable {
    /// A view that represents the body of a button.
    associatedtype Body: View

    /// Creates the view that represents the button.
    ///
    /// - Parameter configuration: The button's label, role and trigger.
    /// - Returns: The button's control.
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body

    /// The properties of the button being styled.
    typealias Configuration = PrimitiveButtonStyleConfiguration
}

/// The properties of a button handed to a ``PrimitiveButtonStyle``.
public struct PrimitiveButtonStyleConfiguration {
    /// A type-erased button label.
    public typealias Label = ButtonStyleConfiguration.Label

    /// The button's label.
    public let label: Label

    /// The button's role, if it has one.
    public let role: ButtonRole?

    /// Performs the button's action.
    private let action: @MainActor () -> Void

    package init(
        label: Label,
        role: ButtonRole?,
        action: @escaping @MainActor () -> Void
    ) {
        self.label = label
        self.role = role
        self.action = action
    }

    /// Performs the button's action.
    @MainActor
    public func trigger() {
        action()
    }
}

extension EnvironmentValues {
    /// The primitive button style set by
    /// ``View/buttonStyle(_:)-(PrimitiveButtonStyle)``, if one is in effect.
    ///
    /// Setting a ``ButtonStyle`` clears it, and setting a primitive style
    /// clears ``buttonStyle``, so the innermost of the two wins.
    @Entry public var primitiveButtonStyle: (any PrimitiveButtonStyle)?
}

extension View {
    /// Sets the style for buttons within this view to a primitive button
    /// style, which builds each button's control itself.
    ///
    /// - Parameter style: The style to use.
    /// - Returns: A view whose descendant buttons use `style`.
    public func buttonStyle<S: PrimitiveButtonStyle>(_ style: S) -> some View {
        EnvironmentModifier(self) { environment in
            environment
                .with(\.primitiveButtonStyle, style)
                .with(\.buttonStyle, nil)
        }
    }
}
