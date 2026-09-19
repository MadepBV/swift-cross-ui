import Foundation

/// A view the displays text.
///
/// ``Text`` truncates its content to fit within its proposed size. To wrap
/// without truncation, put the ``Text`` (or its enclosing view hierarchy) into
/// an ideal height context such as a ``ScrollView``. Alternatively, use
/// ``View/fixedSize(horizontal:vertical:)`` with `horizontal` set to false and
/// `vertical` set to true, but be aware that this may lead to unintuitive
/// minimum sizing behaviour when used within a window. Often when developers
/// use ``View/fixedSize()`` on text, what they really need is a ``ScrollView``.
///
/// To avoid wrapping and truncation entirely, use ``View/fixedSize()``.
///
/// ## Technical notes
///
/// The reason that ``Text`` truncates its content to fit its proposed size is
/// that SwiftCrossUI's layout system behaves rather unintuitively with views
/// that trade off width for height. The layout system used to support this
/// behaviour well, but when overhauling the layout system with performance in
/// mind, we discovered that it's not possible to handle minimum view sizing in
/// the intuitive way that we were, without a large performance cost or layout
/// system complexity cost.
///
/// With the current system, windows determine the minimum size of their content
/// by proposing a size of 0x0. A text view that doesn't truncate its content
/// would take on a width of 0 and then lay out each character on a new line (as
/// that's what most UI frameworks do when text is given a small width). This
/// leads to the window thinking that its minimum height is
/// `characterCount * lineHeight`, even though when given a width larger than
/// zero, the text view would be shorter than this 'minimum height'. The
/// underlying cause is the assumption that 'minimum size' is a sensible notion
/// for every view. A text view without truncation doesn't have a
/// 'minimum size'; are we minimizing width? height? width + height? area?
///
/// SwiftCrossUI's old layout system separated the concept of minimum size into
/// 'minimum width for current height', and 'minimum height for current width'.
/// This led to much more intuitive window sizing behaviour. If you had
/// non-truncating text inside a window, and resized the width of the window
/// such that the height of the text became taller than the window, then the
/// window would become taller, and if you resized the height of the window then
/// you'd reach the window's minimum height before the text could overflow the
/// window horizontally. Unfortunately this required a lot of book-keeping, and
/// was deemed to be unfeasible to do without significantly hurting performance
/// due to all the layout assumptions that we'd have to drop from our stack
/// layout algorithm.
///
/// ## Styling
///
/// ``Text`` carries its own styling attributes, exactly as SwiftUI's does.
/// ``font(_:)``, ``fontWeight(_:)``, ``foregroundColor(_:)`` and friends are
/// declared on ``Text`` itself and return a ``Text``, so a styled run of text
/// stays a ``Text`` and can be handed to APIs that demand one — most
/// importantly ``GraphicsContext/draw(_:at:anchor:)``.
///
/// ```swift
/// context.draw(
///     Text("N12")
///         .font(.system(size: 9.0))
///         .fontWeight(.semibold)
///         .foregroundColor(.blue),
///     at: CGPoint(x: 20.0, y: 8.0)
/// )
/// ```
///
/// The same attributes apply when the text is rendered as an ordinary view;
/// they are folded into the environment that the text view is measured and
/// drawn with, so they override whatever the surrounding hierarchy set, just
/// like the equivalent ``View`` modifiers do.
///
/// ### Attributes that no backend honours yet
///
/// ``strikethrough(_:color:)``, ``underline(_:color:)`` and
/// ``monospacedDigit()`` are accepted and carried on the value, but no
/// SwiftCrossUI backend exposes a text decoration axis or a digit-width axis,
/// so they currently have no visible effect. They exist so that SwiftUI source
/// compiles unchanged, and so that there is somewhere for the styling to live
/// once a backend gains the capability.
///
/// The new layout system behaviour is in line with SwiftUI's layout behaviour.
public struct Text: Sendable {
    /// The string to be shown in the text view.
    public private(set) var string: String

    /// The styling attributes applied by ``Text``'s own modifiers.
    ///
    /// These are separate from the environment so that a styled ``Text``
    /// remains a ``Text``. See the type's documentation.
    var attributes = Attributes()

    /// Creates a new text view that displays a string.
    ///
    /// - Parameter string: The string to display.
    public init(_ string: String) {
        self.string = string
    }

    /// Creates a text view that displays a value formatted with a given
    /// format style.
    ///
    /// The format style comes from Foundation, so all of the standard
    /// styles work exactly as they do in SwiftUI.
    ///
    /// ```swift
    /// Text(diameter, format: .number.precision(.fractionLength(2)))
    /// Text(utilisation, format: .percent)
    /// Text(placedAt, format: .dateTime)
    /// ```
    ///
    /// The value is formatted eagerly, using the format style's own locale
    /// (which is the current locale unless the style says otherwise);
    /// SwiftCrossUI has no locale environment value to override it with.
    ///
    /// - Parameters:
    ///   - input: The value to display.
    ///   - format: The format style used to convert `input` into a string.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *)
    public init<F: FormatStyle>(_ input: F.FormatInput, format: F)
        where F.FormatInput: Equatable, F.FormatOutput == String
    {
        self.string = format.format(input)
    }
}

extension Text {
    /// The styling that a ``Text`` carries with it, as opposed to the styling
    /// it inherits from the environment.
    ///
    /// Attributes always win over the surrounding environment, matching
    /// SwiftUI, where `Text("a").font(.title)` inside a `.font(.body)`
    /// hierarchy renders as a title.
    struct Attributes: Hashable, Sendable {
        /// The font to draw the text with, if overridden.
        var font: Font?
        /// The font weight to draw the text with, if overridden.
        var weight: Font.Weight?
        /// The font design to draw the text with, if overridden.
        var design: Font.Design?
        /// Whether to use the font's emphasized variant.
        var isEmphasized = false
        /// Whether to italicize the text.
        var isItalic = false
        /// The color to draw the text with, if overridden.
        var foregroundColor: Color?
        /// Whether the text is struck through.
        ///
        /// - Note: Not honoured by any backend yet. See ``Text``.
        var isStruckThrough = false
        /// The color of the strikethrough line, if overridden.
        ///
        /// - Note: Not honoured by any backend yet. See ``Text``.
        var strikethroughColor: Color?
        /// Whether the text is underlined.
        ///
        /// - Note: Not honoured by any backend yet. See ``Text``.
        var isUnderlined = false
        /// The color of the underline, if overridden.
        ///
        /// - Note: Not honoured by any backend yet. See ``Text``.
        var underlineColor: Color?
        /// Whether the text uses fixed-width digits.
        ///
        /// - Note: Not honoured by any backend yet. See ``Text``.
        var usesMonospacedDigits = false

        /// Whether any attribute modifies the font that the text resolves to.
        var modifiesFont: Bool {
            font != nil || weight != nil || design != nil || isEmphasized
                || isItalic
        }

        /// Folds the font-related attributes into a base font.
        ///
        /// The attributes are baked into the font's own overlay rather than
        /// applied to an environment, so that a resolved font can travel on
        /// its own — which is what ``ResolvedText`` needs.
        ///
        /// - Parameter base: The font to start from, usually the one that the
        ///   surrounding environment supplies.
        /// - Returns: The font that the text should be drawn with, or `nil` if
        ///   the text neither overrides the font nor was given a base.
        func resolvedFont(basedOn base: Font?) -> Font? {
            let inherited = font ?? base
            guard modifiesFont else {
                return inherited
            }

            var resolved = inherited ?? .body
            resolved = resolved.weight(weight)
            resolved = resolved.design(design)
            if isEmphasized {
                resolved = resolved.emphasized()
            }
            if isItalic {
                resolved = resolved.italic()
            }
            return resolved
        }

        /// Folds the attributes into an environment.
        ///
        /// This is the path taken when a ``Text`` is rendered as a view. The
        /// environment's font overlay is used rather than the font's own
        /// overlay so that the attributes override anything the surrounding
        /// hierarchy set, matching the ``View`` modifiers of the same names.
        ///
        /// - Parameter environment: The environment to fold the attributes
        ///   into.
        /// - Returns: The updated environment.
        func apply(to environment: EnvironmentValues) -> EnvironmentValues {
            var environment = environment
            if let font {
                environment = environment.with(\.font, font)
            }
            if let weight {
                environment = environment.with(\.fontOverlay.weight, weight)
            }
            if let design {
                environment = environment.with(\.fontOverlay.design, design)
            }
            if isEmphasized {
                environment = environment.with(\.fontOverlay.emphasize, true)
            }
            if isItalic {
                environment = environment.with(\.fontOverlay.italicize, true)
            }
            if let foregroundColor {
                environment = environment.with(
                    \.foregroundColor,
                    foregroundColor
                )
            }
            return environment
        }
    }

    /// Returns a copy of this text with its attributes updated.
    ///
    /// - Parameter update: A closure that mutates the copy's attributes.
    /// - Returns: The updated text.
    private func withAttributes(
        _ update: (inout Attributes) -> Void
    ) -> Text {
        var text = self
        update(&text.attributes)
        return text
    }
}

// MARK: - Text-returning style modifiers

extension Text {
    /// Sets the font of this text.
    ///
    /// Unlike ``View/font(_:)``, this returns a ``Text``, so the styled text
    /// can still be passed to APIs that require one.
    ///
    /// - Parameter font: The font to use. `nil` clears any font previously set
    ///   on this text, letting it inherit from the environment again.
    /// - Returns: The styled text.
    public func font(_ font: Font?) -> Text {
        withAttributes { attributes in
            attributes.font = font
        }
    }

    /// Sets the font weight of this text.
    ///
    /// - Parameter weight: The weight to use. `nil` clears any weight
    ///   previously set on this text.
    /// - Returns: The styled text.
    public func fontWeight(_ weight: Font.Weight?) -> Text {
        withAttributes { attributes in
            attributes.weight = weight
        }
    }

    /// Sets the font design of this text.
    ///
    /// - Parameter design: The design to use. `nil` clears any design
    ///   previously set on this text.
    /// - Returns: The styled text.
    public func fontDesign(_ design: Font.Design?) -> Text {
        withAttributes { attributes in
            attributes.design = design
        }
    }

    /// Sets the color of this text.
    ///
    /// - Parameter color: The color to use. `nil` clears any color previously
    ///   set on this text, letting it inherit from the environment again.
    /// - Returns: The styled text.
    public func foregroundColor(_ color: Color?) -> Text {
        withAttributes { attributes in
            attributes.foregroundColor = color
        }
    }

    /// Applies a bold font weight to this text.
    ///
    /// As with ``View/emphasized()``, text using a ``Font/TextStyle``-based
    /// font takes on that style's emphasized weight rather than an
    /// unconditional ``Font/Weight/bold``.
    ///
    /// - Parameter isActive: Whether to embolden the text.
    /// - Returns: The styled text.
    public func bold(_ isActive: Bool = true) -> Text {
        withAttributes { attributes in
            attributes.isEmphasized = isActive
        }
    }

    /// Italicizes this text.
    ///
    /// - Parameter isActive: Whether to italicize the text.
    /// - Returns: The styled text.
    public func italic(_ isActive: Bool = true) -> Text {
        withAttributes { attributes in
            attributes.isItalic = isActive
        }
    }

    /// Applies a monospaced font design to this text.
    ///
    /// - Parameter isActive: Whether to use the monospaced design. `false`
    ///   restores the default design.
    /// - Returns: The styled text.
    public func monospaced(_ isActive: Bool = true) -> Text {
        withAttributes { attributes in
            attributes.design = isActive ? .monospaced : .default
        }
    }

    /// Asks for fixed-width digits while leaving other glyphs proportional.
    ///
    /// - Note: SwiftCrossUI's font model has no digit-width axis, so this
    ///   currently has no visible effect. It is deliberately *not* mapped onto
    ///   ``monospaced(_:)``, which would also change the letterforms and is a
    ///   visibly different design.
    ///
    /// - Returns: The styled text.
    public func monospacedDigit() -> Text {
        withAttributes { attributes in
            attributes.usesMonospacedDigits = true
        }
    }

    /// Strikes through this text.
    ///
    /// - Note: No SwiftCrossUI backend exposes a text decoration axis yet, so
    ///   this currently has no visible effect. See ``Text``.
    ///
    /// - Parameters:
    ///   - isActive: Whether to strike the text through.
    ///   - color: The color of the line. `nil` uses the text's own color.
    /// - Returns: The styled text.
    public func strikethrough(
        _ isActive: Bool = true,
        color: Color? = nil
    ) -> Text {
        withAttributes { attributes in
            attributes.isStruckThrough = isActive
            attributes.strikethroughColor = color
        }
    }

    /// Underlines this text.
    ///
    /// - Note: No SwiftCrossUI backend exposes a text decoration axis yet, so
    ///   this currently has no visible effect. See ``Text``.
    ///
    /// - Parameters:
    ///   - isActive: Whether to underline the text.
    ///   - color: The color of the line. `nil` uses the text's own color.
    /// - Returns: The styled text.
    public func underline(
        _ isActive: Bool = true,
        color: Color? = nil
    ) -> Text {
        withAttributes { attributes in
            attributes.isUnderlined = isActive
            attributes.underlineColor = color
        }
    }
}

extension Text: View {
    public var _asMenuItems: [MenuItem] {
        [.text(self)]
    }
}

extension Text: ElementaryView {
    public func asWidget<Backend: BaseAppBackend>(
        backend: Backend
    ) -> Backend.Widget {
        return backend.createTextView()
    }

    public func computeLayout<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        proposedSize: ProposedViewSize,
        environment: EnvironmentValues,
        backend: Backend
    ) -> ViewLayoutResult {
        // The text's own attributes override whatever the surrounding
        // hierarchy put in the environment, exactly as they do in SwiftUI.
        let environment = attributes.apply(to: environment)
        let transformedString = environment.applyingTextTransforms(to: string)

        // Gtk measures *through* the widget (it takes its Pango layout context
        // from it), so for those backends the text view has to hold the string
        // before the measurement below can be asked for. Backends that measure
        // with their own scratch element don't, and write the widget on commit
        // instead: a container asks a label for its size several times per pass,
        // and each of these is a backend call — a few thousand per pass for a
        // window of a few hundred labels. See
        // ``BackendFeatures/TextViews/measuresTextIndependentlyOfWidget``.
        if !backend.measuresTextIndependentlyOfWidget {
            BackendCallStatistics.record("text.updateTextView")
            backend
                .updateTextView(widget, content: transformedString, environment: environment)
        }

        // UI frameworks often handle the zero proposal specially. We want to
        // have standard text sizing behaviour so it's better for us to never
        // propose zero in either dimension and then fix up the resulting size
        // to match our expectations.
        //
        // Our desired behaviour is for a zero width proposal to result in at least
        // one line's worth of height (for a non-empty string). Furthermore, if
        // proposed more than one line's worth of height, then a zero width
        // proposal should result in height equivalent to however many lines are
        // required to put each character of the text on a new line (excluding
        // whitespace).
        //
        // A zero height proposal should result in the text using at least one
        // line of height (if non-empty).
        BackendCallStatistics.record("text.measure")
        var size = backend.size(
            of: transformedString,
            whenDisplayedIn: widget,
            proposedWidth: proposedSize.width.flatMap {
                // For text, an infinite proposal is the same as an unspecified
                // proposal, and this works nicer with most backends than converting
                // .infinity to a large integer (which is the alternative).
                $0 == .infinity ? nil : $0
            }.map(LayoutSystem.roundSize).map { max(1, $0) },
            proposedHeight: proposedSize.height.flatMap {
                $0 == .infinity ? nil : $0
            }.map(LayoutSystem.roundSize).map { max(1, $0) },
            environment: environment
        )

        // If the proposed width was 0 and the resuling width was 1, then set the
        // resulting width to 0. See above for more detail.
        if proposedSize.width == 0 && size.x == 1 {
            size.x = 0
        }

        return ViewLayoutResult.leafView(size: ViewSize(size))
    }

    public func commit<Backend: BaseAppBackend>(
        _ widget: Backend.Widget,
        layout: ViewLayoutResult,
        environment: EnvironmentValues,
        backend: Backend
    ) {
        // The counterpart of the guarded call in `computeLayout`: whichever of
        // the two runs, the widget ends the pass holding this text. Committing
        // it here costs one call per label per pass instead of one per layout
        // computation.
        if backend.measuresTextIndependentlyOfWidget {
            let environment = attributes.apply(to: environment)
            BackendCallStatistics.record("text.updateTextView")
            backend.updateTextView(
                widget,
                content: environment.applyingTextTransforms(to: string),
                environment: environment
            )
        }
        backend.setSize(of: widget, to: layout.size.vector)
    }
}
