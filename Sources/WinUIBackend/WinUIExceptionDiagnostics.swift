import Foundation
import WinSDK
import WinUI
@preconcurrency import WindowsFoundation

/// Optional file-only evidence for WinUI stowed exceptions. The event is not
/// marked handled, so diagnostics do not change the application's crash policy.
@MainActor
internal enum WinUIExceptionDiagnostics {
    static func install(on application: WinUI.Application) -> WindowsFoundation.EventCleanup? {
        guard let path = ProcessInfo.processInfo.environment["SCUI_WINUI_UNHANDLED_EXCEPTION_FILE"],
            !path.isEmpty,
            let sink = Sink(path: path)
        else { return nil }

        let cleanup = application.unhandledException.addHandler { _, arguments in
            guard let arguments else { return }
            let code = UInt32(bitPattern: arguments.exception)
            let hex = String(code, radix: 16, uppercase: true)
            sink.write([
                "event": "winui.unhandledException",
                "hresult": "0x" + String(repeating: "0", count: max(0, 8 - hex.count)) + hex,
                "message": arguments.message,
            ])
            // Deliberately do not set arguments.handled.
        }
        sink.write(["event": "winui.unhandledException.listenerInstalled"])
        return cleanup
    }

    private final class Sink: @unchecked Sendable {
        private let handle: FileHandle
        private let lock = NSLock()

        init?(path: String) {
            if !FileManager.default.fileExists(atPath: path),
                !FileManager.default.createFile(atPath: path, contents: nil)
            {
                return nil
            }
            guard let handle = FileHandle(forWritingAtPath: path) else { return nil }
            self.handle = handle
            handle.seekToEndOfFile()
        }

        func write(_ fields: [String: Any]) {
            var record = fields
            record["unixTime"] = Date().timeIntervalSince1970
            record["processID"] = ProcessInfo.processInfo.processIdentifier
            record["threadID"] = GetCurrentThreadId()
            guard var data = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]) else { return }
            data.append(0x0a)
            lock.lock()
            defer { lock.unlock() }
            // Failure to write diagnostic evidence must not create a second
            // application error or redirect output to an application's pipe.
            try? handle.write(contentsOf: data)
            try? handle.synchronize()
        }

        deinit { try? handle.close() }
    }
}
