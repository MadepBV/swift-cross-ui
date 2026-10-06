import Foundation // for CGFloat

extension View {
    /// Adds padding to a view.
    ///
    /// Separate from ``View/padding(_:_:)`` because overload resolution didn't
    /// like the double default parameters.
    ///
    /// - Parameter amount: The amount of padding to use. If `nil`, a
    ///   backend-specific default value is used.
    public func padding(_ amount: Int? = nil) -> some View {
        return padding(.all, amount)
    }

    /// Adds an equal amount of padding to every edge of a view.
    ///
    /// SwiftUI's primary spelling, provided alongside the integral
    /// `padding(_ amount: Int?)` so that a stored `CGFloat` metric can be
    /// passed straight through.
    ///
    /// - Note: SwiftCrossUI lays out in whole points, so `length` is rounded
    ///   to the nearest integer.
    ///
    /// - Parameter length: The amount of padding to use.
    public func padding(_ length: CGFloat) -> some View {
        return padding(.all, EdgeInsets.round(length))
    }

    /// Adds padding to the given edges of a view.
    ///
    /// SwiftUI's primary spelling, provided alongside the integral
    /// `padding(_ edges: Edge.Set, _ amount: Int?)` so that a stored `CGFloat`
    /// metric can be passed straight through.
    ///
    /// - Note: SwiftCrossUI lays out in whole points, so `length` is rounded
    ///   to the nearest integer.
    ///
    /// - Parameters:
    ///   - edges: The edges to apply the padding to.
    ///   - length: The amount of padding to use. If `nil`, a backend-specific
    ///     default value is used.
    public func padding(_ edges: Edge.Set, _ length: CGFloat?) -> some View {
        return padding(edges, length.map(EdgeInsets.round))
    }

    /// Adds padding to a view.
    ///
    /// - Parameters:
    ///   - edges: The edges to apply the padding to. Defaults to
    ///     ``Edge/Set/all``.
    ///   - amount: The amount of padding to use. If `nil`, a backend-specific
    ///     default value is used.
    public func padding(_ edges: Edge.Set = .all, _ amount: Int? = nil) -> some View {
        let insets = EdgeInsets.Internal(edges: edges, amount: amount)
        return PaddingModifierView(body: TupleView1(self), insets: insets)
    }

    /// Adds padding to a view with a different amount for each edge.
    ///
    /// - Parameter insets: The edge insets to use.
    public func padding(_ insets: EdgeInsets) -> some View {
        return PaddingModifierView(body: TupleView1(self), insets: EdgeInsets.Internal(insets))
    }
}

/// Insets for the sides of a rectangle. Generally used to represent view padding.
///
/// Measured in `CGFloat`, as in SwiftUI. SwiftCrossUI lays out in whole
/// points, so padding rounds each inset to the nearest point.
public struct EdgeInsets: Equatable, Sendable {
    /// The top inset.
    public var top: CGFloat
    /// The leading inset.
    public var leading: CGFloat
    /// The bottom inset.
    public var bottom: CGFloat
    /// The trailing inset.
    public var trailing: CGFloat

    /// Rounds a fractional length to the whole points SwiftCrossUI lays out
    /// in.
    ///
    /// - Parameter length: The length to round.
    /// - Returns: The nearest whole number of points.
    static func round(_ length: CGFloat) -> Int {
        Int(length.rounded())
    }

    /// Constructs edge insets from individual insets, in SwiftUI's order.
    ///
    /// - Parameters:
    ///   - top: The top inset.
    ///   - leading: The leading inset.
    ///   - bottom: The bottom inset.
    ///   - trailing: The trailing inset.
    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    /// Constructs edge insets from whole-point insets, in SwiftCrossUI's
    /// original parameter order.
    ///
    /// Kept so that existing backends and apps keep compiling; prefer
    /// ``init(top:leading:bottom:trailing:)``.
    ///
    /// - Parameters:
    ///   - top: The top inset.
    ///   - bottom: The bottom inset.
    ///   - leading: The leading inset.
    ///   - trailing: The trailing inset.
    @_disfavoredOverload
    public init(top: Int = 0, bottom: Int = 0, leading: Int = 0, trailing: Int = 0) {
        self.init(
            top: CGFloat(top),
            leading: CGFloat(leading),
            bottom: CGFloat(bottom),
            trailing: CGFloat(trailing)
        )
    }

    /// The insets rounded to the whole points that layout works in.
    var integral: Integral {
        Integral(
            top: Self.round(top),
            bottom: Self.round(bottom),
            leading: Self.round(leading),
            trailing: Self.round(trailing)
        )
    }

    /// Edge insets in whole points, as the layout system uses them.
    struct Integral {
        var top: Int
        var bottom: Int
        var leading: Int
        var trailing: Int

        /// The total inset along each axis.
        var axisTotals: SIMD2<Int> {
            SIMD2(
                leading + trailing,
                top + bottom
            )
        }

        init(top: Int, bottom: Int, leading: Int, trailing: Int) {
            self.top = top
            self.bottom = bottom
            self.leading = leading
            self.trailing = trailing
        }

        init(_ insets: Internal, defaultAmount: Int) {
            top = insets.top ?? defaultAmount
            bottom = insets.bottom ?? defaultAmount
            leading = insets.leading ?? defaultAmount
            trailing = insets.trailing ?? defaultAmount
        }
    }

    struct Internal {
        var top: Int?
        var bottom: Int?
        var leading: Int?
        var trailing: Int?
    }
}

extension EdgeInsets.Internal {
    init(edges: Edge.Set, amount: Int?) {
        self.top = edges.contains(.top) ? amount : 0
        self.bottom = edges.contains(.bottom) ? amount : 0
        self.leading = edges.contains(.leading) ? amount : 0
        self.trailing = edges.contains(.trailing) ? amount : 0
    }

    init(_ insets: EdgeInsets) {
        let integral = insets.integral
        top = integral.top
        bottom = integral.bottom
        leading = integral.leading
        trailing = integral.trailing
    }
}

/// The implementation for the ``View/padding(_:_:)`` modifier.
struct PaddingModifierView<Child: View>: TypeSafeView {
    var body: TupleView1<Child>

    /// The insets for each edge.
    var insets: EdgeInsets.Internal

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> TupleViewChildren1<Child> {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: TupleViewChildren1<Child>,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        backend.insert(children.child0.widget.into(), into: container, at: 0)
        return container
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ container: Backend.Widget,
        children: TupleViewChildren1<Child>,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // This first block of calculations is somewhat repeated in `commit`,
        // make sure to update things in both places.
        let insets = EdgeInsets.Integral(insets, defaultAmount: backend.defaultPaddingAmount)
        let horizontalPadding = Double(insets.leading + insets.trailing)
        let verticalPadding = Double(insets.top + insets.bottom)

        var childProposal = proposedSize
        if let proposedWidth = proposedSize.width {
            childProposal.width = max(proposedWidth - horizontalPadding, 0)
        }
        if let proposedHeight = proposedSize.height {
            childProposal.height = max(proposedHeight - verticalPadding, 0)
        }

        let childResult = children.child0.computeLayout(
            with: body.view0,
            proposedSize: childProposal,
            environment: environment
        )

        var size = childResult.size
        size.width += horizontalPadding
        size.height += verticalPadding

        return ViewLayoutResult(
            size: size,
            childResults: [childResult]
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ container: Backend.Widget,
        children: TupleViewChildren1<Child>,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        _ = children.child0.commit()

        let size = layout.size
        backend.setSize(of: container, to: size.vector)

        let insets = EdgeInsets.Integral(insets, defaultAmount: backend.defaultPaddingAmount)
        let childPosition = SIMD2(insets.leading, insets.top)
        backend.setPosition(ofChildAt: 0, in: container, to: childPosition)
    }
}
