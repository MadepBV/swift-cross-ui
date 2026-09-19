import Foundation

/// The environment used when constructing scenes and views. Each scene or view
/// gets to modify the environment before passing it on to its children, which
/// is the basis of many view modifiers.
public struct EnvironmentValues {
    /// A font resolution context derived from the current environment.
    ///
    /// Essentially just a subset of the environment.
    @MainActor
    public var fontResolutionContext: Font.Context {
        Font.Context(
            overlay: fontOverlay,
            deviceClass: backend.deviceClass,
            resolveTextStyle: { backend.resolveTextStyle($0) }
        )
    }

    /// The current font resolved to a form suitable for rendering.
    ///
    /// Just a helper method for our own backends. We haven't made this public
    /// because it would be weird to have two pretty equivalent ways of resolving
    /// fonts.
    @MainActor
    @_spi(Backends) public var resolvedFont: Font.Resolved {
        font.resolve(in: fontResolutionContext)
    }

    /// The suggested foreground color for backends to use.
    ///
    /// Backends don't neccessarily have to obey this when
    /// ``EnvironmentValues/foregroundColor`` is `nil`.
    public var suggestedForegroundColor: Color {
        foregroundColor ?? colorScheme.defaultForegroundColor
    }

    /// Called by view graph nodes when they resize due to an internal state
    /// change and end up changing size.
    ///
    /// Each view graph node sets its own handler when passing the environment
    /// on to its children, setting up a bottom-up update chain up which resize
    /// events can propagate.
    @_spi(Backends) public var onResize: @MainActor (_ newSize: ViewSize) -> Void

    /// Backing storage for extensible subscript
    private var values: [ObjectIdentifier: Any]

    /// An internal environment value used to control whether layout caching is
    /// enabled or not.
    ///
    /// This is set to `true` when computing non-final layouts. E.g. when a stack
    /// computes the minimum and maximum sizes of its children, it should enable
    /// layout caching because those updates are guaranteed to be non-final. The
    /// reason that we can't cache on non-final updates is that the last layout
    /// proposal received by each view must be its intended final proposal.
    var allowLayoutCaching: Bool = false

    /// Whether the layout system is currently probing sizes rather than
    /// settling on one.
    ///
    /// A container works out how flexible its children are by asking each of
    /// them how big it would be at the smallest and the largest size it could
    /// be given, and only then proposes the size it has decided on. A view
    /// whose content depends on the proposed size — a ``GeometryReader``, or a
    /// ``Canvas`` that draws from it — therefore has its content produced
    /// several times per update pass, at sizes it will never be shown at.
    ///
    /// Read this to do the expensive part of that work only once:
    ///
    /// ```swift
    /// GeometryReader { proxy in
    ///     SheetView(size: proxy.size, drawsContent: !isProbingLayout)
    /// }
    /// ```
    ///
    /// - Important: A view must still report the same *size* whether it is
    ///   being probed or not, or the layout it ends up with will not be the one
    ///   that was measured. Use this to skip work that doesn't affect layout —
    ///   rasterising, drawing, expensive formatting — never to change how big
    ///   the view claims to be.
    public var isProbingLayout: Bool {
        allowLayoutCaching
    }

    /// The current stack orientation.
    ///
    /// Inherited by ``ForEach`` and ``Group`` so that they can be used without
    /// affecting layout.
    ///
    /// Stored directly rather than in ``values`` because every stack reads all
    /// three stack layout properties and replaces all three for its children,
    /// on every layout computation and every commit. Going through the
    /// extensible storage would mean a dictionary lookup and a dynamic cast per
    /// read, and a copy-on-write of the whole dictionary per write.
    public var layoutOrientation: Orientation = .vertical

    /// The current stack alignment.
    ///
    /// Inherited by ``ForEach`` and ``Group`` so that they can be used without
    /// affecting layout.
    public var layoutAlignment: StackAlignment = .center

    /// The current stack spacing.
    ///
    /// Inherited by ``ForEach`` and ``Group`` so that they can be used without
    /// affecting layout.
    public var layoutSpacing: Int = 10

    /// Whether to use the ZStack StackLayout variants.
    public var usesZStackLayout: Bool = false

    /// The alignment of content inside a ``ZStack``.
    /// Only gets used when ``usesZStackLayout`` is `true`.
    public var zStackContentAlignment: Alignment = .center

    /// The layout that an enclosing container has published for the children of
    /// grouping containers such as ``ForEach`` and ``Group``.
    ///
    /// Stored directly for the same reason as the stack layout properties: it's
    /// read once and cleared once per stack layout.
    var containerChildLayout: (any ContainerChildLayout)?

    /// Backing storage for observable subscript
    ///
    /// Typed as `AnyObject` rather than `any ObservableObject` so that classes
    /// declared with the standard library's `@Observable` can live here too;
    /// they're tracked through `Observation` instead of through
    /// ``ObservableObject/didChange``. See the `observable` subscript below.
    private var observableObjects: [ObjectIdentifier: AnyObject]

    /// Gets an environment value given an environment key's metatype.
    ///
    /// - Parameter key: The type of the key.
    /// - Returns: The environment value associated with `key`, or the key's
    ///   default value if it hasn't been set in the environment yet.
    public subscript<T: EnvironmentKey>(_ key: T.Type) -> T.Value {
        get {
            values[ObjectIdentifier(T.self), default: T.defaultValue] as! T.Value
        }
        set {
            values[ObjectIdentifier(T.self)] = newValue
        }
    }

    /// Gets or sets the object of a given type held in the environment.
    ///
    /// Objects are keyed by their exact type, which is how
    /// ``Environment/init(_:)`` finds them again.
    ///
    /// The key is only required to be a class, not an ``ObservableObject``, so
    /// that a class declared with the standard library's `@Observable` can be
    /// put in the environment as well. Neither kind of object is subscribed to
    /// here: an ``ObservableObject`` is observed by whichever view owns it,
    /// and an `@Observable` object invalidates the views that read its
    /// properties through ``ViewObservationTracking``.
    ///
    /// - Parameter key: The type of the object.
    /// - Returns: The object of that type in the environment, or `nil` if
    ///   there isn't one.
    public subscript<T: AnyObject>(observable key: T.Type) -> T? {
        get {
            guard let value = observableObjects[ObjectIdentifier(T.self)] as? T? else {
                let message =
                    "EnvironmentValues type mismatch: value for key '\(T.self).self' doesn't match expected type '\(T.self)'"
                logger.critical("\(message)")
                fatalError(message)
            }
            return value
        }
        set {
            observableObjects[ObjectIdentifier(T.self)] = newValue
        }
    }

    /// Looks an object up by its exact type without a generic constraint.
    ///
    /// ``Environment``'s `Value` is unconstrained (it's a key path's value
    /// type in the common case), so an ``Environment`` holding an object can't
    /// reach ``subscript(observable:)`` — which needs `Value: AnyObject` —
    /// without first opening an existential metatype. This does the same
    /// lookup with no constraint at all so that it can.
    ///
    /// - Parameter type: The type the object was stored under.
    /// - Returns: The object stored under `type`, or `nil` if there isn't one.
    func observableObject(ofType type: Any.Type) -> AnyObject? {
        observableObjects[ObjectIdentifier(type)]
    }

    /// Brings the current window forward.
    ///
    /// This is not guaranteed to always bring the window to the top (due
    /// to focus stealing prevention).
    @MainActor
    func bringWindowForward() {
        func activate<Backend: BaseAppBackend>(with backend: Backend) {
            backend.activate(window: window as! Backend.Window)
        }
        activate(with: backend)
    }

    /// The parts of the environment that are fixed for the app's lifetime.
    ///
    /// Every view graph node copies the environment several times per layout
    /// computation, so the struct's width and its number of reference-counted
    /// fields sit directly on the framework's hottest path. ``backend`` is an
    /// existential — five words, and a retain/release on every copy — and
    /// ``supportedDatePickerStyles`` is an array, costing another. Neither can
    /// change once the environment exists, so both live behind a single shared
    /// immutable reference instead: a copy of ``EnvironmentValues`` then moves
    /// five fewer words and performs one retain/release where it used to do
    /// two.
    ///
    /// This is purely a representation change. Both values are still read
    /// through properties of the same name and type.
    final class Constants {
        /// The backend in use.
        let backend: any BaseAppBackend
        /// The display styles supported by ``DatePicker``.
        let supportedDatePickerStyles: [DatePickerStyle]

        init(
            backend: any BaseAppBackend,
            supportedDatePickerStyles: [DatePickerStyle]
        ) {
            self.backend = backend
            self.supportedDatePickerStyles = supportedDatePickerStyles
        }
    }

    /// The environment's lifetime-constant values. See ``Constants``.
    private let constants: Constants

    /// The backend in use.
    ///
    /// Mustn't change throughout the app's lifecycle.
    var backend: any BaseAppBackend { constants.backend }

    /// Presents an 'Open file' dialog fit for selecting a single file.
    ///
    /// Displays as a modal for the current window, or the entire app if
    /// accessed outside of a scene's view graph (in which case the backend
    /// can decide whether to make it an app modal, a standalone window, or a
    /// modal for a window of its choosing).
    ///
    /// - Important: GtkBackend, Gtk3Backend, and WinUIBackend will only
    ///   enable _either_ files or directories for selection, but won't
    ///   enable both types in a single dialog.
    @MainActor
    @available(tvOS, unavailable, message: "tvOS does not provide file system access")
    public var chooseFile: PresentSingleFileOpenDialogAction {
        PresentSingleFileOpenDialogAction(
            backend: backend,
            window: MainActorBox(value: window)
        )
    }

    /// Presents a 'Save file' dialog fit for selecting a save destination.
    ///
    /// Displays as a modal for the current window, or the entire app if
    /// accessed outside of a scene's view graph (in which case the backend
    /// can decide whether to make it an app modal, a standalone window, or a
    /// window of its choosing).
    @MainActor
    public var chooseFileSaveDestination: PresentFileSaveDialogAction {
        PresentFileSaveDialogAction(
            backend: backend,
            window: MainActorBox(value: window)
        )
    }

    /// Presents an alert for the current window, or the entire app if accessed
    /// outside of a scene's view graph (in which case the backend can decide
    /// whether to make it an app modal, a standalone window, or a modal for a
    /// window of its choosing).
    @MainActor
    public var presentAlert: PresentAlertAction {
        PresentAlertAction(environment: self)
    }

    /// Opens a URL with the default application.
    ///
    /// May present an application picker if multiple applications are registered
    /// for the given URL protocol.
    ///
    /// `nil` on platforms that don't support opening external URLS (none at the
    /// moment).
    @MainActor
    public var openURL: OpenURLAction {
        OpenURLAction(backend: backend)
    }

    /// Opens a window with the specified ID.
    @MainActor
    public var openWindow: OpenWindowAction {
        OpenWindowAction(environment: self)
    }

    /// Closes the enclosing window.
    @MainActor
    public var dismissWindow: DismissWindowAction {
        DismissWindowAction(
            backend: backend,
            window: MainActorBox(value: window)
        )
    }

    /// Reveals a file in the system's file manager.
    ///
    /// This opens the file's enclosing directory and highlights the file.
    ///
    /// `nil` on platforms that don't support revealing files, e.g. iOS.
    @MainActor
    public var revealFile: RevealFileAction? {
        RevealFileAction(backend: backend)
    }

    /// Whether the backend can have multiple windows open at once. Mobile
    /// backends generally can't.
    @MainActor
    public var supportsMultipleWindows: Bool {
        backend.supportsMultipleWindows
    }

    /// The display styles supported by ``DatePicker``. ``datePickerStyle`` must be one of these.
    ///
    /// Computed rather than stored so that it doesn't widen the environment or
    /// add a retain to every copy of it; see ``Constants``. Still immutable,
    /// exactly as when it was a `let`.
    public var supportedDatePickerStyles: [DatePickerStyle] {
        constants.supportedDatePickerStyles
    }

    /// Checks whether a picker style is supported by the current backend.
    @MainActor
    public var isPickerStyleSupported: PickerSupportedAction {
        PickerSupportedAction(backend: backend)
    }

    /// Creates the default environment.
    ///
    /// - Parameters:
    ///   - backend: The app's backend.
    @_spi(Backends) public init<Backend: BaseAppBackend>(backend: Backend) {
        onResize = { _ in }
        values = [:]
        observableObjects = [:]

        let supportedDatePickerStyles: [DatePickerStyle]
        if let backend = backend as? any BackendFeatures.DatePickers {
            supportedDatePickerStyles = backend.supportedDatePickerStyles
        } else {
            supportedDatePickerStyles = [.automatic]
        }

        constants = Constants(
            backend: backend,
            supportedDatePickerStyles: supportedDatePickerStyles
        )
    }

    /// Returns a copy of the environment with the specified property set to the
    /// provided new value.
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the property to set.
    ///   - newValue: The new value of the property.
    /// - Returns: A copy of the environment with the specified property set to
    ///   `newValue`.
    public func with<T>(_ keyPath: WritableKeyPath<Self, T>, _ newValue: T) -> Self {
        var environment = self
        environment[keyPath: keyPath] = newValue
        return environment
    }

    /// Returns a copy with the stack layout parameters replaced.
    ///
    /// A stack sets all three on every layout computation and every commit.
    /// Chaining `with(_:_:)` would copy the environment once per property, and
    /// the environment is a large struct full of reference-counted fields.
    ///
    /// - Parameters:
    ///   - orientation: The stack's orientation.
    ///   - alignment: The stack's alignment.
    ///   - spacing: The stack's spacing.
    /// - Returns: A copy of the environment with the stack layout parameters
    ///   replaced.
    func withStackLayout(
        orientation: Orientation,
        alignment: StackAlignment,
        spacing: Int
    ) -> Self {
        var environment = self
        environment.layoutOrientation = orientation
        environment.layoutAlignment = alignment
        environment.layoutSpacing = spacing
        environment.usesZStackLayout = false
        return environment
    }
}

extension EnvironmentValues {
    /// The app storage provider to use for `@AppStorage` property wrappers.
    @Entry public var appStorageProvider: any AppStorageProvider = DefaultAppStorageProvider()

    /// The current font.
    @Entry public var font: Font = .body

    /// A font overlay storing font modifications.
    ///
    /// If these conflict with the font's internal overlay, these win out.
    ///
    /// We keep this separate overlay for modifiers because we want modifiers to
    /// be persisted even if the developer sets a custom font further down the
    /// view hierarchy.
    @Entry internal var fontOverlay = Font.Overlay()

    /// How lines should be aligned relative to each other when line wrapped.
    @Entry public var multilineTextAlignment: HorizontalAlignment = .leading

    /// Whether to override the case of displayed ``Text`` views.
    ///
    /// `nil` displays the text without any case changes.
    @Entry public var textCase: Text.Case?

    /// The current color scheme of the current view scope.
    @Entry public var colorScheme: ColorScheme = .light

    /// The foreground color.
    ///
    /// `nil` means that the default foreground color of the current color scheme
    /// should be used.
    @Entry public var foregroundColor: Color?

    /// Called when a text field gets submitted (usually due to the user
    /// pressing Enter/Return).
    @Entry public var onSubmit: (@MainActor @Sendable () -> Void)?

    /// The scale factor of the current window.
    @Entry public var windowScaleFactor: Double = 1

    /// The type of input that text fields represent.
    ///
    /// This affects autocomplete suggestions, and on devices with no physical keyboard, which
    /// on-screen keyboard to use.
    ///
    /// - Warning: Do not use this in place of validation, even if you only plan on supporting
    ///   mobile devices, as this does not restrict copy-paste and many mobile devices support
    ///   Bluetooth keyboards.
    @Entry public var textContentType: TextContentType = .text

    /// The way that scrollable content interacts with the software keyboard.
    @Entry public var scrollDismissesKeyboardMode: ScrollDismissesKeyboardMode = .automatic

    /// The style of list to use.
    @Entry @_spi(Backends) public var listStyle: ListStyle = .default

    /// The style of toggle to use.
    @Entry public var toggleStyle: ToggleStyle = .button

    /// Whether the text should be selectable.
    ///
    /// Set by ``View/textSelectionEnabled(_:)``.
    @Entry public var isTextSelectionEnabled: Bool = false

    /// The resizing behaviour of windows.
    ///
    /// Set by ``Window/windowResizability(_:)->Scene``.
    @Entry internal var windowResizability: WindowResizability = .automatic

    /// The default launch behavior of windows.
    ///
    /// Set by ``Window/defaultLaunchBehavior(_:)->Scene``.
    @Entry internal var defaultLaunchBehavior: SceneLaunchBehavior = .automatic

    /// The default size of windows.
    ///
    /// Defaults to 900x450.
    ///
    /// Set by ``Window/defaultSize(width:height:)->Scene``.
    @Entry internal var defaultWindowSize: SIMD2<Int> = SIMD2(900, 450)

    /// The menu ordering to use.
    @Entry public var menuOrder: MenuOrder = .automatic

    /// Backing store for ``EnvironmentValues/openWindowFunctionsByID``.
    /// Used to resolve "non-sendable type" warnings in Swift 5 and errors in Swift 6 language mode.
    @Entry private var openWindowFunctionsByIDStore = UncheckedSendable(
        wrappedValue: Box<[String: @MainActor () -> Void]>([:])
    )

    /// A mapping of window IDs to functions that open the corresponding windows.
    internal var openWindowFunctionsByID: Box<[String: @MainActor () -> Void]> {
        get {
            openWindowFunctionsByIDStore.wrappedValue
        }
        set {
            openWindowFunctionsByIDStore.wrappedValue = newValue
        }
    }

    /// The app's lifecycle phase.
    ///
    /// Unlike in SwiftUI, where the app's lifecycle phase can only be accessed
    /// by using `@Environment(\.scenePhase)` directly on the ``App`` struct, this
    /// environment value can be accessed from anywhere within the application.
    @Entry public package(set) var appPhase: AppPhase = .active

    /// The current scene's lifecycle phase.
    ///
    /// - Important: Unlike SwiftUI, this environment value cannot be accessed from
    ///   outside a scene. If you need to access the phase of the entire application,
    ///   use ``appPhase`` instead.
    public package(set) var scenePhase: ScenePhase {
        get {
            guard let phase = self[__Key_scenePhase.self] else {
                if window != nil {
                    // If there's a window but no scenePhase, we assume that the
                    // backend is actively trying to _set_ the scene phase; return
                    // a dummy value to prevent a crash.
                    return .inactive
                }

                fatalError(
                    """
                    'scenePhase' accessed from outside a scene (most likely \
                    with an @Environment property on the App struct); you \
                    probably meant to use 'appPhase' instead
                    """
                )
            }
            return phase
        }
        set { self[__Key_scenePhase.self] = newValue }
    }
    private struct __Key_scenePhase: EnvironmentKey {
        static let defaultValue: ScenePhase? = nil
    }

    /// Backing store for ``EnvironmentValues/window``.
    /// Used to resolve "non-sendable type" warnings in Swift 5 and errors in Swift 6 language mode.
    @Entry private var windowStore = UncheckedSendable<Any?>(wrappedValue: nil)

    /// The backend's representation of the window that the current view is
    /// in, if any.
    ///
    /// This is a very internal detail that should never get exposed to users.
    @_spi(Backends) public var window: Any? {
        get {
            windowStore.wrappedValue
        }
        set {
            windowStore.wrappedValue = newValue
        }
    }

    /// Backing store for ``EnvironmentValues/sheet``.
    /// Used to resolve "non-sendable type" warnings in Swift 5 and errors in Swift 6 language mode.
    @Entry private var sheetStore = UncheckedSendable<Any?>(wrappedValue: nil)

    /// The backend's representation of the sheet that the current view is
    /// in, if any.
    ///
    /// This is a very internal detail that should never get exposed to users.
    @_spi(Backends) public var sheet: Any? {
        get {
            sheetStore.wrappedValue
        }
        set {
            sheetStore.wrappedValue = newValue
        }
    }

    /// The current calendar that views should use when handling dates.
    @Entry public var calendar: Calendar = .current

    /// The current time zone that views should use when handling dates.
    @Entry public var timeZone: TimeZone = .current

    /// The current locale.
    @Entry public var locale: Locale = .current

    /// The display style used by ``Picker``.
    @Entry public var pickerStyle: any PickerStyle = .automatic

    /// The display style used by ``DatePicker``.
    @Entry public var datePickerStyle: DatePickerStyle = .automatic

    /// Whether user interaction is enabled.
    ///
    /// Set by ``View/disabled(_:)``.
    @Entry public var isEnabled: Bool = true

    /// The number of lines text can occupy and whether to reserve that space.
    @Entry public var lineLimitSettings: LineLimit?

    /// The maximum number of lines that text can occupy in a view.
    public var lineLimit: Int? {
        lineLimitSettings?.limit
    }

    /// Whether the current device has a circular screen. Primarily Android smart watches.
    @Entry public var isCircularScreen: Bool = false

    /// The display style used by ``Button``.
    ///
    /// Set this with ``View/buttonStyle(_:)`` rather than mutating the
    /// environment directly.
    @Entry public var buttonStyle: (any ButtonStyle)?

    /// The default button style as declared by the backend.
    @MainActor
    public var defaultButtonStyle: any ButtonStyle {
        backend.defaultButtonStyle()
    }

    /// The resolved ``ButtonStyle``. Either ``buttonStyle``, or ``defaultButtonStyle`` if nil.
    ///
    /// ``DefaultButtonStyle`` resolves to ``defaultButtonStyle`` too, since
    /// asking for the automatic style is asking for whatever the backend
    /// would have drawn anyway.
    @MainActor
    public var resolvedButtonStyle: any ButtonStyle {
        guard let buttonStyle, !(buttonStyle is DefaultButtonStyle) else {
            return defaultButtonStyle
        }
        return buttonStyle
    }

    /// The amount of padding that the current backend applies to the labels of buttons with the current ``ButtonStyle``.
    @MainActor
    public var buttonPadding: SIMD2<Int> {
        backend.buttonPadding(in: self)
    }

    /// The device class of the current device.
    @MainActor
    public var deviceClass: DeviceClass { backend.deviceClass }

    /// All observers set by ``View/focused(_:)`` in the environment.
    @Entry @_spi(Backends) public var widgetFocusObservers: [WidgetFocusObserver] = []

    /// A value used to make widgets programmatically gain or lose focus.
    @Entry @_spi(Backends) public var focusOverride: Focus?

    /// Whether to highlight a focused widget.
    @Entry public var focusEffectDisabled: Bool = false
}

extension EnvironmentValues {
    func applyingTextTransforms(to string: String) -> String {
        var string = string

        switch textCase {
            case .lowercase: string = string.lowercased(with: locale)
            case .uppercase: string = string.uppercased(with: locale)
            case nil: break
        }

        return string
    }
}

/// A key that can be used to extend the environment with new properties.
public protocol EnvironmentKey<Value> {
    /// The type of value the key can hold.
    associatedtype Value
    /// The default value for the key.
    static var defaultValue: Value { get }
}
