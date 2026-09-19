extension BackendFeatures {
    /// Backend methods for driving and observing keyboard focus.
    ///
    /// These are used by ``View/focused(_:equals:)`` and ``View/focused(_:)``,
    /// which back the ``FocusState`` property wrapper.
    ///
    /// ## Bidirectionality
    ///
    /// ``FocusState`` is a two-way binding: writing to it must move platform
    /// focus, and the user moving focus (by clicking or tabbing) must write
    /// back. Backends therefore have two jobs:
    ///
    /// - **State to focus.** ``updateFocusTarget(_:isFocused:environment:onFocusChange:)``
    ///   receives the desired focus state and must make it so, using e.g.
    ///   `NSWindow.makeFirstResponder(_:)`, `Control.Focus(_:)`,
    ///   `UIResponder.becomeFirstResponder()`, or `gtk_widget_grab_focus`.
    /// - **Focus to state.** Whenever the platform changes focus, the backend
    ///   calls `onFocusChange` with the new state.
    ///
    /// To avoid feedback loops, backends must only invoke `onFocusChange` when
    /// the focus state actually changed, and must not invoke it synchronously
    /// from within a focus change that they themselves initiated in
    /// `updateFocusTarget`.
    ///
    /// If a backend can only implement the first direction, it should still
    /// conform, never call `onFocusChange`, and document the limitation.
    ///
    /// Backends that do not conform to this protocol degrade silently:
    /// ``View/focused(_:equals:)`` becomes a no-op rather than crashing.
    @MainActor
    public protocol Focus: Core {
        /// Wraps a widget in a container whose focus can be driven and
        /// observed.
        ///
        /// Backends that can drive and observe the child directly may return
        /// the child as-is.
        ///
        /// - Parameter child: The widget to wrap.
        /// - Returns: A widget that participates in focus management.
        func createFocusTarget(wrapping child: Widget) -> Widget

        /// Updates a focus target's desired focus state and change handler.
        ///
        /// - Parameters:
        ///   - target: The target returned by
        ///     ``createFocusTarget(wrapping:)``.
        ///   - isFocused: Whether the target should hold focus. Backends must
        ///     only move focus when this differs from the target's current
        ///     focus state, so that repeated updates don't steal focus.
        ///   - environment: The current environment. A disabled target must
        ///     never be given focus.
        ///   - onFocusChange: Called with the new focus state whenever the
        ///     platform changes the target's focus. Replaces the previously
        ///     registered handler.
        func updateFocusTarget(
            _ target: Widget,
            isFocused: Bool,
            environment: EnvironmentValues,
            onFocusChange: @escaping (Bool) -> Void
        )
    }
}
