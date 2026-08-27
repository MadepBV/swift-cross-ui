/// The underlying view used to render the various ``_BuiltinPickerStyle``s.
public struct _BuiltinPickerImplementation: TypeSafeView {
    public var body: EmptyView { return EmptyView() }

    var style: BackendPickerStyle
    var options: [String]
    var selectedIndex: Binding<Int?>

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> BuiltinPickerChildren {
        BuiltinPickerChildren(
            container: AnyWidget(backend.createContainer()),
            picker: nil,
            style: style
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: BuiltinPickerChildren,
        backend: Backend
    ) -> Backend.Widget {
        children.container.widget as! Backend.Widget
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: BuiltinPickerChildren,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        var pickerWidget: Backend.Widget

        if let picker = children.picker, children.style == self.style {
            pickerWidget = picker.widget as! Backend.Widget
        } else {
            let containerWidget = children.container.widget as! Backend.Widget
            backend.removeAllChildren(of: containerWidget)

            pickerWidget = backend.createPicker(style: style)
            children.style = self.style
            children.picker = AnyWidget(pickerWidget)

            backend.insert(pickerWidget, into: containerWidget, at: 0)
            backend.setPosition(ofChildAt: 0, in: containerWidget, to: .zero)
        }

        // TODO: Implement picker sizing within SwiftCrossUI so that we can
        //   properly separate committing logic out into `commit`.
        //
        // Because it happens here rather than in `commit`, it happens on every
        // layout computation — up to three times per update pass, since the
        // layout system probes a view's minimum and maximum size before
        // proposing a final one. `updatePicker` writes every option into the
        // backend's picker, so on WinUI that was one COM crossing per option
        // per probe. The options and the selection are almost always the ones
        // already showing, so the writes are skipped when nothing changed.
        let selection = selectedIndex.wrappedValue
        if children.appliedOptions != options {
            children.appliedOptions = options
            backend.updatePicker(
                pickerWidget,
                options: options,
                environment: environment
            ) {
                selectedIndex.wrappedValue = $0
            }
            // A backend may reset its selection when its options change, so
            // the selection has to be re-applied alongside them.
            children.appliedSelection = nil
        }
        if children.appliedSelection != .some(selection) {
            children.appliedSelection = .some(selection)
            backend.setSelectedOption(ofPicker: pickerWidget, to: selection)
        }

        // Special handling for UIKitBackend:
        // When backed by a UITableView, its natural size is -1 x -1,
        // but it can and should be as large as reasonable
        let naturalSize: SIMD2<Int>
        if let cached = children.naturalSize {
            // A picker's natural size only depends on its options and its
            // font, and measuring it means a real layout pass in the backend.
            naturalSize = cached
        } else {
            naturalSize = backend.naturalSize(of: pickerWidget)
            children.naturalSize = naturalSize
        }
        let size: ViewSize
        if naturalSize == SIMD2(-1, -1) {
            size = proposedSize.replacingUnspecifiedDimensions(by: ViewSize(10, 10))
        } else {
            size = ViewSize(naturalSize)
        }
        return ViewLayoutResult.leafView(size: size)
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: BuiltinPickerChildren,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.setSize(of: widget, to: layout.size.vector)
        backend.setSize(
            of: children.picker!.widget as! Backend.Widget,
            to: layout.size.vector
        )
    }
}

/// The children of a built-in picker. Pickers don't actually have child nodes,
/// we just use this to persist information between updates.
final class BuiltinPickerChildren: ViewGraphNodeChildren {
    var container: AnyWidget
    var picker: AnyWidget?
    var style: BackendPickerStyle {
        didSet {
            // A new picker widget means nothing has been applied to it yet.
            appliedOptions = nil
            appliedSelection = nil
            naturalSize = nil
        }
    }

    /// The options last written to the backend's picker.
    var appliedOptions: [String]?
    /// The selection last written to the backend's picker.
    var appliedSelection: Int??
    /// The natural size the backend last reported for the picker.
    var naturalSize: SIMD2<Int>?

    init(container: AnyWidget, picker: AnyWidget? = nil, style: BackendPickerStyle) {
        self.container = container
        self.picker = picker
        self.style = style
    }

    var widgets: [AnyWidget] { [container] }
    var erasedNodes: [ErasedViewGraphNode] { [] }
}
