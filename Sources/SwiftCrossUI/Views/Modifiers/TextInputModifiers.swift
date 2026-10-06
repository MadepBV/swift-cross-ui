/// The label of the return key of an on-screen keyboard.
///
/// Only touch keyboards label their return key, and none of SwiftCrossUI's
/// backends exposes that label yet; see ``View/submitLabel(_:)``.
public struct SubmitLabel: Hashable, Sendable {
    /// The label's identity.
    private let rawValue: Int

    /// Done.
    public static let done = SubmitLabel(rawValue: 0)
    /// Go.
    public static let go = SubmitLabel(rawValue: 1)
    /// Send.
    public static let send = SubmitLabel(rawValue: 2)
    /// Join.
    public static let join = SubmitLabel(rawValue: 3)
    /// Route.
    public static let route = SubmitLabel(rawValue: 4)
    /// Search.
    public static let search = SubmitLabel(rawValue: 5)
    /// Return.
    public static let `return` = SubmitLabel(rawValue: 6)
    /// Next.
    public static let next = SubmitLabel(rawValue: 7)
    /// Continue.
    public static let `continue` = SubmitLabel(rawValue: 8)
}

extension EnvironmentValues {
    /// Whether text fields leave the platform's autocorrection, spell
    /// checking and text prediction off, set by
    /// ``View/autocorrectionDisabled(_:)``.
    @Entry public var autocorrectionDisabled = false

    /// Whether text fields are drawn without a border or background, set by
    /// ``View/textFieldStyle(_:)`` with ``PlainTextFieldStyle``.
    @Entry @_spi(Backends) public var textFieldIsPlain = false
}

/// How a ``TextField`` is drawn.
public protocol TextFieldStyle: Sendable {
    /// Whether the style draws the field without a border or background.
    var _isPlain: Bool { get }
}

/// The platform's default text field style.
public struct DefaultTextFieldStyle: TextFieldStyle {
    public var _isPlain: Bool { false }

    public init() {}
}

/// A text field with no border or background, for fields drawn inside a
/// container of their own.
public struct PlainTextFieldStyle: TextFieldStyle {
    public var _isPlain: Bool { true }

    public init() {}
}

/// A text field with a rounded border: the default on every backend.
public struct RoundedBorderTextFieldStyle: TextFieldStyle {
    public var _isPlain: Bool { false }

    public init() {}
}

extension TextFieldStyle where Self == DefaultTextFieldStyle {
    /// The platform's default text field style.
    public static var automatic: DefaultTextFieldStyle { DefaultTextFieldStyle() }
}

extension TextFieldStyle where Self == PlainTextFieldStyle {
    /// A text field with no border or background.
    public static var plain: PlainTextFieldStyle { PlainTextFieldStyle() }
}

extension TextFieldStyle where Self == RoundedBorderTextFieldStyle {
    /// A text field with a rounded border.
    public static var roundedBorder: RoundedBorderTextFieldStyle {
        RoundedBorderTextFieldStyle()
    }
}

extension View {
    /// Turns off autocorrection, spell checking and text prediction in the
    /// text fields within this view.
    ///
    /// For addresses, user names, codes and search terms, which a
    /// dictionary would only get wrong. `WinUIBackend` turns off its text
    /// boxes' spell checking and text prediction; macOS text fields don't
    /// autocorrect to begin with.
    ///
    /// - Parameter disable: Whether to turn autocorrection off.
    /// - Returns: A view whose text fields don't autocorrect.
    public func autocorrectionDisabled(_ disable: Bool = true) -> some View {
        environment(\.autocorrectionDisabled, disable)
    }

    /// Sets the label of the return key of on-screen keyboards while a text
    /// field within this view is being edited.
    ///
    /// Purely cosmetic, and without effect: none of SwiftCrossUI's backends
    /// exposes the label of a touch keyboard's return key, and hardware
    /// keyboards have none. Submitting the field works as usual
    /// (``View/onSubmit(of:_:)``).
    ///
    /// - Parameter submitLabel: The label.
    /// - Returns: This view, unchanged.
    public func submitLabel(_ submitLabel: SubmitLabel) -> some View {
        self
    }

    /// Sets the style of the text fields within this view.
    ///
    /// ``PlainTextFieldStyle`` draws fields without a border or background
    /// (`AppKitBackend` and `WinUIBackend`); the other styles are the
    /// backends' default field.
    ///
    /// - Parameter style: The style.
    /// - Returns: A view whose text fields use `style`.
    public func textFieldStyle(_ style: some TextFieldStyle) -> some View {
        environment(\.textFieldIsPlain, style._isPlain)
    }
}
