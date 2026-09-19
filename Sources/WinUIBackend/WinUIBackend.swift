import CWinRT
import Foundation
import Dispatch
@_spi(Backends) import SwiftCrossUI
import UWP
import WinAppSDK
import WinSDK
import WinUI
import WinUIInterop
@preconcurrency import WindowsFoundation
import Mutex

// Many force tries are required for the WinUI backend but we don't really want them
// anywhere else so just disable the lint rule at a file level.
// swiftlint:disable force_try

extension App {
    public typealias Backend = WinUIBackend

    public var backend: WinUIBackend {
        WinUIBackend(urlSchemes: Self.metadata?.urlSchemes?.map(\.scheme))
    }
}

class WinUIApplication: SwiftApplication, @unchecked Sendable {
    static let callback = Mutex<(@MainActor (WinUIApplication, AppInstance) -> Void)?>(nil)
    static let urlSchemes = Mutex<[String]>([])
    private var mainQueueWakeupBridge: MainQueueWakeupBridge?
    private var exceptionDiagnostics: WindowsFoundation.EventCleanup?

    override func onLaunched(_ args: WinUI.LaunchActivatedEventArgs) {
        // Register the schemes on each launch. Windows ignores duplicate URL
        // scheme registrations so this is safe.
        let schemes = Self.urlSchemes.withLock { $0 }
        var processName = ProcessInfo.processInfo.processName
        if processName.hasSuffix(".exe") {
            processName = String(processName.dropLast(".exe".count))
        }
        for scheme in schemes {
            ActivationRegistrationManager.registerForProtocolActivation(
                scheme,
                "",
                processName,
                ""
            )
        }

        // Adapted from https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/applifecycle/applifecycle-single-instance
        let args = try! AppInstance.getCurrent().getActivatedEventArgs()!
        let keyInstance = AppInstance.findOrRegisterForKey(processName)!
        guard keyInstance.isCurrent else {
            Self.redirectActivation(args, to: keyInstance)
        }

        Self.callback.withLock { callback in
            MainActor.assumeIsolated {
                WinUITimingDiagnostics.start()
                if exceptionDiagnostics == nil {
                    exceptionDiagnostics = WinUIExceptionDiagnostics.install(on: self)
                }
                if mainQueueWakeupBridge == nil {
                    mainQueueWakeupBridge = MainQueueWakeupBridge()
                }
                callback?(self, keyInstance)
            }
        }
    }

    override func onShutdown() {
        MainActor.assumeIsolated {
            mainQueueWakeupBridge?.stop()
            mainQueueWakeupBridge = nil
            exceptionDiagnostics?.dispose()
            exceptionDiagnostics = nil
            WinUITimingDiagnostics.stop()
        }
    }

    // Adapted from https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/applifecycle/applifecycle-single-instance
    static func redirectActivation(
        _ args: AppActivationArguments,
        to keyInstance: AppInstance
    ) -> Never {
        let semaphore = DispatchSemaphore(value: 0)
        let promise = try! keyInstance.redirectActivationToAsync(args)!
        promise.completed = { _, _ in
            semaphore.signal()
        }

        semaphore.wait()

        // Bring key instance to the foreground
        do {
            try InstancingHelpers.activateProcess(withId: Int(keyInstance.processId))
        } catch {
            print(
                """
                Failed to bring key instance (pid=\(keyInstance.processId)) to \
                foreground: \(error.localizedDescription)
                """
            )
        }
        Foundation.exit(0)
    }
}

public final class WinUIBackend:
    BaseAppBackend,
    BackendFeatures.ApplicationMenus,
    BackendFeatures.ExternalURLs,
    BackendFeatures.IncomingURLs,
    BackendFeatures.FileDialogs,
    BackendFeatures.CornerRadius,
    BackendFeatures.Gestures,
    BackendFeatures.AttachedMenus,
    BackendFeatures.Paths,
    BackendFeatures.Tooltips,
    BackendFeatures.Colors,
    BackendFeatures.DatePickers,
    BackendFeatures.Windowing,
    BackendFeatures.LinearGradients,
    BackendFeatures.RadialGradients
{
    // Logging
    private struct LogLocation: Hashable, Equatable {
        let file: String
        let line: Int
        let column: Int
    }

    private var logsPerformed: Set<LogLocation> = []

    func debugLogOnce(
        _ message: String,
        file: String = #file,
        line: Int = #line,
        column: Int = #column
    ) {
        #if DEBUG
            let location = LogLocation(file: file, line: line, column: column)
            if logsPerformed.insert(location).inserted {
                logger.notice("\(message)")
            }
        #endif
    }

    public typealias Window = CustomWindow
    public typealias Widget = WinUI.FrameworkElement
    public typealias Menu = WinUI.MenuFlyout
    public typealias Path = GeometryGroupHolder

    public let defaultTableRowContentHeight = 20
    public let defaultTableCellVerticalPadding = 4
    public let defaultPaddingAmount = 10
    public let requiresImageUpdateOnScaleFactorChange = false
    public let supportsMultipleWindows = true
    public let deviceClass = SwiftCrossUI.DeviceClass.desktop
    public let supportedDatePickerStyles: [DatePickerStyle] = [
        .automatic,
        .graphical,
        .compact,
        .wheel,
    ]
    public let supportedPickerStyles: [BackendPickerStyle] = [.menu, .radioGroup, .segmented]
    public let canOverrideWindowColorScheme = true
    public let restoresWindowFrames = false
    // `size(of:whenDisplayedIn:...)` measures with `measurementTextBlock` and
    // never reads the widget it is handed, so `Text` doesn't have to write the
    // widget before every measurement. That used to be a few thousand calls per
    // pass for a window of a few hundred labels.
    public let measuresTextIndependentlyOfWidget = true

    public var scrollBarWidth: Int {
        12
    }

    var borderedButtonPadding: SIMD2<Int>?

    class InternalState {
        var buttonClickActions: [ObjectIdentifier: () -> Void] = [:]
        var toggleClickActions: [ObjectIdentifier: (Bool) -> Void] = [:]
        var switchClickActions: [ObjectIdentifier: (Bool) -> Void] = [:]
        var sliderChangeActions: [ObjectIdentifier: (Double) -> Void] = [:]
        var textFieldChangeActions: [ObjectIdentifier: (String) -> Void] = [:]
        var textFieldSubmitActions: [ObjectIdentifier: () -> Void] = [:]
    }
    private var rootEnvironmentChangeHandler: (@Sendable @MainActor () -> Void)?

    var internalState: InternalState
    nonisolated(unsafe) private var dispatcherQueue: WinAppSDK.DispatcherQueue?

    var windows: [Window] = []

    private var measurementTextBlock: TextBlock!

    public convenience init() {
        self.init(urlSchemes: nil)
    }

    public init(urlSchemes: [String]?) {
        internalState = InternalState()
        WinUIApplication.urlSchemes.withLock { schemes in
            schemes = urlSchemes ?? []
        }
    }

    struct Error: LocalizedError {
        var message: String

        var errorDescription: String? {
            message
        }
    }

    public static func earlySetup() {
        do {
            try Self.attachToParentConsole()
        } catch {
            Self.reportConsoleSetupFailure(error)
        }
    }

    public func runMainLoop(_ callback: @escaping @MainActor () -> Void) {
        do {
            try Self.attachToParentConsole()
        } catch {
            Self.reportConsoleSetupFailure(error)
        }

        // Ensure that the app's windows adapt to DPI changes at runtime
        SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)

        WinUIApplication.callback.withLock { launchCallback in
            launchCallback = { application, instance in
                // Toggle Switch has annoying default 'internal margins' (not Control
                // margins that we can set directly) that we can luckily get rid of by
                // overriding the relevant resource values.
                _ = application.resources.insert("ToggleSwitchPreContentMargin", 0.0 as Double)
                _ = application.resources.insert("ToggleSwitchPostContentMargin", 0.0 as Double)

                // Handle theme changes
                UWP.UISettings().colorValuesChanged.addHandler { _, _ in
                    Task { @MainActor in
                        self.rootEnvironmentChangeHandler?()
                    }
                }

                // TODO: Read in previously hardcoded values from the application's
                // resources dictionary for future-proofing. Example code for getting
                // property values;
                //   let iinspectable =
                //       application.resources.lookup("ToggleSwitchPreContentMargin")!
                //       as! WindowsFoundation.IInspectable
                //   let pv: __ABI_Windows_Foundation.IPropertyValue = try! iinspectable.QueryInterface()
                //   let value = try! pv.GetDoubleImpl()

                self.measurementTextBlock = (self.createTextView() as! TextBlock)

                instance.activated.addHandler { (_, args: AppActivationArguments?) in
                    guard let args else {
                        logger.warning("Received activation with no activation arguments?")
                        return
                    }
                    self.processActivationArguments(args)
                }

                callback()
            }
        }
        WinUIApplication.main()
    }

    public func createWindow(withDefaultSize size: SIMD2<Int>?, id: String) -> Window {
        let window = CustomWindow()
        WinUIPointerHitDiagnostics.install(on: window.grid)
        windows.append(window)
        window.closed.addHandler { _, _ in
            self.windows.removeAll { other in
                window === other
            }
        }

        if self.dispatcherQueue == nil {
            self.dispatcherQueue = window.dispatcherQueue
        }

        // import WinSDK
        // import CWinRT
        // @_spi(WinRTInternal) import WindowsFoundation
        // let minSizeHook: HOOKPROC = { (nCode: Int32, wParam: WPARAM, lParam: LPARAM) in
        //     if nCode >= 0 {
        //         let ptr = UnsafeRawPointer(bitPattern: Int(lParam))?
        //             .assumingMemoryBound(to: CWPRETSTRUCT.self)
        //         if let msgInfo = ptr?.pointee, msgInfo.message == WM_GETMINMAXINFO {
        //             print("Received WM_GETMINMAXINFO")

        //             // var value: HWND = .init(0)
        //             _ = try! window._inner.perform(
        //                 as: __x_ABI_CMicrosoft_CUI_CXaml_CIWindowNative.self
        //             ) { pThis in
        //                 try! CHECKED(pThis.pointee.lpVtbl.pointee.get_WindowHandle(pThis, nil))
        //             }
        //         }
        //     }
        //     return CallNextHookEx(nil, nCode, wParam, lParam)
        // }

        // _ = SetWindowsHookExW(WH_CALLWNDPROCRET, minSizeHook, nil, GetCurrentThreadId())
        // print("Registered")

        // print(GetDpiForWindow(nil))

        if let size {
            // `setSize(ofWindow:to:)` clamps to the display's work area, so a
            // default size larger than a small or heavily scaled screen
            // still produces a window that fits on it.
            setSize(ofWindow: window, to: size)
        }
        return window
    }

    public func updateWindow(_ window: Window, environment: EnvironmentValues) {
        window.menuBar.requestedTheme = switch environment.colorScheme {
            case .light: .light
            case .dark: .dark
        }

        let backgroundColor: SwiftCrossUI.Color = switch environment.colorScheme {
            case .light: .white
            case .dark: .black
        }
        let brush = WinUI.SolidColorBrush()
        brush.color = backgroundColor.resolve(in: environment).uwpColor
        window.grid.background = brush
    }

    public func size(ofWindow window: Window) -> SIMD2<Int> {
        let size = window.appWindow.clientSize
        let scaleFactor = window.scaleFactor
        let width = Double(size.width) / scaleFactor
        let height = Double(size.height) / scaleFactor
        let out = SIMD2(
            Int(width.rounded(.towardZero)),
            Int(height.rounded(.towardZero)) - window.contentHeightAdjustment
        )
        return out
    }

    public func isWindowProgrammaticallyResizable(_ window: Window) -> Bool {
        // TODO: Detect whether window is fullscreen
        return true
    }

    public func setSize(ofWindow window: Window, to newSize: SIMD2<Int>) {
        // Sizes cross this boundary in points (logical pixels); AppWindow
        // works in physical pixels, so the display's scale factor is applied
        // exactly once, here. The result is clamped to the work area of the
        // display the window is on, so a window never starts off larger than
        // the screen.
        var contentSize = newSize
        if let available = window.availableContentSize {
            contentSize.x = min(contentSize.x, available.x)
            contentSize.y = min(contentSize.y, available.y)
        }
        try! window.appWindow.resizeClient(window.physicalClientSize(forContentSize: contentSize))
    }

    public func setSizeLimits(
        ofWindow window: Window,
        minimum minimumSize: SIMD2<Int>,
        maximum maximumSize: SIMD2<Int>?
    ) {
        // Windows App SDK 1.4 (swift-winui 0.2) has no presenter-level
        // minimum/maximum, so the limits are enforced by resizing back
        // whenever the window's client size leaves them.
        window.minimumContentSize = minimumSize
        window.maximumContentSize = maximumSize
        window.installSizeLimitEnforcement()
        window.enforceSizeLimits()
    }

    public func setResizeHandler(
        ofWindow window: Window,
        to action: @escaping (SIMD2<Int>) -> Void
    ) {
        window.sizeChanged.addHandler { [weak self, weak window] _, _ in
            guard let self, let window else { return }
            // Read the size back the same way `size(ofWindow:)` does, so the
            // layout is always given the client size in points regardless of
            // the units the event reports in.
            action(self.size(ofWindow: window))
        }
    }

    public func setTitle(ofWindow window: Window, to title: String) {
        window.title = title
    }

    public func setBehaviors(
        ofWindow window: Window,
        closable: Bool,
        minimizable: Bool,
        resizable: Bool
    ) {
        // Source: https://devblogs.microsoft.com/oldnewthing/20100604-00/?p=13803
        let hwnd = window.getHWND()!
        let flags = if closable { MF_ENABLED } else { MF_DISABLED | MF_GRAYED }
        EnableMenuItem(
            GetSystemMenu(hwnd, false),
            numericCast(SC_CLOSE),
            numericCast(MF_BYCOMMAND | flags)
        )

        (window.appWindow.presenter as? OverlappedPresenter)?.isMinimizable = minimizable
        (window.appWindow.presenter as? OverlappedPresenter)?.isResizable = resizable
    }

    public func setChild(ofWindow window: Window, to widget: Widget) {
        window.setChild(widget)
        try! widget.updateLayout()
        widget.actualThemeChanged.addHandler { _, _ in
            Task { @MainActor in
                self.rootEnvironmentChangeHandler?()
            }
        }
    }

    public func show(window: Window) {
        activate(window: window)
    }

    public func activate(window: Window) {
        do {
            try window.activate()
        } catch {
            logger.warning("Failed to activate window: \(error)")
        }
    }

    public func close(window: Window) {
        window.requestAuthorizedClose()
    }

    public func setCloseHandler(
        ofWindow window: Window,
        to action: @escaping () -> Void
    ) {
        window.closed.addHandler { _, _ in
            action()
        }
    }

    public func openExternalURL(_ url: URL) throws {
        let promise = UWP.Launcher.launchUriAsync(WindowsFoundation.Uri(url.absoluteString))!
        let semaphore = DispatchSemaphore(value: 0)
        promise.completed = { _, status in
            semaphore.signal()

            if status != .completed {
                logger.warning("Failed to open external URL \(url)")
            }
        }

        // Block until the URL has been launched
        semaphore.wait()
    }

    public func runInMainThread(action: @escaping @MainActor () -> Void) {
        let queued = WinUITimingDiagnostics.begin()
        _ = try! dispatcherQueue!.tryEnqueue(.normal) {
            MainActor.assumeIsolated {
                WinUITimingDiagnostics.end(.updateWait, queued)
                let timing = WinUITimingDiagnostics.begin(cpu: true)
                defer { WinUITimingDiagnostics.end(.updateExecute, timing) }
                action()
            }
        }
    }

    public func show(widget _: Widget) {}

    private func renderMenuItem(
        _ item: ResolvedMenu.Item,
        environment: EnvironmentValues
    ) -> MenuFlyoutItemBase {
        switch item {
            case .button(let label, let action):
                let widget = MenuFlyoutItem()
                widget.text = label
                widget.click.addHandler { _, _ in
                    action?()
                }
                widget.isEnabled = environment.isEnabled
                return widget
            case .toggle(let label, let value, let onChange):
                let widget = ToggleMenuFlyoutItem()
                widget.text = label
                widget.isChecked = value
                widget.click.addHandler { [weak widget] _, _ in
                    guard let widget else { return }
                    onChange(widget.isChecked)
                }
                widget.isEnabled = environment.isEnabled
                return widget
            case .separator:
                return MenuFlyoutSeparator()
            case .submenu(let submenu):
                let widget = MenuFlyoutSubItem()
                widget.text = submenu.label
                for subitem in submenu.content.items {
                    widget.items.append(
                        renderMenuItem(subitem, environment: environment)
                    )
                }
                return widget
            case .modifiedEnvironment(let item, let modification):
                return renderMenuItem(item, environment: modification(environment))
        }
    }

    public func setApplicationMenu(
        _ submenus: [ResolvedMenu.Submenu],
        environment: EnvironmentValues
    ) {
        let items = submenus.map { submenu in
            let item = MenuBarItem()
            item.title = submenu.label
            for subitem in submenu.content.items {
                item.items.append(
                    renderMenuItem(subitem, environment: environment)
                )
            }
            return item
        }

        for window in windows {
            window.menuBar.items.clear()
            for item in items {
                window.menuBar.items.append(item)
            }
            window.setMenuBarVisible(!items.isEmpty)
            window.menuBar.requestedTheme = .dark
        }
    }

    public func computeRootEnvironment(
        defaultEnvironment: EnvironmentValues
    ) -> EnvironmentValues {
        // Source: https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/ui/apply-windows-themes#know-when-dark-mode-is-enabled
        let backgroundColor = try! UWP.UISettings().getColorValue(.background)

        let green = Int(backgroundColor.g)
        let red = Int(backgroundColor.r)
        let blue = Int(backgroundColor.b)
        let isLight = 5 * green + 2 * red + blue > 8 * 128

        let locale = Foundation.Locale.windowsCurrent

        return
            defaultEnvironment
                .with(\.colorScheme, isLight ? .light : .dark)
                .with(\.appPhase, windows.contains(where: \.isActive) ? .active : .inactive)
                .with(\.locale, locale)
                .with(\.calendar, locale.calendar)
    }

    public func setRootEnvironmentChangeHandler(
        to action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.rootEnvironmentChangeHandler = action
    }

    public func computeWindowEnvironment(
        window: Window,
        rootEnvironment: EnvironmentValues
    ) -> EnvironmentValues {
        // Points stay points; the scale factor is only there for views that
        // rasterise their own content (images, canvases) so they can draw at
        // the display's pixel density. A DPI change resizes the window, which
        // re-runs this through the resize handler.
        rootEnvironment
            .with(\.windowScaleFactor, window.scaleFactor)
            .with(\.scenePhase, window.isActive ? .active : .inactive)
    }

    public func setWindowEnvironmentChangeHandler(
        of window: Window,
        to action: @escaping @Sendable @MainActor () -> Void
    ) {
        // TODO: Notify when window scale factor changes

        // NB: This event fires when the window is activated _or_ deactivated.
        window.activated.addHandler { _, _ in
            if let rootHandler = self.rootEnvironmentChangeHandler {
                rootHandler()
                // Don't bother calling `action` since this window's environment
                // will be recomputed anyway.
            } else {
                action()
            }
        }
    }

    var incomingURLHandler: ((URL) -> Void)?

    public func setIncomingURLHandler(to action: @escaping (URL) -> Void) {
        let isFirstCall = incomingURLHandler == nil
        self.incomingURLHandler = action

        if isFirstCall {
            // Check if this app instance was launched by a URL activation. If it
            // was a URL activation, then handle it now.
            let args = try! AppInstance.getCurrent().getActivatedEventArgs()!
            processActivationArguments(args)
        }
    }

    private func processActivationArguments(_ args: AppActivationArguments) {
        if args.kind == .protocol {
            if let data = args.data as? IProtocolActivatedEventArgs {
                let urlString = data.uri.absoluteUri
                if let url = URL(string: urlString) {
                    self.incomingURLHandler?(url)
                } else {
                    logger.warning("Failed to parse activation URL: \(urlString)")
                }
            } else {
                logger.warning("Failed to get activation URL")
            }
        }
    }

    public func createContainer() -> Widget {
        WinUI.Canvas()
    }

    public func removeAllChildren(of container: Widget) {
        let container = container as! WinUI.Canvas
        container.children.clear()
        WidgetPropertyCache.shared.invalidateChildPositions(of: container)
    }

    public func insert(_ child: Widget, into container: Widget, at index: Int) {
        let container = container as! WinUI.Canvas
        container.children.insertAt(UInt32(index), child)
        WidgetPropertyCache.shared.invalidateChildPositions(of: container)
    }

    public func swap(childAt firstIndex: Int, withChildAt secondIndex: Int, in container: Widget) {
        // TODO: Find out if there's an efficient way to do this without WinUI
        //   getting annoyed at us for having the same element in the list twice.
        let container = container as! WinUI.Canvas
        let largerIndex = UInt32(max(firstIndex, secondIndex))
        let smallerIndex = UInt32(min(firstIndex, secondIndex))
        let element1 = container.children[Int(smallerIndex)]
        let element2 = container.children[Int(largerIndex)]
        container.children.removeAt(largerIndex)
        container.children.removeAt(smallerIndex)
        container.children.insertAt(smallerIndex, element2)
        container.children.insertAt(largerIndex, element1)
        WidgetPropertyCache.shared.invalidateChildPositions(of: container)
    }

    public func remove(childAt index: Int, from container: Widget) {
        let container = container as! WinUI.Canvas
        container.children.removeAt(UInt32(index))
        WidgetPropertyCache.shared.invalidateChildPositions(of: container)
    }

    public func setPosition(ofChildAt index: Int, in container: Widget, to position: SIMD2<Int>) {
        let container = container as! WinUI.Canvas

        // A commit repositions every child of every container, and almost all
        // of them land where they already were. The lookup and the two attached
        // property writes below are three COM crossings, so the position is
        // remembered against the container (a child fetched from the children
        // collection is a fresh projected object each time and can't be used as
        // a cache key). `invalidateChildPositions(of:)` is called wherever the
        // container's children are rearranged, so an index always refers to the
        // same child as when its position was recorded.
        let entry = WidgetPropertyCache.shared.entry(for: container)
        if entry.childPositions[index] == position {
            return
        }

        guard let child = container.children.getAt(UInt32(index)) else {
            logger.warning("child to set position of not found")
            return
        }

        WinUI.Canvas.setTop(child, Double(position.y))
        WinUI.Canvas.setLeft(child, Double(position.x))
        entry.childPositions[index] = position
    }

    public func createColorableRectangle() -> Widget {
        WinUI.Canvas()
    }

    public func setColor(
        ofColorableRectangle widget: Widget,
        to color: SwiftCrossUI.Color.Resolved
    ) {
        let canvas = widget as! WinUI.Canvas
        let entry = WidgetPropertyCache.shared.entry(for: canvas)
        guard entry.backgroundColor != color else {
            return
        }
        entry.backgroundColor = color
        canvas.background = SolidColorBrushCache.brush(for: color)
    }

    public func createCornerRadiusContainer(wrapping child: Widget) -> Widget {
        child
    }

    public func setCornerRadius(of widget: Widget, to radius: Int) {
        guard let clip = CornerClipRegistry.shared.clip(for: widget) else {
            return
        }
        clip.geometry.cornerRadius = WindowsFoundation.Vector2(
            x: Float(radius),
            y: Float(radius)
        )
        clip.resize(width: widget.width, height: widget.height)
    }

    public func naturalSize(of widget: Widget) -> SIMD2<Int> {
        Self.naturalSize(of: widget)
    }

    /// A static version of `naturalSize(of:)` for convenience. Used by
    /// WinUIElementRepresentable.
    ///
    /// Measuring is answered from ``WidgetPropertyCache/Entry/naturalSize``
    /// while the layout pass that produced it is still the current one. The
    /// layout system asks a control for its natural size up to three times
    /// within one pass — a minimum probe, a maximum probe and the proposal its
    /// container settles on — and every one of those runs the measurement
    /// below, which is nine COM crossings and a synchronous WinUI measure.
    @MainActor
    public static func naturalSize(of widget: Widget) -> SIMD2<Int> {
        let entry = WidgetPropertyCache.shared.entry(for: widget)
        if let cached = entry.naturalSize, cached.token == LayoutPass.token {
            return cached.size
        }
        let size = measureNaturalSize(of: widget)
        entry.naturalSize = (LayoutPass.token, size)
        return size
    }

    /// Measures a widget's natural size, ignoring any cached answer.
    @MainActor
    private static func measureNaturalSize(of widget: Widget) -> SIMD2<Int> {
        let allocation = WindowsFoundation.Size(
            width: .infinity,
            height: .infinity
        )

        // Some elements don't return any sort of sensible measurement before
        // they've been rendered. For said elements, we just compute their sizes
        // as best we can by roughly replicating WinUI's internal calculations.
        let noPadding = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        if widget is WinUI.Slider {
            // As with buttons, slider sizing also doesn't work before the first
            // view update. The width and height I've hardcoded here were taken
            // from the WinUI source code: https://github.com/microsoft/microsoft-ui-xaml/blob/650b2c1bad272393400403ca323b3cb8745f95d0/src/controls/dev/CommonStyles/Slider_themeresources.xaml#L169
            return SIMD2(
                18 + 8,
                18 + 8
            )
        } else if widget is WinUI.ToggleSwitch {
            // WinUI sets the min-width of switches to 154 for whatever reason,
            // and I don't know how to override that default from Swift, so I'm
            // just hardcoding the size. This keeps getting jankier and
            // jankier...
            return SIMD2(
                40,
                20
            )
        } else if widget is CustomCheckBox {
            // WinUI sets quite a strange default size for checkboxes (with a
            // minimum width of 120), so we just hardcode the correct natural
            // size. The value 20 was taken from the WinUI source code:
            // https://github.com/microsoft/microsoft-ui-xaml/blob/d37afef65a0fc3219ba6b349301d685099fb129d/src/controls/dev/CommonStyles/CheckBox_themeresources.xaml#L270
            return SIMD2(20, 20)
        } else if let picker = widget as? CustomComboBox, picker.padding == noPadding {
            let label = TextBlock()
            // Empty lists and a transient out-of-range native index can be
            // measured before the control has loaded. Preserve the first-item
            // estimate for no selection, and use empty text if no item exists.
            let index = Int(max(picker.selectedIndex, 0))
            label.text = picker.options.indices.contains(index) ? picker.options[index] : ""
            label.fontSize = picker.fontSize
            label.fontWeight = picker.fontWeight
            label.fontStyle = picker.fontStyle
            try! label.measure(allocation)

            // These padding values were gathered experimentally. I've found that
            // WinUI generally hardcodes padding, border thickness and such in its
            // default theme, so I feel it's safe enough to use this workaround for
            // now (until https://github.com/microsoft/microsoft-ui-xaml/issues/10278
            // gets an answer).
            let labelSize = label.desiredSize
            return SIMD2(
                Int(labelSize.width) + 50,
                // The default minimum picker height is 32 pixels
                max(Int(labelSize.height) + 12, 32)
            )
        } else if widget is ProgressRing {
            // ProgressRing appears to kind of grow to fill by default, but
            // SwiftCrossUI expects progress spinners to be fixed size, which
            // results in WinUI progress rings getting given astronomically
            // large fixed dimensions and causing crashes. To work around that,
            // we just override their 'natural size' to 32x32, which is based off
            // the defaults set in the following code from the WinUI repository:
            // https://github.com/marcelwgn/microsoft-ui-xaml/blob/ff21f9b212cea2191b959649e45e52486c8465aa/src/controls/dev/ProgressRing/ProgressRing.xaml#L12
            return SIMD2(32, 32)
        } else if let segmentedPicker = widget as? CustomSegmentedPicker {
            // A row of toggle buttons whose padding, like a button's, isn't
            // measured before the first render; add the segments up by hand.
            return segmentedPicker.naturalSize()
        } else if let datePicker = widget as? CustomDatePicker {
            // CustomDatePicker is a StackPanel whose individual subviews need to be manually sized
            // and then added together. Its naturalSize(in:) method dispatches back here once for
            // each of its children.
            return datePicker.naturalSize()
        } else if widget is WinUI.DatePicker {
            // Width is 296:
            // https://github.com/marcelwgn/microsoft-ui-xaml/blob/ff21f9b212cea2191b959649e45e52486c8465aa/src/controls/dev/CommonStyles/DatePicker_themeresources.xaml#L261
            // Height is experimentally 29 which I don't see anywhere in that file.
            return SIMD2(296, 29)
        }

        let oldWidth = widget.width
        let oldHeight = widget.height
        defer {
            widget.width = oldWidth
            widget.height = oldHeight
        }
        // The measurement below writes Width and Height directly. The `defer`
        // above puts them back, but only after WinUI has seen the intermediate
        // values, so forget the remembered size rather than assume the restore
        // leaves the element in the state the cache describes. Only the size is
        // touched here, so the text, font and colour entries stay valid.
        WidgetPropertyCache.shared.entry(for: widget).size = nil

        widget.width = .nan
        widget.height = .nan

        try! widget.measure(allocation)

        let computedSize = widget.desiredSize
        let adjustment = sizeCorrection(for: widget)

        let out = SIMD2(
            Int(computedSize.width) + adjustment.x,
            Int(computedSize.height) + adjustment.y
        )

        return out
    }

    /// Some elements don't get their default padding/border applied until
    /// they've been rendered. For such elements we have to compute our own
    /// adjustment factors based off values taken from WinUI's default theme.
    /// We can detect such elements because their padding property will be set
    /// to zero until first render (and atm WinUIBackend doesn't set this padding
    /// property itself so this is a safe detection method).
    @MainActor
    public static func sizeCorrection(for widget: Widget) -> SIMD2<Int> {
        let adjustment: SIMD2<Int>
        let noPadding = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        if let button = widget as? WinUI.Button, button.padding == noPadding {
            // WinUI buttons have padding, but the `padding` property returns
            // zero until the button has been rendered at least once. And even
            // if you manually set the button's padding, it gets ignored by
            // `measure()` before first render.
            //
            // The default in my Windows 11 VM seems to be 11 pixels either
            // side, 5 pixels above, and 6 pixels below. I found this hardcoded
            // in the WinUI repository, so hopefully it is the same everywhere...
            // Hardcoded here: https://github.com/microsoft/microsoft-ui-xaml/blob/650b2c1bad272393400403ca323b3cb8745f95d0/src/controls/dev/CommonStyles/Button_themeresources.xaml#L116
            //
            // We'll have to find a more dynamic way of correcting for WinUI's
            // measurement weirdness at some point (which will probably involve
            // figuring out how to access the `ButtonPadding` resource value
            // from Swift).
            //
            // Buttons seem to have 1 pixel of border on each side which also
            // gets ignored before first render.
            adjustment = SIMD2(
                11 + 11 + 2,
                5 + 6 + 2
            )
        } else if let toggleButton = widget as? WinUI.ToggleButton,
                  toggleButton.padding == noPadding
        {
            // See the above comment regarding Button. Very similar situation.
            adjustment = SIMD2(
                11 + 11 + 2,
                5 + 6 + 2
            )
        } else if let textField = widget as? TextBoxProtocol, textField.padding == noPadding {
            // The default padding applied to text boxes can be found here:
            // https://github.com/microsoft/microsoft-ui-xaml/blob/650b2c1bad272393400403ca323b3cb8745f95d0/src/controls/dev/CommonStyles/Common_themeresources.xaml#L12
            // However, text fields return 0x0 before rendering so our adjustment
            // just has to be the entire size of the text field. I've currently just
            // hardcoded a value obtained from one of my example apps.
            adjustment = SIMD2(64, 32)
        } else if widget is CalendarView {
            // I don't actually know why this is necessary, but without it the abbreviations for the
            // weekdays wrap, making it taller than it says it is. Value was derived by trial and
            // error.
            adjustment = SIMD2(20, 0)
        } else if widget is CalendarDatePicker {
            // Reading `DesiredSize` crosses the projection, and this is the
            // only correction that depends on it, so it is read here rather
            // than up front for every widget this function is called for.
            let computedSize = widget.desiredSize
            if computedSize.width == 0 && computedSize.height == 0 {
                // I can't find any source on what the size of CalendarDatePicker is, but it reports
                // 0x0 in at least some cases before initial render. In these cases, use a size
                // derived experimentally.
                adjustment = SIMD2(116, 32)
            } else {
                adjustment = .zero
            }
        } else {
            adjustment = .zero
        }
        return adjustment
    }

    public func setSize(of widget: Widget, to size: SIMD2<Int>) {
        // Writing Width or Height invalidates the element's measure and arrange
        // passes even when the value is unchanged, and a commit sizes every
        // widget in the window.
        let entry = WidgetPropertyCache.shared.entry(for: widget)
        guard entry.size != size else {
            return
        }
        entry.size = size
        widget.width = Double(size.x)
        widget.height = Double(size.y)
    }

    public func createTooltipContainer(wrapping child: Widget) -> Widget {
        // TODO(bbrk24): Look into removing the container, like on AppKit
        TooltipContainer(child: child)
    }

    public func updateTooltipContainer(_ widget: Widget, tooltip: String) {
        let widget = widget as! TooltipContainer
        // `HelpView` commits this unconditionally, so a window full of
        // `.help(_:)`-annotated views used to write one tooltip per view per
        // commit for text that essentially never changes.
        let entry = WidgetPropertyCache.shared.entry(for: widget)
        guard entry.tooltip != tooltip else {
            return
        }
        entry.tooltip = tooltip
        widget.tooltip.content = tooltip
    }

    public func size(
        of text: String,
        whenDisplayedIn widget: Widget,
        proposedWidth: Int?,
        proposedHeight: Int?,
        environment: EnvironmentValues
    ) -> SIMD2<Int> {
        // A WinUI measure pass is expensive and the layout system asks for the
        // same measurement repeatedly: up to three times within one update pass
        // per label, and again on every subsequent pass even when nothing about
        // the label changed. The key spells out every input this function reads
        // so that adding a new one is a compile-time decision.
        let cacheKey = TextMeasurementCache.Key(
            text: text,
            proposedWidth: proposedWidth,
            proposedHeight: proposedHeight,
            font: environment.resolvedFont,
            lineLimit: environment.lineLimitSettings
        )
        if let cached = TextMeasurementCache.measurement(for: cacheKey) {
            return cached
        }

        // Update the text view's environment and measure its desired line height
        updateTextView(measurementTextBlock, content: text, environment: environment)

        // Measure the text's size
        var size = Self.measure(
            measurementTextBlock,
            proposedWidth: proposedWidth,
            proposedHeight: proposedHeight
        )

        var usedHeight = size.y
        let lineHeight = environment.resolvedFont.lineHeight

        if let lineLimitSettings = environment.lineLimitSettings {
            let height = Int(
                Double(max(lineLimitSettings.limit, 1)) * lineHeight
            )

            if height < usedHeight || lineLimitSettings.reservesSpace {
                usedHeight = height
            }
        }

        // Make sure the text doesn't get shorter than a single line of text even if
        // it's empty.
        size.y = max(usedHeight, Int(lineHeight))
        TextMeasurementCache.record(size, for: cacheKey)
        return size
    }

    private static func measure(
        _ textBlock: TextBlock,
        proposedWidth: Int?,
        proposedHeight: Int?
    ) -> SIMD2<Int> {
        let allocation = WindowsFoundation.Size(
            width: proposedWidth.map(Float.init) ?? .infinity,
            height: proposedHeight.map(Float.init) ?? .infinity
        )
        try! textBlock.measure(allocation)

        let computedSize = textBlock.desiredSize
        return SIMD2(
            Int(computedSize.width),
            Int(computedSize.height)
        )
    }

    public func createTextView() -> Widget {
        let textBlock = TextBlock()
        textBlock.textWrapping = .wrap
        textBlock.textTrimming = .characterEllipsis
        textBlock.lineStackingStrategy = .blockLineHeight
        return textBlock
    }

    public func updateTextView(
        _ textView: Widget,
        content: String,
        environment: EnvironmentValues
    ) {
        let block = textView as! TextBlock

        // `Text` calls this once per pass per label. Each of the writes below is
        // a COM crossing and the foreground brush used to be a fresh WinRT
        // object every time, so a window of static labels spent thousands of COM
        // calls per frame rewriting the values it had just written.
        //
        // The entry is looked up once and handed to `apply(to:entry:)`, which
        // would otherwise look up the same widget a second time.
        let entry = WidgetPropertyCache.shared.entry(for: block)

        if entry.text != content {
            entry.text = content
            block.text = content
        }

        let isTextSelectionEnabled = environment.isTextSelectionEnabled
        if entry.isTextSelectionEnabled != isTextSelectionEnabled {
            entry.isTextSelectionEnabled = isTextSelectionEnabled
            block.isTextSelectionEnabled = isTextSelectionEnabled
        }

        // TODO: Font design handling (monospace vs normal)
        environment.apply(to: block, entry: entry)
    }

    public func createSimpleButton() -> Widget {
        let button = WinUI.Button()
        button.click.addHandler { [weak internalState] _, _ in
            guard let internalState else { return }
            internalState.buttonClickActions[ObjectIdentifier(button)]?()
        }
        return button
    }

    public func updateSimpleButton(
        _ button: Widget,
        label: String,
        environment: EnvironmentValues,
        action: @escaping () -> Void
    ) {
        let button = button as! WinUI.Button
        // Activating a `TextBlock` and reassigning `Button.content` rebuilds the
        // button's visual tree, and this runs on every update pass. Reuse the
        // label that's already there.
        let block = Self.label(of: button)
        if Self.setLabelText(label, of: block) {
            // A button is measured through its label, and the label's text is
            // written against the *label's* cache entry, so nothing else would
            // tell the button that its remembered natural size is stale.
            WidgetPropertyCache.shared.entry(for: button).naturalSize = nil
        }
        environment.apply(to: block)

        environment.apply(to: button)
        internalState.buttonClickActions[ObjectIdentifier(button)] = action
    }

    /// The text block used as a button's label, creating and installing one if
    /// the button doesn't have one yet.
    ///
    /// - Parameter button: The button.
    /// - Returns: The button's label element.
    @MainActor
    private static func label(of button: WinUI.Button) -> TextBlock {
        let entry = WidgetPropertyCache.shared.entry(for: button)
        if let existing = entry.buttonLabel {
            return existing
        }
        // Configured the same way as `createTextView`, so that a button's
        // label measures like any other text and the button's height agrees
        // with the padding computed in `borderedButtonPadding`.
        let block = TextBlock()
        block.textWrapping = .wrap
        block.textTrimming = .characterEllipsis
        block.lineStackingStrategy = .blockLineHeight
        entry.buttonLabel = block
        button.content = block
        return block
    }

    /// Writes a label's text if it isn't already what's wanted.
    ///
    /// - Parameters:
    ///   - text: The wanted text.
    ///   - block: The label element.
    /// - Returns: Whether the text had to be written.
    @MainActor
    @discardableResult
    private static func setLabelText(_ text: String, of block: TextBlock) -> Bool {
        let entry = WidgetPropertyCache.shared.entry(for: block)
        guard entry.text != text else {
            return false
        }
        entry.text = text
        block.text = text
        return true
    }

    public func createPopoverMenu() -> Menu {
        let flyout = MenuFlyout()
        flyout.placement = .bottomEdgeAlignedLeft
        return flyout
    }

    public func updatePopoverMenu(
        _ menu: Menu,
        content: ResolvedMenu,
        environment: EnvironmentValues
    ) {
        menu.items.clear()
        for item in content.items {
            menu.items.append(renderMenuItem(item, environment: environment))
        }
    }

    public func updateButton(
        _ button: Widget,
        label: String,
        menu: Menu,
        environment: EnvironmentValues
    ) {
        let button = button as! WinUI.Button
        // See `updateSimpleButton`, including why a new label forgets the
        // button's remembered natural size.
        let block = Self.label(of: button)
        if Self.setLabelText(label, of: block) {
            WidgetPropertyCache.shared.entry(for: button).naturalSize = nil
        }
        environment.apply(to: block)

        environment.apply(to: button)
        button.flyout = menu
    }

    public func createScrollContainer(for child: Widget) -> Widget {
        let scrollViewer = WinUI.ScrollViewer()
        scrollViewer.content = child
        child.horizontalAlignment = .left
        child.verticalAlignment = .top
        return scrollViewer
    }

    public func updateScrollContainer(
        _ scrollView: Widget,
        environment: EnvironmentValues,
        bounceHorizontally: Bool,
        bounceVertically: Bool,
        hasHorizontalScrollBar: Bool,
        hasVerticalScrollBar: Bool
    ) {
        let scrollViewer = scrollView as! WinUI.ScrollViewer

        scrollViewer.isHorizontalRailEnabled = hasHorizontalScrollBar
        scrollViewer.horizontalScrollMode = hasHorizontalScrollBar ? .enabled : .disabled
        scrollViewer.horizontalScrollBarVisibility = hasHorizontalScrollBar ? .visible : .hidden

        scrollViewer.isVerticalRailEnabled = hasVerticalScrollBar
        scrollViewer.verticalScrollMode = hasVerticalScrollBar ? .enabled : .disabled
        scrollViewer.verticalScrollBarVisibility = hasVerticalScrollBar ? .visible : .hidden
    }

    class CustomListView: WinUI.ListView {
        var selectionHandler: ((_ selectedIndex: Int) -> Void)?
        var currentItems: [WinUI.ListViewItem] = []
        var cachedSelectedItem: Int? = nil
    }

    public func createSelectableListView() -> Widget {
        let listView = CustomListView()
        listView.selectionMode = .single
        listView.selectionChanged.addHandler { [weak listView] _, _ in
            guard let listView else { return }
            guard listView.selectedRanges.count > 0 else {
                return
            }
            let selection = Int(listView.selectedRanges[0]!.firstIndex)
            guard selection != listView.cachedSelectedItem else {
                return
            }
            listView.selectionHandler?(selection)
        }
        return listView
    }

    public func updateSelectableListView(
        _ selectableListView: Widget,
        environment: EnvironmentValues
    ) {
        let listView = selectableListView as! CustomListView
        listView.isEnabled = environment.isEnabled
    }

    public func baseItemPadding(ofSelectableListView listView: Widget) -> EdgeInsets {
        EdgeInsets(
            top: 8,
            bottom: 8,
            leading: 16,
            trailing: 12
        )
    }

    public func minimumRowSize(ofSelectableListView listView: Widget) -> SIMD2<Int> {
        SIMD2(
            80,
            40
        )
    }

    public func setItems(
        ofSelectableListView listView: Widget,
        to items: [Widget],
        withRowHeights rowHeights: [Int]
    ) {
        let listView = listView as! CustomListView
        listView.itemContainerTransitions.clear()

        for listItem in listView.currentItems {
            listItem.content = nil
        }

        if items.count != listView.currentItems.count {
            listView.items.clear()
        }

        // We add the new items to the list but also to `listView.currentItems`.
        // This is so that we can retrieve the correct list item instances in
        // setSelectedItem. If we just use `listView.items` instead we get separate
        // incorrect instances for whatever reason (symptom is that it crashes stuff).
        var listItems: [WinUI.ListViewItem] = []
        for (index, item) in items.enumerated() {
            let listItem: WinUI.ListViewItem
            if items.count == listView.currentItems.count {
                listItem = listView.currentItems[index]
            } else {
                listItem = WinUI.ListViewItem()
            }
            listItem.horizontalContentAlignment = .left
            listItem.content = item
            listItem.padding = Thickness(left: 16, top: 8, right: 12, bottom: 8)
            if items.count != listView.currentItems.count {
                listItems.append(listItem)
                listView.items.append(listItem)
            }
        }

        if items.count != listView.currentItems.count {
            listView.currentItems = listItems
            listView.cachedSelectedItem = nil
        }
    }

    public func setSelectionHandler(
        forSelectableListView listView: Widget,
        to action: @escaping (_ selectedIndex: Int) -> Void
    ) {
        let listView = listView as! CustomListView
        listView.selectionHandler = action
    }

    public func setSelectedItem(
        ofSelectableListView listView: Widget,
        toItemAt index: Int?
    ) {
        let listView = listView as! CustomListView
        guard index != listView.cachedSelectedItem else {
            return
        }
        listView.cachedSelectedItem = index
        if let index {
            // We use `listView.currentItems` instead of `listView.items` because
            // `listView.items` isn't the original instances we added and WinUI
            // doesn't like that.
            listView.selectedItem = listView.currentItems[index]
        } else {
            listView.selectedItem = nil
        }
    }

    public func createSlider() -> Widget {
        let slider = Slider()
        slider.valueChanged.addHandler { [weak internalState, weak slider] _, event in
            guard
                let internalState,
                let slider
            else { return }

            internalState.sliderChangeActions[ObjectIdentifier(slider)]?(
                Double(event?.newValue ?? 0)
            )
        }
        slider.stepFrequency = 0.01
        return slider
    }

    public func updateSlider(
        _ slider: Widget,
        minimum: Double,
        maximum: Double,
        decimalPlaces _: Int,
        environment: EnvironmentValues,
        onChange: @escaping (Double) -> Void
    ) {
        let slider = slider as! WinUI.Slider
        slider.minimum = minimum
        slider.maximum = maximum
        environment.apply(to: slider)
        internalState.sliderChangeActions[ObjectIdentifier(slider)] = onChange
    }

    public func setValue(ofSlider slider: Widget, to value: Double) {
        let slider = slider as! WinUI.Slider
        slider.value = value
    }

    public func createPicker(style: BackendPickerStyle) -> Widget {
        switch style {
            case .menu:
                let picker = CustomComboBox()
                picker.selectionChanged.addHandler { [weak picker] _, _ in
                    guard let picker, !picker.isApplyingModelUpdate else { return }
                    picker.onChangeSelection?(
                        picker.selectedIndex < 0 ? nil : Int(picker.selectedIndex)
                    )
                }

                // When hovering over a picker, its foreground changes to black,
                // when the pointer exits the picker the foreground color remains
                // black instead of returning to its regular value. I've tried various
                // variations of the solution below and it seems like the only thing
                // that works is fully recreating the brush.
                picker.pointerExited.addHandler { [weak picker] _, _ in
                    guard let picker else { return }
                    let brush = SolidColorBrush()
                    brush.color = picker.actualForegroundColor
                    picker.foreground = brush
                }

                return picker
            case .radioGroup:
                let picker = CustomRadioButtons()
                picker.loaded.addHandler { [weak picker] _, _ in
                    picker?.requestInitialSizeAfterLoading()
                }

                picker.selectionChanged.addHandler { [weak picker] _, _ in
                    guard let picker, !picker.isApplyingModelUpdate else { return }
                    // RadioButtons realizes a pre-load SelectedIndex only when
                    // its repeater loads, after our synchronous update scope.
                    // Compare the current property, not a queued event payload.
                    let index = picker.selectedIndex
                    guard picker.selectionTracker.shouldForwardNativeSelection(index) else {
                        return
                    }
                    // The tracker advances before calling application code,
                    // which may synchronously write a different model index.
                    picker.onChangeSelection?(index < 0 ? nil : Int(index))
                }

                return picker
            case .segmented:
                return CustomSegmentedPicker()
            default:
                // A style this backend can't draw is still a picker; the
                // menu picker is the closest thing to every other style.
                logger.warnOnce(
                    "WinUIBackend can't draw picker style \(style); drawing a menu picker instead"
                )
                return createPicker(style: .menu)
        }
    }

    public func updatePicker(
        _ picker: Widget,
        options: [String],
        environment: EnvironmentValues,
        onChange: @escaping (Int?) -> Void
    ) {
        if let picker = picker as? CustomComboBox {
            let wasApplying = picker.isApplyingModelUpdate
            picker.isApplyingModelUpdate = true
            defer { picker.isApplyingModelUpdate = wasApplying }
            picker.onChangeSelection = onChange
            // The shared picker calls this for changed options or appearance.
            // Clear the same-pass measurement before the options early return: font
            // changes and an empty list can change size with no item writes.
            WidgetPropertyCache.shared.entry(for: picker).naturalSize = nil
            environment.apply(to: picker)
            picker.actualForegroundColor =
                environment.suggestedForegroundColor.resolve(in: environment).uwpColor

            let items = picker.items!
            let previousCount = items.count
            // The backend owns the option strings. Compare the last applied
            // values instead of unboxing every native item during layout.
            guard picker.options != options || previousCount != options.count else {
                return
            }

            // Remove from the end: removing an earlier element shifts all
            // later indices and makes an ascending removal range invalid.
            if previousCount > options.count {
                for index in (options.count..<previousCount).reversed() {
                    items.removeAt(UInt32(index))
                }
            }
            for index in 0..<min(previousCount, options.count) {
                if !picker.options.indices.contains(index)
                    || picker.options[index] != options[index] {
                    items.setAt(UInt32(index), options[index])
                }
            }
            if previousCount < options.count {
                for index in previousCount..<options.count {
                    items.append(options[index])
                }
            }
            picker.options = options
        } else if let picker = picker as? CustomRadioButtons {
            let wasApplying = picker.isApplyingModelUpdate
            picker.isApplyingModelUpdate = true
            defer { picker.isApplyingModelUpdate = wasApplying }
            picker.onInitialSizeReady = environment.onResize
            WidgetPropertyCache.shared.entry(for: picker).naturalSize = nil
            environment.apply(to: picker)
            for i in 0..<min(picker.items.count, options.count) {
                let block = picker.items[i] as! TextBlock
                block.text = options[i]
                environment.apply(to: block)
            }

            if picker.items.count > options.count {
                for i in (options.count..<picker.items.count).reversed() {
                    _ = picker.items.remove(at: i)
                }
            } else {
                for option in options[picker.items.count...] {
                    let block = TextBlock()
                    block.text = option
                    environment.apply(to: block)
                    picker.items.append(block)
                }
            }

            picker.onChangeSelection = onChange
        } else if let picker = picker as? CustomSegmentedPicker {
            picker.onChangeSelection = onChange
            picker.setOptions(options, environment: environment)
            // A segmented picker adds its segments up by hand, so its natural
            // size follows its options. Cleared unconditionally because
            // `setOptions` decides for itself whether anything changed.
            WidgetPropertyCache.shared.entry(for: picker).naturalSize = nil
        }
    }

    public func setSelectedOption(ofPicker picker: Widget, to selectedOption: Int?) {
        // Committed on every layout computation. Writing the index is a COM
        // call that also invalidates the element's measure and arrange passes,
        // and it almost always writes the index the element already holds, so
        // the one read below replaces a write in the common case.
        if let picker = picker as? CustomComboBox {
            let wasApplying = picker.isApplyingModelUpdate
            picker.isApplyingModelUpdate = true
            defer { picker.isApplyingModelUpdate = wasApplying }
            let index = Int32(selectedOption ?? -1)
            guard picker.selectedIndex != index else {
                return
            }
            picker.selectedIndex = index
            // A combo box is measured from its selected option.
            WidgetPropertyCache.shared.entry(for: picker).naturalSize = nil
        } else if let picker = picker as? CustomRadioButtons {
            let wasApplying = picker.isApplyingModelUpdate
            picker.isApplyingModelUpdate = true
            defer { picker.isApplyingModelUpdate = wasApplying }
            let index = Int32(selectedOption ?? -1)
            // A matching native property may still have an unrealized selection
            // notification pending. Acknowledge even when no write is needed.
            picker.selectionTracker.recordProgrammaticSelection(index)
            guard picker.selectedIndex != index else {
                return
            }
            picker.selectedIndex = index
            WidgetPropertyCache.shared.entry(for: picker).naturalSize = nil
        } else if let picker = picker as? CustomSegmentedPicker {
            picker.setSelectedIndex(selectedOption)
            WidgetPropertyCache.shared.entry(for: picker).naturalSize = nil
        }
    }

    public func createTextEditor() -> Widget {
        let textEditor = TextBox()
        textEditor.textChanged.addHandler { [weak internalState, weak textEditor] _, _ in
            guard
                let internalState,
                let textEditor
            else { return }
            guard !textEditor.shouldBlockNextChangedSignal else {
                textEditor.shouldBlockNextChangedSignal = false
                return
            }
            // Reuse this storage because it's the same widget type as a text field
            internalState.textFieldChangeActions[ObjectIdentifier(textEditor)]?(textEditor.text)
        }
        textEditor.acceptsReturn = true
        textEditor.textWrapping = .wrap

        // Remove padding
        textEditor.padding = Thickness(left: 0, top: 0, right: 0, bottom: 0)

        // Remove background color
        let brush = SolidColorBrush()
        brush.color = UWP.Color(a: 0, r: 0, g: 0, b: 0)
        textEditor.background = brush

        // Remove hover and focus effects
        _ = textEditor.resources.insert("TextControlBackgroundPointerOver", brush)
        _ = textEditor.resources.insert("TextControlBackgroundFocused", brush)
        _ = textEditor.resources.insert("TextControlBorderBrushFocused", brush)

        return textEditor
    }

    public func updateTextEditor(
        _ textEditor: Widget,
        environment: EnvironmentValues,
        onChange: @escaping (String) -> Void
    ) {
        let textEditor = (textEditor as! TextBox)
        internalState.textFieldChangeActions[ObjectIdentifier(textEditor)] = onChange
        environment.apply(to: textEditor)

        updateInputScope(of: textEditor, textContentType: environment.textContentType)
    }

    public func setContent(ofTextEditor textEditor: Widget, to content: String) {
        let textEditor = textEditor as! TextBox
        textEditor.shouldBlockNextChangedSignal = true
        textEditor.text = content
    }

    public func getContent(ofTextEditor textEditor: Widget) -> String {
        (textEditor as! TextBox).text
    }

    func updateInputScope(
        of textField: some TextBoxProtocol,
        textContentType: TextContentType
    ) {

        let inputScope: InputScopeNameValue? =
            switch textField {
                case is TextBox:
                    switch textContentType {
                        case .decimal(_): .number
                        case .digits(_): .digits
                        case .emailAddress: .emailSmtpAddress
                        case .name: .personalFullName
                        case .phoneNumber: .telephoneNumber
                        case .text: .default
                        case .url: .url
                    }
                case is PasswordBox:
                    switch textContentType {
                        case .digits(_): .numericPin
                        case .text: .password
                        default: nil
                    }
                default: nil
            }
        guard let inputScope else { return }

        let inputScopeName = InputScopeName(inputScope)

        if let inputScope = textField.inputScope,
           inputScope.names.count == 1
        {
            inputScope.names[0] = inputScopeName
        } else {
            let inputScope = InputScope()
            inputScope.names.append(inputScopeName)
            textField.inputScope = inputScope
        }
    }

    public func createImageView() -> Widget {
        let imageView = WinUI.Image()
        // SwiftCrossUI has already decided the size the image should be
        // displayed at, so fill it exactly rather than letting WinUI fit the
        // bitmap's aspect ratio inside it a second time.
        imageView.stretch = .fill
        return imageView
    }

    public func updateImageView(
        _ imageView: Widget,
        rgbaData: [UInt8],
        width: Int,
        height: Int,
        targetWidth: Int,
        targetHeight: Int,
        dataHasChanged: Bool,
        environment: EnvironmentValues
    ) {
        let imageView = imageView as! WinUI.Image

        // Resizing is handled entirely by `stretch`, so unless the pixels
        // changed (or there's no bitmap yet) there's nothing to redraw. A
        // canvas that replaces a large frame every update reuses the same
        // `WriteableBitmap` for as long as its dimensions stay the same.
        let lookupTiming = WinUITimingDiagnostics.begin()
        let (bitmap, bitmapIsNew) = ImageBitmapRegistry.shared.bitmap(
            for: imageView,
            width: width,
            height: height
        )
        WinUITimingDiagnostics.end(.imageLookup, lookupTiming)
        WinUITimingDiagnostics.count(bitmapIsNew ? "image.recreated" : "image.reused")
        guard dataHasChanged || bitmapIsNew else {
            WinUITimingDiagnostics.count("image.unchanged")
            return
        }

        let uploadTiming = WinUITimingDiagnostics.begin(cpu: true)
        defer { WinUITimingDiagnostics.end(.imageUpload, uploadTiming) }
        let bufferTiming = WinUITimingDiagnostics.begin()
        guard let pixelBuffer = bitmap.pixelBuffer, let buffer = try? pixelBuffer.buffer else {
            WinUITimingDiagnostics.end(.imageBuffer, bufferTiming)
            WinUITimingDiagnostics.count("image.bufferUnavailable")
            logger.warning("failed to access the pixel buffer of a WriteableBitmap")
            return
        }
        WinUITimingDiagnostics.end(.imageBuffer, bufferTiming)
        // Convert directly into WinRT's buffer. Copying the frame first and
        // then swapping channels in-place touches every pixel twice at each
        // frame publication, on the UI thread.
        let copyTiming = WinUITimingDiagnostics.begin()
        let byteCount = rgbaData.withUnsafeBytes { source in
            RGBAImageBuffer.copyToBGRA(
                source,
                into: UnsafeMutableRawBufferPointer(
                    start: buffer, count: Int(pixelBuffer.length)))
        }
        WinUITimingDiagnostics.end(.imageCopy, copyTiming)
        WinUITimingDiagnostics.count("image.uploadBytes", UInt64(byteCount))
        BackendCallStatistics.record("image.upload")
        BackendCallStatistics.record("image.uploadBytes", byteCount)

        // Tells WinUI that the pixel buffer changed so that it redraws.
        let invalidateTiming = WinUITimingDiagnostics.begin()
        try? bitmap.invalidate()
        WinUITimingDiagnostics.end(.imageInvalidate, invalidateTiming)

        if bitmapIsNew {
            let sourceTiming = WinUITimingDiagnostics.begin()
            imageView.source = bitmap
            WinUITimingDiagnostics.end(.imageSource, sourceTiming)
        }
    }

    public func createSplitView(leadingChild: Widget, trailingChild: Widget) -> Widget {
        let splitView = CustomSplitView()
        splitView.pane = leadingChild
        splitView.content = trailingChild
        splitView.isPaneOpen = true
        splitView.displayMode = .inline
        return splitView
    }

    public func setResizeHandler(
        ofSplitView splitView: Widget,
        to action: @escaping () -> Void
    ) {
        // WinUI's SplitView currently doesn't support resizing, but we still
        // store the sidebar resize handler because we programmatically resize
        // the sidebar and call the handler whenever the minimum sidebar width
        // changes.
        let splitView = splitView as! CustomSplitView
        splitView.sidebarResizeHandler = action
    }

    public func sidebarWidth(ofSplitView splitView: Widget) -> Int {
        let splitView = splitView as! CustomSplitView
        return Int(splitView.openPaneLength.rounded(.towardZero))
    }

    public func setSidebarWidthBounds(
        ofSplitView splitView: Widget,
        minimum minimumWidth: Int,
        maximum maximumWidth: Int
    ) {
        let splitView = splitView as! CustomSplitView
        let newWidth = Double(max(minimumWidth, 10))
        if newWidth != splitView.openPaneLength {
            splitView.openPaneLength = newWidth
            splitView.sidebarResizeHandler?()
        }
    }

    public func createToggle() -> Widget {
        let toggle = ToggleButton()
        toggle.click.addHandler { [weak internalState] _, _ in
            guard let internalState else { return }
            internalState.toggleClickActions[ObjectIdentifier(toggle)]?(toggle.isChecked ?? false)
        }
        return toggle
    }

    public func updateToggle(
        _ toggle: Widget,
        label: String,
        environment: EnvironmentValues,
        onChange: @escaping (Bool) -> Void
    ) {
        let toggle = toggle as! ToggleButton
        let block = TextBlock()
        block.text = label
        toggle.content = block

        // Use opposite color scheme for label if checked to match WinUI's default
        // behaviour.
        environment.with(
            \.colorScheme,
            toggle.isChecked == true
                ? environment.colorScheme.opposite
                : environment.colorScheme
        ).apply(to: block)

        environment.apply(to: toggle)

        internalState.toggleClickActions[ObjectIdentifier(toggle)] = { state in
            onChange(state)

            // Update label color scheme just in case the update doesn't get
            // propagated back to us (e.g. if the user passes in a dummy binding)
            environment.with(
                \.colorScheme,
                state ? environment.colorScheme.opposite : environment.colorScheme
            ).apply(to: block)
        }
    }

    public func setState(ofToggle toggle: Widget, to state: Bool) {
        let toggle = toggle as! ToggleButton
        toggle.isChecked = state
    }

    public func createSwitch() -> Widget {
        let toggleSwitch = ToggleSwitch()
        toggleSwitch.offContent = ""
        toggleSwitch.onContent = ""
        toggleSwitch.padding = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        toggleSwitch.toggled.addHandler { [weak internalState] _, _ in
            guard let internalState else { return }
            internalState.switchClickActions[ObjectIdentifier(toggleSwitch)]?(toggleSwitch.isOn)
        }
        return toggleSwitch
    }

    public func updateSwitch(
        _ toggleSwitch: Widget,
        environment: EnvironmentValues,
        onChange: @escaping (Bool) -> Void
    ) {
        let toggleSwitch = toggleSwitch as! ToggleSwitch
        internalState.switchClickActions[ObjectIdentifier(toggleSwitch)] = onChange
        environment.apply(to: toggleSwitch)
    }

    public func setState(ofSwitch switchWidget: Widget, to state: Bool) {
        let switchWidget = switchWidget as! ToggleSwitch
        if switchWidget.isOn != state {
            switchWidget.isOn = state
        }
    }

    class CustomCheckBox: WinUI.CheckBox {
        var onToggle: ((Bool) -> Void)?

        func handleToggle() {
            if isChecked == nil {
                logger.warning("checkbox in limbo")
            }
            onToggle?(isChecked ?? false)
        }
    }

    public func createCheckbox() -> Widget {
        let checkbox = CustomCheckBox()

        // This natural size is hardcoded, but it's the actual visible size of
        // the checkbox. WinUI puts a bunch of extra space around checkboxes
        // by default which messes things up.
        let naturalSize = naturalSize(of: checkbox)
        checkbox.minWidth = Double(naturalSize.x)
        checkbox.minHeight = Double(naturalSize.y)

        checkbox.padding = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        checkbox.checked.addHandler { [weak checkbox] _, _ in
            checkbox?.handleToggle()
        }
        checkbox.unchecked.addHandler { [weak checkbox] _, _ in
            checkbox?.handleToggle()
        }
        return checkbox
    }

    public func updateCheckbox(
        _ checkbox: Widget,
        environment: EnvironmentValues,
        onChange: @escaping (Bool) -> Void
    ) {
        let checkbox = checkbox as! CustomCheckBox
        checkbox.padding = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        checkbox.onToggle = onChange
        environment.apply(to: checkbox)
    }

    public func setState(ofCheckbox checkboxWidget: Widget, to state: Bool) {
        let checkboxWidget = checkboxWidget as! CustomCheckBox
        if checkboxWidget.isChecked != state {
            checkboxWidget.isChecked = state
        }
    }

    public func showOpenDialog(
        fileDialogOptions: FileDialogOptions,
        openDialogOptions: OpenDialogOptions,
        window: Window?,
        resultHandler handleResult: @escaping (DialogResult<[URL]>) -> Void
    ) {
        guard let hwnd = (window ?? windows.first)?.getHWND() else {
            logger.warning("WinUI can't show a file dialog without a window")
            handleResult(.cancelled)
            return
        }

        // WinRT's pickers can't show files and folders in one dialog, so a
        // dialog that only accepts folders uses the folder picker and one that
        // accepts files (or both) uses the file picker.
        if openDialogOptions.allowSelectingDirectories && !openDialogOptions.allowSelectingFiles {
            let picker = FolderPicker()
            do {
                let interface: SwiftIInitializeWithWindow = try picker.thisPtr.QueryInterface()
                try interface.initialize(with: hwnd)
                // The folder picker requires at least one filter entry.
                picker.fileTypeFilter.append("*")
                if !fileDialogOptions.defaultButtonLabel.isEmpty {
                    picker.commitButtonText = fileDialogOptions.defaultButtonLabel
                }

                guard let promise = try picker.pickSingleFolderAsync() else {
                    handleResult(.cancelled)
                    return
                }
                promise.completed = { operation, status in
                    let result: DialogResult<[URL]> = Self.handleAsyncOperationCompletion(
                        operation,
                        status
                    ) { result in
                        let folder = URL(fileURLWithPath: result.path, isDirectory: true)
                        return .success([folder])
                    } onFailure: {
                        return .cancelled
                    }
                    handleResult(result)
                }
            } catch {
                logger.error("failed to show folder picker", metadata: ["error": "\(error)"])
                handleResult(.cancelled)
            }
            return
        }

        let picker = FileOpenPicker()
        do {
            let interface: SwiftIInitializeWithWindow = try picker.thisPtr.QueryInterface()
            try interface.initialize(with: hwnd)

            for filter in Self.fileTypeFilters(for: fileDialogOptions) {
                picker.fileTypeFilter.append(filter)
            }
            if !fileDialogOptions.defaultButtonLabel.isEmpty {
                picker.commitButtonText = fileDialogOptions.defaultButtonLabel
            }

            if openDialogOptions.allowMultipleSelections {
                guard let promise = try picker.pickMultipleFilesAsync() else {
                    handleResult(.cancelled)
                    return
                }
                promise.completed = { operation, status in
                    let result: DialogResult<[URL]> = Self.handleAsyncOperationCompletion(
                        operation,
                        status
                    ) { result in
                        let files = Array(result).compactMap { $0 }
                            .map(\.path)
                            .map(URL.init(fileURLWithPath:))
                        return .success(files)
                    } onFailure: {
                        return .cancelled
                    }
                    handleResult(result)
                }
            } else {
                guard let promise = try picker.pickSingleFileAsync() else {
                    handleResult(.cancelled)
                    return
                }
                promise.completed = { operation, status in
                    let result: DialogResult<[URL]> = Self.handleAsyncOperationCompletion(
                        operation,
                        status
                    ) { result in
                        let file = URL(fileURLWithPath: result.path)
                        return .success([file])
                    } onFailure: {
                        return .cancelled
                    }
                    handleResult(result)
                }
            }
        } catch {
            logger.error("failed to show file picker", metadata: ["error": "\(error)"])
            handleResult(.cancelled)
        }
    }

    public func showSaveDialog(
        fileDialogOptions: FileDialogOptions,
        saveDialogOptions: SaveDialogOptions,
        window: Window?,
        resultHandler handleResult: @escaping (DialogResult<URL>) -> Void
    ) {
        guard let hwnd = (window ?? windows.first)?.getHWND() else {
            logger.warning("WinUI can't show a file dialog without a window")
            handleResult(.cancelled)
            return
        }

        let picker = FileSavePicker()
        do {
            let interface: SwiftIInitializeWithWindow = try picker.thisPtr.QueryInterface()
            try interface.initialize(with: hwnd)

            // The save picker requires at least one file type choice. "." is
            // the documented way of allowing any extension.
            var hasChoices = false
            for contentType in fileDialogOptions.allowedContentTypes {
                let extensions = contentType.fileExtensions.map(Self.pickerExtension)
                guard !extensions.isEmpty else {
                    continue
                }
                _ = picker.fileTypeChoices.insert(contentType.name, extensions.toVector())
                hasChoices = true
            }
            if !hasChoices || fileDialogOptions.allowOtherContentTypes {
                _ = picker.fileTypeChoices.insert("All files", ["."].toVector())
            }

            if let defaultFileName = saveDialogOptions.defaultFileName {
                picker.suggestedFileName = defaultFileName
            }
            if !fileDialogOptions.defaultButtonLabel.isEmpty {
                picker.commitButtonText = fileDialogOptions.defaultButtonLabel
            }

            guard let promise = try picker.pickSaveFileAsync() else {
                handleResult(.cancelled)
                return
            }
            promise.completed = { operation, status in
                let result: DialogResult<URL> = Self.handleAsyncOperationCompletion(
                    operation,
                    status
                ) { result in
                    let file = URL(fileURLWithPath: result.path)
                    return .success(file)
                } onFailure: {
                    return .cancelled
                }
                handleResult(result)
            }
        } catch {
            logger.error("failed to show save picker", metadata: ["error": "\(error)"])
            handleResult(.cancelled)
        }
    }

    /// The file type filters for an open dialog.
    ///
    /// WinRT spells extensions with a leading dot and requires at least one
    /// entry, with `"*"` meaning any file.
    ///
    /// - Parameter options: The dialog's options.
    /// - Returns: The filters to install.
    private static func fileTypeFilters(for options: FileDialogOptions) -> [String] {
        var filters: [String] = []
        for contentType in options.allowedContentTypes {
            for fileExtension in contentType.fileExtensions {
                let filter = pickerExtension(fileExtension)
                if !filters.contains(filter) {
                    filters.append(filter)
                }
            }
        }
        if filters.isEmpty || options.allowOtherContentTypes {
            filters.append("*")
        }
        return filters
    }

    /// Spells a file extension the way WinRT's pickers expect it.
    ///
    /// - Parameter fileExtension: The extension, with or without a leading dot.
    /// - Returns: The extension with a leading dot.
    private static func pickerExtension(_ fileExtension: String) -> String {
        fileExtension.hasPrefix(".") ? fileExtension : "." + fileExtension
    }

    /// A helper method that abstracts out the common failure case handling code
    /// from all of our file dialog related async operation completion handlers.
    private static func handleAsyncOperationCompletion<T, R>(
        _ operation: AnyIAsyncOperation<T?>?,
        _ status: AsyncStatus,
        onSuccess handleSuccess: (T) -> R,
        onFailure handleFailure: () -> R
    ) -> R {
        guard let operation else {
            logger.warning(
                "operation parameter unexpectedly nil",
                metadata: [
                    "function": #function
                ]
            )
            return handleFailure()
        }

        guard
            status == .completed,
            let result = try? operation.getResults()
        else {
            if status == .error {
                logger.error(
                    "\(WindowsFoundation.Error(hr: operation.errorCode))",
                    metadata: [
                        "function": #function
                    ]
                )

                if UInt32(bitPattern: operation.errorCode) == 0x80004005 {
                    // https://github.com/microsoft/WindowsAppSDK/issues/4625#issuecomment-2281358235
                    logger.warning(
                        """
                        This may indicate that you're attempting to launch a \
                        file picker from an app launched as administrator
                        """
                    )
                }
            }
            return handleFailure()
        }

        return handleSuccess(result)
    }

    public func createProgressSpinner() -> Widget {
        let spinner = ProgressRing()
        spinner.isIndeterminate = true
        return spinner
    }

    public func createProgressBar() -> Widget {
        let progressBar = ProgressBar()
        progressBar.maximum = 10_000
        return progressBar
    }

    public func updateProgressBar(
        _ widget: Widget,
        progressFraction: Double?,
        environment: EnvironmentValues
    ) {
        let progressBar = widget as! ProgressBar
        if let progressFraction {
            progressBar.isIndeterminate = false
            progressBar.value = progressBar.maximum * progressFraction
        } else {
            progressBar.isIndeterminate = true
        }
    }

    public func createPathWidget() -> Widget {
        WinUI.Path()
    }

    public func createPath() -> Path {
        GeometryGroupHolder()
    }

    public func updatePath(
        _ path: Path,
        _ source: SwiftCrossUI.Path,
        bounds: SwiftCrossUI.Path.Rect,
        pointsChanged: Bool,
        environment: EnvironmentValues
    ) {
        path.strokeStyle = source.strokeStyle

        if pointsChanged {
            updateGeometry(of: path, to: source.actions)
        }

        // Writing the fill rule is a COM call, and it essentially never changes.
        if path.appliedFillRule != source.fillRule {
            path.appliedFillRule = source.fillRule
            path.group.fillRule =
                switch source.fillRule {
                    case .evenOdd:
                        .evenOdd
                    case .winding:
                        .nonzero
                }
        }
    }

    /// Brings a path's WinRT geometry up to date with a new set of actions.
    ///
    /// Rebuilding the geometry means activating a WinRT object per segment and
    /// appending it, then walking the collection again to drop empty figures —
    /// every one of those a COM crossing. An overlay that animates redraws the
    /// *same shape with moved points* on every pointer sample, so the objects
    /// already there are the right ones; only their coordinates are stale.
    ///
    /// This updates them in place when the new actions have the same kinds in
    /// the same order as the ones the tree was built from, which is what makes
    /// the tree's shape identical, and rebuilds otherwise.
    private func updateGeometry(
        of path: GeometryGroupHolder,
        to actions: [SwiftCrossUI.Path.Action]
    ) {
        // An identical path is a no-op. `Canvas` already diffs its actions
        // before calling, but `Shape` and symbol rendering don't.
        if path.appliedActions == actions, !path.appliedActions.isEmpty {
            return
        }

        if reconcileGeometry(of: path, to: actions) {
            path.appliedActions = actions
            return
        }

        path.group.children.clear()
        let recorder = PathReconciliation.canReconcile(actions)
            ? PathTargetRecorder()
            : nil
        applyActions(actions, to: path.group.children, recorder: recorder)
        path.appliedActions = actions
        path.actionTargets = recorder?.targets ?? []
    }

    /// Updates a path's existing WinRT objects in place.
    ///
    /// - Returns: Whether it could. `false` means the tree has to be rebuilt.
    private func reconcileGeometry(
        of path: GeometryGroupHolder,
        to actions: [SwiftCrossUI.Path.Action]
    ) -> Bool {
        let previous = path.appliedActions
        guard
            !actions.isEmpty,
            path.actionTargets.count == actions.count,
            previous.count == actions.count,
            PathReconciliation.haveSameShape(previous, actions)
        else {
            return false
        }

        // Mirrors the point bookkeeping in `applyActions`, because a figure's
        // start point comes from wherever the previous action left off: a
        // segment whose own coordinates are unchanged may still need its
        // figure's start point rewritten.
        var previousLastPoint = SIMD2<Double>(0.0, 0.0)
        var newLastPoint = SIMD2<Double>(0.0, 0.0)

        for index in actions.indices {
            let old = previous[index]
            let new = actions[index]
            let incomingPointMoved = previousLastPoint != newLastPoint

            guard
                PathGeometryReconciler.apply(
                    new,
                    changed: old != new,
                    incomingPoint: Point(
                        x: Float(newLastPoint.x),
                        y: Float(newLastPoint.y)
                    ),
                    incomingPointMoved: incomingPointMoved,
                    to: path.actionTargets[index]
                )
            else {
                return false
            }

            previousLastPoint = PathReconciliation.endPoint(
                after: old,
                current: previousLastPoint
            )
            newLastPoint = PathReconciliation.endPoint(
                after: new,
                current: newLastPoint
            )
        }

        return true
    }

    /// - Returns: The figure to append segments to, and whether it had to be
    ///   created — in which case its start point came from `lastPoint`, which
    ///   an in-place update has to rewrite when that point moves.
    func requirePathFigure(
        _ collection: WinUI.GeometryCollection,
        lastPoint: Point
    ) -> (figure: PathFigure, wasCreated: Bool) {
        var pathGeometry: PathGeometry
        if collection.size > 0,
           let castedLast = collection.getAt(collection.size - 1) as? PathGeometry
        {
            pathGeometry = castedLast
        } else {
            pathGeometry = PathGeometry()
            collection.append(pathGeometry)
        }

        var figure: PathFigure
        if pathGeometry.figures.size > 0 {
            // Note: the if check and force-unwrap is necessary. You can't do an `if let`
            // here because PathFigureCollection uses unsigned integers for its indices so
            // `size - 1` would underflow (causing a fatalError) if it's empty.
            figure = pathGeometry.figures.getAt(pathGeometry.figures.size - 1)!
            return (figure, false)
        } else {
            figure = PathFigure()
            figure.startPoint = lastPoint
            pathGeometry.figures.append(figure)
            return (figure, true)
        }
    }

    /// - Parameter recorder: Collects the object each action wrote into, so
    ///   that a later upload of the same shape can update them in place. Pass
    ///   `nil` when the shape isn't one ``PathGeometryReconciler`` handles.
    func applyActions(
        _ actions: [SwiftCrossUI.Path.Action],
        to geometry: WinUI.GeometryCollection,
        recorder: PathTargetRecorder? = nil
    ) {
        var lastPoint = Point(x: 0.0, y: 0.0)

        for action in actions {
            switch action {
                case .moveTo(let point):
                    lastPoint = Point(x: Float(point.x), y: Float(point.y))

                    if geometry.size > 0,
                       let pathGeometry = geometry.getAt(geometry.size - 1) as? PathGeometry,
                       pathGeometry.figures.size > 0
                    {
                        let figure = pathGeometry.figures.getAt(pathGeometry.figures.size - 1)!
                        if figure.segments.size > 0 {
                            let newFigure = PathFigure()
                            newFigure.startPoint = lastPoint
                            pathGeometry.figures.append(newFigure)
                            recorder?.record(.figureStart(newFigure))
                        } else {
                            figure.startPoint = lastPoint
                            recorder?.record(.figureStart(figure))
                        }
                    } else {
                        // Nothing to move yet; the point is carried into the
                        // figure that the next drawing action creates.
                        recorder?.record(.none)
                    }
                case .lineTo(let point):
                    let wfPoint = Point(x: Float(point.x), y: Float(point.y))
                    defer { lastPoint = wfPoint }

                    let (figure, startedFigure) = requirePathFigure(
                        geometry,
                        lastPoint: lastPoint
                    )

                    let segment = LineSegment()
                    segment.point = wfPoint
                    figure.segments.append(segment)
                    recorder?.record(
                        .line(segment, startedFigure: startedFigure ? figure : nil)
                    )
                case .quadCurve(let control, let end):
                    let wfControl = Point(x: Float(control.x), y: Float(control.y))
                    let wfEnd = Point(x: Float(end.x), y: Float(end.y))
                    defer { lastPoint = wfEnd }

                    let (figure, startedFigure) = requirePathFigure(
                        geometry,
                        lastPoint: lastPoint
                    )

                    let segment = QuadraticBezierSegment()
                    segment.point1 = wfControl
                    segment.point2 = wfEnd
                    figure.segments.append(segment)
                    recorder?.record(
                        .quad(segment, startedFigure: startedFigure ? figure : nil)
                    )
                case .cubicCurve(let control1, let control2, let end):
                    let wfControl1 = Point(x: Float(control1.x), y: Float(control1.y))
                    let wfControl2 = Point(x: Float(control2.x), y: Float(control2.y))
                    let wfEnd = Point(x: Float(end.x), y: Float(end.y))
                    defer { lastPoint = wfEnd }

                    let (figure, startedFigure) = requirePathFigure(
                        geometry,
                        lastPoint: lastPoint
                    )

                    let segment = BezierSegment()
                    segment.point1 = wfControl1
                    segment.point2 = wfControl2
                    segment.point3 = wfEnd
                    figure.segments.append(segment)
                    recorder?.record(
                        .cubic(segment, startedFigure: startedFigure ? figure : nil)
                    )
                case .rectangle(let rect):
                    let rectGeo = RectangleGeometry()
                    rectGeo.rect = Rect(
                        x: Float(rect.x),
                        y: Float(rect.y),
                        width: Float(rect.width),
                        height: Float(rect.height)
                    )
                    geometry.append(rectGeo)
                    recorder?.record(.rectangle(rectGeo))
                case .circle(let center, let radius):
                    let ellipse = EllipseGeometry()
                    ellipse.radiusX = radius
                    ellipse.radiusY = radius
                    ellipse.center = Point(x: Float(center.x), y: Float(center.y))
                    geometry.append(ellipse)
                    recorder?.record(.ellipse(ellipse))
                case .arc(
                let center,
                let radius,
                let startAngle,
                let endAngle,
                let clockwise
            ):
                    let startPoint = Point(
                        x: Float(center.x + radius * cos(startAngle)),
                        y: Float(center.y + radius * sin(startAngle))
                    )
                    let endPoint = Point(
                        x: Float(center.x + radius * cos(endAngle)),
                        y: Float(center.y + radius * sin(endAngle))
                    )
                    defer { lastPoint = endPoint }

                    let (figure, _) = requirePathFigure(geometry, lastPoint: lastPoint)
                    // Whether an arc needs a connecting line depends on where
                    // the previous action left off, so moving a point can change
                    // the structure. Not reconciled; see `canReconcile`.
                    recorder?.record(.unsupported)

                    if startPoint != lastPoint {
                        if figure.segments.size > 0 {
                            let connector = LineSegment()
                            connector.point = startPoint
                            figure.segments.append(connector)
                        } else {
                            figure.startPoint = startPoint
                        }
                    }

                    let segment = ArcSegment()

                    if clockwise {
                        if startAngle < endAngle {
                            segment.isLargeArc = (endAngle - startAngle > .pi)
                        } else {
                            segment.isLargeArc = (startAngle - endAngle < .pi)
                        }
                        segment.sweepDirection = .clockwise
                    } else {
                        if startAngle < endAngle {
                            segment.isLargeArc = (endAngle - startAngle < .pi)
                        } else {
                            segment.isLargeArc = (startAngle - endAngle > .pi)
                        }
                        segment.sweepDirection = .counterclockwise
                    }

                    segment.point = endPoint
                    segment.size = Size(width: Float(radius), height: Float(radius))

                    figure.segments.append(segment)
                case .transform(let transform):
                    let matrixTransform = MatrixTransform()
                    matrixTransform.matrix = Matrix(
                        m11: transform.linearTransform.x,
                        m12: transform.linearTransform.z,
                        m21: transform.linearTransform.y,
                        m22: transform.linearTransform.w,
                        offsetX: transform.translation.x,
                        offsetY: transform.translation.y
                    )

                    for case let geo? in geometry {
                        if geo.transform == nil {
                            geo.transform = matrixTransform
                        } else if let group = geo.transform as? TransformGroup {
                            group.children.append(matrixTransform)
                        } else {
                            let group = TransformGroup()
                            group.children.append(geo.transform)
                            group.children.append(matrixTransform)
                            geo.transform = group
                        }
                    }

                    if geometry.size > 0,
                       let pathGeometry = geometry.getAt(geometry.size - 1) as? PathGeometry,
                       pathGeometry.figures.contains(where: { ($0?.segments.size ?? 0) > 0 })
                    {
                        // Start a new PathGeometry so that transforms don't apply going forward
                        geometry.append(PathGeometry())
                    }
                    recorder?.record(.unsupported)
                case .subpath(let actions):
                    let subGeo = GeometryGroup()
                    applyActions(actions, to: subGeo.children)
                    geometry.append(subGeo)
                    recorder?.record(.unsupported)
            }
        }

        // Cleanup: remove empty paths
        // Having empty paths in the geometry group causes rendering it to silently crash
        for i in (0..<geometry.size).reversed() {
            if let pathGeo = geometry.getAt(i) as? PathGeometry,
               pathGeo.figures.size == 0
            {
                geometry.removeAt(i)
            }
        }
    }

    public func renderPath(
        _ path: Path,
        container: Widget,
        strokeColor: SwiftCrossUI.Color.Resolved,
        fillColor: SwiftCrossUI.Color.Resolved,
        overrideStrokeStyle: StrokeStyle?
    ) {
        let winUiPath = container as! WinUI.Path
        let strokeStyle = overrideStrokeStyle ?? path.strokeStyle!

        // A `Canvas` renders one path widget per drawing command and re-renders
        // every one of them on every commit. Everything below is a COM crossing
        // and the brushes and the dash collection used to be fresh WinRT objects
        // each time, so a sheet overlay with a few hundred commands spent
        // thousands of COM calls per frame repainting an unchanged drawing.
        let entry = WidgetPropertyCache.shared.entry(for: winUiPath)
        if entry.pathFillColor == fillColor,
           entry.pathStrokeColor == strokeColor,
           entry.pathStrokeStyle == strokeStyle
        {
            return
        }
        entry.pathFillColor = fillColor
        entry.pathStrokeColor = strokeColor
        entry.pathStrokeStyle = strokeStyle

        winUiPath.fill = SolidColorBrushCache.brush(for: fillColor)
        winUiPath.stroke = SolidColorBrushCache.brush(for: strokeColor)
        winUiPath.strokeThickness = strokeStyle.width

        switch strokeStyle.cap {
            case .butt:
                winUiPath.strokeStartLineCap = .flat
                winUiPath.strokeEndLineCap = .flat
            case .round:
                winUiPath.strokeStartLineCap = .round
                winUiPath.strokeEndLineCap = .round
            case .square:
                winUiPath.strokeStartLineCap = .square
                winUiPath.strokeEndLineCap = .square
        }

        switch strokeStyle.join {
            case .miter(let limit):
                winUiPath.strokeMiterLimit = limit
                winUiPath.strokeLineJoin = .miter
            case .round:
                winUiPath.strokeLineJoin = .round
            case .bevel:
                winUiPath.strokeLineJoin = .bevel
        }

        // WinUI measures dash lengths and the dash offset in multiples of the
        // stroke thickness rather than in points, so both have to be divided
        // by the thickness on the way in. An empty collection means "solid",
        // and has to be assigned so that a path that stops being dashed stops
        // rendering its old pattern.
        let dashes = WinUI.DoubleCollection()
        if let pattern = strokeStyle.resolvedDash, strokeStyle.width > 0.0 {
            for length in pattern {
                dashes.append(length / strokeStyle.width)
            }
            winUiPath.strokeDashOffset =
                Double(strokeStyle.dashPhase) / strokeStyle.width
        } else {
            winUiPath.strokeDashOffset = 0.0
        }
        winUiPath.strokeDashArray = dashes

        winUiPath.data = path.group
    }

    public func createDatePicker() -> Widget {
        return CustomDatePicker()
    }

    public func updateDatePicker(
        _ datePicker: Widget,
        environment: EnvironmentValues,
        date: Date,
        range: ClosedRange<Date>,
        components: DatePickerComponents,
        onChange: @escaping (Date) -> Void
    ) {
        let customDatePicker = datePicker as! CustomDatePicker

        if components.contains(.hourMinuteAndSecond) {
            print(
                "DatePickerComponents.hourMinuteAndSecond is not supported in WinUIBackend. Falling back to .hourAndMinute."
            )
        }

        customDatePicker.toggleTimeView(shown: components.contains(.hourAndMinute))

        if environment.timeZone != .current {
            print("environment.timeZone is has no effect in WinUIBackend.")
        }

        let dateViewType: CustomDatePicker.DateViewType.Discriminator? =
            if components.contains(.date) {
                switch environment.datePickerStyle {
                    case .automatic, .wheel:
                        .datePicker
                    case .compact:
                        .calendarDatePicker
                    case .graphical:
                        .calendarView
                }
            } else {
                nil
            }

        customDatePicker.onChange = onChange
        customDatePicker.changeDateView(to: dateViewType)
        customDatePicker.updateIfNeeded(date: date, calendar: environment.calendar)
        customDatePicker.setDateRange(to: range)
        customDatePicker.setEnabled(to: environment.isEnabled)

        // `CustomDatePicker.naturalSize()` adds its subviews up, and the calls
        // above can add or remove one, so the remembered natural size no longer
        // describes it. Cleared unconditionally because each of those calls
        // decides for itself whether anything changed.
        WidgetPropertyCache.shared.entry(for: customDatePicker).naturalSize = nil

        // TODO(parity): foreground color ignored
        // Setting foreground like for other views works for TimePicker and DatePicker but not for
        // CalendarView or CalendarDatePicker.
    }

    // public func createTable(rows: Int, columns: Int) -> Widget {
    //     let grid = Grid()
    //     grid.columnSpacing = 10
    //     grid.rowSpacing = 10
    //     for _ in 0..<rows {
    //         let rowDefinition = RowDefinition()
    //         rowDefinition.height = GridLength(value: 0, gridUnitType: .auto)
    //         grid.rowDefinitions.append(rowDefinition)
    //     }

    //     for _ in 0..<columns {
    //         let columnDefinition = ColumnDefinition()
    //         columnDefinition.width = GridLength(value: 0, gridUnitType: .auto)
    //         grid.columnDefinitions.append(columnDefinition)
    //     }
    //     return grid
    // }

    // public func setRowCount(ofTable table: Widget, to rows: Int) {
    //     let grid = table as! Grid
    //     grid.rowDefinitions.clear()
    //     for _ in 0..<rows {
    //         let rowDefinition = RowDefinition()
    //         rowDefinition.height = GridLength(value: 0, gridUnitType: .auto)
    //         grid.rowDefinitions.append(rowDefinition)
    //     }
    // }

    // public func setColumnCount(ofTable table: Widget, to columns: Int) {
    //     let grid = table as! Grid
    //     grid.columnDefinitions.clear()
    //     for _ in 0..<columns {
    //         let columnDefinition = ColumnDefinition()
    //         columnDefinition.width = GridLength(value: 0, gridUnitType: .auto)
    //         grid.columnDefinitions.append(columnDefinition)
    //     }
    // }

    // public func setCell(at position: CellPosition, inTable table: Widget, to widget: Widget) {
    //     let grid = table as! Grid
    //     Grid.setColumn(widget, Int32(position.column))
    //     Grid.setRow(widget, Int32(position.row))
    //     grid.children.append(widget)
    // }
}

extension EnvironmentValues {
    /// A brush painting the current foreground colour.
    ///
    /// Shared rather than freshly activated per access; see
    /// ``SolidColorBrushCache``.
    @MainActor
    var winUIForegroundBrush: WinUI.Brush {
        SolidColorBrushCache.brush(for: suggestedForegroundColor.resolve(in: self))
    }

    /// Applies the environment's font, colours and enabled state to a control.
    ///
    /// Every write here is a COM crossing, and this runs on every update pass
    /// for every button, text field, toggle, slider and picker in the window,
    /// so each group of writes is skipped when its inputs are unchanged.
    @MainActor
    func apply(to control: WinUI.Control) {
        let entry = WidgetPropertyCache.shared.entry(for: control)

        let resolvedFont = resolvedFont
        if entry.font != resolvedFont {
            entry.font = resolvedFont
            entry.naturalSize = nil
            control.fontSize = resolvedFont.pointSize
            control.fontWeight.weight = resolvedFont.winUIFontWeight
            control.fontStyle = resolvedFont.isItalic ? .italic : .normal
        }

        let foregroundColor = suggestedForegroundColor.resolve(in: self)
        if entry.foregroundColor != foregroundColor {
            entry.foregroundColor = foregroundColor
            control.foreground = SolidColorBrushCache.brush(for: foregroundColor)
        }

        if entry.isEnabled != isEnabled {
            entry.isEnabled = isEnabled
            control.isEnabled = isEnabled
        }

        if entry.colorScheme != colorScheme {
            entry.colorScheme = colorScheme
            switch colorScheme {
                case .light:
                    control.requestedTheme = .light
                case .dark:
                    control.requestedTheme = .dark
            }
        }
    }

    /// Applies the environment's font and foreground colour to a text block.
    ///
    /// See the note on ``apply(to:)-(WinUI.Control)`` for why the writes are
    /// guarded.
    @MainActor
    func apply(to textBlock: WinUI.TextBlock) {
        apply(to: textBlock, entry: WidgetPropertyCache.shared.entry(for: textBlock))
    }

    /// Applies the environment's font and foreground colour to a text block
    /// whose cache entry the caller has already looked up.
    ///
    /// - Parameters:
    ///   - textBlock: The text block to write.
    ///   - entry: `textBlock`'s cache entry. Must be the entry for
    ///     `textBlock`; passing another widget's entry would let a write be
    ///     skipped because a *different* widget already holds the value.
    @MainActor
    func apply(to textBlock: WinUI.TextBlock, entry: WidgetPropertyCache.Entry) {
        let resolvedFont = resolvedFont
        if entry.font != resolvedFont {
            entry.font = resolvedFont
            entry.naturalSize = nil
            textBlock.fontSize = resolvedFont.pointSize
            textBlock.fontWeight.weight = resolvedFont.winUIFontWeight
            textBlock.lineHeight = resolvedFont.lineHeight
            textBlock.fontStyle = resolvedFont.isItalic ? .italic : .normal
        }

        let foregroundColor = suggestedForegroundColor.resolve(in: self)
        if entry.foregroundColor != foregroundColor {
            entry.foregroundColor = foregroundColor
            textBlock.foreground = SolidColorBrushCache.brush(for: foregroundColor)
        }
    }
}

extension Font.Resolved {
    var winUIFontWeight: UInt16 {
        switch weight {
            case .ultraLight:
                100
            case .thin:
                200
            case .light:
                300
            case .regular:
                400
            case .medium:
                500
            case .semibold:
                600
            case .bold:
                700
            case .heavy:
                800
            case .black:
                900
        }
    }
}

final class CustomComboBox: ComboBox {
    // Native SelectionChanged also fires for framework item/index writes.
    var isApplyingModelUpdate = false
    var options: [String] = []
    var onChangeSelection: ((Int?) -> Void)?
    var actualForegroundColor: UWP.Color = UWP.Color(a: 255, r: 0, g: 0, b: 0)
}

final class CustomRadioButtons: RadioButtons {
    var isApplyingModelUpdate = false
    var selectionTracker = NativeSelectionTracker<Int32>(initialSelection: -1)
    var onChangeSelection: ((Int?) -> Void)?
    var onInitialSizeReady: (@MainActor (ViewSize) -> Void)?
    private var initialSizeNotificationPending = false
    private var initialSizeNotificationDelivered = false

    @MainActor
    func requestInitialSizeAfterLoading() {
        guard !initialSizeNotificationPending, !initialSizeNotificationDelivered,
            let queue = dispatcherQueue else { return }
        initialSizeNotificationPending = true
        // The native repeater realizes after the control's initial zero-sized
        // layout. Let the whole Loaded route and current layout stack finish
        // before asking the existing shared resize chain to measure it again.
        // One delivered notification per native widget, without timers or a
        // SizeChanged loop. If detached before delivery, the next Loaded can retry.
        let queued = (try? queue.tryEnqueue(.normal) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.initialSizeNotificationPending = false
                guard self.isLoaded, let onResize = self.onInitialSizeReady else { return }
                self.initialSizeNotificationDelivered = true
                WidgetPropertyCache.shared.entry(for: self).naturalSize = nil
                onResize(.zero)
            }
        }) ?? false
        // A queue rejected during shutdown must not trigger synchronous layout.
        if !queued { initialSizeNotificationPending = false }
    }
}

final class CustomSplitView: SplitView {
    var sidebarResizeHandler: (() -> Void)?
}

final class TooltipContainer: WinUI.Canvas {
    var child: WinUI.FrameworkElement
    var tooltip: ToolTip

    init(child: WinUI.FrameworkElement) {
        self.child = child
        self.tooltip = ToolTip()

        super.init()

        children.append(child)
        ToolTipService.setToolTip(self, tooltip)
    }
}

class SwiftIInitializeWithWindow: WindowsFoundation.IUnknown {
    override class var IID: WindowsFoundation.IID {
        WindowsFoundation.IID(
            Data1: 0x3E68_D4BD,
            Data2: 0x7135,
            Data3: 0x4D10,
            Data4: (0x80, 0x18, 0x9F, 0xB6, 0xD9, 0xF3, 0x3F, 0xA1)
        )
    }

    func initialize(with hwnd: HWND) throws {
        _ = try perform(as: IInitializeWithWindow.self) { pThis in
            try CHECKED(pThis.pointee.lpVtbl.pointee.Initialize(pThis, hwnd))
        }
    }
}

public class CustomWindow: WinUI.Window {
    /// Hardcoded menu bar height from MenuBar_themeresources.xaml in the
    /// microsoft-ui-xaml repository (the MenuBarHeight property)
    private static let menuBarHeight = 40

    var menuBar = WinUI.MenuBar()
    var child: WinUIBackend.Widget?
    var grid: WinUI.Grid
    var cachedAppWindow: WinAppSDK.AppWindow!
    var isActive = false
    var currentAlert: WinUIBackend.Alert?
    var closeRequestController: WinUIWindowCloseRequestController?

    private(set) var menuBarIsVisible = false

    /// The amount of height to subtract off the window height to obtain the
    /// window's available content height.
    var contentHeightAdjustment: Int {
        menuBarIsVisible ? Self.menuBarHeight : 0
    }

    /// The smallest content size the window may shrink to, in points.
    var minimumContentSize: SIMD2<Int> = .zero

    /// The largest content size the window may grow to, in points.
    var maximumContentSize: SIMD2<Int>?

    /// Whether ``enforceSizeLimits()`` is already run on every size change.
    private var enforcesSizeLimits = false

    /// The client size, in physical pixels, that shows a given content size.
    ///
    /// - Parameter contentSize: The content size in points.
    /// - Returns: The client size for `AppWindow`.
    func physicalClientSize(forContentSize contentSize: SIMD2<Int>) -> UWP.SizeInt32 {
        let scaleFactor = scaleFactor
        let width = scaleFactor * Double(contentSize.x)
        let height = scaleFactor * Double(contentSize.y + contentHeightAdjustment)
        return UWP.SizeInt32(
            width: Int32(width.rounded(.towardZero)),
            height: Int32(height.rounded(.towardZero))
        )
    }

    /// The largest content size, in points, that fits the work area of the
    /// display the window is on, allowing for the window's own frame.
    ///
    /// `nil` when the display can't be determined.
    var availableContentSize: SIMD2<Int>? {
        guard
            let displayArea = WinAppSDK.DisplayArea.getFromWindowId(
                cachedAppWindow.id,
                WinAppSDK.DisplayAreaFallback.nearest
            )
        else {
            return nil
        }
        let workArea = displayArea.workArea
        guard workArea.width > 0, workArea.height > 0 else {
            return nil
        }

        // The frame (title bar and borders) is the difference between the
        // window's outer size and its client size.
        let outer = cachedAppWindow.size
        let client = cachedAppWindow.clientSize
        let frameWidth = max(0, Int(outer.width) - Int(client.width))
        let frameHeight = max(0, Int(outer.height) - Int(client.height))

        let scaleFactor = scaleFactor
        let width = Double(Int(workArea.width) - frameWidth) / scaleFactor
        let height = Double(Int(workArea.height) - frameHeight) / scaleFactor
        return SIMD2(
            max(1, Int(width.rounded(.towardZero))),
            max(1, Int(height.rounded(.towardZero)) - contentHeightAdjustment)
        )
    }

    /// Starts resizing the window back into its limits whenever its size
    /// changes. Does nothing the second time.
    func installSizeLimitEnforcement() {
        guard !enforcesSizeLimits else {
            return
        }
        enforcesSizeLimits = true
        cachedAppWindow.changed.addHandler { [weak self] _, args in
            guard let self, let args, args.didSizeChange else { return }
            self.enforceSizeLimits()
        }
    }

    /// Resizes the window back into ``minimumContentSize`` and
    /// ``maximumContentSize`` if it has left them.
    func enforceSizeLimits() {
        let minimum = physicalClientSize(forContentSize: minimumContentSize)
        let maximum = maximumContentSize.map(physicalClientSize(forContentSize:))
        let current = cachedAppWindow.clientSize

        var width = max(current.width, minimum.width)
        var height = max(current.height, minimum.height)
        if let maximum {
            width = min(width, maximum.width)
            height = min(height, maximum.height)
        }

        guard width != current.width || height != current.height else {
            return
        }
        // Resizing raises `changed` again; the size is then within the
        // limits, so that call returns above.
        try? cachedAppWindow.resizeClient(UWP.SizeInt32(width: width, height: height))
    }

    var scaleFactor: Double {
        // I'm leaving this code here for future travellers. Be warned that this always
        // seems to return 100% even if the scale factor is set to 125% in settings.
        // Perhaps it's only the device's built-in default scaling? But that seems pretty
        // useless, and isn't what the docs seem to imply.
        //
        //   var deviceScaleFactor = SCALE_125_PERCENT
        //   _ = GetScaleFactorForMonitor(monitor, &deviceScaleFactor)

        let hwnd = cachedAppWindow.getHWND()!
        let monitor = MonitorFromWindow(hwnd, DWORD(bitPattern: MONITOR_DEFAULTTONEAREST))!

        var x: UINT = 0
        var y: UINT = 0
        let result = GetDpiForMonitor(monitor, MDT_EFFECTIVE_DPI, &x, &y)

        let windowScaleFactor: Double
        if result == S_OK {
            windowScaleFactor = Double(x) / Double(USER_DEFAULT_SCREEN_DPI)
        } else {
            logger.warning("failed to get window scale factor, defaulting to 1.0")
            windowScaleFactor = 1
        }

        return windowScaleFactor
    }

    public override init() {
        grid = WinUI.Grid()

        super.init()

        let menuBarRowDefinition = WinUI.RowDefinition()
        let contentRowDefinition = WinUI.RowDefinition()
        grid.rowDefinitions.append(menuBarRowDefinition)
        grid.rowDefinitions.append(contentRowDefinition)
        grid.children.append(menuBar)
        WinUI.Grid.setRow(menuBar, 0)
        self.content = grid

        // NB: This event fires when the window is activated _or_ deactivated.
        self.activated.addHandler { [weak self] _, args in
            switch args?.windowActivationState {
                case .codeActivated, .pointerActivated: self?.isActive = true
                case .deactivated: self?.isActive = false
                // NB: The compiler apparently thinks we didn't exhaustively switch
                // over this enum without this `default` (even after adding a `case nil`).
                // Might be because it doesn't treat the underlying C enum as a Swift enum?
                default: break
            }
        }

        // Caching appWindow is apparently a good idea in terms of performance:
        // https://github.com/thebrowsercompany/swift-winrt/issues/199#issuecomment-2611006020
        cachedAppWindow = appWindow

        // Default to not showing the menu bar; we only want to show it when it's non-empty
        setMenuBarVisible(menuBarIsVisible)
    }

    /// Sets whether the menu bar of the current window is visible. The menu bar
    /// is what holds the in-window app menu, it's not the title bar (the one with
    /// the window controls).
    public func setMenuBarVisible(_ visible: Bool) {
        grid.rowDefinitions[0]!.height = WinUI.GridLength(
            value: visible ? Double(Self.menuBarHeight) : 0,
            gridUnitType: .pixel
        )
        menuBarIsVisible = visible
    }

    public func setChild(_ child: WinUIBackend.Widget) {
        self.child = child
        grid.children.append(child)
        WinUI.Grid.setRow(child, 1)
    }
}

public final class GeometryGroupHolder {
    var group = GeometryGroup()
    var strokeStyle: StrokeStyle?

    /// The actions the WinRT geometry currently represents.
    ///
    /// Compared against the next upload so that an unchanged path costs
    /// nothing, and so that an upload of the same shape with moved points can
    /// be reconciled rather than rebuilt.
    var appliedActions: [SwiftCrossUI.Path.Action] = []

    /// The object each applied action wrote into, index-aligned with
    /// ``appliedActions``.
    ///
    /// Empty when the geometry was built from a path that
    /// ``PathGeometryReconciler`` doesn't handle, which forces a rebuild.
    var actionTargets: [PathActionTarget] = []

    /// The fill rule currently applied, so that it isn't rewritten every time.
    var appliedFillRule: SwiftCrossUI.FillRule?
}

/// Keeps the composition clip behind each rounded element so that the clip
/// follows the element's size.
///
/// `setCornerRadius(of:to:)` used to size the clip once from the element's
/// width and height at the time of the call; an element that hadn't been
/// sized yet, or that was resized later, was clipped to the wrong rectangle
/// (a zero-sized one hides the element entirely). The clip now resizes with
/// the element's `SizeChanged` event.
@MainActor
final class CornerClipRegistry {
    static let shared = CornerClipRegistry()

    /// A rounded-rectangle clip on one element.
    final class Clip {
        let geometry: WinAppSDK.CompositionRoundedRectangleGeometry

        init(geometry: WinAppSDK.CompositionRoundedRectangleGeometry) {
            self.geometry = geometry
        }

        /// Unset dimensions (NaN or negative) are not allocations. Zero is a
        /// real collapsed bound and must replace a previous visible rectangle.
        func resize(width: Double, height: Double) {
            guard width.isFinite, height.isFinite, width >= 0.0, height >= 0.0 else {
                return
            }
            let x = Float(width)
            let y = Float(height)
            guard x.isFinite, y.isFinite else { return }
            geometry.size = WindowsFoundation.Vector2(x: x, y: y)
        }
    }

    private struct Entry {
        weak var element: WinUI.FrameworkElement?
        let clip: Clip
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    private init() {}

    /// The clip installed on an element, created and attached on first use.
    ///
    /// - Parameter element: The element to clip.
    /// - Returns: The clip, or `nil` if the element has no composition visual.
    func clip(for element: WinUI.FrameworkElement) -> Clip? {
        let key = ObjectIdentifier(element)
        if let entry = entries[key], entry.element === element {
            return entry.clip
        }

        entries = entries.filter { _, entry in entry.element != nil }

        guard
            let visual: WinAppSDK.Visual = try? element.getVisualInternal(),
            let geometry = try? visual.compositor.createRoundedRectangleGeometry(),
            let geometricClip = try? visual.compositor.createGeometricClip()
        else {
            logger.warning("failed to create a composition clip for a rounded element")
            return nil
        }
        geometricClip.geometry = geometry
        visual.clip = geometricClip

        let clip = Clip(geometry: geometry)
        element.sizeChanged.addHandler { [weak clip] _, args in
            guard let clip, let args else { return }
            clip.resize(width: Double(args.newSize.width), height: Double(args.newSize.height))
        }
        entries[key] = Entry(element: element, clip: clip)
        return clip
    }
}

/// Keeps the `WriteableBitmap` behind each image view so that an image whose
/// pixels change every update rewrites one pixel buffer instead of allocating
/// a new bitmap each time.
///
/// `WinUI.Image` is a final class, so the bitmap can't live on a subclass.
/// Entries hold the image view weakly and are checked for identity on every
/// lookup, so a recycled `ObjectIdentifier` can never hand a new image view
/// another view's bitmap.
@MainActor
final class ImageBitmapRegistry {
    static let shared = ImageBitmapRegistry()

    private struct Entry {
        weak var imageView: WinUI.Image?
        let bitmap: WriteableBitmap
        let width: Int
        let height: Int
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    private init() {}

    /// Returns a bitmap of the given size for an image view, reusing the
    /// view's existing bitmap when the size hasn't changed.
    ///
    /// - Parameters:
    ///   - imageView: The image view the bitmap is for.
    ///   - width: The bitmap's width in pixels.
    ///   - height: The bitmap's height in pixels.
    /// - Returns: The bitmap, and whether it was newly created (in which case
    ///   it still has to be assigned as the view's source).
    func bitmap(
        for imageView: WinUI.Image,
        width: Int,
        height: Int
    ) -> (bitmap: WriteableBitmap, isNew: Bool) {
        let key = ObjectIdentifier(imageView)
        if let entry = entries[key],
           entry.imageView === imageView,
           entry.width == width,
           entry.height == height
        {
            return (entry.bitmap, false)
        }

        // Drop entries whose image views have gone away so the registry
        // doesn't grow without bound in a long-lived app.
        entries = entries.filter { _, entry in entry.imageView != nil }

        let bitmap = WriteableBitmap(Int32(max(width, 1)), Int32(max(height, 1)))
        entries[key] = Entry(
            imageView: imageView,
            bitmap: bitmap,
            width: width,
            height: height
        )
        return (bitmap, true)
    }
}

@MainActor
final class CustomDatePicker: StackPanel {
    override init() {
        super.init()
        self.spacing = 10
    }

    deinit {
        timeChangedEvent?.dispose()
        dateChangedEvent?.dispose()
    }

    enum DateViewType {
        case calendarView(CalendarView)
        case calendarDatePicker(CalendarDatePicker)
        case datePicker(WinUI.DatePicker)

        var asControl: Control {
            switch self {
                case .calendarView(let calendarView): calendarView
                case .calendarDatePicker(let calendarDatePicker): calendarDatePicker
                case .datePicker(let datePicker): datePicker
            }
        }

        enum Discriminator {
            case calendarView
            case calendarDatePicker
            case datePicker
        }

        var discriminator: Discriminator {
            switch self {
                case .calendarView(_): .calendarView
                case .calendarDatePicker(_): .calendarDatePicker
                case .datePicker(_): .datePicker
            }
        }
    }

    private var dateView: DateViewType?
    private var timeView: TimePicker?
    private var date = Date()
    private var calendar = Calendar.current
    private var needsUpdate = false
    var onChange: ((Date) -> Void)?
    private var timeChangedEvent: EventCleanup?
    private var dateChangedEvent: EventCleanup?

    func toggleTimeView(shown: Bool) {
        guard shown != (self.timeView != nil) else { return }

        if shown {
            let timeView = TimePicker()
            children.append(timeView)
            self.timeView = timeView
            timeChangedEvent = timeView.timeChanged.addHandler { [unowned self] _, change in
                guard let change else { return }
                self.date =
                    calendar.startOfDay(for: date)
                        + Double(change.newTime.duration) / ticksPerSecond
                self.onChange?(self.date)
            }
            needsUpdate = true
        } else {
            timeChangedEvent?.dispose()
            timeChangedEvent = nil
            children.removeAtEnd()
            self.timeView = nil
        }
    }

    func setEnabled(to isEnabled: Bool) {
        dateView?.asControl.isEnabled = isEnabled
        timeView?.isEnabled = isEnabled
    }

    func changeDateView(to newDiscriminator: DateViewType.Discriminator?) {
        guard newDiscriminator != dateView?.discriminator else { return }

        dateChangedEvent?.dispose()
        if dateView != nil {
            children.removeAt(0)
        }

        switch newDiscriminator {
            case .calendarView:
                let calendarView = CalendarView()
                dateView = .calendarView(calendarView)
                children.insertAt(0, calendarView)
                orientation = .vertical
                dateChangedEvent = calendarView.selectedDatesChanged.addHandler {
                    [unowned self] _, _ in

                    guard calendarView.selectedDates.size > 0 else {
                        let (dateTime, _) = foundationDateToComponents(self.date)
                        calendarView.selectedDates.append(dateTime)
                        return
                    }

                    self.date = componentsToFoundationDate(
                        dateTime: calendarView.selectedDates.getAt(0),
                        timeSpan: timeView?.selectedTime
                    )

                    if calendarView.selectedDates.size > 1 {
                        self.needsUpdate = true
                    }

                    self.onChange?(self.date)
                }
                needsUpdate = true
            case .calendarDatePicker:
                let calendarDatePicker = CalendarDatePicker()
                dateView = .calendarDatePicker(calendarDatePicker)
                children.insertAt(0, calendarDatePicker)
                orientation = .horizontal
                dateChangedEvent = calendarDatePicker.dateChanged.addHandler {
                    [unowned self] _, change in

                    guard let newDate = change?.newDate else { return }
                    self.date = componentsToFoundationDate(
                        dateTime: newDate,
                        timeSpan: timeView?.selectedTime
                    )
                    self.onChange?(self.date)
                }
                needsUpdate = true
            case .datePicker:
                let datePicker = WinUI.DatePicker()
                dateView = .datePicker(datePicker)
                children.insertAt(0, datePicker)
                orientation = .horizontal
                dateChangedEvent = datePicker.selectedDateChanged.addHandler {
                    [unowned self] _, _ in

                    guard let selectedDate = datePicker.selectedDate else { return }
                    self.date = componentsToFoundationDate(
                        dateTime: selectedDate,
                        timeSpan: timeView?.selectedTime
                    )
                    self.onChange?(self.date)
                }
                needsUpdate = true
            case nil:
                break
        }
    }

    func setDateRange(to range: ClosedRange<Date>) {
        guard let dateView else { return }

        let (startDate, _) = foundationDateToComponents(range.lowerBound)
        let (endDate, _) = foundationDateToComponents(range.upperBound)

        switch dateView {
            case .calendarView(let calendarView):
                calendarView.minDate = startDate
                calendarView.maxDate = endDate
            case .calendarDatePicker(let calendarDatePicker):
                calendarDatePicker.minDate = startDate
                calendarDatePicker.maxDate = endDate
            case .datePicker(let datePicker):
                datePicker.minYear = startDate
                datePicker.maxYear = endDate
        }
    }

    func updateIfNeeded(date: Date, calendar: Calendar) {
        if !needsUpdate && date == self.date && calendar == self.calendar { return }
        defer { needsUpdate = false }

        self.date = date
        self.calendar = calendar

        let (dateTime, timeSpan) = foundationDateToComponents(date)

        switch dateView {
            case .calendarView(let calendarView):
                calendarView.calendarIdentifier = identifier(for: calendar)
                switch calendarView.selectedDates.size {
                    case 0:
                        calendarView.selectedDates.append(dateTime)
                    case 1:
                        calendarView.selectedDates.setAt(0, dateTime)
                    default:
                        calendarView.selectedDates.clear()
                        calendarView.selectedDates.setAt(0, dateTime)
                }
            case .calendarDatePicker(let calendarDatePicker):
                calendarDatePicker.calendarIdentifier = identifier(for: calendar)
                calendarDatePicker.date = dateTime
            case .datePicker(let datePicker):
                datePicker.selectedDate = dateTime
            case nil:
                break
        }

        if let timeView {
            timeView.selectedTime = timeSpan
        }
    }

    private func identifier(for calendar: Calendar) -> String {
        switch calendar.identifier {
            case .chinese: return "ChineseLunarCalendar"
            case .gregorian, .iso8601: return "GregorianCalendar"
            case .hebrew: return "HebrewCalendar"
            case .islamicTabular: return "HijriCalendar"
            case .islamicUmmAlQura: return "UmAlQuraCalendar"
            case .japanese: return "JapaneseCalendar"
            case .persian: return "PersianCalendar"
            case .republicOfChina: return "TaiwanCalendar"
            #if compiler(>=6.2)
                case .vietnamese: return "VietnameseLunarCalendar"
            #endif
            case let id:
                print("Unsupported calendar identifier '\(id)'. Falling back to Gregorian.")
                return "GregorianCalendar"
        }
    }

    // Magic numbers taken from https://stackoverflow.com/a/5471380/6253337
    private let ticksPerSecond: Double = 10_000_000
    private let unixEpochInUniversalTime: Int64 = 116_444_736_000_000_000

    private func foundationDateToComponents(_ date: Date) -> (DateTime, TimeSpan) {
        let timeInterval = date.timeIntervalSince(calendar.startOfDay(for: date))

        return (
            DateTime(
                universalTime: Int64(
                    date.timeIntervalSince1970 * ticksPerSecond + Double(unixEpochInUniversalTime)
                )
            ),
            TimeSpan(duration: Int64(timeInterval * ticksPerSecond))
        )
    }

    private func componentsToFoundationDate(dateTime: DateTime, timeSpan: TimeSpan?) -> Date {
        let baseDate = Date(
            timeIntervalSince1970: Double(dateTime.universalTime - unixEpochInUniversalTime)
                / ticksPerSecond
        )

        if let timeSpan {
            let time = Double(timeSpan.duration) / ticksPerSecond
            return calendar.startOfDay(for: baseDate) + time
        } else {
            return baseDate
        }
    }

    func naturalSize() -> SIMD2<Int> {
        let timeViewSize =
            if timeView != nil {
                // Width is 242, as shown in the WinUI repository:
                // https://github.com/marcelwgn/microsoft-ui-xaml/blob/ff21f9b212cea2191b959649e45e52486c8465aa/src/controls/dev/CommonStyles/TimePicker_themeresources.xaml#L116
                // Height is experimentally 29 which I don't see anywhere in that file.
                SIMD2(242, 29)
            } else {
                SIMD2<Int>.zero
            }

        let dateViewSize =
            if let dateControl = dateView?.asControl {
                WinUIBackend.naturalSize(of: dateControl)
            } else {
                SIMD2<Int>.zero
            }

        if orientation == .horizontal {
            return SIMD2(
                x: timeViewSize.x + dateViewSize.x + Int(self.spacing),
                y: max(timeViewSize.y, dateViewSize.y)
            )
        } else {
            return SIMD2(
                x: max(timeViewSize.x, dateViewSize.x),
                y: timeViewSize.y + dateViewSize.y + Int(self.spacing)
            )
        }
    }
}

extension WinUI.FrameworkElement {
    var shouldBlockNextChangedSignal: Bool {
        get {
            (self.tag as? [String: Any])?["shouldBlockNextChangedSignal"] as? Bool ?? false
        }
        set {
            var value = self.tag as? [String: Any] ?? [:]
            value["shouldBlockNextChangedSignal"] = newValue
            self.tag = value
        }
    }
}


/// Opt-in evidence for a real pointer's native target. This never changes
/// handled, capture, focus or hit testing, and is not a performance instrument.
/// Typed event subscriptions observe only routes not already handled by a child;
/// an inert decorative Path is such a source. Absence of an event is inconclusive.
@MainActor
private enum WinUIPointerHitDiagnostics {
    private static let sink: Sink? = {
        guard let path = ProcessInfo.processInfo.environment["SCUI_WINUI_POINTER_HIT_FILE"],
            !path.isEmpty else { return nil }
        return Sink(path: path)
    }()
    private static var sequence = 0
    private static let maximumRecords = 512

    static func install(on root: WinUI.Grid) {
        guard let sink else { return }
        root.pointerPressed.addHandler { [weak root] _, event in
            guard let root, let event else { return }
            record("pressed", event: event, root: root)
        }
        root.pointerReleased.addHandler { [weak root] _, event in
            guard let root, let event else { return }
            record("released", event: event, root: root)
        }
        sink.enqueue([
            "event": "pointer-hit-observer-installed",
            "processID": ProcessInfo.processInfo.processIdentifier,
            "observesHandledEvents": false,
            "maximumRecords": maximumRecords,
            "note": "Real unhandled routed events; no input injection or routing mutation."
        ])
    }

    private static func record(
        _ phase: String, event: WinUI.PointerRoutedEventArgs, root: WinUI.Grid
    ) {
        guard let sink, sequence < maximumRecords, root.isLoaded,
            let point = try? event.getCurrentPoint(nil),
            point.position.x.isFinite, point.position.y.isFinite else { return }
        sequence += 1
        let source = event.originalSource as? WinUI.DependencyObject
        var ancestors: [[String: Any]] = []
        var current = source
        while let node = current, ancestors.count < 16 {
            ancestors.append(describe(node))
            current = WinUI.VisualTreeHelper.getParent(node)
        }
        // nil-relative pointer coordinates and this API both use the XAML
        // host's logical coordinate space. Do not apply display scaling twice.
        var hits: [[String: Any]] = []
        if let nativeHits = WinUI.VisualTreeHelper.findElementsInHostCoordinates(
            point.position, root, false), let iterator = nativeHits.first()
        {
            var visited = 0
            while iterator.hasCurrent, visited < 32 {
                if let candidate = iterator.current { hits.append(describe(candidate)) }
                visited += 1
                _ = iterator.moveNext()
            }
        }
        sink.enqueue([
            "event": "pointer-hit", "phase": phase, "sequence": sequence,
            "tickNS": DispatchTime.now().uptimeNanoseconds,
            "processID": ProcessInfo.processInfo.processIdentifier,
            "threadID": GetCurrentThreadId(), "pointerID": point.pointerId,
            "pointInHost": [Double(point.position.x), Double(point.position.y)],
            "handledObserved": event.handled,
            "originalSource": source.map(describe) ?? ["type": "unprojected-or-nil"],
            "ancestors": ancestors, "nativeHitStack": hits
        ])
    }

    private static func describe(_ node: WinUI.DependencyObject) -> [String: Any] {
        var fields: [String: Any] = ["type": String(reflecting: type(of: node))]
        if let element = node as? WinUI.UIElement {
            fields["isHitTestVisible"] = element.isHitTestVisible
            fields["opacity"] = element.opacity
        }
        if let element = node as? WinUI.FrameworkElement {
            fields["width"] = element.actualWidth
            fields["height"] = element.actualHeight
            fields["name"] = String(element.name.prefix(160))
        }
        if let text = node as? WinUI.TextBlock {
            fields["text"] = String(text.text.prefix(160))
        }
        if let control = node as? WinUI.Control {
            fields["isEnabled"] = control.isEnabled
        }
        if let shape = node as? WinUI.Shape {
            fields["fillIsNil"] = shape.fill == nil
            fields["strokeIsNil"] = shape.stroke == nil
            fields["strokeThickness"] = shape.strokeThickness
            if let fill = shape.fill as? WinUI.SolidColorBrush {
                fields["fillAlphaByte"] = Int(fill.color.a)
            }
            if let stroke = shape.stroke as? WinUI.SolidColorBrush {
                fields["strokeAlphaByte"] = Int(stroke.color.a)
            }
        }
        return fields
    }

    private final class Sink: @unchecked Sendable {
        private let queue = DispatchQueue(label: "SwiftCrossUI.pointer-hit-diagnostics")
        private let handle: FileHandle

        init?(path: String) {
            if !FileManager.default.fileExists(atPath: path),
                !FileManager.default.createFile(atPath: path, contents: nil) { return nil }
            guard let handle = FileHandle(forWritingAtPath: path) else { return nil }
            self.handle = handle
            handle.seekToEndOfFile()
        }

        func enqueue(_ record: [String: Any]) {
            guard var data = try? JSONSerialization.data(
                withJSONObject: record, options: [.sortedKeys]) else { return }
            data.append(0x0a)
            let encoded = data
            queue.async { [self] in
                // No synchronous per-click file I/O on the native UI callback.
                // Diagnostic write failure must not affect application input.
                try? handle.write(contentsOf: encoded)
            }
        }

        deinit { try? handle.close() }
    }
}
