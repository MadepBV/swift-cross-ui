/// A control that initiates an action.
public struct Button<Label: View> {
    /// A button's label with the environment's ``ButtonStyle`` applied to it.
    ///
    /// A built-in style is drawn by the backend, so this renders the label
    /// untouched and lets the backend put its chrome around it. A style
    /// defined outside of SwiftCrossUI has no backend counterpart, so this
    /// renders ``ButtonStyle/makeBody(configuration:)`` instead and the
    /// backend is asked for ``ButtonStyleKind/plain`` — no chrome — leaving
    /// the style in sole charge of the button's appearance, exactly as
    /// SwiftUI does it.
    public struct StyledLabel: View {
        /// The style to apply, taken from the environment.
        @Environment(\.buttonStyle) private var buttonStyle

        /// The button's label.
        var label: @MainActor () -> Label

        /// The button's role, if it has one.
        var role: ButtonRole?

        /// Creates a label that applies the environment's button style.
        ///
        /// - Parameters:
        ///   - label: The button's label.
        ///   - role: The button's role, if it has one.
        init(label: @escaping @MainActor () -> Label, role: ButtonRole?) {
            self.label = label
            self.role = role
        }

        /// The label with the style applied, if the style is a custom one.
        private var styledLabel: any View {
            guard
                let buttonStyle,
                !(buttonStyle is any _BuiltinButtonStyle)
            else {
                return label()
            }
            return buttonStyle.makeBody(
                configuration: ButtonStyleConfiguration(
                    label: ButtonStyleConfiguration.Label(label()),
                    role: role,
                    isPressed: false
                )
            )
        }

        public var body: some View {
            AnyView(styledLabel)
        }
    }

    public typealias Content = TupleView1<StyledLabel>
    /// The label to show on the button.
    @_spi(Backends) public var label: () -> Label
    /// The action to be performed when the button is clicked.
    @_spi(Backends) public var action: @MainActor () -> Void
    /// The button's role, if it has one.
    ///
    /// See ``ButtonRole`` for what a role changes.
    @_spi(Backends) public var role: ButtonRole?

    /// Creates a button that displays a text label.
    ///
    /// - Parameters:
    ///   - label: The label to show on the button.
    ///   - role: The button's role, describing what kind of action it
    ///     performs. Defaults to `nil` (no particular role).
    ///   - action: The action to be performed when the button is clicked.
    public init(
        _ label: String,
        role: ButtonRole? = nil,
        action: @escaping @MainActor () -> Void = {}
    ) where Label == TupleView1<Text> {
        self.label = { TupleView1(Text(label)) }
        self.action = action
        self.role = role
    }

    /// Creates a button that displays a custom view as label.
    ///
    /// - Parameters:
    ///   - role: The button's role, describing what kind of action it
    ///     performs. Defaults to `nil` (no particular role).
    ///   - label: The label to show on the button.
    ///   - action: The action to be performed when the button is clicked.
    @MainActor
    public init (
        role: ButtonRole? = nil,
        action: @escaping @MainActor () -> Void = {},
        @ViewBuilder label: @escaping @MainActor () -> Label
    ) {
        self.label = label
        self.action = action
        self.role = role
    }

    private struct ConstrainedButtonLabel<ConstrainedLabel: View>: View {
        @Environment(\.buttonPadding.x) var horizontalPadding

        var content: ConstrainedLabel
        var width: Int?

        var body: some View {
            content.ifLet(width) { view, width in
                view.frame(width: Double(width - horizontalPadding))
            }
        }
    }

    @MainActor
    @available(
        *,
        deprecated,
        message: "Use @ViewBuilder init of Button instead and apply a frame modifier to the label."
    )
    public func _buttonWidth(_ width: Int?) -> Button<some View> {
        let label = self.label
        return Button<TupleView1<ConstrainedButtonLabel<Label>>>(
            role: role,
            action: action,
            label: { ConstrainedButtonLabel(content: label(), width: width) }
        )
    }
}

@MainActor
extension Button: TypeSafeView {
    public var body: TupleView1<StyledLabel> {
        StyledLabel(label: label, role: role)
    }

    typealias Children = TupleViewChildren1<StyledLabel>

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        Children(
            body.view0,
            backend: backend,
            snapshots: snapshots,
            environment: environment
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        backend.createButton(wrapping: children.child0.widget.into())
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        let buttonPadding = backend.buttonPadding(in: environment)
        let childEnvironment = Self.labelEnvironment(
            role: role,
            environment: environment,
            backend: backend
        )

        var childProposal = proposedSize
        if let proposedWidth = proposedSize.width {
            childProposal.width = max(proposedWidth - Double(buttonPadding.x), 0)
        }
        if let proposedHeight = proposedSize.height {
            childProposal.height = max(proposedHeight - Double(buttonPadding.y), 0)
        }

        let childResult = children.child0.computeLayout(
            with: body.view0,
            proposedSize: childProposal,
            environment: childEnvironment
        )

        backend.updateButton(
            widget,
            environment: environment.with(\.buttonRole, role),
            action: action
        )

        // Buttons should always be set to label size + padding.
        // The backend representation of a button is expected not to have a minSize.
        let size = SIMD2(
            Int(childResult.size.width) + buttonPadding.x,
            Int(childResult.size.height) + buttonPadding.y
        )

        return ViewLayoutResult.leafView(size: ViewSize(size))
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        _ = children.child0.commit()
        backend.setSize(of: widget, to: layout.size.vector)
    }

    /// Computes the environment for a button's label, applying the button's
    /// role on top of whatever the backend asks for.
    ///
    /// A ``ButtonRole/destructive`` button's label is tinted with the
    /// platform's warning colour. Backends draw the button's chrome but not
    /// its label (the label is an arbitrary view), so tinting here is the only
    /// way a destructive button reads as destructive on every backend rather
    /// than only on the ones with a native destructive flag.
    ///
    /// The tint is skipped when the author set an explicit foreground colour,
    /// which wins over the role, and when the button is disabled, so that the
    /// backend's dimming survives.
    ///
    /// - Parameters:
    ///   - role: The button's role, if it has one.
    ///   - environment: The button's own environment.
    ///   - backend: The app's backend.
    /// - Returns: The environment to give the button's label.
    static func labelEnvironment<Backend: BaseAppBackend>(
        role: ButtonRole?,
        environment: EnvironmentValues,
        backend: Backend
    ) -> EnvironmentValues {
        let labelEnvironment = backend.computeButtonLabelEnvironment(from: environment)

        guard
            role?.kind == .destructive,
            environment.isEnabled,
            environment.foregroundColor == nil
        else {
            return labelEnvironment
        }

        return labelEnvironment.with(\.foregroundColor, .system(.red))
    }
}

@MainActor
extension Button where Label == SwiftCrossUI.Label<Text, Image> {
    /// Creates a button that displays a title and a system image (an SF
    /// Symbol) beside it.
    ///
    /// This is shorthand for building the button's label yourself:
    ///
    /// ```swift
    /// Button {
    ///     pickAxis()
    /// } label: {
    ///     Label("Pick axis", systemImage: "scope")
    /// }
    /// ```
    ///
    /// SF Symbols are an Apple-only font, so the name is resolved through the
    /// environment's ``EnvironmentValues/symbolProvider``, which by default
    /// draws an equivalent bundled Lucide icon on every platform. See
    /// ``Image/init(systemName:)`` for the details, and
    /// ``View/labelStyle(_:)`` for hiding either half of the label.
    ///
    /// - Parameters:
    ///   - title: The title displayed beside the symbol.
    ///   - systemImage: The name of the SF Symbol to use as the button's icon.
    ///   - role: The button's role, describing what kind of action it
    ///     performs. Defaults to `nil` (no particular role).
    ///   - action: The action to be performed when the button is clicked.
    public init(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping @MainActor () -> Void = {}
    ) {
        self.label = { SwiftCrossUI.Label(title, systemImage: systemImage) }
        self.action = action
        self.role = role
    }
}

@MainActor
extension Button where Label == SwiftCrossUI.Label<Text, EmptyView> {
    /// Creates a button that displays a title and an image resource beside it.
    ///
    /// - Important: SwiftCrossUI has no asset catalog, so it can't resolve an
    ///   image name into an image. Buttons created with this initializer show
    ///   their title alone. The name is recorded on the underlying ``Label``
    ///   so that a future asset mechanism can pick it up without any call site
    ///   having to change. To show an icon today, load it yourself with
    ///   ``Image/init(_:useFileExtension:)`` and use
    ///   ``Button/init(role:action:label:)`` with a ``Label``.
    ///
    /// - Parameters:
    ///   - title: The title displayed by the button.
    ///   - image: The name of the image resource to use as the button's icon.
    ///   - role: The button's role, describing what kind of action it
    ///     performs. Defaults to `nil` (no particular role).
    ///   - action: The action to be performed when the button is clicked.
    public init(
        _ title: String,
        image: String,
        role: ButtonRole? = nil,
        action: @escaping @MainActor () -> Void = {}
    ) {
        self.label = { SwiftCrossUI.Label(title, image: image) }
        self.action = action
        self.role = role
    }
}

@MainActor
extension Button where Label == TupleView1<Text> {
    /// The text shown on the button.
    ///
    /// Menus, alerts and confirmation dialogs can only present a button as a
    /// string, so they read its title back through this. Reaching into
    /// ``Button/body`` for it isn't supported: the body is where the
    /// environment's ``ButtonStyle`` gets applied, so its shape depends on
    /// which style is in effect.
    @_spi(Backends) public var title: String {
        label().view0.string
    }
}

@MainActor
extension Button {
    /// Represents the button as a menu item.
    ///
    /// ``MenuItem/button(_:)`` can only hold a button whose label is a piece of
    /// text, but this is deliberately unconstrained anyway: a protocol
    /// requirement gets one witness for `Button<Label>` as a whole, so a
    /// version constrained to `Label == TupleView1<Text>` would only ever be
    /// found by static dispatch. A button reached through a generic container —
    /// a ``TupleView``, which is what every view builder produces — would fall
    /// back to ``View``'s default implementation and arrive as its label's
    /// text, losing its action.
    ///
    /// A button built by `init(_:systemImage:role:action:)` or
    /// `init(_:image:role:action:)` is rebuilt as a text button carrying the
    /// same action and role. Menus can't show its icon, but dropping to the
    /// label's own menu representation would turn a working menu command into
    /// an inert piece of text.
    ///
    /// A button with some other kind of label still falls back to that default,
    /// because there's no menu item that can represent it.
    public var _asMenuItems: [MenuItem] {
        if let textButton = self as? Button<TupleView1<Text>> {
            return [.button(textButton)]
        }

        let items = label()._asMenuItems
        guard
            hasTitleAndIconLabel,
            items.count == 1,
            case .text(let title) = items[0]
        else {
            return items
        }
        return [
            .button(
                Button<TupleView1<Text>>(
                    title.string,
                    role: role,
                    action: action
                )
            )
        ]
    }

    /// Whether the button's label is one of the ``Label``s that
    /// `init(_:systemImage:role:action:)` and `init(_:image:role:action:)`
    /// build.
    ///
    /// Those are the only labels whose menu representation is known to be the
    /// button's title and nothing else, which is what makes it safe to swap
    /// the action back in.
    private var hasTitleAndIconLabel: Bool {
        Label.self == SwiftCrossUI.Label<Text, Image>.self
            || Label.self == SwiftCrossUI.Label<Text, EmptyView>.self
    }
}
