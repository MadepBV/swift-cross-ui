import Foundation

extension View {
    /// Sets the view's horizontal alignment guide to a computed value.
    ///
    /// A ``VStack`` aligned on `guide` places this view so that the computed
    /// value lines up with its siblings' values for the same guide.
    ///
    /// - Parameters:
    ///   - guide: The guide to set.
    ///   - computeValue: Computes the guide's offset from the view's leading
    ///     edge, given the view's dimensions.
    /// - Returns: A view whose `guide` is set to the computed value.
    public func alignmentGuide(
        _ guide: HorizontalAlignment,
        computeValue: @escaping (ViewDimensions) -> CGFloat
    ) -> some View {
        AlignmentGuideModifier(content: self, key: guide.key, computeValue: computeValue)
    }

    /// Sets the view's vertical alignment guide to a computed value.
    ///
    /// An ``HStack`` aligned on `guide` places this view so that the computed
    /// value lines up with its siblings' values for the same guide. Stacks
    /// carry their children's guides outwards, so a guide set deep inside a
    /// ``VStack`` still aligns that stack within an enclosing ``HStack``.
    ///
    /// - Parameters:
    ///   - guide: The guide to set.
    ///   - computeValue: Computes the guide's offset from the view's top
    ///     edge, given the view's dimensions.
    /// - Returns: A view whose `guide` is set to the computed value.
    public func alignmentGuide(
        _ guide: VerticalAlignment,
        computeValue: @escaping (ViewDimensions) -> CGFloat
    ) -> some View {
        AlignmentGuideModifier(content: self, key: guide.key, computeValue: computeValue)
    }
}

/// Records an explicit alignment guide on its content's layout result.
struct AlignmentGuideModifier<Child: View>: View {
    var body: TupleView1<Child>
    var key: AlignmentKey
    var computeValue: (ViewDimensions) -> CGFloat

    init(content: Child, key: AlignmentKey, computeValue: @escaping (ViewDimensions) -> CGFloat) {
        body = TupleView1(content)
        self.key = key
        self.computeValue = computeValue
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        var result = body.computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
        result.alignmentGuides[key] = Double(computeValue(ViewDimensions(result)))
        return result
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        body.commit(
            widget,
            children: children,
            layout: layout,
            environment: environment,
            backend: backend
        )
    }
}
