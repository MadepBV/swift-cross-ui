/// A description of a single column (or row) of a grid.
///
/// Pass an array of grid items to
/// ``LazyVGrid/init(columns:alignment:spacing:content:)`` to describe the
/// columns of a grid. Each grid item describes how wide its column should be,
/// how much space should separate it from the next column, and how the items
/// placed in that column should be aligned within their cells.
///
/// ```swift
/// LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
///     ForEach(items, id: \.id) { item in
///         ItemView(item)
///     }
/// }
/// ```
public struct GridItem: Sendable, Hashable {
    /// The spacing used between grid items that don't specify their own
    /// ``GridItem/spacing``.
    ///
    /// Matches ``VStack``'s default spacing so that grids feel consistent with
    /// the rest of SwiftCrossUI's containers.
    static let defaultSpacing: Double = 10

    /// The largest number of tracks that a single adaptive column is allowed
    /// to expand into.
    ///
    /// Purely a defensive measure against pathological inputs (such as a
    /// minimum of zero paired with an enormous available width).
    private static let maximumAdaptiveTrackCount = 10_000

    /// The width of a grid column (or the height of a grid row).
    public enum Size: Sendable, Hashable {
        /// A single column with a fixed width.
        case fixed(Double)
        /// A single column that expands to fill the space available to it,
        /// within the given bounds.
        case flexible(minimum: Double = 10, maximum: Double = .infinity)
        /// Multiple columns in the space that a single
        /// ``GridItem/Size/flexible(minimum:maximum:)`` column would've
        /// occupied.
        ///
        /// As many columns as possible are placed in the available space, with
        /// each column at least `minimum` wide.
        case adaptive(minimum: Double, maximum: Double = .infinity)

        /// Whether the size takes part in the distribution of the grid's
        /// leftover width (i.e. whether it isn't a fixed size).
        var isFlexible: Bool {
            switch self {
                case .fixed:
                    false
                case .flexible, .adaptive:
                    true
            }
        }
    }

    /// The column's width.
    public var size: Size
    /// The spacing between this column and the next one.
    ///
    /// Also used as the spacing between the tracks that an
    /// ``GridItem/Size/adaptive(minimum:maximum:)`` column expands into.
    /// `nil` means that the grid should use its default spacing.
    public var spacing: Double?
    /// The alignment used to position items within this column's cells.
    ///
    /// `nil` means that the grid should use its default cell alignment
    /// (``Alignment/center``).
    public var alignment: Alignment?

    /// Creates a description of a single grid column.
    ///
    /// - Parameters:
    ///   - size: The column's width.
    ///   - spacing: The spacing between this column and the next one. `nil`
    ///     uses the grid's default spacing.
    ///   - alignment: The alignment used to position items within this
    ///     column's cells. `nil` uses the grid's default cell alignment.
    public init(
        _ size: Size = .flexible(),
        spacing: Double? = nil,
        alignment: Alignment? = nil
    ) {
        self.size = size
        self.spacing = spacing
        self.alignment = alignment
    }
}

extension GridItem {
    /// A concrete column of a grid, resolved from an array of ``GridItem``s and
    /// the width available to the grid.
    ///
    /// A single ``GridItem`` resolves to exactly one track unless it uses
    /// ``GridItem/Size/adaptive(minimum:maximum:)``, in which case it resolves
    /// to as many equally sized tracks as fit in the space allotted to it.
    struct ResolvedTrack: Hashable {
        /// The track's width.
        var width: Double
        /// The alignment used to position items within the track's cells.
        /// `nil` means that the grid's default cell alignment should be used.
        var alignment: Alignment?
        /// The spacing between this track and the following track. Zero for
        /// the final track.
        var spacingAfter: Double
    }

    /// Resolves an array of column descriptions into the grid's concrete
    /// columns.
    ///
    /// Fixed columns always get exactly the width that they ask for. The space
    /// that remains after accounting for fixed columns and inter-column
    /// spacing gets shared evenly between the flexible and adaptive columns,
    /// clamped to each column's bounds (columns are visited in order, and any
    /// space freed up by clamping gets offered to the columns that follow).
    /// Adaptive columns then subdivide their share into as many equally sized
    /// tracks of at least their minimum width as fit.
    ///
    /// When `availableWidth` is `nil` or infinite the grid has no concrete
    /// width to distribute, so every non-fixed column falls back to its
    /// minimum width and adaptive columns resolve to a single track.
    ///
    /// - Parameters:
    ///   - columns: The column descriptions to resolve.
    ///   - availableWidth: The width available to the grid, if known.
    ///   - defaultSpacing: The spacing to use for columns that don't specify
    ///     their own spacing.
    /// - Returns: The grid's concrete columns, in leading to trailing order.
    static func resolveTracks(
        columns: [GridItem],
        availableWidth: Double?,
        defaultSpacing: Double = GridItem.defaultSpacing
    ) -> [ResolvedTrack] {
        guard !columns.isEmpty else {
            return []
        }

        // The spacing that follows each column. The final column's trailing
        // spacing never gets used, so it doesn't contribute to the total.
        let trailingSpacings = columns.map { column in
            max(column.spacing ?? defaultSpacing, 0)
        }
        let interColumnSpacing = trailingSpacings.dropLast().reduce(0, +)

        // `nil` means that we weren't given a concrete width to distribute.
        var remainingWidth: Double? = nil
        if let availableWidth, availableWidth.isFinite {
            var remaining = availableWidth - interColumnSpacing
            for column in columns {
                guard case .fixed(let width) = column.size else {
                    continue
                }
                remaining -= max(width, 0)
            }
            remainingWidth = max(remaining, 0)
        }

        var flexibleColumnsRemaining = columns.count { column in
            column.size.isFlexible
        }

        var tracks: [ResolvedTrack] = []
        for (index, column) in columns.enumerated() {
            let isFinalColumn = index == columns.count - 1
            let trailingSpacing = isFinalColumn ? 0 : trailingSpacings[index]

            switch column.size {
                case .fixed(let width):
                    tracks.append(
                        ResolvedTrack(
                            width: max(width, 0),
                            alignment: column.alignment,
                            spacingAfter: trailingSpacing
                        )
                    )
                case .flexible(let minimum, let maximum):
                    let width = allocateWidth(
                        minimum: minimum,
                        maximum: maximum,
                        remainingWidth: &remainingWidth,
                        columnsRemaining: &flexibleColumnsRemaining
                    )
                    tracks.append(
                        ResolvedTrack(
                            width: width,
                            alignment: column.alignment,
                            spacingAfter: trailingSpacing
                        )
                    )
                case .adaptive(let minimum, let maximum):
                    let allottedWidth = allocateWidth(
                        minimum: minimum,
                        maximum: .infinity,
                        remainingWidth: &remainingWidth,
                        columnsRemaining: &flexibleColumnsRemaining
                    )
                    tracks.append(
                        contentsOf: adaptiveTracks(
                            allottedWidth: allottedWidth,
                            minimum: minimum,
                            maximum: maximum,
                            itemSpacing: max(column.spacing ?? defaultSpacing, 0),
                            alignment: column.alignment,
                            trailingSpacing: trailingSpacing
                        )
                    )
            }
        }

        return tracks
    }

    /// Computes the total width occupied by a grid's resolved columns,
    /// including the spacing between them.
    ///
    /// - Parameter tracks: The grid's resolved columns.
    /// - Returns: The total width of the columns and the spacing between them.
    static func totalWidth(of tracks: [ResolvedTrack]) -> Double {
        let widths = tracks.map(\.width).reduce(0, +)
        let spacing = tracks.dropLast().map(\.spacingAfter).reduce(0, +)
        return widths + spacing
    }

    /// Takes one flexible or adaptive column's share out of the grid's
    /// remaining width.
    ///
    /// - Parameters:
    ///   - minimum: The column's minimum width.
    ///   - maximum: The column's maximum width.
    ///   - remainingWidth: The width left to distribute. `nil` if the grid
    ///     wasn't given a concrete width, in which case the column falls back
    ///     to its minimum width. Updated in place.
    ///   - columnsRemaining: The number of flexible and adaptive columns left
    ///     to allocate width to (including this one). Updated in place.
    /// - Returns: The width allotted to the column.
    private static func allocateWidth(
        minimum: Double,
        maximum: Double,
        remainingWidth: inout Double?,
        columnsRemaining: inout Int
    ) -> Double {
        let minimum = max(minimum, 0)
        guard let remaining = remainingWidth, columnsRemaining > 0 else {
            columnsRemaining = max(columnsRemaining - 1, 0)
            return minimum
        }

        let share = remaining / Double(columnsRemaining)
        let width = LayoutSystem.clamp(
            share,
            minimum: minimum,
            maximum: maximum.isFinite ? max(maximum, minimum) : nil
        )
        remainingWidth = max(remaining - width, 0)
        columnsRemaining -= 1
        return width
    }

    /// Subdivides the space allotted to an adaptive column into as many
    /// equally sized tracks as fit.
    ///
    /// - Parameters:
    ///   - allottedWidth: The width allotted to the adaptive column.
    ///   - minimum: The minimum width of each resulting track.
    ///   - maximum: The maximum width of each resulting track.
    ///   - itemSpacing: The spacing between the resulting tracks.
    ///   - alignment: The alignment to give each resulting track.
    ///   - trailingSpacing: The spacing to give the final resulting track.
    /// - Returns: The tracks that the adaptive column expands into. Always
    ///   contains at least one track.
    private static func adaptiveTracks(
        allottedWidth: Double,
        minimum: Double,
        maximum: Double,
        itemSpacing: Double,
        alignment: Alignment?,
        trailingSpacing: Double
    ) -> [ResolvedTrack] {
        // A non-positive minimum would let infinitely many tracks fit, so we
        // treat it as a single point wide.
        let minimum = max(minimum, 1)
        let trackStride = minimum + itemSpacing
        let exactCount = ((allottedWidth + itemSpacing) / trackStride).rounded(.down)
        let count =
            if exactCount.isFinite {
                max(min(Int(exactCount), maximumAdaptiveTrackCount), 1)
            } else {
                1
            }

        let totalSpacing = itemSpacing * Double(count - 1)
        var width = (allottedWidth - totalSpacing) / Double(count)
        if maximum.isFinite {
            width = min(width, max(maximum, 0))
        }
        width = max(width, 0)

        return (0..<count).map { index in
            ResolvedTrack(
                width: width,
                alignment: alignment,
                spacingAfter: index == count - 1 ? trailingSpacing : itemSpacing
            )
        }
    }
}
