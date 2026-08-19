/// A view with gestures attached to it.
///
/// Created by ``View/gesture(_:)``. It is returned concretely rather than as
/// `some View` so that ``GestureModifier/simultaneousGesture(_:)`` can add a
/// gesture to an existing target instead of nesting a second one — nested
/// targets would mean only the outermost ever saw a pointer event.
public struct GestureModifier<Content: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children

    /// The view the gestures are attached to.
    public var body: TupleView1<Content>

    /// The gestures to recognize.
    ///
    /// Empty when every gesture handed to this view was one that no backend
    /// can recognize, in which case this modifier is a pass-through.
    var gestures: [ResolvedGesture]

    /// Adds another gesture to this view.
    ///
    /// - Parameter gesture: The gesture to recognize.
    /// - Returns: A view that recognizes `gesture` too.
    public func gesture(_ gesture: some Gesture) -> GestureModifier<Content> {
        adding(gesture)
    }

    /// Adds another gesture to this view, alongside the ones already on it.
    ///
    /// - Parameter gesture: The gesture to recognize.
    /// - Returns: A view that recognizes `gesture` too.
    public func simultaneousGesture(
        _ gesture: some Gesture
    ) -> GestureModifier<Content> {
        adding(gesture)
    }

    /// Returns a copy of this view with one more gesture attached.
    ///
    /// - Parameter gesture: The gesture to recognize.
    /// - Returns: A view that recognizes `gesture` too.
    private func adding(_ gesture: some Gesture) -> GestureModifier<Content> {
        guard let resolved = GestureModifier.resolve(gesture) else {
            return self
        }
        var modified = self
        modified.gestures.append(resolved)
        return modified
    }

    /// Reduces a gesture to the kind a backend can recognize.
    ///
    /// Returns `nil`, having warned, for a gesture that SwiftCrossUI cannot
    /// deliver truthfully — a gesture type defined outside the framework, or
    /// one asking for a coordinate space that can't be resolved.
    ///
    /// - Parameter gesture: The gesture to resolve.
    /// - Returns: The resolved gesture, or `nil` if it can't be delivered.
    @MainActor
    static func resolve(_ gesture: some Gesture) -> ResolvedGesture? {
        guard let resolvable = gesture as? any _ResolvableGesture else {
            logger.warnOnce(
                """
                '\(type(of: gesture))' isn't a gesture SwiftCrossUI knows how \
                to recognize, so its handlers will never run. Only \
                'DragGesture' and 'SpatialTapGesture' can be attached with \
                'View.gesture(_:)'.
                """
            )
            return nil
        }

        let resolved = resolvable._resolved
        guard case .named(let name) = resolved.coordinateSpace else {
            return resolved
        }
        logger.warnOnce(
            """
            A gesture asked for the named coordinate space '\(name)', which \
            SwiftCrossUI can't resolve yet, so its handlers will never run. \
            Reporting positions from the wrong origin would be worse than \
            reporting none. Use '.local' or '.global' instead.
            """
        )
        return nil
    }

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

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        let child: Backend.Widget = children.child0.widget.into()

        func createTarget<
            PointerBackend: BaseAppBackend & BackendFeatures.PointerGestures
        >(_ backend: PointerBackend) -> Backend.Widget {
            let target = backend.createPointerGestureTarget(
                wrapping: child as! PointerBackend.Widget
            )
            return target as! Backend.Widget
        }

        guard
            !gestures.isEmpty,
            let pointerBackend = backend
                as? any BaseAppBackend & BackendFeatures.PointerGestures
        else {
            return child
        }
        return createTarget(pointerBackend)
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

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let size = children.child0.commit().size
        backend.setSize(of: widget, to: size.vector)

        let gestures = gestures
        var dragDistances: [Double] = []
        var tapCount: Int?
        for gesture in gestures {
            switch gesture {
                case .drag: dragDistances.append(gesture.minimumDragDistance)
                case .spatialTap: tapCount = gesture.tapCount
            }
        }

        var onDragChanged: (@MainActor (PointerGestureEvent) -> Void)?
        var onDragEnded: (@MainActor (PointerGestureEvent) -> Void)?
        var onTap: (@MainActor (PointerGestureEvent) -> Void)?

        if !dragDistances.isEmpty {
            onDragChanged = { event in
                for gesture in gestures {
                    gesture.sendDrag(event, phase: .changed)
                }
            }
            onDragEnded = { event in
                for gesture in gestures {
                    gesture.sendDrag(event, phase: .ended)
                }
            }
        }

        if tapCount != nil {
            onTap = { event in
                for gesture in gestures {
                    gesture.sendTap(event)
                }
            }
        }

        func updateTarget<
            PointerBackend: BaseAppBackend & BackendFeatures.PointerGestures
        >(_ backend: PointerBackend) {
            backend.updatePointerGestureTarget(
                widget as! PointerBackend.Widget,
                minimumDragDistance: dragDistances.min() ?? 0.0,
                tapCount: tapCount ?? 1,
                coordinateSpace: gestures[0].coordinateSpace,
                environment: environment,
                onDragChanged: onDragChanged,
                onDragEnded: onDragEnded,
                onTap: onTap
            )
        }

        guard
            !gestures.isEmpty,
            let pointerBackend = backend
                as? any BaseAppBackend & BackendFeatures.PointerGestures
        else {
            return
        }
        updateTarget(pointerBackend)
    }
}

extension View {
    /// Attaches a gesture to this view.
    ///
    /// ```swift
    /// Canvas { context, size in
    ///     draw(&context, size)
    /// }
    /// .gesture(
    ///     DragGesture(minimumDistance: 4)
    ///         .onEnded { value in
    ///             move(from: value.startLocation, to: value.location)
    ///         }
    /// )
    /// ```
    ///
    /// ## Backend support
    ///
    /// Recognizing a gesture needs the backend to implement
    /// ``BackendFeatures/PointerGestures``. A backend that doesn't leaves the
    /// view's layout and hit testing exactly as they were and never calls the
    /// gesture's handlers; ``View/onTapGesture(gesture:perform:)`` and
    /// ``View/onHover(perform:)`` work everywhere and need no such support.
    /// `AppKitBackend` implements it.
    ///
    /// ## Limits
    ///
    /// - A gesture asking for ``CoordinateSpace/named(_:)`` is refused, with a
    ///   warning, rather than reporting positions from the wrong origin.
    ///   SwiftCrossUI has no registry of named coordinate spaces yet.
    /// - ``DragGesture/Value/startLocation`` is where the drag was
    ///   *recognized*, which for a non-zero
    ///   ``DragGesture/minimumDistance`` is that far from where the pointer
    ///   went down.
    ///
    /// - Parameter gesture: The gesture to recognize.
    /// - Returns: A view that recognizes `gesture`.
    ///
    /// ## See Also
    ///
    /// - ``Gesture``
    /// - ``View/simultaneousGesture(_:)``
    /// - ``View/onTapGesture(gesture:perform:)``
    public func gesture(_ gesture: some Gesture) -> GestureModifier<Self> {
        GestureModifier(
            body: TupleView1(self),
            gestures: [GestureModifier<Self>.resolve(gesture)].compactMap { $0 }
        )
    }

    /// Attaches a gesture to this view, letting the gestures already on it
    /// keep running alongside it.
    ///
    /// Carries the same backend requirements and limits as
    /// ``View/gesture(_:)``.
    ///
    /// - Parameter gesture: The gesture to recognize.
    /// - Returns: A view that recognizes `gesture` alongside its existing
    ///   gestures.
    ///
    /// ## See Also
    ///
    /// - ``Gesture``
    /// - ``View/gesture(_:)``
    public func simultaneousGesture(
        _ gesture: some Gesture
    ) -> GestureModifier<Self> {
        self.gesture(gesture)
    }
}
