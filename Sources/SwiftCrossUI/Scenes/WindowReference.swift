
/// Holds the view graph and window handle for a single window.
@MainActor
final class WindowReference<SceneType: WindowingScene> {
    /// The scene.
    private var scene: SceneType
    /// The view graph of the window's root view.
    private let viewGraph: ViewGraph<SceneType.Content>
    /// The window being rendered in.
    let window: Any
    /// `false` after the first scene update.
    private var isFirstUpdate = true
    /// The cached window size. Nil on first run or after a window is resized.
    private var cachedWindowSize: SIMD2<Int>?
    /// The environment most recently provided by this node's parent scene.
    private var parentEnvironment: EnvironmentValues
    /// The container used to center the root view in the window.
    private let containerWidget: AnyWidget
    /// The window's preferred color scheme, cached from the last update.
    private var preferredColorScheme: ColorScheme?

    /// The window's content size limits, and the ``LayoutPass`` token as of the
    /// end of the update that measured them.
    ///
    /// Deriving these means laying the whole graph out at proposals the window
    /// never uses, so an update that can prove nothing has changed since reuses
    /// them instead. See the use site for what makes that safe.
    private var cachedSizeLimits:
        (minimum: ViewSize, maximum: ViewSize?, token: UInt64)?

    /// Observation of the scene's content closure.
    ///
    /// The closure handed to `WindowGroup { ... }` runs outside any view
    /// graph node, so an observable property it reads (`Text(model.title)`
    /// at the window's root, say) would otherwise never invalidate anything.
    /// Created by the first update.
    private var contentObservation: ObservationRegistration?

    /// - Parameters:
    ///   - closeHandler: The action to perform when the window is closed. Should
    ///     dispose of the scene's reference to this `WindowReference`.
    ///   - id: A unique id to use when restoring the window's frame from disk (if present).
    init<Backend: BaseAppBackend>(
        scene: SceneType,
        backend: Backend,
        environment: EnvironmentValues,
        onClose closeHandler: @escaping @Sendable @MainActor () -> Void,
        id: String
    ) {
        self.scene = scene
        let window = backend.createWindow(
            withDefaultSize: environment.defaultWindowSize,
            id: id
        )

        viewGraph = ViewGraph(
            for: scene.content(),
            backend: backend,
            environment: environment.with(\.window, window)
        )
        let rootWidget = viewGraph.rootNode.concreteNode(for: Backend.self).widget

        let container = backend.createContainer()
        backend.insert(rootWidget, into: container, at: 0)
        self.containerWidget = AnyWidget(container)

        backend.setChild(ofWindow: window, to: container)
        backend.setTitle(ofWindow: window, to: scene.title)

        self.window = window
        parentEnvironment = environment

        if let backend = backend as? any BackendFeatures.WindowClosing {
            func setCloseHandler<NewBackend: BackendFeatures.WindowClosing>(backend: NewBackend) {
                backend.setCloseHandler(ofWindow: window as! NewBackend.Window, to: closeHandler)
            }
            setCloseHandler(backend: backend)
        }

        backend.setResizeHandler(ofWindow: window) { [weak self] newSize in
            guard let self else { return }
            self.update(
                // A resize changes the size the content is proposed and
                // nothing else, so the scene value is the one already stored.
                // Passing it as `newScene` would re-run the scene's content
                // closure and re-register its observation on every frame of a
                // window drag, and would defeat the size-limit cache, all to
                // rebuild a value equal to the one already held.
                nil,
                proposedWindowSize: newSize,
                needsWindowSizeCommit: false,
                backend: backend,
                environment: self.parentEnvironment,
                windowSizeIsFinal: !backend.isWindowProgrammaticallyResizable(window)
            )
        }

        backend.setWindowEnvironmentChangeHandler(of: window) { [weak self] in
            guard let self else { return }
            self.update(
                self.scene,
                proposedWindowSize: backend.size(ofWindow: window),
                needsWindowSizeCommit: false,
                backend: backend,
                environment: self.parentEnvironment,
                windowSizeIsFinal: !backend.isWindowProgrammaticallyResizable(window)
            )
        }
    }

    func update<Backend: BaseAppBackend>(
        _ newScene: SceneType?,
        backend: Backend,
        environment: EnvironmentValues
    ) {
        guard let window = window as? Backend.Window else {
            fatalError("Scene updated with a backend incompatible with the window it was given")
        }

        let isProgramaticallyResizable =
            backend.isWindowProgrammaticallyResizable(window)

        let proposedWindowSize: SIMD2<Int>
        let usedDefaultSize: Bool
        if isFirstUpdate && isProgramaticallyResizable && !backend.restoresWindowFrames {
            proposedWindowSize = environment.defaultWindowSize
            usedDefaultSize = true
        } else {
            proposedWindowSize = cachedWindowSize ?? backend.size(ofWindow: window)
            usedDefaultSize = false
        }

        update(
            newScene,
            proposedWindowSize: proposedWindowSize,
            needsWindowSizeCommit: usedDefaultSize,
            backend: backend,
            environment: environment,
            windowSizeIsFinal: !isProgramaticallyResizable
        )
    }

    /// Drives one update at an explicit proposed size.
    ///
    /// Exists for the performance harness, which needs to measure a window
    /// update — and in particular a window *resize*, where only the proposed
    /// size changes — without faking a backend resize event. The framework
    /// itself never calls this; it goes through
    /// ``update(_:proposedWindowSize:needsWindowSizeCommit:backend:environment:windowSizeIsFinal:)``
    /// like everything else.
    ///
    /// - Parameters:
    ///   - newScene: The scene, or `nil` to reuse the previous scene value (as
    ///     a resize does).
    ///   - proposedWindowSize: The size to lay the window's content out at.
    ///   - backend: The backend to use.
    ///   - environment: The current environment.
    func updateForBenchmarking<Backend: BaseAppBackend>(
        _ newScene: SceneType?,
        proposedWindowSize: SIMD2<Int>,
        backend: Backend,
        environment: EnvironmentValues
    ) {
        update(
            newScene,
            proposedWindowSize: proposedWindowSize,
            needsWindowSizeCommit: false,
            backend: backend,
            environment: environment,
            // Measuring one update means measuring exactly one, so don't let a
            // clamped size restart it part way through.
            windowSizeIsFinal: true
        )
    }

    /// Updates the `WindowReference`.
    /// - Parameters:
    ///   - newScene: The scene. `nil` if reusing previous scene value.
    ///   - proposedWindowSize: The proposed window size.
    ///   - needsWindowSizeCommit: Whether the proposed window size matches the
    ///     windows current size (or imminent size in the case of a window
    ///     resize). We use this parameter instead of comparing to the window's
    ///     current size to the proposed size, because some backends (such as
    ///     AppKitBackend) trigger window resize handlers *before* the underlying
    ///     window gets assigned its new size (allowing us to pre-emptively update the
    ///     window's content to match the new size).
    ///   - backend: The backend to use.
    ///   - environment: The current environment.
    ///   - windowSizeIsFinal: If true, no further resizes can/will be made. This
    ///     is true on platforms that don't support programmatic window resizing,
    ///     and when a window is full screen.
    private func update<Backend: BaseAppBackend>(
        _ newScene: SceneType?,
        proposedWindowSize: SIMD2<Int>,
        needsWindowSizeCommit: Bool,
        backend: Backend,
        environment: EnvironmentValues,
        windowSizeIsFinal: Bool = false
    ) {
        guard let window = window as? Backend.Window else {
            fatalError("Scene updated with a backend incompatible with the window it was given")
        }

        parentEnvironment = environment

        if let newScene {
            // Don't set default size even if it has changed. We only set that once
            // at window creation since some backends don't have a concept of
            // 'default' size which would mean that setting the default size every time
            // the default size changed would resize the window (which is incorrect
            // behaviour).
            backend.setTitle(ofWindow: window, to: newScene.title)
            scene = newScene
        }

        var environment =
            backend.computeWindowEnvironment(
                window: window,
                rootEnvironment: environment.with(\.window, window)
            )
            .with(\.onResize) { [weak self] _ in
                guard let self else { return }
                self.cachedWindowSize = nil
                // TODO: Figure out whether this would still work if we didn't recompute the
                //   scene's body. I have a vague feeling that it wouldn't work in all cases?
                //   But I don't have the time to come up with a counterexample right now.
                self.update(
                    self.scene,
                    proposedWindowSize: backend.size(ofWindow: window),
                    needsWindowSizeCommit: false,
                    backend: backend,
                    environment: environment
                )
            }
        let outerColorScheme = environment.colorScheme

        // Update environment with latest cached value before first update to
        // minimise toggling between outer color scheme and preferred color
        // scheme where possible (could confuse people when logging the color
        // scheme or debugging things)
        if let preferredColorScheme {
            environment.colorScheme = preferredColorScheme
        }

        // The scene's content closure is re-run when the scene changed, and
        // once on the first update so that what it reads is observed (the
        // evaluation in `init` couldn't be tracked yet).
        let newContent: SceneType.Content?
        if newScene != nil || contentObservation == nil {
            newContent = trackedContent(of: newScene ?? scene, backend: backend)
        } else {
            newContent = nil
        }

        // The window's size limits come from laying the whole graph out at
        // proposals the window will never actually use — `.zero` for the
        // minimum, and `.infinity` for the maximum under `.contentSize`. Those
        // sizes are a function of the content and the environment, and not of
        // the size the window is being proposed, so a resize (which changes
        // only the proposal) can reuse the ones it measured last time.
        //
        // Reuse is only safe while nothing in the graph can have changed since
        // they were measured, which is precisely what an unchanged
        // ``LayoutPass`` token says: a token only advances when the graph is
        // entered from outside, so if no pass has begun since the end of the
        // last update then no state change, observation change or resize
        // handler has run in between. Content being recomputed advances it too,
        // via the passes below, and is ruled out separately because a new
        // content value can change the limits without any pass having run.
        //
        // Note that the cache holds the probes' *results*, never their bodies:
        // a body evaluated while `isProbingLayout` is true is not valid for the
        // final pass, so the final pass below still evaluates its own.
        let canReuseSizeLimits =
            newContent == nil
            && cachedSizeLimits?.token == LayoutPass.token

        let minimumWindowSize: ViewSize
        let maximumWindowSize: ViewSize?
        if canReuseSizeLimits, let cached = cachedSizeLimits {
            minimumWindowSize = cached.minimum
            maximumWindowSize = cached.maximum
            // The environment update that the probes would have performed is a
            // no-op here: `preferredColorScheme` is unchanged (nothing has run
            // that could change it), and the caller already applied the cached
            // value to `environment` above.
        } else {
            let probingResult = viewGraph.computeLayout(
                with: newContent,
                proposedSize: .zero,
                environment: environment
                    .with(\.allowLayoutCaching, true)
            )
            minimumWindowSize = probingResult.size
            updateEnvironment(
                &environment,
                viewLayoutResult: probingResult,
                outerColorScheme: outerColorScheme,
                backend: backend
            )

            // With `.contentSize`, the window's maximum size is the maximum size of its
            // content. With `.contentMinSize` (and `.automatic`), there is no maximum
            // size.
            switch environment.windowResizability {
                case .contentSize:
                    let result = viewGraph.computeLayout(
                        with: newScene?.content(),
                        proposedSize: .infinity,
                        environment: environment.with(\.allowLayoutCaching, true)
                    )
                    updateEnvironment(
                        &environment,
                        viewLayoutResult: result,
                        outerColorScheme: outerColorScheme,
                        backend: backend
                    )
                    maximumWindowSize = result.size
                case .automatic, .contentMinSize:
                    maximumWindowSize = nil
            }
        }

        let clampedWindowSize = ViewSize(
            min(
                maximumWindowSize?.width ?? .infinity,
                max(minimumWindowSize.width, Double(proposedWindowSize.x))
            ),
            min(
                maximumWindowSize?.height ?? .infinity,
                max(minimumWindowSize.height, Double(proposedWindowSize.y))
            )
        )

        if clampedWindowSize.vector != proposedWindowSize && !windowSizeIsFinal {
            // Restart the window update if the content has caused the window to
            // change size.
            return update(
                scene,
                proposedWindowSize: clampedWindowSize.vector,
                needsWindowSizeCommit: true,
                backend: backend,
                environment: environment,
                windowSizeIsFinal: true
            )
        }

        // Set these even if the window isn't programmatically resizable
        // because the window may still be user resizable.
        backend.setSizeLimits(
            ofWindow: window,
            minimum: minimumWindowSize.vector,
            maximum: maximumWindowSize?.vector
        )

        let finalContentResult = viewGraph.computeLayout(
            proposedSize: ProposedViewSize(proposedWindowSize),
            environment: environment
        )
        updateEnvironment(
            &environment,
            viewLayoutResult: finalContentResult,
            outerColorScheme: outerColorScheme,
            backend: backend
        )

        backend.setPosition(
            ofChildAt: 0,
            in: containerWidget.into(),
            to: (proposedWindowSize &- finalContentResult.size.vector) / 2
        )

        if needsWindowSizeCommit {
            backend.setSize(ofWindow: window, to: proposedWindowSize)
        }
        cachedWindowSize = proposedWindowSize

        if let backend = backend as? any BackendFeatures.WindowBehaviors {
            func setBehaviors<NewBackend: BackendFeatures.WindowBehaviors>(backend: NewBackend) {
                backend.setBehaviors(
                    ofWindow: window as! NewBackend.Window,
                    closable: finalContentResult.preferences.windowDismissBehavior?
                        .isEnabled ?? true,
                    minimizable: finalContentResult.preferences.preferredWindowMinimizeBehavior?
                        .isEnabled ?? true,
                    resizable: finalContentResult.preferences.windowResizeBehavior?
                        .isEnabled ?? true
                )
            }
            setBehaviors(backend: backend)
        }

        if let backend = backend as? any BackendFeatures.WindowCloseRequests {
            func setCloseRequestHandler<NewBackend: BackendFeatures.WindowCloseRequests>(
                backend: NewBackend
            ) {
                backend.setCloseRequestHandler(
                    ofWindow: window as! NewBackend.Window,
                    to: finalContentResult.preferences.onWindowCloseRequested
                )
            }
            setCloseRequestHandler(backend: backend)
        } else if finalContentResult.preferences.onWindowCloseRequested != nil {
            logger.warnOnce("\(type(of: backend)) doesn't support window close authorization")
        }

        // Generally just used to update the window color scheme
        backend.updateWindow(window, environment: environment)

        // Delay committing the view graph so that the View.inspectWindow(_:)
        // modifiers can be used to overwrite certain SwiftCrossUI behaviors
        viewGraph.commit()

        // Remember the size limits against the token this update finished on,
        // so that the next update can tell whether anything has entered the
        // graph since. Recorded after the commit because a commit can still
        // begin a pass.
        cachedSizeLimits = (minimumWindowSize, maximumWindowSize, LayoutPass.token)

        if isFirstUpdate {
            backend.show(window: window)
            isFirstUpdate = false
        }
    }

    /// Evaluates the scene's content closure, observing what it reads.
    ///
    /// When an observed property later changes, the scene is updated again
    /// (on the main thread, asynchronously) so that the closure re-runs with
    /// the new value.
    ///
    /// - Parameters:
    ///   - scene: The scene whose content to evaluate.
    ///   - backend: The backend, used to schedule the update.
    /// - Returns: The content.
    private func trackedContent<Backend: BaseAppBackend>(
        of scene: SceneType,
        backend: Backend
    ) -> SceneType.Content {
        let registration: ObservationRegistration
        if let contentObservation {
            registration = contentObservation
        } else {
            registration = ObservationRegistration { [weak self, backend] in
                backend.runInMainThread {
                    self?.contentDidChange(backend: backend)
                }
            }
            contentObservation = registration
        }

        let generation = registration.beginGeneration()
        return ObservationSupport.withTracking {
            scene.content()
        } onChange: {
            registration.reportChange(generation: generation)
        }
    }

    /// Re-runs the scene's content closure after something it read changed.
    ///
    /// - Parameter backend: The backend to update through.
    private func contentDidChange<Backend: BaseAppBackend>(backend: Backend) {
        contentObservation?.updateWillRun()
        guard let window = window as? Backend.Window else {
            return
        }
        update(
            scene,
            proposedWindowSize: cachedWindowSize ?? backend.size(ofWindow: window),
            needsWindowSizeCommit: false,
            backend: backend,
            environment: parentEnvironment,
            windowSizeIsFinal: !backend.isWindowProgrammaticallyResizable(window)
        )
    }

    func activate<Backend: BaseAppBackend>(backend: Backend) {
        guard let window = window as? Backend.Window else {
            fatalError("Scene updated with a backend incompatible with the window it was given")
        }

        backend.activate(window: window)
    }

    private func updateEnvironment<Backend: BaseAppBackend>(
        _ environment: inout EnvironmentValues,
        viewLayoutResult: ViewLayoutResult,
        outerColorScheme: ColorScheme,
        backend: Backend
    ) {
        preferredColorScheme = viewLayoutResult.preferences.preferredColorScheme

        // Update environment with preferred color scheme if provided
        if let preferredColorScheme, backend.canOverrideWindowColorScheme {
            environment.colorScheme = preferredColorScheme
        } else {
            // If the preferred color scheme just changed to nil, then we must
            // reset the environment's color scheme to the outer color scheme
            // provided by a higher scene or the system.
            environment.colorScheme = outerColorScheme
        }
    }
}
