import Foundation

extension View {
    /// Presents a file picker when the binding becomes true. The binding is
    /// reset before completion; cancelling the picker does not call completion.
    ///
    /// Content filters and multiple selection are handled by the backend's
    /// native file picker. Backends without file-open support report a failure.
    @available(tvOS, unavailable, message: "tvOS does not provide file system access")
    public func fileImporter(
        isPresented: Binding<Bool>,
        allowedContentTypes: [ContentType],
        allowsMultipleSelection: Bool = false,
        onCompletion: @escaping (Result<[URL], any Error>) -> Void
    ) -> some View {
        FileImporterModifierView(
            child: self, isPresented: isPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection,
            onCompletion: onCompletion)
    }
}

/// Failures reported before a file picker can be presented.
public enum FileImporterError: Error, Sendable {
    /// The current backend does not implement file-open dialogs.
    case unsupportedBackend
}

struct FileImporterModifierView<Child: View>: TypeSafeView {
    typealias Children = FileImporterModifierChildren<Child>

    var body = EmptyView()
    var child: Child
    var isPresented: Binding<Bool>
    var allowedContentTypes: [ContentType]
    var allowsMultipleSelection: Bool
    var onCompletion: (Result<[URL], any Error>) -> Void

    func children<Backend: BaseAppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: EnvironmentValues
    ) -> Children {
        Children(childNode: AnyViewGraphNode(ViewGraphNode(
            for: child, backend: backend, environment: environment)))
    }

    func asWidget<Backend: BaseAppBackend>(
        _ children: Children, backend: Backend
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
            with: child, proposedSize: proposedSize, environment: environment)
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        _ = children.childNode.commit()
        // Like a sheet, presentation is a commit side effect. Layout probes
        // only measure the unchanged child and never open a native dialog.
        guard !environment.isProbingLayout else { return }
        if !isPresented.wrappedValue {
            children.pending?.acceptsResult = false
        }
        children.presentIfNeeded = { [weak children] in
            guard let children else { return }
            presentIfNeeded(children: children, environment: environment, backend: backend)
        }
        children.presentIfNeeded?()
    }

    private func presentIfNeeded<Backend: BaseAppBackend>(
        children: Children, environment: EnvironmentValues, backend: Backend
    ) {
        guard isPresented.wrappedValue, children.pending == nil else { return }
        guard let backend = backend as? any BackendFeatures.FileOpenDialogs else {
            isPresented.wrappedValue = false
            onCompletion(.failure(FileImporterError.unsupportedBackend))
            return
        }
        func present<B: BackendFeatures.FileOpenDialogs>(_ backend: B) {
            let request = FileImporterPendingRequest()
            children.pending = request
            let binding = isPresented
            let completion = onCompletion
            let allowsMultipleSelection = allowsMultipleSelection
            backend.showOpenDialog(
                fileDialogOptions: FileDialogOptions(
                    title: "Open", defaultButtonLabel: "Open",
                    allowedContentTypes: allowedContentTypes,
                    showHiddenFiles: false, allowOtherContentTypes: false,
                    initialDirectory: nil),
                openDialogOptions: OpenDialogOptions(
                    allowSelectingFiles: true, allowSelectingDirectories: false,
                    allowMultipleSelections: allowsMultipleSelection),
                window: environment.window as? B.Window
            ) { [weak children] result in
                guard let children, children.pending === request else { return }
                children.pending = nil
                // The backend protocol cannot close a picker programmatically.
                // A revoked request loses its result authority; a subsequent
                // true binding can present only after the old picker closes.
                guard request.acceptsResult, binding.wrappedValue else {
                    children.presentIfNeeded?()
                    return
                }
                binding.wrappedValue = false
                switch result {
                    case .success(let urls) where !urls.isEmpty:
                        completion(.success(allowsMultipleSelection ? urls : Array(urls.prefix(1))))
                    case .success, .cancelled:
                        break
                }
            }
        }
        present(backend)
    }
}

@MainActor
private final class FileImporterPendingRequest {
    var acceptsResult = true
}

@MainActor
final class FileImporterModifierChildren<Child: View>: ViewGraphNodeChildren {
    let childNode: AnyViewGraphNode<Child>
    fileprivate var pending: FileImporterPendingRequest?
    var presentIfNeeded: (() -> Void)?

    var widgets: [AnyWidget] { [childNode.widget] }
    var erasedNodes: [ErasedViewGraphNode] { [ErasedViewGraphNode(wrapping: childNode)] }

    init(childNode: AnyViewGraphNode<Child>) {
        self.childNode = childNode
    }
}
