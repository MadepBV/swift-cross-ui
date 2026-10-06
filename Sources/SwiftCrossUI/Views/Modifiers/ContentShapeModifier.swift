/// The interactions a content shape defines the area of.
public struct ContentShapeKinds: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Pointer and touch hit testing.
    public static let interaction = ContentShapeKinds(rawValue: 1 << 0)
    /// The outline of a drag preview.
    public static let dragPreview = ContentShapeKinds(rawValue: 1 << 1)
    /// The outline of a context menu preview.
    public static let contextMenuPreview = ContentShapeKinds(rawValue: 1 << 2)
    /// The outline of a hover effect.
    public static let hoverEffect = ContentShapeKinds(rawValue: 1 << 3)
    /// The outline of a focus effect.
    public static let focusEffect = ContentShapeKinds(rawValue: 1 << 4)
    /// The outline announced by accessibility.
    public static let accessibility = ContentShapeKinds(rawValue: 1 << 5)
}

extension View {
    /// Makes the whole of `shape`, in this view's frame, respond to the
    /// pointer, including the empty space between the view's content.
    ///
    /// ```swift
    /// HStack {
    ///     Text(title)
    ///     Spacer()
    ///     Image(systemName: "chevron.right")
    /// }
    /// .contentShape(Rectangle())
    /// .onTapGesture { open() }
    /// ```
    ///
    /// The shape is laid behind the content in a transparent fill, which
    /// native hit testing treats as part of the view (an unfilled area of a
    /// WinUI container, for example, lets clicks through).
    ///
    /// - Parameters:
    ///   - shape: The area that responds.
    ///   - eoFill: Accepted for source compatibility.
    /// - Returns: The view.
    public func contentShape<HitShape: Shape>(
        _ shape: HitShape,
        eoFill: Bool = false
    ) -> some View {
        background(shape.fill(Color.clear))
    }

    /// Sets the shape of the given interactions with this view.
    ///
    /// For ``ContentShapeKinds/interaction`` this is
    /// ``View/contentShape(_:eoFill:)``. The other kinds outline previews
    /// and effects that SwiftCrossUI's backends draw at the view's frame, so
    /// for them the shape isn't used.
    ///
    /// - Parameters:
    ///   - kinds: The interactions the shape is for.
    ///   - shape: The shape.
    ///   - eoFill: Accepted for source compatibility.
    /// - Returns: The view.
    public func contentShape<HitShape: Shape>(
        _ kinds: ContentShapeKinds,
        _ shape: HitShape,
        eoFill: Bool = false
    ) -> some View {
        let respondsToPointer = kinds.contains(.interaction)
        return background {
            if respondsToPointer {
                shape.fill(Color.clear)
            }
        }
    }
}
