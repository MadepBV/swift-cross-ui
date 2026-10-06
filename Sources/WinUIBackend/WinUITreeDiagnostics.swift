import Dispatch
import Foundation
import UWP
import WinUI
import WindowsFoundation

/// Opt-in dump of every window's element tree, for diagnosing layout on a
/// machine where only screenshots can be taken. Set SCUI_WINUI_TREE_FILE to a
/// local path before launch; every few seconds the file is replaced with one
/// line per element: its type, its frame in window coordinates, its opacity
/// and visibility, and a text block's text. Nothing runs without the variable.
@MainActor
enum WinUITreeDiagnostics {
    private static let path: String? = {
        guard let path = ProcessInfo.processInfo.environment["SCUI_WINUI_TREE_FILE"], !path.isEmpty
        else { return nil }
        return path
    }()
    private static var started = false

    static func start(windows: @escaping @MainActor () -> [CustomWindow]) {
        guard path != nil, !started else { return }
        started = true
        schedule(windows)
    }

    private static func schedule(_ windows: @escaping @MainActor () -> [CustomWindow]) {
        let interval = Double(ProcessInfo.processInfo.environment["SCUI_WINUI_TREE_INTERVAL"] ?? "") ?? 5
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            MainActor.assumeIsolated {
                guard let path else { return }
                var lines: [String] = ["dumped \(Date())"]
                for window in windows() {
                    lines.append("window")
                    walk(window.grid, root: window.grid, depth: 0, into: &lines)
                }
                try? lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
                schedule(windows)
            }
        }
    }

    private static func walk(
        _ node: WinUI.DependencyObject, root: WinUI.UIElement, depth: Int, into lines: inout [String]
    ) {
        guard lines.count < 20_000, depth < 600 else { return }
        var line = String(repeating: " ", count: depth) + "\(type(of: node))"
        if let element = node as? WinUI.FrameworkElement {
            if let transform = try? element.transformToVisual(root),
                let origin = try? transform.transformPoint(WindowsFoundation.Point(x: 0, y: 0))
            {
                line += " [\(Int(origin.x)),\(Int(origin.y)) \(Int(element.actualWidth))x\(Int(element.actualHeight))]"
            } else {
                line += " [? \(Int(element.actualWidth))x\(Int(element.actualHeight))]"
            }
            if element.opacity < 1 { line += " a=\(element.opacity)" }
            if element.renderTransform != nil { line += " T" }
            if element.clip != nil { line += " clip" }
        }
        if let text = node as? WinUI.TextBlock { line += " \"\(text.text.prefix(60))\"" }
        lines.append(line)
        let count = WinUI.VisualTreeHelper.getChildrenCount(node)
        guard count > 0 else { return }
        for index in 0..<count {
            if let child = WinUI.VisualTreeHelper.getChild(node, index) {
                walk(child, root: root, depth: depth + 1, into: &lines)
            }
        }
    }
}
