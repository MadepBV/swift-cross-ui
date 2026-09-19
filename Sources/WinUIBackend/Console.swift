import Foundation
import WinSDK
import ucrt

extension WinUIBackend {
    private static var didPrepareConsoleIO = false

    /// Makes standard FILE streams usable before SwiftCrossUI initializes its
    /// logger. GUI launches may have no console and use CRT descriptor -2.
    /// Preserve inherited redirection and prepare only once: runMainLoop calls
    /// this again after the application's own initialization.
    static func attachToParentConsole() throws {
        guard !didPrepareConsoleIO else { return }
        didPrepareConsoleIO = true

        let streams: [(file: UnsafeMutablePointer<FILE>?, handle: DWORD, write: Bool)] = [
            (stdin, STD_INPUT_HANDLE, false),
            (stdout, STD_OUTPUT_HANDLE, true),
            (stderr, STD_ERROR_HANDLE, true),
        ]
        // AttachConsole replaces standard handles unless the process was
        // launched with STARTF_USESTDHANDLES. Retain existing valid handles so
        // a command-line file/pipe redirection is never changed by attachment.
        let inheritedHandles = streams.map { validStandardHandle($0.handle) }
        _ = AttachConsole(DWORD(bitPattern: -1))
        for (stream, inherited) in zip(streams, inheritedHandles) {
            if let inherited { _ = SetStdHandle(stream.handle, inherited) }
        }

        var failures: [String] = []
        for stream in streams {
            do {
                try repairStandardStream(
                    stream.file, standardHandle: stream.handle, write: stream.write)
            } catch {
                // Repair all three, even if an earlier stream could not open.
                failures.append(String(describing: error))
            }
        }
        if !failures.isEmpty {
            throw Error(message: failures.joined(separator: "; "))
        }
    }

    /// This failure path must not use the logger: a failed freopen closes its
    /// FILE stream, and logging to it can itself fast-fail in ucrt fwrite.
    /// OutputDebugString does not depend on the console or C standard streams.
    static func reportConsoleSetupFailure(_ error: any Swift.Error) {
        "SwiftCrossUI: unable to prepare standard IO: \(error)\n"
            .withCString(encodedAs: UTF16.self) { OutputDebugStringW($0) }
    }

    private static func validStandardHandle(_ identifier: DWORD) -> HANDLE? {
        guard let handle = GetStdHandle(identifier), handle != INVALID_HANDLE_VALUE else {
            return nil
        }
        SetLastError(0)
        let kind = GetFileType(handle)
        guard kind != FILE_TYPE_UNKNOWN || GetLastError() == 0 else { return nil }
        return handle
    }

    /// Leaves an already-open CRT stream unchanged. For a missing stream,
    /// reopen the actual FILE object (binding descriptor 0/1/2 alone does not
    /// repair a FILE whose descriptor is -2), then adopt an available inherited
    /// or attached-console handle. NUL remains usable if that adoption fails.
    private static func repairStandardStream(
        _ stream: UnsafeMutablePointer<FILE>?, standardHandle: DWORD, write: Bool
    ) throws {
        guard let stream else { throw Error(message: "Missing standard FILE object") }
        guard _fileno(stream) < 0 else { return }

        // freopen may close the old stream and update the Win32 standard
        // handle. Duplicate our chosen destination before that can happen.
        var duplicate: HANDLE?
        if let handle = validStandardHandle(standardHandle) {
            let process = GetCurrentProcess()
            _ = DuplicateHandle(
                process, handle, process, &duplicate,
                0, true, DWORD(DUPLICATE_SAME_ACCESS))
        }
        defer {
            if let duplicate { _ = CloseHandle(duplicate) }
        }

        var reopened: UnsafeMutablePointer<FILE>?
        guard freopen_s(&reopened, "NUL", write ? "w" : "r", stream) == 0,
              let reopened
        else {
            throw Error(message: "Failed to open NUL for standard IO")
        }
        var descriptor = _fileno(reopened)
        guard descriptor >= 0 else {
            throw Error(message: "Reopened standard FILE has no descriptor")
        }
        if let retained = duplicate {
            let flags = (write ? _O_WRONLY : _O_RDONLY) | _O_TEXT
            let source = _open_osfhandle(Int(bitPattern: retained), flags)
            if source >= 0 {
                duplicate = nil // The CRT owns this handle after successful adoption.
                if source != descriptor {
                    let result = _dup2(source, descriptor)
                    _ = _close(source)
                    if result != 0 {
                        // A failed dup may have closed its destination. Repair
                        // the FILE again before anyone attempts to log to it.
                        var fallback: UnsafeMutablePointer<FILE>?
                        guard freopen_s(
                            &fallback, "NUL", write ? "w" : "r", reopened) == 0,
                              let fallback, _fileno(fallback) >= 0
                        else {
                            throw Error(message: "Failed to restore standard IO after duplication")
                        }
                        descriptor = _fileno(fallback)
                    }
                }
            }
        }
        // Publish the live descriptor's handle after dup/close, never the
        // temporary handle whose ownership was transferred to the CRT.
        let handle = _get_osfhandle(descriptor)
        if handle != -1 {
            _ = SetStdHandle(standardHandle, HANDLE(bitPattern: handle))
        }
    }
}
