/// A type that applies a custom appearance to all ``Label``s within a view
/// hierarchy.
///
/// Apply a label style with ``View/labelStyle(_:)``. The style propagates
/// through the environment, so it affects every ``Label`` nested inside the
/// modified view, including labels used as the content of controls such as
/// ``Button``.
///
/// ```swift
/// HStack {
///     Label("Duplicate", systemImage: "square.on.square")
///     Label("Delete", systemImage: "trash")
/// }
/// .labelStyle(.iconOnly)
/// ```
///
/// ## See Also
///
/// - ``Label``
/// - ``View/labelStyle(_:)``
public struct LabelStyle: Hashable, Sendable {
    /// The set of label styles that SwiftCrossUI knows how to render.
    package enum Kind: Hashable, Sendable {
        /// Resolved by ``Label`` based on the context that it's used in.
        case automatic
        /// Displays both the title and the icon.
        case titleAndIcon
        /// Displays the icon and hides the title.
        case iconOnly
        /// Displays the title and hides the icon.
        case titleOnly
    }

    /// The built-in style that this value represents.
    package var kind: Kind

    /// A label style that resolves its appearance based on the label's
    /// context.
    ///
    /// SwiftCrossUI currently resolves this to ``LabelStyle/titleAndIcon`` in
    /// every context, matching SwiftUI's behaviour outside of a handful of
    /// Apple-specific containers.
    public static let automatic = Self(kind: .automatic)

    /// A label style that shows both the title and the icon, with the icon
    /// leading the title.
    public static let titleAndIcon = Self(kind: .titleAndIcon)

    /// A label style that only shows the label's icon.
    ///
    /// If the label has no icon to show (which is the case for the asset names
    /// passed to ``Label/init(_:image:)``, since SwiftCrossUI has no asset
    /// catalog), the label falls back to showing its title so that it never
    /// renders as nothing at all. See ``Label`` for details.
    public static let iconOnly = Self(kind: .iconOnly)

    /// A label style that only shows the label's title.
    public static let titleOnly = Self(kind: .titleOnly)

    /// Whether labels using this style show their title.
    ///
    /// ``LabelStyle/automatic`` is treated as ``LabelStyle/titleAndIcon``.
    package var showsTitle: Bool {
        switch kind {
            case .automatic, .titleAndIcon, .titleOnly: true
            case .iconOnly: false
        }
    }

    /// Whether labels using this style show their icon.
    ///
    /// ``LabelStyle/automatic`` is treated as ``LabelStyle/titleAndIcon``.
    package var showsIcon: Bool {
        switch kind {
            case .automatic, .titleAndIcon, .iconOnly: true
            case .titleOnly: false
        }
    }
}

extension LabelStyle: CustomStringConvertible {
    public var description: String {
        "\(kind)"
    }
}

extension EnvironmentValues {
    /// The display style used by ``Label``.
    ///
    /// Set this with ``View/labelStyle(_:)`` rather than mutating the
    /// environment directly.
    @Entry public var labelStyle: LabelStyle = .automatic
}
