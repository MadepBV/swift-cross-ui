/// A view with gestures attached to it.
///
/// Created by ``View/gesture(_:)``, ``View/onScrollWheel(perform:)``,
/// ``View/onMagnify(perform:)``, ``View/onContinuousHover(coordinateSpace:perform:)``
/// and ``View/onPointerMove(perform:)``. It is returned concretely rather than as
/// `some View` so that ``GestureModifier/simultaneousGesture(_:)`` (and the
/// scroll and magnify modifiers) can add to an existing target instead of
/// nesting a second one — nested targets would mean only the outermost ever
/// saw a pointer event.
public struct GestureModifier<Content: View>: TypeSafeView {
    typealias Children = TupleView1<Content>.Children

    /// The view the gestures are attached to.
    public var body: TupleView1<Content>

    /// The gestures to recognize.
    ///
    /// Empty when every gesture handed to this view was one that no backend
    /// can recognize, in which case this modifier is a pass-through.
    var gestures: [ResolvedGesture]

    /// The actions to run for each scroll wheel or trackpad scroll step.
    var scrollHandlers: [@MainActor (PointerScrollEvent) -> Void] = []

    /// The actions to run for each pinch-to-zoom step.
    var magnifyHandlers: [@MainActor (PointerMagnifyEvent) -> Void] = []

    /// The actions to run for each button-less pointer move (and the exit).
    var moveHandlers: [@MainActor (PointerMoveEvent) -> Void] = []

    /// The coordinate space asked for by a hover, when no gesture picked one.
    var moveCoordinateSpace: CoordinateSpace = .local

    /// Whether anything at all is attached, and so whether a pointer gesture
    /// target is needed.
    private var hasHandlers: Bool {
        !gestures.isEmpty || !scrollHandlers.isEmpty || !magnifyHandlers.isEmpty
            || !moveHandlers.isEmpty
    }

    /// Adds a pointer move handler to this view, alongside whatever is
    /// already attached.
    ///
    /// - Parameter action: The action to run for each move.
    /// - Returns: A view that also reports pointer movement.
    public func onPointerMove(
        perform action: @escaping @MainActor (PointerMoveEvent) -> Void
    ) -> GestureModifier<Content> {
        var modified = self
        modified.moveHandlers.append(action)
        return modified
    }

    /// Adds a continuous hover handler to this view, alongside whatever is
    /// already attached.
    ///
    /// - Parameters:
    ///   - coordinateSpace: The space to report locations in.
    ///   - action: The action to run for each hover phase.
    /// - Returns: A view that also reports hovering.
    public func onContinuousHover(
        coordinateSpace: CoordinateSpace = .local,
        perform action: @escaping @MainActor (HoverPhase) -> Void
    ) -> GestureModifier<Content> {
        guard let space = GestureModifier.resolveCoordinateSpace(coordinateSpace) else {
            return self
        }
        var modified = self
        modified.moveCoordinateSpace = space
        modified.moveHandlers.append { event in
            action(event.phase)
        }
        return modified
    }

    /// Refuses a named coordinate space, which SwiftCrossUI can't resolve.
    ///
    /// - Parameter coordinateSpace: The requested space.
    /// - Returns: The space, or `nil` (having warned) if it can't be honoured.
    @MainActor
    static func resolveCoordinateSpace(_ coordinateSpace: CoordinateSpace) -> CoordinateSpace? {
        guard case .named(let name) = coordinateSpace else {
            return coordinateSpace
        }
        logger.warnOnce(
            """
            A hover asked for the named coordinate space '\(name)', which \
            SwiftCrossUI can't resolve yet, so its handler will never run. \
            Use '.local' or '.global' instead.
            """
        )
        return nil
    }

    /// Adds a scroll wheel handler to this view, alongside whatever is
    /// already attached.
    ///
    /// - Parameter action: The action to run for each scroll step.
    /// - Returns: A view that also reports scrolling.
    public func onScrollWheel(
        perform action: @escaping @MainActor (PointerScrollEvent) -> Void
    ) -> GestureModifier<Content> {
        var modified = self
        modified.scrollHandlers.append(action)
        return modified
    }

    /// Adds a pinch-to-zoom handler to this view, alongside whatever is
    /// already attached.
    ///
    /// - Parameter action: The action to run for each pinch step.
    /// - Returns: A view that also reports pinching.
    public func onMagnify(
        perform action: @escaping @MainActor (PointerMagnifyEvent) -> Void
    ) -> GestureModifier<Content> {
        var modified = self
        modified.magnifyHandlers.append(action)
        return modified
    }

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
            hasHandlers,
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

        let scrollHandlers = scrollHandlers
        var onScroll: (@MainActor (PointerScrollEvent) -> Void)?
        if !scrollHandlers.isEmpty {
            onScroll = { event in
                for handler in scrollHandlers {
                    handler(event)
                }
            }
        }

        let magnifyHandlers = magnifyHandlers
        var onMagnify: (@MainActor (PointerMagnifyEvent) -> Void)?
        if !magnifyHandlers.isEmpty {
            onMagnify = { event in
                for handler in magnifyHandlers {
                    handler(event)
                }
            }
        }

        let moveHandlers = moveHandlers
        var onMove: (@MainActor (PointerMoveEvent) -> Void)?
        if !moveHandlers.isEmpty {
            onMove = { event in
                for handler in moveHandlers {
                    handler(event)
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
                // One target reports every event in one space: the first
                // gesture's, else the hover's, else the target's own.
                coordinateSpace: gestures.first?.coordinateSpace ?? moveCoordinateSpace,
                environment: environment,
                onDragChanged: onDragChanged,
                onDragEnded: onDragEnded,
                onTap: onTap,
                onScroll: onScroll,
                onMagnify: onMagnify,
                onMove: onMove
            )
        }

        guard
            hasHandlers,
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

    /// Runs an action for each step of a scroll wheel or trackpad scroll
    /// over this view.
    ///
    /// SwiftUI has no modifier for raw wheel input, so this is SwiftCrossUI
    /// vocabulary. It exists for views that scroll or zoom their own content
    /// — a drawing canvas panning with the wheel and zooming at the cursor
    /// with Command (Control on Windows) held:
    ///
    /// ```swift
    /// SheetCanvas()
    ///     .onScrollWheel { event in
    ///         if event.modifiers.contains(.command) {
    ///             zoom(by: event.deltaY, at: event.location)
    ///         } else {
    ///             pan(by: CGSize(width: event.deltaX, height: event.deltaY))
    ///         }
    ///     }
    /// ```
    ///
    /// While a handler is attached the view consumes the scrolling; without
    /// one it reaches whatever it would have reached before, such as an
    /// enclosing ``ScrollView``. See ``PointerScrollEvent`` for the units the
    /// deltas are in.
    ///
    /// Carries the same backend requirements as ``View/gesture(_:)``: a
    /// backend without ``BackendFeatures/PointerGestures`` never calls the
    /// action. `AppKitBackend` and `WinUIBackend` implement it.
    ///
    /// - Parameter action: The action to run for each scroll step.
    /// - Returns: A view that reports scrolling.
    ///
    /// ## See Also
    ///
    /// - ``PointerScrollEvent``
    /// - ``View/onMagnify(perform:)``
    public func onScrollWheel(
        perform action: @escaping @MainActor (PointerScrollEvent) -> Void
    ) -> GestureModifier<Self> {
        GestureModifier(
            body: TupleView1(self),
            gestures: [],
            scrollHandlers: [action]
        )
    }

    /// Runs an action for each step of a pinch-to-zoom over this view.
    ///
    /// This is SwiftCrossUI's spelling of SwiftUI's `MagnifyGesture`, as a
    /// modifier: ``PointerMagnifyEvent/magnification`` is the same
    /// accumulated scale factor that `MagnifyGesture.Value.magnification`
    /// reports, and the event adds the pinch's location and the modifier
    /// keys.
    ///
    /// ```swift
    /// SheetCanvas()
    ///     .onMagnify { event in
    ///         if event.phase == .began { zoomAtPinchStart = zoom }
    ///         zoom = zoomAtPinchStart * event.magnification
    ///     }
    /// ```
    ///
    /// Carries the same backend requirements as ``View/gesture(_:)``. On
    /// macOS a trackpad pinch drives it; on Windows a touch pinch does, and a
    /// precision touchpad pinch arrives as a Control+wheel
    /// ``View/onScrollWheel(perform:)`` event instead, as it does for every
    /// Windows app.
    ///
    /// - Parameter action: The action to run for each pinch step.
    /// - Returns: A view that reports pinching.
    ///
    /// ## See Also
    ///
    /// - ``PointerMagnifyEvent``
    /// - ``View/onScrollWheel(perform:)``
    public func onMagnify(
        perform action: @escaping @MainActor (PointerMagnifyEvent) -> Void
    ) -> GestureModifier<Self> {
        GestureModifier(
            body: TupleView1(self),
            gestures: [],
            magnifyHandlers: [action]
        )
    }

    /// Runs an action as the pointer moves over this view with no button
    /// held, and once more when it leaves.
    ///
    /// This is SwiftUI's `onContinuousHover`. A snap echo that follows the
    /// mouse, say:
    ///
    /// ```swift
    /// SheetCanvas()
    ///     .onContinuousHover { phase in
    ///         switch phase {
    ///             case .active(let location): snapEcho = snap(near: location)
    ///             case .ended: snapEcho = nil
    ///         }
    ///     }
    /// ```
    ///
    /// Moves with a button held are drags, delivered through ``DragGesture``
    /// rather than here. Use ``View/onPointerMove(perform:)`` to also learn
    /// which modifier keys were held during the move.
    ///
    /// Carries the same backend requirements and coordinate-space limits as
    /// ``View/gesture(_:)``: a backend without
    /// ``BackendFeatures/PointerGestures`` never calls the action, and
    /// ``CoordinateSpace/named(_:)`` is refused with a warning. When a
    /// gesture on the same view asks for a different space, the gesture's
    /// space wins for every event on the view.
    ///
    /// - Parameters:
    ///   - coordinateSpace: The space to report locations in.
    ///   - action: The action to run for each hover phase.
    /// - Returns: A view that reports hovering.
    ///
    /// ## See Also
    ///
    /// - ``HoverPhase``
    /// - ``View/onPointerMove(perform:)``
    /// - ``View/onHover(perform:)``
    public func onContinuousHover(
        coordinateSpace: CoordinateSpace = .local,
        perform action: @escaping @MainActor (HoverPhase) -> Void
    ) -> GestureModifier<Self> {
        GestureModifier(body: TupleView1(self), gestures: [])
            .onContinuousHover(coordinateSpace: coordinateSpace, perform: action)
    }

    /// Runs an action as the pointer moves over this view with no button
    /// held, and once more when it leaves, with the modifier keys.
    ///
    /// SwiftUI's ``View/onContinuousHover(coordinateSpace:perform:)`` reports
    /// only a location; this is SwiftCrossUI vocabulary for the cases that
    /// need to know whether Shift or Command was held during the move (a
    /// constrained draft preview, say). ``PointerMoveEvent/phase`` is the
    /// same ``HoverPhase`` the SwiftUI spelling delivers.
    ///
    /// Locations are reported in the view's own space, or in the window's
    /// when a gesture or hover on the same view asked for
    /// ``CoordinateSpace/global``.
    ///
    /// - Parameter action: The action to run for each move.
    /// - Returns: A view that reports pointer movement.
    ///
    /// ## See Also
    ///
    /// - ``PointerMoveEvent``
    /// - ``View/onContinuousHover(coordinateSpace:perform:)``
    public func onPointerMove(
        perform action: @escaping @MainActor (PointerMoveEvent) -> Void
    ) -> GestureModifier<Self> {
        GestureModifier(
            body: TupleView1(self),
            gestures: [],
            moveHandlers: [action]
        )
    }
}
