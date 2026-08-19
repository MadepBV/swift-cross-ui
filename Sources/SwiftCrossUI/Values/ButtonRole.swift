/// A description of what a button does, used to give it the appearance and
/// behaviour its platform reserves for that kind of action.
///
/// A role never changes what a button *does* — that's entirely up to its
/// action. It only tells the framework and the backend how the button should
/// present itself.
///
/// ```swift
/// Button("Delete", role: .destructive) { delete() }
/// Button("Cancel", role: .cancel) { dismiss() }
/// ```
///
/// A button with the ``ButtonRole/destructive`` role renders in the platform's
/// warning colour, and backends that can express destructiveness natively
/// (AppKit's `NSButton.hasDestructiveAction`, for example) are told about it
/// too. A button with the ``ButtonRole/cancel`` role carries its role for
/// containers that treat cancellation specially — most notably confirmation
/// dialogs, which make the cancelling button the dialog's escape route.
///
/// ## See Also
/// - ``Button/init(_:role:action:)``
/// - ``Button/init(role:action:label:)``
public struct ButtonRole: Hashable, Sendable {
    /// The set of roles a button can have.
    ///
    /// Backends switch over this rather than comparing against the static
    /// members, so that adding a role is a compile-time error for them.
    package enum Kind: Hashable, Sendable {
        /// See ``ButtonRole/destructive``.
        case destructive
        /// See ``ButtonRole/cancel``.
        case cancel
    }

    /// Which role this is.
    package var kind: Kind

    /// A role for a button that performs an irreversible or otherwise
    /// dangerous action, such as deleting or resetting something.
    public static let destructive = Self(kind: .destructive)

    /// A role for a button that abandons the operation in progress.
    public static let cancel = Self(kind: .cancel)
}

extension ButtonRole: CustomStringConvertible {
    /// A textual description of the role.
    public var description: String {
        "\(kind)"
    }
}

extension EnvironmentValues {
    /// The role of the ``Button`` currently being updated, if it has one.
    ///
    /// ``Button`` sets this on the environment it hands to the backend when
    /// updating its widget, so that backends can express the role natively
    /// without the button protocol having to grow a parameter. Nothing else
    /// should set it, and reading it anywhere other than a backend's button
    /// implementation is meaningless.
    @Entry @_spi(Backends) public var buttonRole: ButtonRole?
}
