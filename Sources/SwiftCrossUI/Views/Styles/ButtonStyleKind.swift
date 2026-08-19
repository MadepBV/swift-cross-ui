/// The chrome that a backend draws behind a button.
///
/// Every built-in ``ButtonStyle`` maps onto one of these, and backends switch
/// over the value to pick a native appearance. A style defined outside of
/// SwiftCrossUI maps onto ``ButtonStyleKind/plain``, since it draws its own
/// appearance instead.
public enum ButtonStyleKind: Hashable, Sendable, CustomStringConvertible {
    /// The standard border for the button's context.
    case bordered

    /// No decoration while idle, though the backend may still indicate the
    /// pressed, focused, or enabled state.
    case plain

    /// No border.
    ///
    /// On desktop operating systems this behaves mostly the same as
    /// ``ButtonStyleKind/plain``, matching SwiftUI's borderless behaviour on
    /// macOS. The only difference is a default foreground colour of grey.
    case borderless

    public var description: String {
        switch self {
            case .bordered: "bordered"
            case .plain: "plain"
            case .borderless: "borderless"
        }
    }
}
