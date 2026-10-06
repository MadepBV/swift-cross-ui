/// A type of tap gesture, and SwiftUI's tap gesture.
///
/// As the type of gesture passed to ``View/onTapGesture(gesture:perform:)``
/// it names an interaction (``primary``, ``secondary``, ``longPress``). As
/// SwiftUI's `TapGesture` it's a ``Gesture`` that recognizes a number of
/// primary clicks and runs the actions given to ``onEnded(_:)``:
///
/// ```swift
/// Color.clear
///     .simultaneousGesture(TapGesture().onEnded { noteActivity() })
/// ```
public struct TapGesture: Sendable, Hashable {
    @_spi(Backends) public var kind: TapGestureKind

    /// The number of taps that must happen in quick succession, when used as
    /// a ``Gesture``.
    public var count = 1

    /// The actions to run once the taps complete, when used as a
    /// ``Gesture``.
    var endHandlers: [@MainActor @Sendable () -> Void] = []

    /// Creates a gesture that recognizes a number of primary taps or clicks,
    /// SwiftUI's spelling.
    ///
    /// - Parameter count: The number of taps that must happen in quick
    ///   succession.
    public init(count: Int = 1) {
        self.kind = .primary
        self.count = count
    }

    /// Creates a tap gesture of a kind.
    ///
    /// - Parameter kind: The kind of interaction.
    init(kind: TapGestureKind) {
        self.kind = kind
    }

    /// Adds an action to run once the taps complete.
    ///
    /// Actions run in the order they were added.
    ///
    /// - Parameter action: The action.
    /// - Returns: A tap gesture that also runs `action`.
    public func onEnded(_ action: @escaping @MainActor @Sendable () -> Void) -> TapGesture {
        var gesture = self
        gesture.endHandlers.append(action)
        return gesture
    }

    public static func == (lhs: TapGesture, rhs: TapGesture) -> Bool {
        lhs.kind == rhs.kind && lhs.count == rhs.count
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(count)
    }

    /// The idiomatic "primary" interaction for the device, such as a left-click
    /// with the mouse or normal tap on a touch screen.
    public static let primary = TapGesture(kind: .primary)
    /// The idiomatic "secondary" interaction for the device, such as a
    /// right-click with the mouse or long press on a touch screen.
    public static let secondary = TapGesture(kind: .secondary)
    /// A long press of the same interaction type as ``primary``.
    ///
    /// May be equivalent to ``secondary`` on some backends, particularly on
    /// mobile devices.
    public static let longPress = TapGesture(kind: .longPress)

    @_spi(Backends) public enum TapGestureKind: Hashable, Sendable {
        case primary
        case secondary
        case longPress
    }
}

extension View {
    /// Adds an action to perform when the user taps or clicks this view.
    ///
    /// Any tappable elements within the view will no longer be tappable with
    /// the same gesture type.
    ///
    /// - Parameters:
    ///   - gesture: The type of gesture to listen for.
    ///   - action: The action to perform.
    public func onTapGesture(
        gesture: TapGesture = .primary,
        perform action: @escaping () -> Void
    ) -> some View {
        OnTapGestureModifier(body: TupleView1(self), gesture: gesture, action: action)
    }

    /// Adds an action to run when this view is clicked. Any clickable elements
    /// within the view will no longer be clickable.
    @available(*, deprecated, renamed: "onTapGesture(gesture:perform:)")
    public func onClick(perform action: @escaping () -> Void) -> some View {
        onTapGesture(perform: action)
    }
}

struct OnTapGestureModifier<Content: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children

    var body: TupleView1<Content>
    var gesture: TapGesture
    var action: () -> Void

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(
            backend: backend,
            snapshots: snapshots,
            environment: environment
        )
    }

    @CastBackend<BackendFeatures.TapGestures>(returnsWidget: true)
    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        backend.createTapGestureTarget(wrapping: children.child0.widget.into(), gesture: gesture)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
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

    @CastBackend<BackendFeatures.TapGestures>
    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: TupleView1<Content>.Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = children.child0.commit().size
        backend.setSize(of: widget, to: size.vector)
        backend.updateTapGestureTarget(
            widget,
            gesture: gesture,
            environment: environment,
            action: action
        )
    }
}

extension TapGesture: Gesture {
    public typealias Value = Void
}

extension TapGesture: _ResolvableGesture {
    /// A tap gesture is recognized as a spatial tap whose location is
    /// ignored.
    package var _resolved: ResolvedGesture {
        let handlers = endHandlers
        return .spatialTap(
            SpatialTapGesture(count: count).onEnded { _ in
                for handler in handlers {
                    handler()
                }
            }
        )
    }
}
