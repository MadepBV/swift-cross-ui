extension View {
    /// Adds a label that describes the view's content to assistive
    /// technologies.
    ///
    /// Use this when a view's visual content doesn't convey its meaning on its
    /// own, such as an icon-only button.
    ///
    /// ```swift
    /// Button("", action: deleteItem)
    ///     .accessibilityLabel("Delete")
    /// ```
    ///
    /// - Parameter label: A short, localized description of the content.
    /// - Returns: A view that exposes `label` to assistive technologies.
    public func accessibilityLabel(_ label: String) -> some View {
        AccessibilityView(self, properties: .init(label: label))
    }

    /// Adds a label that describes the view's content to assistive
    /// technologies.
    ///
    /// - Parameter label: A text view whose string becomes the label.
    /// - Returns: A view that exposes `label` to assistive technologies.
    public func accessibilityLabel(_ label: Text) -> some View {
        AccessibilityView(self, properties: .init(label: label.string))
    }

    /// Adds a hint describing the outcome of interacting with the view.
    ///
    /// Assistive technologies read the hint after the label and value, so
    /// phrase it as an action, e.g. `"Adds a dimension to the sheet"`.
    ///
    /// - Parameter hint: A localized description of what happens on
    ///   interaction.
    /// - Returns: A view that exposes `hint` to assistive technologies.
    public func accessibilityHint(_ hint: String) -> some View {
        AccessibilityView(self, properties: .init(hint: hint))
    }

    /// Adds a hint describing the outcome of interacting with the view.
    ///
    /// - Parameter hint: A text view whose string becomes the hint.
    /// - Returns: A view that exposes `hint` to assistive technologies.
    public func accessibilityHint(_ hint: Text) -> some View {
        AccessibilityView(self, properties: .init(hint: hint.string))
    }

    /// Adds a textual description of the view's current value.
    ///
    /// Use this for views whose content changes, such as a field showing a
    /// measurement.
    ///
    /// - Parameter value: The current value, as a localized string.
    /// - Returns: A view that exposes `value` to assistive technologies.
    public func accessibilityValue(_ value: String) -> some View {
        AccessibilityView(self, properties: .init(value: value))
    }

    /// Adds a textual description of the view's current value.
    ///
    /// - Parameter value: A text view whose string becomes the value.
    /// - Returns: A view that exposes `value` to assistive technologies.
    public func accessibilityValue(_ value: Text) -> some View {
        AccessibilityView(self, properties: .init(value: value.string))
    }

    /// Assigns a stable identifier used to find the view from automation.
    ///
    /// Unlike ``View/accessibilityLabel(_:)``, an identifier is never shown to
    /// users and should not be localized. UI test suites use it to locate
    /// views regardless of the app's language.
    ///
    /// - Parameter identifier: A stable, non-localized identifier.
    /// - Returns: A view that exposes `identifier` to automation.
    public func accessibilityIdentifier(_ identifier: String) -> some View {
        AccessibilityView(self, properties: .init(identifier: identifier))
    }

    /// Hides the view and its descendants from assistive technologies.
    ///
    /// Use this for purely decorative content that would otherwise add noise,
    /// or for content that a nearby view already describes.
    ///
    /// - Parameter hidden: Whether to hide the view. Defaults to `true`.
    /// - Returns: A view that is hidden from assistive technologies when
    ///   `hidden` is `true`.
    public func accessibilityHidden(_ hidden: Bool = true) -> some View {
        AccessibilityView(self, properties: .init(isHidden: hidden))
    }

    /// Adds traits describing how the view behaves.
    ///
    /// Traits accumulate: applying this modifier more than once unions the
    /// trait sets rather than replacing them.
    ///
    /// - Parameter traits: The traits to add.
    /// - Returns: A view that exposes `traits` to assistive technologies.
    public func accessibilityAddTraits(
        _ traits: AccessibilityTraits
    ) -> some View {
        AccessibilityView(self, properties: .init(traits: traits))
    }

    /// Turns the view into a single accessibility element and decides what
    /// happens to its descendants.
    ///
    /// ```swift
    /// HStack {
    ///     Image("bar-icon")
    ///     Text("Ø12 · 4200mm")
    /// }
    /// .accessibilityElement(children: .combine)
    /// ```
    ///
    /// ## Platform support
    ///
    /// `children` is the one accessibility concept that requires reshaping the
    /// accessibility tree rather than setting a property, so backends support
    /// it to differing degrees. See
    /// ``BackendFeatures/AccessibilityProperties/ChildBehavior`` and the
    /// individual backends for exactly what each one does.
    ///
    /// - Parameter children: How the view's descendants participate in the
    ///   accessibility tree. Defaults to ``AccessibilityChildBehavior/ignore``.
    /// - Returns: A view that forms a single accessibility element.
    public func accessibilityElement(
        children: AccessibilityChildBehavior = .ignore
    ) -> some View {
        AccessibilityView(self, properties: .init(childBehavior: children.kind))
    }
}

/// The way a view's descendants participate in the accessibility tree.
///
/// Pass one of these to ``View/accessibilityElement(children:)``.
public struct AccessibilityChildBehavior: Equatable, Hashable, Sendable {
    /// The backend-facing representation of this behaviour.
    let kind: BackendFeatures.AccessibilityProperties.ChildBehavior

    /// The view's descendants are hidden from assistive technologies, leaving
    /// the view itself as a single element described only by its own
    /// accessibility modifiers.
    public static let ignore = AccessibilityChildBehavior(kind: .ignore)

    /// The view becomes a single element whose description is assembled from
    /// its descendants.
    public static let combine = AccessibilityChildBehavior(kind: .combine)

    /// The view becomes a container, and its descendants remain visible to
    /// assistive technologies as separate elements.
    public static let contain = AccessibilityChildBehavior(kind: .contain)
}

/// A view that carries accessibility metadata for the view it wraps.
///
/// Nesting is expected: each `accessibility*` modifier creates its own
/// `AccessibilityView` with only the property it sets. Because they all target
/// the same underlying widget, the outermost one gathers the whole chain via
/// ``AccessibilityPropertyProvider`` before handing it to the backend, so no
/// modifier clobbers the ones beneath it.
struct AccessibilityView<Child: View>: TypeSafeView {
    var body: TupleView1<Child>

    /// The properties contributed by this modifier alone.
    var properties: BackendFeatures.AccessibilityProperties

    init(
        _ child: Child,
        properties: BackendFeatures.AccessibilityProperties
    ) {
        body = TupleView1(child)
        self.properties = properties
    }

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> TupleViewChildren1<Child> {
        body.children(
            backend: backend,
            snapshots: snapshots,
            environment: environment
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: TupleViewChildren1<Child>,
        backend: Backend
    ) -> Backend.Widget {
        children.child0.widget.into()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: TupleViewChildren1<Child>,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        children.child0.computeLayout(
            with: body.view0,
            proposedSize: proposedSize,
            environment: environment
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: TupleViewChildren1<Child>,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        _ = children.child0.commit()

        // Accessibility is an optional backend feature. Rather than trapping
        // on a backend that doesn't implement it (as `@CastBackend` would),
        // we simply don't expose any metadata.
        guard
            let backend = backend as? any BaseAppBackend
                & BackendFeatures.Accessibility
        else {
            return
        }

        Self.apply(
            accumulatedAccessibilityProperties,
            to: children.child0.widget,
            backend: backend
        )
    }

    /// Hands metadata to a backend that supports accessibility.
    ///
    /// Split out from ``commit(_:children:layout:environment:backend:)`` so
    /// that the existential accessibility backend can be opened into a generic
    /// parameter.
    @MainActor
    private static func apply<
        Backend: BaseAppBackend & BackendFeatures.Accessibility
    >(
        _ properties: BackendFeatures.AccessibilityProperties,
        to widget: AnyWidget,
        backend: Backend
    ) {
        backend.updateAccessibility(of: widget.into(), to: properties)
    }
}

/// A view that contributes accessibility metadata to the widget beneath it.
///
/// Only ``AccessibilityView`` conforms. The protocol exists so that an
/// accessibility modifier can discover the modifiers it wraps without knowing
/// their generic parameters.
@MainActor
protocol AccessibilityPropertyProvider {
    /// This modifier's properties merged with those of every accessibility
    /// modifier nested inside it.
    var accumulatedAccessibilityProperties:
        BackendFeatures.AccessibilityProperties
    { get }
}

extension AccessibilityView: AccessibilityPropertyProvider {
    var accumulatedAccessibilityProperties:
        BackendFeatures.AccessibilityProperties
    {
        guard
            let inner = body.view0 as? any AccessibilityPropertyProvider
        else {
            return properties
        }
        return inner.accumulatedAccessibilityProperties.merging(properties)
    }
}
