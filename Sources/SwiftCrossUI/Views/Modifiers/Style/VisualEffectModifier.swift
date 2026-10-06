import Foundation

/// Visual changes applied to a view without changing its layout, computed
/// from the view's geometry by ``View/visualEffect(_:)``.
///
/// Of the effects, SwiftCrossUI draws ``VisualEffect/opacity(_:)`` (through
/// ``BackendFeatures/Opacity``). Scaling, offsetting, rotating and blurring
/// a rendered view need a backend render transform, which no backend exposes
/// yet; those effects are recorded and not drawn, and the view draws in
/// place at its own size, exactly as it lays out.
public protocol VisualEffect: Sendable {
    /// The accumulated effect.
    var _values: VisualEffectValues { get }
}

/// The accumulated values of a ``VisualEffect``.
public struct VisualEffectValues: Hashable, Sendable {
    /// The opacity multiplier.
    public var opacity: Double = 1
    /// The scale, relative to `scaleAnchor`.
    public var scale = SIMD2<Double>(1, 1)
    /// The point scaling is relative to.
    public var scaleAnchor = UnitPoint.center
    /// The offset, in points.
    public var offset = SIMD2<Double>(0, 0)
    /// The blur radius, in points.
    public var blurRadius: Double = 0
    /// The rotation.
    public var rotation = Angle.zero

    public init() {}
}

/// The effect a ``View/visualEffect(_:)`` closure starts from: no change.
public struct EmptyVisualEffect: VisualEffect {
    public var _values: VisualEffectValues { VisualEffectValues() }

    public init() {}
}

/// An effect built up from ``EmptyVisualEffect`` with the ``VisualEffect``
/// modifiers.
public struct ModifiedVisualEffect: VisualEffect {
    public let _values: VisualEffectValues
}

extension VisualEffect {
    private func modified(
        _ update: (inout VisualEffectValues) -> Void
    ) -> ModifiedVisualEffect {
        var values = _values
        update(&values)
        return ModifiedVisualEffect(_values: values)
    }

    /// Multiplies the view's opacity.
    public func opacity(_ opacity: Double) -> ModifiedVisualEffect {
        modified { $0.opacity *= min(max(opacity, 0), 1) }
    }

    /// Scales the view. Recorded, not drawn; see ``VisualEffect``.
    public func scaleEffect(_ scale: CGFloat, anchor: UnitPoint = .center) -> ModifiedVisualEffect {
        scaleEffect(x: scale, y: scale, anchor: anchor)
    }

    /// Scales the view. Recorded, not drawn; see ``VisualEffect``.
    public func scaleEffect(_ scale: CGSize, anchor: UnitPoint = .center) -> ModifiedVisualEffect {
        scaleEffect(x: scale.width, y: scale.height, anchor: anchor)
    }

    /// Scales the view. Recorded, not drawn; see ``VisualEffect``.
    public func scaleEffect(
        x: CGFloat = 1,
        y: CGFloat = 1,
        anchor: UnitPoint = .center
    ) -> ModifiedVisualEffect {
        modified {
            $0.scale *= SIMD2(Double(x), Double(y))
            $0.scaleAnchor = anchor
        }
    }

    /// Offsets the view. Recorded, not drawn; see ``VisualEffect``.
    public func offset(_ offset: CGSize) -> ModifiedVisualEffect {
        self.offset(x: offset.width, y: offset.height)
    }

    /// Offsets the view. Recorded, not drawn; see ``VisualEffect``.
    public func offset(x: CGFloat = 0, y: CGFloat = 0) -> ModifiedVisualEffect {
        modified { $0.offset += SIMD2(Double(x), Double(y)) }
    }

    /// Blurs the view. Recorded, not drawn; see ``VisualEffect``.
    public func blur(radius: CGFloat, opaque: Bool = false) -> ModifiedVisualEffect {
        modified { $0.blurRadius += Double(radius) }
    }

    /// Rotates the view. Recorded, not drawn; see ``VisualEffect``.
    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> ModifiedVisualEffect {
        modified { $0.rotation = Angle(radians: $0.rotation.radians + angle.radians) }
    }
}

extension View {
    /// Applies effects that depend on this view's geometry, without changing
    /// its layout.
    ///
    /// ```swift
    /// title
    ///     .visualEffect { content, proxy in
    ///         content.opacity(proxy.size.height > 40 ? 1 : 0.5)
    ///     }
    /// ```
    ///
    /// The closure runs whenever the view is laid out, with a proxy for the
    /// view's own frame. See ``VisualEffect`` for which effects are drawn.
    ///
    /// - Parameter effect: Computes the effect from the view's geometry.
    /// - Returns: The view with the effect applied.
    public func visualEffect<Effect: VisualEffect>(
        _ effect: @escaping @Sendable (EmptyVisualEffect, GeometryProxy) -> Effect
    ) -> some View {
        VisualEffectModifier(content: self) { proxy in
            effect(EmptyVisualEffect(), proxy)._values
        }
    }
}

struct VisualEffectModifier<Content: View>: View, TypeSafeView {
    var content: Content
    var effect: @Sendable (GeometryProxy) -> VisualEffectValues

    var body: TupleView1<Content> { content }

    typealias Children = TupleView1<Content>.Children

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        body.asWidget(children, backend: backend)
    }

    func layoutableChildren<Backend: BaseAppBackend>(
        backend: Backend,
        children: Children
    ) -> [LayoutSystem.LayoutableChild] {
        body.layoutableChildren(backend: backend, children: children)
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        body.computeLayout(
            widget,
            children: children,
            proposedSize: proposedSize,
            environment: environment,
            backend: backend
        )
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
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
        let values = effect(
            GeometryProxy(
                size: CGSize(width: layout.size.width, height: layout.size.height)
            )
        )
        if let opacityBackend = backend as? any BackendFeatures.Opacity {
            setOpacity(values.opacity, of: widget, with: opacityBackend)
        }
    }

    private func setOpacity<OpacityBackend: BackendFeatures.Opacity>(
        _ opacity: Double,
        of widget: some Any,
        with backend: OpacityBackend
    ) {
        backend.setOpacity(of: widget as! OpacityBackend.Widget, to: opacity)
    }
}
