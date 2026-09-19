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
        let selectionState = children.selectionState
        // Identical option titles can accompany a new binding. Native callbacks
        // must use that binding, including after cached option updates are skipped.
        selectionState.update(
            binding: selectedIndex, optionCount: options.count,
            isEnabled: environment.isEnabled)
        // Creating/removing controls and measuring them can also trigger native
        // selection notifications. None of this layout work is a user edit.
        selectionState.beginProgrammaticUpdate()
        defer { selectionState.endProgrammaticUpdate() }

        var pickerWidget: Backend.Widget

        if let picker = children.picker, children.style == self.style {
            pickerWidget = picker.widget as! Backend.Widget
        } else {
            selectionState.nativeWidgetWillBeReplaced()
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
        let appearance = BuiltinPickerAppearance(environment: environment)
        if children.appliedOptions != options || children.appliedAppearance != appearance {
            children.appliedOptions = options
            children.appliedAppearance = appearance
            children.naturalSize = nil
            backend.updatePicker(
                pickerWidget,
                options: options,
                environment: environment,
                onChange: selectionState.makeNativeSelectionHandler()
            )
            // A backend may rebuild items even when only their appearance
            // changed, so re-apply the selection after any backend update.
            children.appliedSelection = nil
        }
        if children.appliedSelection != .some(selection) {
            children.appliedSelection = .some(selection)
            // Some native controls size to the selected label, not the widest
            // option. A different selection must get a fresh measurement.
            children.naturalSize = nil
            backend.setSelectedOption(ofPicker: pickerWidget, to: selection)
        }

        // Special handling for UIKitBackend:
        // When backed by a UITableView, its natural size is -1 x -1,
        // but it can and should be as large as reasonable
        let naturalSize: SIMD2<Int>
        if let cached = children.naturalSize {
            // Measuring can perform a real native layout pass. Reuse it while
            // the options, selection and native appearance remain unchanged.
            naturalSize = cached
        } else {
            naturalSize = backend.naturalSize(of: pickerWidget)
            // A populated native picker may report zero before its template
            // loads. Leave that provisional measurement uncached so a backend
            // resize notification can pick up the realized control's size.
            // Empty pickers can legitimately stay zero; UIKit's -1/-1 sentinel
            // must also keep its existing proposal-dependent sizing behavior.
            if options.isEmpty || (naturalSize.x != 0 && naturalSize.y != 0) {
                children.naturalSize = naturalSize
            }
        }
        let size: ViewSize
        if naturalSize == SIMD2(-1, -1) {
            size = proposedSize.replacingUnspecifiedDimensions(by: ViewSize(10, 10))
        } else if style == .menu, let width = proposedSize.width, width.isFinite {
            // The closed menu can truncate a long selected title; its popover
            // still contains the complete options. Returning the widest item's
            // intrinsic width here made a picker escape narrow inspector rows.
            // Keep the intrinsic measurement cached independently of this
            // proposal so widening the pane restores the full natural size.
            size = ViewSize(min(Double(naturalSize.x), max(0, width)), Double(naturalSize.y))
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
        BackendHelpers.applyFocusRelatedProperties(
            from: environment,
            to: AnyWidget(children.picker!.widget),
            with: backend
        )

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
    let selectionState = PickerSelectionState()
    var style: BackendPickerStyle {
        didSet {
            // A new picker widget means nothing has been applied to it yet.
            appliedOptions = nil
            appliedAppearance = nil
            appliedSelection = nil
            naturalSize = nil
        }
    }

    /// The options last written to the backend's picker.
    var appliedOptions: [String]?
    /// Native appearance inputs last sent to the backend.
    var appliedAppearance: BuiltinPickerAppearance?
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

/// The environment values used by the built-in backends' picker updates.
/// Keep this in sync when a backend adds an environment-dependent appearance
/// input. Layout proposals and callbacks are intentionally excluded: they change
/// during ordinary probing without changing the native picker.
struct BuiltinPickerAppearance: Equatable {
    var font: Font.Resolved
    var foregroundColor: Color.Resolved?
    var colorScheme: ColorScheme
    var isEnabled: Bool
    var multilineTextAlignment: HorizontalAlignment
    var menuOrder: MenuOrder

    @MainActor
    init(environment: EnvironmentValues) {
        font = environment.resolvedFont
        // UIKit uses its native link color when no foreground was specified.
        // Explicitly requesting the default text color must remain distinct.
        foregroundColor = environment.foregroundColor?.resolve(in: environment)
        colorScheme = environment.colorScheme
        isEnabled = environment.isEnabled
        multilineTextAlignment = environment.multilineTextAlignment
        menuOrder = environment.menuOrder
    }
}
