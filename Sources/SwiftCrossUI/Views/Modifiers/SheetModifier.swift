extension View {
    /// Presents a conditional modal overlay. `onDismiss` gets invoked when the
    /// sheet is dismissed.
    ///
    /// On most platforms sheets appear as form-style modals. On tvOS, sheets
    /// appear as full screen overlays (non-opaque).
    ///
    /// `onDismiss` isn't called when the sheet gets dismissed programmatically
    /// (i.e. by setting `isPresented` to `false`).
    ///
    /// `onDismiss` gets called *after* the sheet has been dismissed by the
    /// underlying UI framework, and *before* `isPresented` gets set to false.
    ///
    /// - Parameters:
    ///   - isPresented: A binding controlling whether the sheet is presented.
    ///   - onDismiss: An action to perform when the sheet is dismissed
    ///     by the user.
    ///   - content: The content of the sheet
    public func sheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        SheetModifier(
            isPresented: isPresented,
            body: TupleView1(self),
            onDismiss: onDismiss,
            sheetContent: content
        )
    }

    /// Presents a modal overlay whenever `item` is non-`nil`, handing the
    /// unwrapped item to `content`.
    ///
    /// This is the item-based counterpart of
    /// ``View/sheet(isPresented:onDismiss:content:)``, for the common case
    /// where the thing being presented *is* the reason for presenting:
    ///
    /// ```swift
    /// @State var placementBeingEdited: Placement?
    ///
    /// var body: some View {
    ///     PlacementList(selection: $placementBeingEdited)
    ///         .sheet(item: $placementBeingEdited) { placement in
    ///             PlacementEditor(placement)
    ///         }
    /// }
    /// ```
    ///
    /// The sheet is presented while `item` holds a value, and `item` is set
    /// back to `nil` when the sheet is dismissed — whether the user dismissed
    /// it or ``EnvironmentValues/dismiss`` did. Setting `item` to `nil`
    /// yourself dismisses the sheet.
    ///
    /// `onDismiss` behaves exactly as it does for
    /// ``View/sheet(isPresented:onDismiss:content:)``: it runs when the user
    /// dismisses the sheet, not when it's dismissed programmatically, and it
    /// runs before `item` is cleared.
    ///
    /// - Note: Unlike SwiftUI, replacing `item` with a *differently identified*
    ///   item while the sheet is presented updates the existing sheet's
    ///   contents in place rather than dismissing and re-presenting it.
    ///
    /// - Parameters:
    ///   - item: A binding to the item to present. The sheet is shown while
    ///     it's non-`nil`.
    ///   - onDismiss: An action to perform when the sheet is dismissed by the
    ///     user.
    ///   - content: Builds the sheet's content from the unwrapped item.
    public func sheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        // Built on the `isPresented` sheet rather than a parallel mechanism, so
        // that presentation, nesting, detents and dismissal all behave
        // identically for both spellings.
        sheet(isPresented: .presenting(item), onDismiss: onDismiss) {
            OptionalView(item.wrappedValue.map(content))
        }
    }
}

extension Binding where Value == Bool {
    /// Derives a presentation binding from a binding to an optional item.
    ///
    /// The derived binding reads `true` while `item` holds a value, and clears
    /// `item` when set to `false`. Setting it to `true` does nothing, because
    /// there'd be no item to present; presentation is driven by `item` alone.
    ///
    /// - Parameter item: The item binding to derive from.
    /// - Returns: A binding suitable for
    ///   ``View/sheet(isPresented:onDismiss:content:)`` and friends.
    static func presenting<Item>(_ item: Binding<Item?>) -> Self {
        Binding(
            get: {
                item.wrappedValue != nil
            },
            set: { isPresented in
                guard !isPresented else {
                    return
                }
                item.wrappedValue = nil
            }
        )
    }
}

struct SheetModifier<Content: View, SheetContent: View>: TypeSafeView {
    typealias Children = SheetModifierViewChildren<Content, SheetContent>

    var isPresented: Binding<Bool>
    var body: TupleView1<Content>
    var onDismiss: (() -> Void)?
    var sheetContent: () -> SheetContent

    var sheet: Any?

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        let bodyViewGraphNode = ViewGraphNode(
            for: body.view0,
            backend: backend,
            environment: environment
        )
        let bodyNode = AnyViewGraphNode(bodyViewGraphNode)

        return SheetModifierViewChildren(
            childNode: bodyNode,
            sheetContentNode: nil,
            sheet: nil
        )
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        children.childNode.widget.into()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        children.childNode.computeLayout(
            with: body.view0,
            proposedSize: proposedSize,
            environment: environment
        )
    }

    @CastBackend<BackendFeatures.Sheets>(backendGenericName: "NewBackend")
    func commit<Backend: BaseAppBackend>(
        _: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        _ = children.childNode.commit()

        if isPresented.wrappedValue {
            let needsPresenting = children.sheet == nil

            let sheet: NewBackend.Sheet
            if children.sheetContentNode == nil {
                let sheetViewGraphNode = ViewGraphNode(
                    for: sheetContent(),
                    backend: backend,
                    environment: environment
                )
                let sheetContentNode = AnyViewGraphNode(sheetViewGraphNode)
                children.sheetContentNode = sheetContentNode

                sheet = backend.createSheet(
                    content: children.sheetContentNode!.widget.into()
                )
            } else {
                guard
                    let existingSheet = children.sheet,
                    let castedSheet = existingSheet as? NewBackend.Sheet
                else {
                    logger.warning(
                        """
                        SheetModifier has a nil sheet, even though the sheet \
                        has already been presented
                        """
                    )
                    return
                }
                sheet = castedSheet
            }

            let dismissAction = DismissAction(action: { [isPresented] in
                isPresented.wrappedValue = false
            })

            let sheetEnvironment =
                environment
                    .with(\.dismiss, dismissAction)
                    .with(\.sheet, sheet)

            _ = children.sheetContentNode!.computeLayout(
                with: sheetContent(),
                proposedSize: .unspecified,
                environment: sheetEnvironment
            )
            let result = children.sheetContentNode!.commit()

            let window = environment.window!
            let preferences = result.preferences
            backend.updateSheet(
                sheet,
                window: window as! NewBackend.Window,
                // We intentionally use the outer environment rather than
                // sheetEnvironment here, because this is meant to be the sheet's
                // environment, not that of its content.
                environment: environment,
                size: result.size.vector,
                onDismiss: { handleDismiss(children: children) },
                cornerRadius: preferences.presentationCornerRadius,
                detents: preferences.presentationDetents ?? [],
                dragIndicatorVisibility: preferences.presentationDragIndicatorVisibility
                    ?? .automatic,
                backgroundColor: preferences.presentationBackground?.resolve(in: environment),
                interactiveDismissDisabled: preferences.interactiveDismissDisabled ?? false
            )

            let parentSheet = environment.sheet.map { $0 as! NewBackend.Sheet }

            if needsPresenting {
                backend.presentSheet(
                    sheet,
                    window: window as! NewBackend.Window,
                    parentSheet: parentSheet
                )
            }

            children.sheet = sheet
            children.window = window
            children.parentSheet = parentSheet
        } else if !isPresented.wrappedValue && children.sheet != nil {
            backend.dismissSheet(
                children.sheet as! NewBackend.Sheet,
                window: children.window! as! NewBackend.Window,
                parentSheet: children.parentSheet.map { $0 as! NewBackend.Sheet }
            )
            children.sheet = nil
            children.window = nil
            children.parentSheet = nil
            children.sheetContentNode = nil
        }
    }

    func handleDismiss(children: Children) {
        onDismiss?()
        children.sheet = nil
        children.window = nil
        children.parentSheet = nil
        children.sheetContentNode = nil
        isPresented.wrappedValue = false
    }
}

class SheetModifierViewChildren<Child: View, SheetContent: View>: ViewGraphNodeChildren {
    var widgets: [AnyWidget] {
        [childNode.widget]
    }

    var erasedNodes: [ErasedViewGraphNode] {
        var nodes: [ErasedViewGraphNode] = [ErasedViewGraphNode(wrapping: childNode)]
        if let sheetContentNode {
            nodes.append(ErasedViewGraphNode(wrapping: sheetContentNode))
        }
        return nodes
    }

    var childNode: AnyViewGraphNode<Child>
    var sheetContentNode: AnyViewGraphNode<SheetContent>?
    var sheet: Any?
    var window: Any?
    var parentSheet: Any?

    init(
        childNode: AnyViewGraphNode<Child>,
        sheetContentNode: AnyViewGraphNode<SheetContent>?,
        sheet: Any?
    ) {
        self.childNode = childNode
        self.sheetContentNode = sheetContentNode
        self.sheet = sheet
    }
}
