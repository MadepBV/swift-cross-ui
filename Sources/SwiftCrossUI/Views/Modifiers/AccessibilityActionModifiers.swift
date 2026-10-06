/// An action that an assistive technology can perform on a view, passed to
/// ``View/accessibilityAction(_:_:)``.
public struct AccessibilityActionKind: Hashable, Sendable {
    let kind: BackendFeatures.AccessibilityProperties.Action.Kind

    /// The view's primary action, as if it had been clicked.
    public static let `default` = AccessibilityActionKind(kind: .default)
    /// Dismisses the view or backs out of it.
    public static let escape = AccessibilityActionKind(kind: .escape)
    /// The app's most important action at this moment (a two-finger double
    /// tap with VoiceOver on iOS).
    public static let magicTap = AccessibilityActionKind(kind: .magicTap)

    /// An action with a user-visible name.
    ///
    /// - Parameter name: The name assistive technologies read out.
    public init(named name: Text) {
        kind = .named(name.string)
    }

    init(kind: BackendFeatures.AccessibilityProperties.Action.Kind) {
        self.kind = kind
    }
}

/// The direction of an adjustment requested by an assistive technology,
/// passed to ``View/accessibilityAdjustableAction(_:)``'s handler.
public enum AccessibilityAdjustmentDirection: Hashable, Sendable {
    /// Increase the value by one step.
    case increment
    /// Decrease the value by one step.
    case decrement
}

/// A key identifying a piece of custom accessibility content, passed to
/// ``View/accessibilityCustomContent(_:_:importance:)``.
public struct AccessibilityCustomContentKey: Hashable, Sendable {
    /// What the content is, read out before it.
    let label: String
    /// Identifies the content, so that a later modifier with the same key
    /// replaces it.
    let id: String

    /// Creates a key with a label and an identifier.
    ///
    /// - Parameters:
    ///   - label: What the content is, e.g. "Rating".
    ///   - id: A stable identifier for the content.
    public init(_ label: Text, id: String) {
        self.label = label.string
        self.id = id
    }

    /// Creates a key with a label and an identifier.
    ///
    /// - Parameters:
    ///   - label: What the content is, e.g. "Rating".
    ///   - id: A stable identifier for the content.
    public init(_ label: String, id: String) {
        self.label = label
        self.id = id
    }

    /// Creates a key whose label is also its identifier.
    ///
    /// - Parameter label: What the content is.
    public init(_ label: String) {
        self.init(label, id: label)
    }
}

/// Namespace for ``AXCustomContent/Importance``, spelled as Apple's
/// Accessibility framework spells it so that SwiftUI source compiles.
public enum AXCustomContent {
    /// How prominently assistive technologies present a piece of custom
    /// content.
    public enum Importance: Hashable, Sendable {
        /// Offered on request (VoiceOver's "More Content" rotor).
        case `default`
        /// Read out automatically, right after the view's label.
        case high
    }
}

extension View {
    /// Adds a labelled detail that assistive technologies offer alongside
    /// the view's label, such as a title's rating.
    ///
    /// ```swift
    /// card.accessibilityCustomContent(ratingKey, Text("4 stars"), importance: .high)
    /// ```
    ///
    /// `.high` content is read out right after the label. Backends without a
    /// custom-content API (AppKit and WinUI among them) append the
    /// high-importance entries to the view's help text, which is read the
    /// same way; default-importance entries need a rotor that only touch
    /// platforms have, so those backends leave them out. A `nil` value adds
    /// nothing.
    ///
    /// - Parameters:
    ///   - key: What the detail is.
    ///   - value: The detail, or `nil` for none.
    ///   - importance: How prominently to present it.
    /// - Returns: A view carrying the detail.
    public func accessibilityCustomContent(
        _ key: AccessibilityCustomContentKey,
        _ value: Text?,
        importance: AXCustomContent.Importance = .default
    ) -> some View {
        accessibilityCustomContent(key, value?.string, importance: importance)
    }

    /// Adds a labelled detail that assistive technologies offer alongside
    /// the view's label. See
    /// ``View/accessibilityCustomContent(_:_:importance:)``.
    ///
    /// - Parameters:
    ///   - key: What the detail is.
    ///   - value: The detail, or `nil` for none.
    ///   - importance: How prominently to present it.
    /// - Returns: A view carrying the detail.
    public func accessibilityCustomContent(
        _ key: AccessibilityCustomContentKey,
        _ value: String?,
        importance: AXCustomContent.Importance = .default
    ) -> some View {
        let content = value.map {
            [
                BackendFeatures.AccessibilityProperties.CustomContent(
                    id: key.id,
                    label: key.label,
                    value: $0,
                    isHighImportance: importance == .high
                )
            ]
        }
        return AccessibilityView(self, properties: .init(customContent: content ?? []))
    }

    /// Adds a labelled detail that assistive technologies offer alongside
    /// the view's label, keyed by its label.
    ///
    /// - Parameters:
    ///   - label: What the detail is.
    ///   - value: The detail.
    ///   - importance: How prominently to present it.
    /// - Returns: A view carrying the detail.
    public func accessibilityCustomContent(
        _ label: Text,
        _ value: Text,
        importance: AXCustomContent.Importance = .default
    ) -> some View {
        accessibilityCustomContent(
            AccessibilityCustomContentKey(label, id: label.string),
            value.string,
            importance: importance
        )
    }

    /// Adds an action that assistive technologies can perform on the view.
    ///
    /// On AppKit the action is a custom `NSAccessibility` action, which
    /// VoiceOver lists under its Actions menu (VO-Command-Space). On WinUI,
    /// UI Automation offers custom actions only through an automation peer of
    /// the control's own class, so the action isn't exposed there; give it a
    /// visible control as well, as Avelio's views already do.
    ///
    /// - Parameters:
    ///   - actionKind: Which action it is.
    ///   - handler: Performs the action.
    /// - Returns: A view offering the action.
    public func accessibilityAction(
        _ actionKind: AccessibilityActionKind = .default,
        _ handler: @escaping () -> Void
    ) -> some View {
        AccessibilityView(
            self,
            properties: .init(actions: [Self.action(actionKind.kind, handler)])
        )
    }

    /// Adds a named action that assistive technologies can perform on the
    /// view, such as "Remove". See ``View/accessibilityAction(_:_:)``.
    ///
    /// - Parameters:
    ///   - name: The name assistive technologies read out.
    ///   - handler: Performs the action.
    /// - Returns: A view offering the action.
    public func accessibilityAction(
        named name: Text,
        _ handler: @escaping () -> Void
    ) -> some View {
        accessibilityAction(AccessibilityActionKind(named: name), handler)
    }

    /// Adds a named action that assistive technologies can perform on the
    /// view, such as "Remove". See ``View/accessibilityAction(_:_:)``.
    ///
    /// - Parameters:
    ///   - name: The name assistive technologies read out.
    ///   - handler: Performs the action.
    /// - Returns: A view offering the action.
    public func accessibilityAction<S: StringProtocol>(
        named name: S,
        _ handler: @escaping () -> Void
    ) -> some View {
        accessibilityAction(AccessibilityActionKind(named: Text(String(name))), handler)
    }

    /// Lets assistive technologies step the view's value up and down, as
    /// they would a slider's.
    ///
    /// ```swift
    /// pageDots
    ///     .accessibilityValue("\(page + 1) of \(count)")
    ///     .accessibilityAdjustableAction { direction in
    ///         switch direction {
    ///         case .increment: page += 1
    ///         case .decrement: page -= 1
    ///         @unknown default: break
    ///         }
    ///     }
    /// ```
    ///
    /// AppKit has no adjustable trait for an arbitrary view, so the two
    /// directions are offered as the custom actions "Increment" and
    /// "Decrement" in VoiceOver's Actions menu. On WinUI they are not exposed,
    /// for the reason given in ``View/accessibilityAction(_:_:)``.
    ///
    /// - Parameter handler: Adjusts the value in the given direction.
    /// - Returns: A view whose value assistive technologies can adjust.
    public func accessibilityAdjustableAction(
        _ handler: @escaping (AccessibilityAdjustmentDirection) -> Void
    ) -> some View {
        AccessibilityView(
            self,
            properties: .init(actions: [
                Self.action(.increment) { handler(.increment) },
                Self.action(.decrement) { handler(.decrement) },
            ])
        )
    }

    /// Wraps an app's handler as a backend action.
    ///
    /// Assistive technologies call actions on the main thread, where views
    /// live, so the handler is carried across as main-actor isolated.
    private static func action(
        _ kind: BackendFeatures.AccessibilityProperties.Action.Kind,
        _ handler: @escaping () -> Void
    ) -> BackendFeatures.AccessibilityProperties.Action {
        let box = UncheckedSendableHandler(handler: handler)
        return BackendFeatures.AccessibilityProperties.Action(kind: kind) {
            box.handler()
        }
    }
}

/// Carries a view's action handler into a `@Sendable` backend action.
///
/// Safe because the handler is only ever called on the main actor, where the
/// view that created it lives; the wrapper exists because SwiftUI's
/// signatures take plain, non-`Sendable` closures.
private struct UncheckedSendableHandler: @unchecked Sendable {
    let handler: () -> Void
}

extension View {
    /// Adds a label, or leaves it out when `isEnabled` is `false`, keeping
    /// the view's identity either way.
    ///
    /// - Parameters:
    ///   - label: The label.
    ///   - isEnabled: Whether to add it.
    /// - Returns: A view carrying the label when enabled.
    public func accessibilityLabel(_ label: String, isEnabled: Bool) -> some View {
        AccessibilityView(self, properties: .init(label: isEnabled ? label : nil))
    }

    /// Adds a label, or leaves it out when `isEnabled` is `false`, keeping
    /// the view's identity either way.
    ///
    /// - Parameters:
    ///   - label: The label.
    ///   - isEnabled: Whether to add it.
    /// - Returns: A view carrying the label when enabled.
    public func accessibilityLabel(_ label: Text, isEnabled: Bool) -> some View {
        accessibilityLabel(label.string, isEnabled: isEnabled)
    }

    /// Adds a hint, or leaves it out when `isEnabled` is `false`, keeping the
    /// view's identity either way (a conditional modifier would rebuild the
    /// view, and drop its focus).
    ///
    /// - Parameters:
    ///   - hint: The hint.
    ///   - isEnabled: Whether to add it.
    /// - Returns: A view carrying the hint when enabled.
    public func accessibilityHint(_ hint: String, isEnabled: Bool) -> some View {
        AccessibilityView(self, properties: .init(hint: isEnabled ? hint : nil))
    }

    /// Adds a hint, or leaves it out when `isEnabled` is `false`.
    ///
    /// - Parameters:
    ///   - hint: The hint.
    ///   - isEnabled: Whether to add it.
    /// - Returns: A view carrying the hint when enabled.
    public func accessibilityHint(_ hint: Text, isEnabled: Bool) -> some View {
        accessibilityHint(hint.string, isEnabled: isEnabled)
    }

    /// Adds a value, or leaves it out when `isEnabled` is `false`.
    ///
    /// - Parameters:
    ///   - value: The value.
    ///   - isEnabled: Whether to add it.
    /// - Returns: A view carrying the value when enabled.
    public func accessibilityValue(_ value: String, isEnabled: Bool) -> some View {
        AccessibilityView(self, properties: .init(value: isEnabled ? value : nil))
    }

    /// Adds a value, or leaves it out when `isEnabled` is `false`.
    ///
    /// - Parameters:
    ///   - value: The value.
    ///   - isEnabled: Whether to add it.
    /// - Returns: A view carrying the value when enabled.
    public func accessibilityValue(_ value: Text, isEnabled: Bool) -> some View {
        accessibilityValue(value.string, isEnabled: isEnabled)
    }
}
