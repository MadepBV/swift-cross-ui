import Foundation

/// A view that draws itself with immediate-mode drawing commands.
///
/// ```swift
/// Canvas { context, size in
///     let bounds = Path.Rect(
///         x: 0.0,
///         y: 0.0,
///         width: size.width,
///         height: size.height
///     )
///     let box = Path().addRectangle(bounds)
///     context.fill(box, with: .color(.white))
///     context.stroke(box, with: .color(.black), lineWidth: 1.0)
/// }
/// ```
///
/// A canvas takes up all of the space proposed to it. When a dimension is
/// unspecified it falls back on 10 points, matching ``Shape``.
///
/// ## How immediate mode is bridged onto the view graph
///
/// SwiftCrossUI is retained-mode: views create widgets once and then update
/// them. Immediate-mode drawing is bridged onto that model by *recording*
/// rather than rasterising. The renderer closure never touches a backend. It
/// issues commands into a ``GraphicsContext``, which accumulates them in a
/// flat list. ``Canvas`` then replays that list onto a pool of backend child
/// widgets held inside a container:
///
/// - each fill and each stroke becomes one path widget, created with
///   `BackendFeatures.Paths`, exactly the same route that ``Shape`` takes;
/// - each run of text becomes one text view, created with
///   `BackendFeatures.TextViews`;
/// - children are laid out in command order, so painter's-algorithm layering
///   works for paths and text alike.
///
/// The pool is reconciled rather than rebuilt: on each pass the new command
/// list is compared with the previous one and widgets are reused for as long as
/// the two agree on the *kind* of each command. Only the diverging tail is torn
/// down and re-created, and a path whose geometry is unchanged is not rebuilt
/// in the backend at all.
///
/// ### What that costs
///
/// - **The renderer runs on every commit.** SwiftCrossUI commits a layout
///   whenever the view graph updates, which is more often than "when the
///   drawing changed". Keep the renderer cheap and free of side effects.
/// - **A canvas costs one widget per drawing command.** A renderer that issues
///   thousands of commands will create thousands of widgets. A hatch-pattern
///   swatch or a profile sketch is fine; a scatter plot of 100,000 points is
///   not. Merge geometry into a single ``Path`` where you can — one `fill` of a
///   path containing 200 subpaths costs one widget.
/// - **Changing the *shape* of the command list is not free.** Reordering
///   fills and text (rather than changing their parameters) discards and
///   re-creates the widgets from the first difference onwards.
/// - **State captured by the closure behaves differently from SwiftUI.** The
///   closure is stored on the view value, so it re-captures whatever the
///   surrounding `body` captured, on every `body` evaluation, as in SwiftUI.
///   But because the closure also runs on layout passes that were not caused
///   by a state change, a renderer that mutates captured reference state will
///   run that mutation more often than the equivalent SwiftUI code does.
///
/// ### What is missing
///
/// - **Clipping is only partially honoured.** See
///   ``GraphicsContext/clip(to:)``. Exact clipping needs a new backend
///   feature — either a `clip` parameter on
///   `BackendFeatures.Paths.renderPath(_:container:strokeColor:fillColor:overrideStrokeStyle:)`
///   or a clipping container widget.
/// - **Text is a widget, not glyphs.** See ``GraphicsContext/draw(_:at:anchor:)``.
///   The context's transform positions text but does not rotate, scale or shear
///   it, and text is never clipped.
/// - **Only solid-color shading exists.** See ``GraphicsContext/Shading``.
/// - **Backends without `BackendFeatures.Paths` cannot show a canvas.** This is
///   the same restriction that ``Shape`` has; `DummyBackend` is the only
///   affected backend.
public struct Canvas: View {
    /// The type of a canvas' drawing closure.
    ///
    /// The closure receives a context to draw into and the canvas' size in
    /// points.
    public typealias Renderer = (inout GraphicsContext, CGSize) -> Void

    /// The closure that draws the canvas' content.
    let renderer: Renderer

    /// Everything the drawing depends on, when the canvas declares it.
    ///
    /// `nil` means the canvas hasn't declared its inputs, in which case the
    /// renderer has to run on every commit because there's no way to know that
    /// it would draw the same thing.
    let inputs: (any Equatable)?

    public var body = EmptyView()

    /// Creates a canvas that draws itself with the given closure.
    ///
    /// - Parameter renderer: The closure that issues drawing commands. It runs
    ///   on every layout commit; see the type's documentation.
    public init(renderer: @escaping Renderer) {
        self.renderer = renderer
        self.inputs = nil
    }

    /// Creates a canvas that redraws only when its inputs change.
    ///
    /// A canvas normally re-runs its renderer on every commit, and a commit
    /// happens whenever anything in the window updates — not only when the
    /// drawing changed. For a renderer that walks a model to issue hundreds of
    /// commands, that is the dominant cost of having the canvas on screen at
    /// all.
    ///
    /// Declaring the inputs lets the canvas skip the renderer, the command
    /// recording and the widget reconciliation entirely while they, the
    /// canvas' size, and the font and foreground colour it inherits are all
    /// unchanged:
    ///
    /// ```swift
    /// Canvas(inputs: DrawingInputs(selection: selection, zoom: zoom)) { context, size in
    ///     // ...
    /// }
    /// ```
    ///
    /// - Important: `inputs` must cover everything the renderer reads. Anything
    ///   left out will not be redrawn when it changes. Reference types are
    ///   compared by whatever `Equatable` conformance they have, so a mutable
    ///   model object is only a valid input if its identity is genuinely what
    ///   the drawing depends on.
    ///
    /// - Parameters:
    ///   - inputs: Everything the renderer reads, in a value that changes
    ///     whenever the drawing should.
    ///   - renderer: The closure that issues drawing commands.
    public init<Inputs: Equatable>(
        inputs: Inputs,
        renderer: @escaping Renderer
    ) {
        self.renderer = renderer
        self.inputs = inputs
    }

    public func children<Backend: BaseAppBackend>(
        backend _: Backend,
        snapshots _: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment _: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        CanvasStorage()
    }

    public func layoutableChildren<Backend: BaseAppBackend>(
        backend _: Backend,
        children _: any ViewGraphNodeChildren
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    @MainActor
    @CastBackend<BackendFeatures.Paths & BackendFeatures.TextViews>(
        returnsWidget: true
    )
    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        backend.createContainer()
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        ViewLayoutResult.leafView(
            size: proposedSize.replacingUnspecifiedDimensions(
                by: ViewSize(10, 10)
            )
        )
    }

    @MainActor
    @CastBackend<BackendFeatures.Paths & BackendFeatures.TextViews>(
        backendGenericName: "NewBackend"
    )
    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let storage = children as! CanvasStorage
        backend.setSize(of: widget, to: layout.size.vector)
        replay(
            in: widget,
            storage: storage,
            size: layout.size,
            environment: environment,
            backend: backend
        )
    }
}

// MARK: - Recording

extension Canvas {
    /// Runs the renderer and returns the drawing commands that it issued.
    ///
    /// This is the single entry point into the renderer; both rendering and
    /// the test suite go through it.
    ///
    /// - Parameters:
    ///   - size: The canvas' size, handed to the renderer.
    ///   - font: The font that ``GraphicsContext/resolve(_:)`` attaches to
    ///     resolved text.
    ///   - measurement: The function backing ``ResolvedText/measure(in:)``.
    ///     Pass `nil` when no backend is available.
    /// - Returns: The recorded commands, in drawing order.
    func record(
        size: CGSize,
        font: Font? = nil,
        measurement: ResolvedText.Measurement? = nil
    ) -> [GraphicsContext.Command] {
        let recorder = GraphicsContext.Recorder()
        var context = GraphicsContext(
            recorder: recorder,
            font: font,
            measurement: measurement
        )
        renderer(&context, size)
        return recorder.commands
    }
}

// MARK: - Replaying commands onto backend widgets

extension Canvas {
    /// Runs the renderer and applies the resulting commands to `container`.
    ///
    /// - Parameters:
    ///   - container: The canvas' container widget.
    ///   - storage: The canvas' persistent child pool.
    ///   - size: The canvas' size.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private func replay<
        Backend: BaseAppBackend & BackendFeatures.Paths
            & BackendFeatures.TextViews
    >(
        in container: Backend.Widget,
        storage: CanvasStorage,
        size: ViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let measurement: ResolvedText.Measurement = { string, targetSize in
            MainActor.assumeIsolated {
                Canvas.measure(
                    string,
                    in: targetSize,
                    storage: storage,
                    environment: environment,
                    backend: backend
                )
            }
        }

        // A canvas that has declared its inputs can skip the renderer, the
        // recording and the reconciliation below while nothing it draws from
        // has moved. See `init(inputs:renderer:)`.
        let font = environment.resolvedFont
        let foregroundColor = environment.suggestedForegroundColor
            .resolve(in: environment)
        if let inputs {
            if let recorded = storage.recordedInputs,
                Canvas.areEquivalent(recorded, inputs),
                storage.recordedSize == size,
                storage.recordedFont == font,
                storage.recordedForegroundColor == foregroundColor
            {
                return
            }
            storage.recordedInputs = inputs
            storage.recordedSize = size
            storage.recordedFont = font
            storage.recordedForegroundColor = foregroundColor
        }

        let commands = record(
            size: CGSize(width: size.width, height: size.height),
            font: environment.font,
            measurement: measurement
        )
        BackendCallStatistics.record("canvas.rendererRun")
        BackendCallStatistics.record("canvas.command", commands.count)

        reconcileChildren(
            of: container,
            storage: storage,
            commands: commands,
            backend: backend
        )

        let bounds = Path.Rect(
            x: 0.0,
            y: 0.0,
            width: size.width,
            height: size.height
        )
        for (index, command) in commands.enumerated() {
            apply(
                command,
                at: index,
                in: container,
                storage: storage,
                bounds: bounds,
                size: size,
                environment: environment,
                backend: backend
            )
        }
    }

    /// Grows or shrinks the child pool so that it matches the command list.
    ///
    /// Children are reused for as long as their kinds match the commands'
    /// kinds; everything from the first mismatch onwards is torn down.
    ///
    /// - Parameters:
    ///   - container: The canvas' container widget.
    ///   - storage: The canvas' persistent child pool.
    ///   - commands: The commands to make room for.
    ///   - backend: The app's backend.
    private func reconcileChildren<
        Backend: BaseAppBackend & BackendFeatures.Paths
            & BackendFeatures.TextViews
    >(
        of container: Backend.Widget,
        storage: CanvasStorage,
        commands: [GraphicsContext.Command],
        backend: Backend
    ) {
        var reusableCount = 0
        let sharedCount = min(commands.count, storage.children.count)
        while reusableCount < sharedCount,
            commands[reusableCount].kind == storage.children[reusableCount].kind
        {
            reusableCount += 1
        }

        BackendCallStatistics.record("canvas.childReused", reusableCount)

        while storage.children.count > reusableCount {
            BackendCallStatistics.record("canvas.childDestroyed")
            backend.remove(
                childAt: storage.children.count - 1,
                from: container
            )
            storage.children.removeLast()
        }

        for index in reusableCount..<commands.count {
            BackendCallStatistics.record("canvas.childCreated")
            let child: CanvasStorage.Child
            switch commands[index].kind {
                case .path:
                    let widget = backend.createPathWidget()
                    child = CanvasStorage.Child(kind: .path, widget: widget)
                    child.backendPath = backend.createPath()
                    backend.insert(widget, into: container, at: index)
                    backend.show(widget: widget)
                case .text:
                    let widget = backend.createTextView()
                    child = CanvasStorage.Child(kind: .text, widget: widget)
                    backend.insert(widget, into: container, at: index)
                    backend.show(widget: widget)
            }
            storage.children.append(child)
        }
    }

    /// Applies one recorded command to its backend child widget.
    ///
    /// - Parameters:
    ///   - command: The command to apply.
    ///   - index: The command's index, which is also its child's index.
    ///   - container: The canvas' container widget.
    ///   - storage: The canvas' persistent child pool.
    ///   - bounds: The canvas' bounds, used by backends that flip the Y axis.
    ///   - size: The canvas' size.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private func apply<
        Backend: BaseAppBackend & BackendFeatures.Paths
            & BackendFeatures.TextViews
    >(
        _ command: GraphicsContext.Command,
        at index: Int,
        in container: Backend.Widget,
        storage: CanvasStorage,
        bounds: Path.Rect,
        size: ViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let child = storage.children[index]
        let defaultColor = environment.suggestedForegroundColor
        let clear = Color.clear.resolve(in: environment)

        switch command {
            case .fill(let fill):
                let color = fill.shading
                    .color(withDefault: defaultColor)
                    .opacity(fill.opacity)
                applyPath(
                    fill.path,
                    to: child,
                    at: index,
                    in: container,
                    bounds: bounds,
                    size: size,
                    strokeColor: clear,
                    fillColor: color.resolve(in: environment),
                    strokeStyle: nil,
                    environment: environment,
                    backend: backend
                )
            case .stroke(let stroke):
                let color = stroke.shading
                    .color(withDefault: defaultColor)
                    .opacity(stroke.opacity)
                applyPath(
                    stroke.path,
                    to: child,
                    at: index,
                    in: container,
                    bounds: bounds,
                    size: size,
                    strokeColor: color.resolve(in: environment),
                    fillColor: clear,
                    strokeStyle: stroke.style,
                    environment: environment,
                    backend: backend
                )
            case .text(let text):
                applyText(
                    text,
                    to: child,
                    at: index,
                    in: container,
                    defaultColor: defaultColor,
                    environment: environment,
                    backend: backend
                )
        }
    }

    /// Renders a recorded path into its child widget.
    ///
    /// - Parameters:
    ///   - path: The path to render, in canvas coordinates.
    ///   - child: The child widget to render into.
    ///   - index: The child's index within the container.
    ///   - container: The canvas' container widget.
    ///   - bounds: The canvas' bounds.
    ///   - size: The canvas' size.
    ///   - strokeColor: The color to stroke with.
    ///   - fillColor: The color to fill with.
    ///   - strokeStyle: The stroke style to override the path's own style with.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private func applyPath<
        Backend: BaseAppBackend & BackendFeatures.Paths
    >(
        _ path: Path,
        to child: CanvasStorage.Child,
        at index: Int,
        in container: Backend.Widget,
        bounds: Path.Rect,
        size: ViewSize,
        strokeColor: Color.Resolved,
        fillColor: Color.Resolved,
        strokeStyle: StrokeStyle?,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let widget = child.widget as! Backend.Widget
        let backendPath = child.backendPath as! Backend.Path

        let pointsChanged = child.lastActions != path.actions
        let styleChanged = child.lastStrokeStyle != .some(strokeStyle)
        if pointsChanged || styleChanged {
            if BackendCallStatistics.isCounting {
                BackendCallStatistics.record("canvas.updatePath")
                if let previous = child.lastActions,
                    PathReconciliation.haveSameShape(previous, path.actions)
                {
                    BackendCallStatistics.record("canvas.updatePath.reconcilable")
                } else {
                    BackendCallStatistics.record("canvas.updatePath.rebuild")
                }
            }
            child.lastActions = path.actions
            backend.updatePath(
                backendPath,
                path,
                bounds: bounds,
                pointsChanged: pointsChanged,
                environment: environment
            )
        }

        let sizeVector = size.vector
        if child.lastSize != sizeVector {
            child.lastSize = sizeVector
            BackendCallStatistics.record("canvas.setSize")
            backend.setSize(of: widget, to: sizeVector)
        }

        if child.lastPosition != .zero {
            child.lastPosition = .zero
            BackendCallStatistics.record("canvas.setPosition")
            backend.setPosition(ofChildAt: index, in: container, to: .zero)
        }

        if styleChanged || child.lastStrokeColor != strokeColor
            || child.lastFillColor != fillColor
        {
            child.lastStrokeStyle = .some(strokeStyle)
            child.lastStrokeColor = strokeColor
            child.lastFillColor = fillColor
            BackendCallStatistics.record("canvas.renderPath")
            backend.renderPath(
                backendPath,
                container: widget,
                strokeColor: strokeColor,
                fillColor: fillColor,
                overrideStrokeStyle: strokeStyle
            )
        }
    }

    /// Renders a recorded run of text into its child widget.
    ///
    /// - Parameters:
    ///   - command: The text command to render.
    ///   - child: The child widget to render into.
    ///   - index: The child's index within the container.
    ///   - container: The canvas' container widget.
    ///   - defaultColor: The color to use for
    ///     ``GraphicsContext/Shading/foreground``.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private func applyText<
        Backend: BaseAppBackend & BackendFeatures.TextViews
    >(
        _ command: GraphicsContext.TextCommand,
        to child: CanvasStorage.Child,
        at index: Int,
        in container: Backend.Widget,
        defaultColor: Color,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        let widget = child.widget as! Backend.Widget
        var textEnvironment = environment
        if let font = command.text.font {
            textEnvironment = textEnvironment.with(\.font, font)
        }
        textEnvironment = textEnvironment.with(
            \.foregroundColor,
            command.text.shading
                .color(withDefault: defaultColor)
                .opacity(command.opacity)
        )

        let content = textEnvironment.applyingTextTransforms(
            to: command.text.string
        )

        // Writing the text view and measuring it are the two most expensive
        // things a canvas does per command, and both are repeated on every
        // commit even when the drawing is unchanged. See the note on
        // ``CanvasStorage/Child/lastSize``.
        let font = textEnvironment.resolvedFont
        let color = textEnvironment.suggestedForegroundColor.resolve(in: textEnvironment)
        let textChanged =
            child.lastText != content || child.lastFont != font
            || child.lastTextColor != color
        if textChanged {
            child.lastText = content
            child.lastFont = font
            child.lastTextColor = color
            BackendCallStatistics.record("canvas.updateTextView")
            backend.updateTextView(
                widget,
                content: content,
                environment: textEnvironment
            )
        }

        let proposedWidth: Int?
        let proposedHeight: Int?
        switch command.placement {
            case .point:
                proposedWidth = nil
                proposedHeight = nil
            case .rect(let rect):
                proposedWidth = Canvas.proposedDimension(rect.width)
                proposedHeight = Canvas.proposedDimension(rect.height)
        }

        let measured: SIMD2<Int>
        if !textChanged, let cached = child.lastMeasurement,
            child.lastProposal == SIMD2(proposedWidth ?? -1, proposedHeight ?? -1)
        {
            measured = cached
        } else {
            BackendCallStatistics.record("canvas.measureText")
            measured = backend.size(
                of: content,
                whenDisplayedIn: widget,
                proposedWidth: proposedWidth,
                proposedHeight: proposedHeight,
                environment: textEnvironment
            )
            child.lastMeasurement = measured
            child.lastProposal = SIMD2(proposedWidth ?? -1, proposedHeight ?? -1)
        }

        if child.lastSize != measured {
            child.lastSize = measured
            backend.setSize(of: widget, to: measured)
        }

        let origin: SIMD2<Double>
        switch command.placement {
            case .point(let position, let anchor):
                origin = SIMD2(
                    x: position.x - anchor.x * Double(measured.x),
                    y: position.y - anchor.y * Double(measured.y)
                )
            case .rect(let rect):
                origin = SIMD2(
                    x: rect.x + (rect.width - Double(measured.x)) / 2.0,
                    y: rect.y + (rect.height - Double(measured.y)) / 2.0
                )
        }

        let position = SIMD2(Int(origin.x.rounded()), Int(origin.y.rounded()))
        if child.lastPosition != position {
            child.lastPosition = position
            backend.setPosition(ofChildAt: index, in: container, to: position)
        }
    }

    /// Measures a string using a scratch text view owned by the canvas.
    ///
    /// - Important: The scratch widget is never inserted into the widget
    ///   hierarchy. Backends whose text metrics depend on a widget's parent (or
    ///   on the widget being realised) may report slightly different sizes here
    ///   than they do for the text views that actually get drawn.
    ///
    /// - Parameters:
    ///   - string: The string to measure.
    ///   - targetSize: The size to lay the string out within. Non-finite and
    ///     non-positive dimensions are treated as unconstrained.
    ///   - storage: The canvas' persistent child pool, which owns the scratch
    ///     text view.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    /// - Returns: The size that the string occupies.
    private static func measure<
        Backend: BaseAppBackend & BackendFeatures.TextViews
    >(
        _ string: String,
        in targetSize: CGSize,
        storage: CanvasStorage,
        environment: EnvironmentValues,
        backend: Backend
    ) -> CGSize {
        let widget: Backend.Widget
        if let existing = storage.measurementWidget as? Backend.Widget {
            widget = existing
        } else {
            widget = backend.createTextView()
            storage.measurementWidget = widget
        }

        let content = environment.applyingTextTransforms(to: string)
        backend.updateTextView(
            widget,
            content: content,
            environment: environment
        )
        let size = backend.size(
            of: content,
            whenDisplayedIn: widget,
            proposedWidth: proposedDimension(Double(targetSize.width)),
            proposedHeight: proposedDimension(Double(targetSize.height)),
            environment: environment
        )
        return CGSize(width: Double(size.x), height: Double(size.y))
    }

    /// Compares two values whose `Equatable` conformances are only known at
    /// runtime.
    ///
    /// - Parameters:
    ///   - lhs: The recorded inputs.
    ///   - rhs: The current inputs.
    /// - Returns: Whether they're the same value of the same type.
    private static func areEquivalent(_ lhs: any Equatable, _ rhs: any Equatable) -> Bool {
        func compare<T: Equatable>(_ lhs: T) -> Bool {
            guard let rhs = rhs as? T else {
                return false
            }
            return lhs == rhs
        }
        return compare(lhs)
    }

    /// Converts a layout dimension into a proposal for a backend text view.
    ///
    /// - Parameter value: The dimension.
    /// - Returns: The proposal, or `nil` if the dimension is unconstrained.
    private static func proposedDimension(_ value: Double) -> Int? {
        guard value.isFinite, value > 0.0 else {
            return nil
        }
        return max(1, Int(value.rounded()))
    }
}

/// The persistent state that a ``Canvas`` keeps between draws.
final class CanvasStorage: ViewGraphNodeChildren {
    /// One backend child widget in a canvas' pool.
    final class Child {
        /// The kind of command that this child renders.
        let kind: GraphicsContext.Kind
        /// The backend widget, type-erased because the backend is generic.
        let widget: Any
        /// The backend path, for children that render a path command.
        var backendPath: Any?
        /// The path actions last uploaded to the backend, used to skip
        /// rebuilding unchanged geometry.
        var lastActions: [Path.Action]?

        /// The size last written to the child widget.
        ///
        /// A canvas re-applies every one of its commands on every commit, and a
        /// commit happens whenever anything in the window updates, not only
        /// when the drawing changed. Each of the backend calls guarded by these
        /// is a COM crossing on Windows, so a sheet overlay with a few hundred
        /// commands used to spend thousands of them per frame repainting an
        /// unchanged drawing.
        var lastSize: SIMD2<Int>?
        /// The position last written for the child widget.
        var lastPosition: SIMD2<Int>?
        /// The stroke colour last rendered into the child widget.
        var lastStrokeColor: Color.Resolved?
        /// The fill colour last rendered into the child widget.
        var lastFillColor: Color.Resolved?
        /// The stroke style last rendered into the child widget.
        var lastStrokeStyle: StrokeStyle??
        /// The text content last written to the child widget.
        var lastText: String?
        /// The font the text content was last written with.
        var lastFont: Font.Resolved?
        /// The colour the text content was last written with.
        var lastTextColor: Color.Resolved?
        /// The measurement the text content last produced.
        var lastMeasurement: SIMD2<Int>?
        /// The proposal ``lastMeasurement`` was produced for. An unspecified
        /// dimension is stored as -1, which no real proposal can be.
        var lastProposal: SIMD2<Int>?

        /// Creates a child.
        ///
        /// - Parameters:
        ///   - kind: The kind of command that this child renders.
        ///   - widget: The backend widget.
        init(kind: GraphicsContext.Kind, widget: Any) {
            self.kind = kind
            self.widget = widget
        }
    }

    let widgets: [AnyWidget] = []
    let erasedNodes: [ErasedViewGraphNode] = []

    /// The canvas' child widgets, one per recorded drawing command.
    var children: [Child] = []

    /// A text view kept around solely to measure text with.
    var measurementWidget: Any?

    /// The inputs the current drawing was recorded for, for a canvas that has
    /// declared them.
    var recordedInputs: (any Equatable)?
    /// The size the current drawing was recorded at.
    var recordedSize: ViewSize?
    /// The font the current drawing was recorded with.
    var recordedFont: Font.Resolved?
    /// The foreground colour the current drawing was recorded with.
    var recordedForegroundColor: Color.Resolved?
}
