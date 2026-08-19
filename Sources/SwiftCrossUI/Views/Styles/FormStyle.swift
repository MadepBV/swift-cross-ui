/// A type that specifies the appearance of all forms within a view hierarchy.
///
/// Apply a form style with ``View/formStyle(_:)``.
///
/// ```swift
/// Form {
///     Section("Drafting parameters") {
///         Toggle("Snap to grid", active: $snapToGrid)
///     }
/// }
/// .formStyle(.grouped)
/// ```
///
/// SwiftUI models form styles as a protocol so that apps can supply their own
/// styles. SwiftCrossUI only ships the built-in styles for now, so this is a
/// simple value type in the same vein as ``ButtonStyle``. That keeps the
/// `.formStyle(.grouped)` call site source compatible with SwiftUI while
/// leaving room to introduce a protocol later.
public struct FormStyle: Hashable, Sendable {
    /// The built-in form styles.
    package enum Kind: Hashable, Sendable {
        /// See ``FormStyle/automatic``.
        case automatic
        /// See ``FormStyle/columns``.
        case columns
        /// See ``FormStyle/grouped``.
        case grouped
    }

    /// The built-in style that this value represents.
    package var kind: Kind

    /// The form style that reflects the platform's default.
    ///
    /// Lays the form out as a plain vertical stack of rows, leaving the
    /// surrounding view hierarchy in charge of insetting the form.
    public static let automatic = Self(kind: .automatic)

    /// A non-scrolling form style with a leading label column.
    ///
    /// SwiftCrossUI currently renders this identically to
    /// ``FormStyle/automatic``. Use ``LabeledContent`` within the form's rows
    /// to line labels up in a column.
    public static let columns = Self(kind: .columns)

    /// A form style that visually groups each ``Section``'s rows together and
    /// insets the form's content.
    ///
    /// This is the closest match to the grouped forms that macOS uses for
    /// settings windows and inspectors.
    public static let grouped = Self(kind: .grouped)
}

extension FormStyle: CustomStringConvertible {
    public var description: String {
        "\(kind)"
    }
}

extension FormStyle {
    /// The vertical spacing that a ``Form`` leaves between its top-level rows.
    var formRowSpacing: Int {
        switch kind {
            case .grouped: 18
            case .automatic, .columns: 10
        }
    }

    /// The padding that a ``Form`` leaves around its content.
    var formPadding: Int {
        switch kind {
            case .grouped: 16
            case .automatic, .columns: 0
        }
    }

    /// The vertical spacing that a ``Section`` leaves between its rows.
    var sectionRowSpacing: Int {
        switch kind {
            case .grouped: 10
            case .automatic, .columns: 8
        }
    }

    /// The vertical spacing that a ``Section`` leaves between its header, its
    /// content, and its footer.
    var sectionHeaderSpacing: Int {
        switch kind {
            case .grouped: 6
            case .automatic, .columns: 8
        }
    }

    /// Whether a ``Section`` draws a container behind its content.
    var groupsSectionContent: Bool {
        switch kind {
            case .grouped: true
            case .automatic, .columns: false
        }
    }

    /// The padding inside a grouped ``Section``'s container.
    var sectionContentPadding: Int { 12 }

    /// The corner radius of a grouped ``Section``'s container.
    var sectionContentCornerRadius: Int { 8 }
}
