/// How a ``Menu`` draws its button.
///
/// Every SwiftCrossUI backend draws a menu as its platform's own menu button
/// (a pull-down button on macOS, a button with a flyout on Windows), so the
/// styles exist for source compatibility and don't change the button's look.
public protocol MenuStyle: Sendable {}

/// The platform's default menu style.
public struct DefaultMenuStyle: MenuStyle {
    public init() {}
}

/// A menu drawn as a button.
public struct ButtonMenuStyle: MenuStyle {
    public init() {}
}

/// A menu drawn as a borderless button.
public struct BorderlessButtonMenuStyle: MenuStyle {
    public init() {}
}

extension MenuStyle where Self == DefaultMenuStyle {
    /// The platform's default menu style.
    public static var automatic: DefaultMenuStyle { DefaultMenuStyle() }
}

extension MenuStyle where Self == ButtonMenuStyle {
    /// A menu drawn as a button.
    public static var button: ButtonMenuStyle { ButtonMenuStyle() }
}

extension MenuStyle where Self == BorderlessButtonMenuStyle {
    /// A menu drawn as a borderless button.
    public static var borderlessButton: BorderlessButtonMenuStyle {
        BorderlessButtonMenuStyle()
    }
}

extension View {
    /// Sets the style of the menus within this view.
    ///
    /// Purely cosmetic, and without effect: backends draw every menu as their
    /// platform's native menu button (see ``MenuStyle``).
    ///
    /// - Parameter style: The style.
    /// - Returns: This view, unchanged.
    public func menuStyle(_ style: some MenuStyle) -> some View {
        self
    }

    /// Shows or hides the disclosure indicator of the menus within this view.
    ///
    /// Purely cosmetic, and without effect: the indicator is part of the
    /// platform's native menu button, which no backend lets SwiftCrossUI
    /// take apart.
    ///
    /// - Parameter visibility: Whether to show the indicator.
    /// - Returns: This view, unchanged.
    public func menuIndicator(_ visibility: Visibility) -> some View {
        self
    }
}
