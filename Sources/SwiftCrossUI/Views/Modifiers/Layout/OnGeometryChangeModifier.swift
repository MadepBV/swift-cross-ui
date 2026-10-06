import Foundation

extension View {
    /// Adds an action to be performed when a value, created from a geometry
    /// proxy, changes.
    ///
    /// The proxy describes the view's committed size, so the action runs
    /// once the view's layout has been committed: first with the initial
    /// value, then whenever the transformed value changes.
    ///
    /// - Parameters:
    ///   - type: The type of value the transform produces.
    ///   - transform: Produces a value from the view's geometry.
    ///   - action: The action to perform, given the new value.
    /// - Returns: A view that watches its geometry.
    public func onGeometryChange<T: Equatable>(
        for type: T.Type,
        of transform: @escaping (GeometryProxy) -> T,
        action: @escaping (_ newValue: T) -> Void
    ) -> some View {
        OnGeometryChangeModifier(
            body: TupleView1(self),
            transform: transform,
            action: { _, newValue in action(newValue) }
        )
    }

    /// Adds an action to be performed when a value, created from a geometry
    /// proxy, changes, handing the action the old and new values.
    ///
    /// On the initial run both values are the initial value.
    ///
    /// - Parameters:
    ///   - type: The type of value the transform produces.
    ///   - transform: Produces a value from the view's geometry.
    ///   - action: The action to perform, given the old and new values.
    /// - Returns: A view that watches its geometry.
    public func onGeometryChange<T: Equatable>(
        for type: T.Type,
        of transform: @escaping (GeometryProxy) -> T,
        action: @escaping (_ oldValue: T, _ newValue: T) -> Void
    ) -> some View {
        OnGeometryChangeModifier(body: TupleView1(self), transform: transform, action: action)
    }

    /// Assigns a name to the view's coordinate space, so other code can
    /// operate on dimensions like points and sizes relative to the named
    /// space.
    ///
    /// - Important: Accepted so that SwiftUI code compiles, but has no
    ///   effect: SwiftCrossUI doesn't track where views sit within their
    ///   ancestors, so ``GeometryProxy/frame(in:)`` always reports a view's
    ///   local bounds.
    ///
    /// - Parameter name: The name of the coordinate space.
    /// - Returns: The view, unchanged.
    public func coordinateSpace<Name: Hashable>(name: Name) -> some View {
        self
    }
}

/// Runs an action when a value computed from its content's committed
/// geometry changes.
struct OnGeometryChangeModifier<Value: Equatable, Child: View>: View {
    /// Reference storage for the last value seen, which must not schedule
    /// an update of its own when recorded (see `OnChangeModifier`).
    struct PreviousValue {
        var box = Box<Value?>(nil)
    }

    @State private var previousValue = PreviousValue()

    var body: TupleView1<Child>
    var transform: (GeometryProxy) -> Value
    var action: (Value, Value) -> Void

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        defaultCommit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )

        let proxy = GeometryProxy(
            size: CGSize(width: layout.size.width, height: layout.size.height)
        )
        let value = transform(proxy)
        let box = previousValue.box
        let previous = box.value
        guard previous != value else {
            return
        }
        box.value = value
        action(previous ?? value, value)
    }
}
