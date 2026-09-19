import Foundation
import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@MainActor @Suite struct FileImporterTests {
    private let png = ContentType(name: "PNG", mimeTypes: ["image/png"], fileExtensions: ["png"])
    private let first = URL(fileURLWithPath: "/tmp/first.png")
    private let second = URL(fileURLWithPath: "/tmp/second.png")

    @Test func layoutDoesNotPresentAndCommitsOpenOneFilteredDialog() {
        let source = PresentationSource(true)
        let session = FileImportSession(Text("Content").fileImporter(
            isPresented: source.binding, allowedContentTypes: [png],
            allowsMultipleSelection: true) { _ in })
        let size = session.layout().size
        #expect(session.probe.requests.isEmpty)
        session.commit()
        session.commit()
        #expect(session.probe.requests.count == 1)
        #expect(session.layout().size == size)
        let request = session.probe.requests[0]
        #expect(request.window === session.window)
        #expect(request.files.allowedContentTypes.map(\.fileExtensions) == [["png"]])
        #expect(!request.files.allowOtherContentTypes)
        #expect(request.open.allowMultipleSelections)
        #expect(request.open.allowSelectingFiles)
        #expect(!request.open.allowSelectingDirectories)
    }

    @Test func successResetsBindingBeforeOneCompletionAndCanReopen() {
        let source = PresentationSource(true)
        var received: [[URL]] = []
        let session = FileImportSession(Text("Content").fileImporter(
            isPresented: source.binding, allowedContentTypes: [png],
            allowsMultipleSelection: true
        ) { result in
            #expect(!source.isPresented)
            if case .success(let urls) = result { received.append(urls) }
        })
        session.commit()
        session.probe.requests[0].complete(.success([first, second]))
        session.probe.requests[0].complete(.success([first]))
        #expect(received == [[first, second]])
        #expect(!source.isPresented)
        session.commit()
        #expect(session.probe.requests.count == 1)
        source.isPresented = true
        session.commit()
        #expect(session.probe.requests.count == 2)
    }

    @Test func singleSelectionRestrictsUnexpectedExtraBackendResults() {
        let source = PresentationSource(true)
        var received: [URL] = []
        let session = FileImportSession(Text("Content").fileImporter(
            isPresented: source.binding, allowedContentTypes: [png]
        ) { result in
            if case .success(let urls) = result { received = urls }
        })
        session.commit()
        #expect(!session.probe.requests[0].open.allowMultipleSelections)
        session.probe.requests[0].complete(.success([first, second]))
        #expect(received == [first])
    }

    @Test func cancellationAndEmptyResultsDoNotRunCompletion() {
        let results: [DialogResult<[URL]>] = [.cancelled, .success([])]
        for result in results {
            let source = PresentationSource(true)
            var completionCount = 0
            let session = FileImportSession(Text("Content").fileImporter(
                isPresented: source.binding, allowedContentTypes: [png]
            ) { _ in completionCount += 1 })
            session.commit()
            session.probe.requests[0].complete(result)
            #expect(!source.isPresented)
            #expect(completionCount == 0)
        }
    }

    @Test func removedViewIgnoresOutstandingNativeResult() {
        let source = PresentationSource(true)
        var completionCount = 0
        let session = FileImportSession(Text("Content").fileImporter(
            isPresented: source.binding, allowedContentTypes: [png]
        ) { _ in completionCount += 1 })
        session.commit()
        session.removeView()
        session.probe.requests[0].complete(.success([first]))
        #expect(completionCount == 0)
        #expect(source.isPresented)
    }

    @Test func revocationSuppressesOldResultBeforeQueuedReopen() {
        let source = PresentationSource(true)
        var received: [[URL]] = []
        let session = FileImportSession(Text("Content").fileImporter(
            isPresented: source.binding, allowedContentTypes: [png]
        ) { result in
            if case .success(let urls) = result { received.append(urls) }
        })
        session.commit()
        source.isPresented = false
        session.commit()
        source.isPresented = true
        session.commit()
        #expect(session.probe.requests.count == 1)
        session.probe.requests[0].complete(.success([first]))
        #expect(received.isEmpty)
        #expect(session.probe.requests.count == 2)
        session.probe.requests[0].complete(.cancelled)
        #expect(source.isPresented)
        session.probe.requests[1].complete(.success([second]))
        #expect(received == [[second]])
        #expect(!source.isPresented)
    }

    @Test func chooseFilePassesFiltersAndHandlesEmptySuccess() async throws {
        let backend = DummyBackend()
        let probe = FileOpenProbe.install(for: backend)
        let action = EnvironmentValues(backend: backend).chooseFile
        let task = Task { await action(allowedContentTypes: [png], allowOtherContentTypes: false) }
        let deadline = Date().addingTimeInterval(3)
        while probe.requests.isEmpty {
            guard Date() < deadline else { throw WaitError.dialogNotPresented }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        #expect(probe.requests[0].files.allowedContentTypes.map(\.fileExtensions) == [["png"]])
        #expect(!probe.requests[0].files.allowOtherContentTypes)
        probe.requests[0].complete(.success([]))
        #expect(await task.value == nil)
    }

    private enum WaitError: Error { case dialogNotPresented }
}

@MainActor
private final class FileImportSession<Content: View> {
    let backend = DummyBackend()
    let window: DummyBackend.Window
    let environment: EnvironmentValues
    let probe: FileOpenProbe
    private var node: ViewGraphNode<Content, DummyBackend>?

    init(_ view: Content) {
        window = backend.createWindow(withDefaultSize: nil, id: "file-import")
        environment = EnvironmentValues(backend: backend).with(\.window, window)
        probe = FileOpenProbe.install(for: backend)
        node = ViewGraphNode(for: view, backend: backend, environment: environment)
    }

    func layout() -> ViewLayoutResult {
        node!.computeLayout(proposedSize: ProposedViewSize(400, 300), environment: environment)
    }

    func commit() {
        _ = layout()
        _ = node!.commit()
    }

    func removeView() { node = nil }
}

@MainActor
private final class FileOpenProbe {
    struct Request {
        let files: FileDialogOptions
        let open: OpenDialogOptions
        let window: DummyBackend.Window?
        let complete: (DialogResult<[URL]>) -> Void
    }
    static var probes: [ObjectIdentifier: FileOpenProbe] = [:]
    var requests: [Request] = []

    static func install(for backend: DummyBackend) -> FileOpenProbe {
        let probe = FileOpenProbe()
        probes[ObjectIdentifier(backend)] = probe
        return probe
    }
}

extension DummyBackend: BackendFeatures.FileOpenDialogs {
    public func showOpenDialog(
        fileDialogOptions: FileDialogOptions,
        openDialogOptions: OpenDialogOptions,
        window: Window?,
        resultHandler handleResult: @escaping (DialogResult<[URL]>) -> Void
    ) {
        guard let probe = FileOpenProbe.probes[ObjectIdentifier(self)] else {
            handleResult(.cancelled)
            return
        }
        probe.requests.append(.init(
            files: fileDialogOptions, open: openDialogOptions,
            window: window, complete: handleResult))
    }
}
