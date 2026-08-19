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
/// The new layout system behaviour is in line with SwiftUI's layout behaviour.
public struct Text: Sendable {
    /// The string to be shown in the text view.
    public private(set) var string: String

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
    where F.FormatInput: Equatable, F.FormatOutput == String {
        self.string = format.format(input)
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
        let transformedString = environment.applyingTextTransforms(to: string)

        // TODO: Avoid this. Move it to commit once we figure out a solution for Gtk.
        // Even in dry runs we must update the underlying text view widget
        // because GtkBackend currently relies on querying the widget for text
        // properties and such (via Pango).
        backend
            .updateTextView(widget, content: transformedString, environment: environment)

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
        backend.setSize(of: widget, to: layout.size.vector)
    }
}
