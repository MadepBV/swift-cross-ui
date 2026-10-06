// SwiftUI's leading-dot shapes: `.clipShape(.rect(cornerRadius: 12))`,
// `.contentShape(.rect)`, `.glassEffect(in: .capsule)`.

extension Shape where Self == Rectangle {
    /// A rectangle.
    public static var rect: Rectangle { Rectangle() }
}

extension Shape where Self == RoundedRectangle {
    /// A rectangle with rounded corners.
    ///
    /// - Parameters:
    ///   - cornerRadius: The corner radius.
    ///   - style: The corner style. See ``RoundedRectangle/init(cornerRadius:style:)``.
    public static func rect(
        cornerRadius: Double,
        style: RoundedCornerStyle = .continuous
    ) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: style)
    }
}

extension Shape where Self == Capsule {
    /// A capsule.
    public static var capsule: Capsule { Capsule() }
}

extension Shape where Self == Circle {
    /// A circle.
    public static var circle: Circle { Circle() }
}

extension Shape where Self == Ellipse {
    /// An ellipse.
    public static var ellipse: Ellipse { Ellipse() }
}
