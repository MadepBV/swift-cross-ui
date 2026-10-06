/// The size a sheet proposes to its content, set with
/// ``View/presentationSizing(_:)``.
///
/// ```swift
/// PaywallView()
///     .presentationSizing(.form.fitted(horizontal: false, vertical: true))
/// ```
///
/// Without a sizing, a sheet fits its content, as ``fitted`` does. ``form``
/// and ``page`` propose a fixed size along each axis that isn't fitted:
/// 580 by 640 points for a form, 800 by 900 for a page, the sizes SwiftUI's
/// form and page sheets have on an iPad and a Mac. The content can still
/// refuse the proposal with its own frame, as in SwiftUI.
public struct PresentationSizing: Hashable, Sendable {
    /// The width proposed to the content, or `nil` to fit it.
    var width: Double?
    /// The height proposed to the content, or `nil` to fit it.
    var height: Double?

    /// The platform's default: the sheet fits its content.
    public static let automatic = PresentationSizing(width: nil, height: nil)
    /// The sheet fits its content in both directions.
    public static let fitted = PresentationSizing(width: nil, height: nil)
    /// A sheet sized for a form.
    public static let form = PresentationSizing(width: 580, height: 640)
    /// A sheet sized like a page of a document.
    public static let page = PresentationSizing(width: 800, height: 900)

    /// This sizing, fitting the content along the chosen axes.
    ///
    /// - Parameters:
    ///   - horizontal: Whether the width fits the content.
    ///   - vertical: Whether the height fits the content.
    /// - Returns: The adjusted sizing.
    public func fitted(horizontal: Bool, vertical: Bool) -> PresentationSizing {
        PresentationSizing(
            width: horizontal ? nil : width,
            height: vertical ? nil : height
        )
    }

    /// This sizing, keeping its size along the chosen axes as the content
    /// changes. Sheets already keep the size they're proposed, so this
    /// returns the sizing unchanged.
    ///
    /// - Parameters:
    ///   - horizontal: Whether the width sticks.
    ///   - vertical: Whether the height sticks.
    /// - Returns: The sizing.
    public func sticky(horizontal: Bool = false, vertical: Bool = false) -> PresentationSizing {
        self
    }

    /// The size proposed to the sheet's content.
    var proposal: ProposedViewSize {
        ProposedViewSize(width, height)
    }
}

extension View {
    /// Sets the size of the enclosing sheet. See ``PresentationSizing``.
    ///
    /// - Parameter sizing: The sheet's sizing.
    /// - Returns: A view with the ``PreferenceValues/presentationSizing``
    ///   preference set.
    public func presentationSizing(_ sizing: PresentationSizing) -> some View {
        preference(key: \.presentationSizing, value: sizing)
    }
}
