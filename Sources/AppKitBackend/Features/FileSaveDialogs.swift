import AppKit
import UniformTypeIdentifiers
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.FileSaveDialogs {
    public func showSaveDialog(
        fileDialogOptions: FileDialogOptions,
        saveDialogOptions: SaveDialogOptions,
        window: Window?,
        resultHandler handleResult: @escaping (DialogResult<URL>) -> Void
    ) {
        let panel = NSSavePanel()
        panel.message = fileDialogOptions.title
        panel.prompt = fileDialogOptions.defaultButtonLabel
        panel.directoryURL = fileDialogOptions.initialDirectory
        panel.showsHiddenFiles = fileDialogOptions.showHiddenFiles
        panel.allowsOtherFileTypes = fileDialogOptions.allowOtherContentTypes

        configureContentTypes(fileDialogOptions.allowedContentTypes, on: panel)

        panel.nameFieldLabel = saveDialogOptions.nameFieldLabel ?? panel.nameFieldLabel
        panel.nameFieldStringValue = saveDialogOptions.defaultFileName ?? ""

        let handleResponse: (NSApplication.ModalResponse) -> Void = { response in
            guard response != .continue else {
                return
            }

            if response == .OK {
                handleResult(.success(panel.url!))
            } else {
                handleResult(.cancelled)
            }
        }

        if let window {
            panel.beginSheetModal(for: window, completionHandler: handleResponse)
        } else {
            let response = panel.runModal()
            handleResponse(response)
        }
    }
}

extension AppKitBackend {
    /// Restricts a save or open panel to a set of content types.
    ///
    /// `NSOpenPanel` inherits from `NSSavePanel`, so this serves both dialogs.
    func configureContentTypes(_ types: [ContentType], on panel: NSSavePanel) {
        if #available(macOS 11.0, *) {
            var seen: Set<String> = []
            panel.allowedContentTypes = types.flatMap { type in
                type.fileExtensions.compactMap { UTType(filenameExtension: $0) }
                    + type.mimeTypes.compactMap { UTType(mimeType: $0) }
            }.filter { seen.insert($0.identifier).inserted }
        } else {
            let extensions = types.flatMap(\.fileExtensions)
            panel.allowedFileTypes = extensions.isEmpty ? nil : extensions
        }
    }
}
