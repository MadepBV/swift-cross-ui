/// A container that arranges its subviews in a grid that grows downwards,
/// only creating them as they become visible.
///
/// The grid's columns get described by an array of ``GridItem``s. Items fill
/// the columns from leading to trailing, wrapping onto a new row once every
/// column of the current row has been filled.
///
/// ```swift
/// LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
///     ForEach(palette.entries, id: \.id) { entry in
///         PaletteCell(entry)
///     }
/// }
/// ```
///
/// Grouping containers are transparent to the grid: the items of a ``ForEach``
/// (or the contents of a ``Group``, including a ``ForEach`` nested within one)
/// each occupy their own cell rather than the container as a whole occupying
/// one. Containers that impose a layout of their own, such as ``VStack``, stay
/// a single cell. See ``ContainerChildLayout`` for how that works.
///
/// - Important: SwiftCrossUI's ``LazyVGrid`` is currently **eager**; it
///   creates all of its children up-front instead of only creating the ones
///   that are scrolled into view. It exists so that code written against
///   SwiftUI's `LazyVGrid` compiles and renders correctly. Virtualising the
///   children requires support from the view graph and remains future work.
/// - Important: A view that produces no content of its own (such as the
///   ``EmptyView`` that an unsatisfied `if` resolves to) still occupies a cell.
public struct LazyVGrid<Content: View>: View {
    /// The spacing used between rows when the grid isn't given a spacing.
    static var defaultSpacing: Double { GridItem.defaultSpacing }

    /// The alignment used to position items within cells whose column doesn't
    /// specify its own ``GridItem/alignment``.
    static var defaultCellAlignment: Alignment { .center }

    public var body: Content

    /// A description of each of the grid's columns.
    private var columns: [GridItem]
    /// The horizontal alignment of the grid's columns within the grid's width.
    private var alignment: HorizontalAlignment
    /// The amount of spacing to apply between rows.
    private var spacing: Double

    /// Creates a grid that grows downwards.
    ///
    /// - Parameters:
    ///   - columns: A description of each of the grid's columns.
    ///   - alignment: The horizontal alignment of the grid's columns within
    ///     the width available to the grid.
    ///   - spacing: The amount of spacing to apply between rows. `nil` uses
    ///     the grid's default spacing.
    ///   - content: The content of the grid.
    public init(
        columns: [GridItem],
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            columns: columns,
            alignment: alignment,
            spacing: spacing,
            content: content()
        )
    }

    /// Creates a grid that grows downwards.
    ///
    /// - Parameters:
    ///   - columns: A description of each of the grid's columns.
    ///   - alignment: The horizontal alignment of the grid's columns within
    ///     the width available to the grid.
    ///   - spacing: The amount of spacing to apply between rows. `nil` uses
    ///     the grid's default spacing.
    ///   - content: The content of the grid.
    init(
        columns: [GridItem],
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        content: Content
    ) {
        body = content
        self.columns = columns
        self.alignment = alignment
        self.spacing = spacing ?? Self.defaultSpacing
    }

    public func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        LazyVGridChildren(
            wrapping: defaultChildren(
                backend: backend,
                snapshots: snapshots,
                environment: environment
            )
        )
    }

    public func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: any ViewGraphNodeChildren
    ) -> [LayoutSystem.LayoutableChild] {
        guard let children = children as? LazyVGridChildren else {
            logUnexpectedChildren(children)
            return []
        }
        // Goes through the default rather than reaching to `body` directly:
        // a `@ViewBuilder` closure containing an explicit `return` opts out of
        // the result builder, so `body` is not necessarily a `TupleView`. See
        // `View.bodyNeedsWrapping`.
        var layoutableChildren = defaultLayoutableChildren(
            backend: backend,
            children: children.wrapped
        )
        LayoutSystem.markGroupingContainers(&layoutableChildren, using: children.wrapped)
        return layoutableChildren
    }

    public func asWidget<Backend: BaseAppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        for (index, child) in children.widgets(for: backend).enumerated() {
            backend.insert(child, into: container, at: index)
        }
        return container
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        guard let gridChildren = children as? LazyVGridChildren else {
            logUnexpectedChildren(children)
            return .leafView(size: .zero)
        }

        let participants = layoutableChildren(backend: backend, children: children)
        let gridLayout = gridChildren.layout
        gridLayout.beginLayoutPass(
            tracks: GridItem.resolveTracks(
                columns: columns,
                availableWidth: proposedSize.width
            ),
            rowSpacing: spacing,
            cellAlignment: Self.defaultCellAlignment
        )

        // Grouping containers still lay themselves out as stacks when they
        // aren't taking part in the grid, so we describe the grid's own
        // downwards flow to them.
        let participantEnvironment =
            environment
                .with(\.layoutOrientation, .vertical)
                .with(\.layoutAlignment, alignment.asStackAlignment)
                .with(\.layoutSpacing, LayoutSystem.roundSize(spacing))

        // The measuring pass exists to stop the view graph's layout cache from
        // swallowing the placing pass. A grouping container only registers its
        // participants while it's actually computing a layout, and the view
        // graph skips that whenever a node is proposed the same size twice in
        // a row, so the two passes deliberately propose differently shaped
        // sizes. `LazyVGridLayout` disables layout caching for the same reason.
        gridLayout.beginPhase(.measuring)
        for participant in participants {
            gridLayout.addParticipant(participant, environment: participantEnvironment)
        }

        gridLayout.beginPhase(.placing)
        var childResults: [ViewLayoutResult] = []
        childResults.reserveCapacity(participants.count)
        for participant in participants {
            childResults.append(
                gridLayout.addParticipant(participant, environment: participantEnvironment)
            )
        }
        gridLayout.finishLayoutPass()

        // The grid fills the width available to it (which is what makes the
        // grid's `alignment` meaningful), but never shrinks below the width
        // that its columns need.
        let contentSize = gridLayout.participantAreaSize
        var width = contentSize.width
        if let proposedWidth = proposedSize.width, proposedWidth.isFinite {
            width = max(proposedWidth, contentSize.width)
        }

        gridLayout.participantAreaOrigin = SIMD2(
            LayoutSystem.roundSize(
                alignment.position(ofChild: contentSize.width, in: width)
            ),
            0
        )

        return ViewLayoutResult(
            size: ViewSize(width, contentSize.height),
            childResults: childResults
        )
    }

    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.setSize(of: widget, to: layout.size.vector)

        guard let gridChildren = children as? LazyVGridChildren else {
            logUnexpectedChildren(children)
            return
        }

        let gridLayout = gridChildren.layout
        gridLayout.beginCommitPass()

        let origin = gridLayout.participantAreaOrigin
        let participants = layoutableChildren(backend: backend, children: children)
        for (index, participant) in participants.enumerated() {
            let placement = gridLayout.commitNextParticipant(participant)
            backend.setPosition(
                ofChildAt: index,
                in: widget,
                to: origin &+ placement.position
            )
        }
    }

    /// Warns that the grid received children that it didn't create.
    ///
    /// - Parameter children: The unexpected children.
    private func logUnexpectedChildren(_ children: any ViewGraphNodeChildren) {
        logger.warning(
            "LazyVGrid received children that it didn't create; layout skipped",
            metadata: [
                "childrenType": "\(type(of: children))",
                "contentType": "\(Content.self)",
            ]
        )
    }
}

/// The children of a ``LazyVGrid``.
///
/// Wraps the content's own children so that the grid has somewhere to persist
/// its ``LazyVGridLayout`` between the layout phase and the commit phase (the
/// same role that `stackLayoutCache` plays for stack layouts).
class LazyVGridChildren: ViewGraphNodeChildren {
    /// The content's own children.
    let wrapped: any ViewGraphNodeChildren

    /// The grid's cell layout, shared with any grouping containers nested
    /// inside the grid.
    let layout = LazyVGridLayout()

    var widgets: [AnyWidget] {
        wrapped.widgets
    }

    var erasedNodes: [ErasedViewGraphNode] {
        wrapped.erasedNodes
    }

    /// Wraps a grid's content's children.
    ///
    /// - Parameter wrapped: The content's own children.
    init(wrapping wrapped: any ViewGraphNodeChildren) {
        self.wrapped = wrapped
    }
}

/// The cell layout of a single ``LazyVGrid``.
///
/// Every view that ends up in one of the grid's cells is handed to this by
/// either the grid itself or by a grouping container nested inside the grid
/// (see ``ContainerChildLayout``), which is what lets the items of a
/// ``ForEach`` occupy individual cells.
final class LazyVGridLayout: ContainerChildLayout {
    /// The stage of the grid's layout that's currently running.
    enum Phase {
        /// Participants are being probed at their ideal size.
        case measuring
        /// Participants are being laid out into the grid's cells.
        case placing
    }

    /// The cell allotted to a single participant.
    private struct Cell {
        /// The cell's top left corner, relative to the participant area.
        var origin: SIMD2<Int>
        /// The size of the cell.
        var size: SIMD2<Int>
        /// How the participant is aligned within the cell.
        var alignment: Alignment
    }

    /// The grid's resolved columns.
    private var tracks: [GridItem.ResolvedTrack] = []
    /// The amount of spacing between neighbouring rows.
    private var rowSpacing: Double = 0
    /// The alignment used by columns that don't specify their own.
    private var defaultCellAlignment: Alignment = .center
    /// The stage of the layout that's currently running.
    private var phase: Phase = .measuring
    /// The size reported by each participant during the current phase.
    private var participantSizes: [ViewSize] = []
    /// The cell allotted to each participant, resolved by
    /// ``finishLayoutPass()``.
    private var cells: [Cell] = []
    /// How many participants have been committed during the current commit.
    private var commitCursor = 0

    private(set) var participantAreaSize: ViewSize = .zero

    /// The top left corner of the participant area within the grid's own
    /// bounds.
    ///
    /// The grid is free to be wider than its columns need, in which case its
    /// alignment decides where the columns sit within it.
    var participantAreaOrigin: SIMD2<Int> = .zero

    /// Prepares the layout for a fresh layout computation.
    ///
    /// - Parameters:
    ///   - tracks: The grid's resolved columns.
    ///   - rowSpacing: The amount of spacing between neighbouring rows.
    ///   - cellAlignment: The alignment used by columns that don't specify
    ///     their own.
    func beginLayoutPass(
        tracks: [GridItem.ResolvedTrack],
        rowSpacing: Double,
        cellAlignment: Alignment
    ) {
        self.tracks = tracks
        self.rowSpacing = rowSpacing
        defaultCellAlignment = cellAlignment
    }

    /// Moves the layout on to the given phase, ready to receive every
    /// participant once more.
    ///
    /// - Parameter phase: The phase that's about to run.
    func beginPhase(_ phase: Phase) {
        self.phase = phase
        participantSizes = []
    }

    @discardableResult
    func addParticipant(
        _ participant: LayoutSystem.LayoutableChild,
        environment: EnvironmentValues
    ) -> ViewLayoutResult {
        let index = participantSizes.count
        let proposedSize: ProposedViewSize =
            switch phase {
                case .measuring:
                    .unspecified
                case .placing:
                    ProposedViewSize(width(ofCellAt: index), nil)
            }

        // Only a grouping container may be handed the grid; anything else is
        // proposed to with the grid cleared, so that a `ForEach` buried inside
        // an ordinary view's implementation can't join the grid by accident.
        // Layout caching is disabled for grouping containers because a cached
        // layout would stop them from registering their participants, leaving
        // the grid believing that it has no cells at all.
        let participantEnvironment =
            participant.isGroupingContainer
                ? environment
                .with(\.containerChildLayout, self)
                .with(\.allowLayoutCaching, false)
                : environment.with(\.containerChildLayout, nil)

        let result = participant.computeLayout(
            proposedSize: proposedSize,
            environment: participantEnvironment
        )

        guard !participant.isGroupingContainer, participantSizes.count == index else {
            // A nested grouping container took over and registered its own
            // participants, so it doesn't occupy a cell of its own.
            return result
        }
        participantSizes.append(result.size)
        return result
    }

    /// Resolves the grid's geometry once every participant has been added.
    func finishLayoutPass() {
        cells = []
        guard !tracks.isEmpty else {
            participantAreaSize = .zero
            return
        }

        let rowHeights = Self.rowHeights(of: participantSizes, columnCount: tracks.count)

        var columnOrigins: [Double] = []
        var x = 0.0
        for track in tracks {
            columnOrigins.append(x)
            x += track.width + track.spacingAfter
        }

        var rowOrigins: [Double] = []
        var y = 0.0
        for rowHeight in rowHeights {
            rowOrigins.append(y)
            y += rowHeight + rowSpacing
        }

        cells.reserveCapacity(participantSizes.count)
        for index in participantSizes.indices {
            let column = index % tracks.count
            let row = index / tracks.count
            let track = tracks[column]
            cells.append(
                Cell(
                    origin: SIMD2(
                        LayoutSystem.roundSize(columnOrigins[column]),
                        LayoutSystem.roundSize(rowOrigins[row])
                    ),
                    size: SIMD2(
                        LayoutSystem.roundSize(track.width),
                        LayoutSystem.roundSize(rowHeights[row])
                    ),
                    alignment: track.alignment ?? defaultCellAlignment
                )
            )
        }

        let contentHeight =
            rowHeights.reduce(0, +) + rowSpacing * Double(max(rowHeights.count - 1, 0))
        participantAreaSize = ViewSize(GridItem.totalWidth(of: tracks), contentHeight)
    }

    /// Prepares the layout to hand out the positions it resolved.
    func beginCommitPass() {
        commitCursor = 0
    }

    func commitNextParticipant(
        _ participant: LayoutSystem.LayoutableChild
    ) -> (position: SIMD2<Int>, result: ViewLayoutResult) {
        let index = commitCursor
        let result = participant.commit()

        guard !participant.isGroupingContainer, commitCursor == index else {
            // A nested grouping container committed its own participants, so
            // it covers the whole participant area.
            return (.zero, result)
        }
        commitCursor += 1

        guard index < cells.count else {
            return (.zero, result)
        }
        let cell = cells[index]
        let offsetInCell = cell.alignment.position(ofChild: result.size.vector, in: cell.size)
        return (cell.origin &+ offsetInCell, result)
    }

    /// The width of the cell at the given participant index.
    ///
    /// - Parameter index: The participant's index.
    /// - Returns: The width of the column that the participant falls into.
    private func width(ofCellAt index: Int) -> Double {
        guard !tracks.isEmpty else {
            return 0
        }
        return tracks[index % tracks.count].width
    }

    /// Computes the height of each of the grid's rows.
    ///
    /// A row is as tall as its tallest item. Items fill the columns of a row
    /// from leading to trailing before wrapping onto the next row.
    ///
    /// - Parameters:
    ///   - sizes: The sizes of the grid's items, in the order that they get
    ///     placed into cells.
    ///   - columnCount: The number of columns that the grid resolved to.
    /// - Returns: The height of each row, from top to bottom.
    static func rowHeights(of sizes: [ViewSize], columnCount: Int) -> [Double] {
        guard columnCount > 0 else {
            return []
        }

        var heights: [Double] = []
        for (index, size) in sizes.enumerated() {
            let row = index / columnCount
            if row == heights.count {
                heights.append(size.height)
            } else {
                heights[row] = max(heights[row], size.height)
            }
        }
        return heights
    }
}
