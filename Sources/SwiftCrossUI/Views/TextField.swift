import Foundation

/// A control that displays an editable text interface.
public struct TextField: ElementaryView, View {
    /// The ideal width of a `TextField`.
    private static let idealWidth: Double = 100

    /// The label to show when the field is empty.
    private var placeholder: String
    /// The field's content.
    @Binding private var text: String
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

    /// Creates an editable text field with a given placeholder.
    ///
    /// - Parameters:
    ///   - placeholder: The label to show when the field is empty.
    ///   - text: The field's content.
    public init(_ placeholder: String = "", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
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

        // The parsed values get compared via their formatted output because
        // `ParseableFormatStyle` doesn't require its input to be `Equatable`.
        self.representsBoundValue = { string in
            guard let parsed = try? strategy.parse(string) else {
                return false
            }
            return format.format(parsed) == format.format(value.wrappedValue)
        }
    }

    func asWidget<Backend: BaseAppBackend>(backend: Backend) -> Backend.Widget {
        return backend.createTextField()
    }

    func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        let naturalHeight = backend.naturalSize(of: widget).y
        let size = ViewSize(
            proposedSize.width ?? Self.idealWidth,
            Double(naturalHeight)
        )

        // TODO: Allow backends to set their own ideal text field width
        return ViewLayoutResult.leafView(size: size)
    }

    func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        backend.updateTextField(
            widget,
            placeholder: placeholder,
            environment: environment,
            onChange: { newValue in
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
            },
            onSubmit: environment.onSubmit ?? {}
        )

        let text = text
        let content = backend.getContent(ofTextField: widget)
        let contentIsUpToDate = representsBoundValue?(content) ?? false
        if text != content && !contentIsUpToDate {
            backend.setContent(ofTextField: widget, to: text)
        }

        backend.setSize(of: widget, to: layout.size.vector)
    }
}
