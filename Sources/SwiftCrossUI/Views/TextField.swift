import Foundation

/// A control that displays an editable text interface.
public struct TextField: ElementaryView, View {
    /// The ideal width of a `TextField`.
    private static let idealWidth: Double = 100

    /// The label to show when the field is empty.
    private var placeholder: String
    /// The field's content.
    @Binding private var text: String
    /// The axis the field grows along.
    ///
    /// A horizontal field is a single line of text. A vertical one wraps and
    /// grows downwards as the user types; see ``init(_:text:prompt:axis:)`` for
    /// what that costs.
    private var axis: Axis = .horizontal
    /// Whether a string that the user has typed already represents the bound
    /// value, in which case the field's content is left exactly as they typed
    /// it instead of being replaced with the formatted value.
    ///
    /// Without this, a field bound to a number reformats itself on every
    /// keystroke, which makes intermediate states impossible to type: a
    /// trailing decimal point would be parsed away and then written back out
    /// as soon as it was typed. Only set by the format style initializer;
    /// `nil` for the initializers that bind straight to a string.
    private var representsBoundValue: ((String) -> Bool)? = nil

    /// A value snapshot distinguishes an incomplete native edit from a model
    /// change. Its box is node-local and does not publish during layout.
    private struct DraftState {
        let value = Box<FormattedFieldValue?>(nil)
    }
    @State private var draftState = DraftState()
    private var captureFormattedValue: (() -> FormattedFieldValue?)? = nil
    private var canParseInput: ((String) -> Bool)? = nil

    /// Creates an editable text field.
    ///
    /// The title is what the field shows while it's empty, unless a `prompt` is
    /// given, in which case the prompt is shown instead:
    ///
    /// ```swift
    /// TextField("Description", text: $description, prompt: Text("Optional"))
    /// ```
    ///
    /// A field with a `.vertical` axis wraps its content and grows downwards as
    /// the user types, instead of scrolling a single line sideways:
    ///
    /// ```swift
    /// TextField("Description", text: $description, axis: .vertical)
    /// ```
    ///
    /// - Note: A vertical field is backed by the same multi-line text editor
    ///   widget that ``TextEditor`` uses, which costs it two things that the
    ///   single-line field has: no backend can show a placeholder in one, so
    ///   `title` and `prompt` are not displayed, and none of them report
    ///   submission, so ``SwiftCrossUI/View/onSubmit(_:)`` never fires for it.
    ///   ``SwiftCrossUI/View/lineLimit(_:)-(ClosedRange<Int>)`` doesn't bound
    ///   its height either; it grows to fit whatever it holds.
    ///
    /// - Important: The axis is fixed for as long as the field is on screen.
    ///   SwiftCrossUI creates a view's widget once and updates it in place, and
    ///   a single-line field and a multi-line editor are different widgets, so
    ///   `axis` has to be a constant at each call site rather than something
    ///   computed from state that changes.
    ///
    /// - Parameters:
    ///   - placeholder: The label to show when the field is empty, and the
    ///     field's accessible name.
    ///   - text: The field's content.
    ///   - prompt: Guidance shown in place of `placeholder` while the field is
    ///     empty.
    ///   - axis: The axis the field grows along.
    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        prompt: Text? = nil,
        axis: Axis = .horizontal
    ) {
        self.placeholder = prompt?.string ?? placeholder
        self._text = text
        self.axis = axis
    }

    /// Creates an editable text field with a given placeholder.
    @available(*, deprecated, renamed: "init(_:text:)")
    public init(_ placeholder: String = "", _ value: Binding<String>? = nil) {
        self.placeholder = placeholder
        var dummy = ""
        self._text = value ?? Binding(get: { dummy }, set: { dummy = $0 })
    }

    /// Creates an editable text field bound to a binary integer value.
    ///
    /// The field's content is kept in sync with `value` via simple string
    /// conversion. When the user enters text that cannot be parsed as the
    /// target integer type, the binding is not updated (the previous value
    /// is preserved), mirroring the behaviour of SwiftUI's
    /// `TextField(_:value:formatter:)` when the formatter fails.
    ///
    /// - Parameters:
    ///   - placeholder: The label to show when the field is empty.
    ///   - value: A binding to the integer value to edit.
    public init<V: BinaryInteger & LosslessStringConvertible>(
        _ placeholder: String = "",
        value: Binding<V>
    ) {
        self.placeholder = placeholder
        self._text = Binding(
            get: { String(value.wrappedValue) },
            set: { newString in
                if let parsed = V(newString), parsed != value.wrappedValue {
                    value.wrappedValue = parsed
                }
            }
        )
    }

    /// Creates an editable text field bound to a binary floating-point value.
    ///
    /// The field's content is kept in sync with `value` via simple string
    /// conversion. When the user enters text that cannot be parsed as the
    /// target floating-point type, the binding is not updated (the previous
    /// value is preserved), mirroring the behaviour of SwiftUI's
    /// `TextField(_:value:formatter:)` when the formatter fails.
    ///
    /// - Parameters:
    ///   - placeholder: The label to show when the field is empty.
    ///   - value: A binding to the floating-point value to edit.
    public init<V: BinaryFloatingPoint & LosslessStringConvertible>(
        _ placeholder: String = "",
        value: Binding<V>
    ) {
        self.placeholder = placeholder
        self._text = Binding(
            get: { String(value.wrappedValue) },
            set: { newString in
                if let parsed = V(newString), parsed != value.wrappedValue {
                    value.wrappedValue = parsed
                }
            }
        )
    }

    /// Creates an editable text field bound to a value that a format style
    /// knows how to display and parse.
    ///
    /// The format style comes from Foundation, so all of the standard
    /// parseable styles work exactly as they do in SwiftUI.
    ///
    /// ```swift
    /// TextField("", value: $diameter, format: .number)
    /// TextField("", value: $cover, format: .number.precision(.fractionLength(1)))
    /// ```
    ///
    /// The field displays `format.format(value)`, and each edit is fed back
    /// through `format.parseStrategy`. When the user's text can't be parsed
    /// (which includes every intermediate state along the way to a valid
    /// value, such as a lone minus sign) the binding is left untouched,
    /// mirroring the behaviour of SwiftUI's
    /// `TextField(_:value:formatter:)` when its formatter fails.
    ///
    /// For `Equatable` value types, incomplete native edits also survive
    /// layout and body updates while the bound value and format are unchanged.
    /// A changed value or format reconciles the field with its binding. This
    /// does not add submission or end-editing normalization. Other input types
    /// retain the parsed/formatted-output comparison described above.
    ///
    /// - Parameters:
    ///   - placeholder: The label to show when the field is empty.
    ///   - value: A binding to the value to edit.
    ///   - format: The format style used to display and parse the value.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *)
    public init<F: ParseableFormatStyle>(
        _ placeholder: String = "",
        value: Binding<F.FormatInput>,
        format: F
    ) where F.FormatOutput == String {
        self.placeholder = placeholder

        // Resolved once so that the binding captures the strategy rather than
        // rebuilding it on every keystroke.
        let strategy = format.parseStrategy
        self._text = Binding(
            get: { format.format(value.wrappedValue) },
            set: { newString in
                guard let parsed = try? strategy.parse(newString) else {
                    return
                }
                value.wrappedValue = parsed
            }
        )

        self.captureFormattedValue = {
            FormattedFieldValue(value.wrappedValue, format: AnyHashable(format))
        }
        self.canParseInput = { (try? strategy.parse($0)) != nil }

        // Exact equality prevents a real model change from being hidden by a
        // rounding format. Unconstrained inputs retain the original fallback.
        self.representsBoundValue = { string in
            guard let parsed = try? strategy.parse(string) else {
                return false
            }
            if let parsed = parsed as? any Equatable {
                return formattedFieldValuesEqual(parsed, value.wrappedValue)
            }
            return format.format(parsed) == format.format(value.wrappedValue)
        }
    }

    func asWidget<Backend: BaseAppBackend>(backend: Backend) -> Backend.Widget {
        switch axis {
            case .horizontal:
                return backend.createTextField()
            case .vertical:
                return backend.createTextEditor()
        }
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        guard axis == .horizontal else {
            return growingLayout(
                widget,
                proposedSize: proposedSize,
                environment: environment,
                backend: backend
            )
        }

        let naturalHeight = backend.naturalSize(of: widget).y
        let size = ViewSize(
            proposedSize.width ?? Self.idealWidth,
            Double(naturalHeight)
        )

        // TODO: Allow backends to set their own ideal text field width
        return ViewLayoutResult
            .leafView(size: size)
            .with(\.isNeverFocusable, false)
    }

    /// The layout of a field that grows along the vertical axis.
    ///
    /// The field takes the width it's offered and asks the backend how tall its
    /// content is at that width, so that it grows a line at a time as the user
    /// types. This mirrors ``TextEditor``'s layout, because it's the same
    /// widget underneath.
    ///
    /// - Parameters:
    ///   - widget: The field's underlying widget.
    ///   - proposedSize: The size suggested by the parent container.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    /// - Returns: The field's computed layout.
    private func growingLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // Resolved once so that the binding isn't read repeatedly.
        let content = text
        let width = proposedSize.width ?? Self.idealWidth

        // An infinite proposal means the same thing to text as an unspecified
        // one, and the width is clamped positive for the same reason ``Text``
        // clamps it: backends measure a non-positive width poorly.
        let contentSize = backend.size(
            of: content,
            whenDisplayedIn: widget,
            proposedWidth: width == .infinity ? nil : max(1, LayoutSystem.roundSize(width)),
            proposedHeight: nil,
            environment: environment
        )
        let size = ViewSize(
            max(width, Double(contentSize.x)),
            max(Double(contentSize.y), Double(backend.naturalSize(of: widget).y))
        )
        return ViewLayoutResult.leafView(size: size)
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        guard axis == .horizontal else {
            commitGrowingField(
                widget,
                layout: layout,
                environment: environment,
                backend: backend
            )
            return
        }

        backend.updateTextField(
            widget,
            placeholder: placeholder,
            environment: environment,
            onChange: { newValue in
                let previousValue = captureFormattedValue?()
                #if DEBUG
                    // We perform this check in debug mode to catch backends that cause
                    // unnecessary binding writes, but avoid doing so in release mode
                    // because comparing text may often be more expensive than just
                    // avoiding the additional write at the backend level. These
                    // additional writes are often the result of the handler being
                    // triggered when we call backend.setContent(ofTextField:to:)
                    if self.text == newValue {
                        logger.warning(
                            """
                            Unnecessary write to text Binding of TextField detected, \
                            please open an issue at \(Meta.issueReportingURL) \
                            so we can fix it for \(type(of: backend)).
                            """
                        )
                    }
                #endif

                self.text = newValue
                rememberEdit(newValue, previousValue: previousValue)
            },
            onSubmit: environment.onSubmit ?? {}
        )

        let text = text
        let content = backend.getContent(ofTextField: widget)
        if shouldReplaceContent(content, with: text) {
            backend.setContent(ofTextField: widget, to: text)
        }

        backend.setSize(of: widget, to: layout.size.vector)
    }

    /// Commits the layout of a field that grows along the vertical axis.
    ///
    /// The placeholder and the submit handler are dropped here: the backends'
    /// multi-line editors take neither. See ``init(_:text:prompt:axis:)``.
    ///
    /// - Parameters:
    ///   - widget: The field's underlying widget.
    ///   - layout: The layout to apply.
    ///   - environment: The current environment.
    ///   - backend: The app's backend.
    private func commitGrowingField<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.updateTextEditor(widget, environment: environment) { newValue in
            let previousValue = captureFormattedValue?()
            #if DEBUG
                // Debug-only for the reason spelled out in `commit`.
                if self.text == newValue {
                    logger.warning(
                        """
                        Unnecessary write to text Binding of TextField detected, \
                        please open an issue at \(Meta.issueReportingURL) \
                        so we can fix it for \(type(of: backend)).
                        """
                    )
                }
            #endif

            self.text = newValue
            rememberEdit(newValue, previousValue: previousValue)
        }

        let text = text
        let content = backend.getContent(ofTextEditor: widget)
        if shouldReplaceContent(content, with: text) {
            backend.setContent(ofTextEditor: widget, to: text)
        }

        backend.setSize(of: widget, to: layout.size.vector)
    }

    /// Native edits can arrive again before the next layout. Acknowledge the
    /// result immediately, but never bless a parsed value rejected or changed
    /// by the binding's setter. Incomplete input is retained only if that
    /// setter left the bound value unchanged.
    private func rememberEdit(_ content: String, previousValue: FormattedFieldValue?) {
        guard let current = captureFormattedValue?() else { return }
        if representsBoundValue?(content) == true
            || (canParseInput?(content) == false && previousValue?.matches(current) == true)
        {
            draftState.value.value = current
        } else {
            draftState.value.value = nil
        }
    }

    private func shouldReplaceContent(_ content: String, with formatted: String) -> Bool {
        let current = captureFormattedValue?()
        let previous = draftState.value.value
        // Record before writing native content: some backends synchronously
        // report programmatic text changes through their current callback.
        draftState.value.value = current
        let unchanged = current.map { previous?.matches($0) == true } ?? false
        let formatChanged = current.map { current in
            previous.map { $0.format != current.format } ?? false
        } ?? false
        return content != formatted && !unchanged
            && (formatChanged || representsBoundValue?(content) != true)
    }
}

/// Retains a comparable value, rather than just its possibly rounded display.
/// A mutable reference cannot serve as a historical snapshot; unsupported
/// inputs conservatively use the pre-existing reconciliation path.
private struct FormattedFieldValue {
    let value: any Equatable
    let format: AnyHashable

    init?<Value>(_ value: Value, format: AnyHashable) {
        guard !(type(of: value) is AnyClass), !(type(of: format.base) is AnyClass),
            let value = value as? any Equatable
        else {
            return nil
        }
        self.value = value
        self.format = format
    }

    func matches(_ other: Self) -> Bool {
        format == other.format && formattedFieldValuesEqual(value, other.value)
    }
}

private func formattedFieldValuesEqual<Value: Equatable>(_ lhs: Value, _ rhs: Any) -> Bool {
    guard let rhs = rhs as? Value else { return false }
    return lhs == rhs
}
