extension BackendFeatures {
    /// Backend methods for alerts.
    ///
    /// These are used by ``View/alert(_:actions:)``,
    /// ``View/alert(_:isPresented:actions:)``, ``EnvironmentValues/presentAlert``,
    /// and ``AlertScene``.
    ///
    /// An alert can also carry a single line of text entry; see
    /// ``addTextField(_:to:)``.
    @MainActor
    public protocol Alerts<Alert>: Core {
        /// The underlying alert type. Can be a wrapper or subclass.
        associatedtype Alert

        /// Creates an alert object (without showing it).
        ///
        /// Alerts contain a title, an optional body, and a set of action buttons.
        /// They prevent users from interacting with the parent window until
        /// dimissed.
        ///
        /// - Returns: An alert.
        func createAlert() -> Alert

        /// Updates the content and appearance of an alert.
        ///
        /// Can only be called once.
        ///
        /// - Parameters:
        ///   - alert: The alert to update.
        ///   - title: The title of the alert.
        ///   - actionLabels: The labels of the alert's action buttons.
        ///   - environment: The current environment.
        func updateAlert(
            _ alert: Alert,
            title: String,
            actionLabels: [String],
            environment: EnvironmentValues
        )

        /// Shows an alert as a modal on top of or within the given window.
        ///
        /// Users should be unable to interact with the parent window until the
        /// alert is dismissed.
        ///
        /// Must only be called once for any given alert.
        ///
        /// - Parameters:
        ///   - alert: The alert to show.
        ///   - window: The window to attach the alert to. If `nil`, the backend can
        ///     either make the alert a whole app modal, a standalone window, or a
        ///     modal for a window of its choosing.
        ///   - handleResponse: The code to run when an action is selected. Receives
        ///     the index of the chosen action (as per the `actionLabels` array).
        ///     The alert will have already been hidden by the time this gets
        ///     called.
        func showAlert(
            _ alert: Alert,
            window: Window?,
            responseHandler handleResponse: @escaping (Int) -> Void
        )

        /// Dismisses an alert programmatically without invoking the response
        /// handler.
        ///
        /// Must only be called after ``showAlert(_:window:responseHandler:)``.
        ///
        /// - Parameters:
        ///   - alert: The alert to dismiss.
        ///   - window: The window the alert is attached to, if any.
        func dismissAlert(_ alert: Alert, window: Window?)

        /// Adds a single-line text field to an alert, turning it into a
        /// text-entry alert.
        ///
        /// Called after the alert has been updated and before it's shown, and
        /// at most once per alert. Backends that add a field must also
        /// implement ``textFieldContents(of:)``, which is how the typed string
        /// gets back to the application.
        ///
        /// The default implementation adds nothing and says so, so that a
        /// backend which can't put a field in an alert keeps working (the
        /// alert's buttons still do their job) while the framework reports the
        /// field it had to drop.
        ///
        /// - Parameters:
        ///   - textField: The field to add.
        ///   - alert: The alert to add it to.
        /// - Returns: Whether the field was added.
        func addTextField(_ textField: AlertTextField, to alert: Alert) -> Bool

        /// The current contents of the text field added by
        /// ``addTextField(_:to:)``.
        ///
        /// Called from the response handler passed to
        /// ``showAlert(_:window:responseHandler:)``, while the alert is still
        /// alive, so that the string the user typed can be handed back before
        /// the chosen action runs.
        ///
        /// The default implementation returns `nil`, matching the default
        /// ``addTextField(_:to:)``.
        ///
        /// - Parameter alert: The alert to read from.
        /// - Returns: The field's contents, or `nil` if the alert has no field.
        func textFieldContents(of alert: Alert) -> String?
    }
}

// MARK: Default Implementations

extension BackendFeatures.Alerts {
    /// Reports that this backend can't put a text field in an alert.
    ///
    /// - Parameters:
    ///   - textField: The field that was requested.
    ///   - alert: The alert it would have been added to.
    /// - Returns: `false`, always.
    public func addTextField(_ textField: AlertTextField, to alert: Alert) -> Bool {
        false
    }

    /// Reports that this backend's alerts never have a text field.
    ///
    /// - Parameter alert: The alert to read from.
    /// - Returns: `nil`, always.
    public func textFieldContents(of alert: Alert) -> String? {
        nil
    }
}

/// The description of a text-entry alert's single input field.
///
/// Only backends and ``AlertActions`` should interface with this type directly.
/// It exists for the same reason as ``AlertAction``: so that alerts don't have
/// to expose the internals of ``TextField``.
///
/// SwiftUI makes an alert a text-entry alert by putting a ``TextField`` in its
/// `actions` block. The field's binding stays on the framework's side of the
/// boundary; the backend is given a plain snapshot of it and hands the typed
/// string back through
/// ``BackendFeatures/Alerts/textFieldContents(of:)``.
///
/// ## See Also
/// - ``View/alert(_:isPresented:actions:)``
public struct AlertTextField: Hashable, Sendable {
    /// The text to show while the field is empty.
    public var placeholder: String
    /// The text the field starts out containing.
    public var initialValue: String
    /// Whether the field should hide what's typed into it, as a password field
    /// does.
    ///
    /// Set when the author wrote a ``SecureField`` rather than a
    /// ``TextField``. Backends that can't hide the contents must refuse the
    /// field rather than showing it in the clear.
    public var isSecure: Bool

    /// Describes a text-entry alert's field.
    ///
    /// - Parameters:
    ///   - placeholder: The text to show while the field is empty.
    ///   - initialValue: The text the field starts out containing.
    ///   - isSecure: Whether the field should hide what's typed into it.
    ///     Defaults to `false`.
    public init(
        placeholder: String,
        initialValue: String,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self.initialValue = initialValue
        self.isSecure = isSecure
    }
}
