import Foundation

/// A control that opens a URL.
///
/// ```swift
/// Link("Privacy policy", destination: privacyURL)
/// ```
///
/// The URL is opened with the environment's ``EnvironmentValues/openURL``
/// action, which by default hands it to the system (the default browser for
/// a web address).
///
/// Outside any button style a link looks like a link: its label is drawn in
/// the tint colour on a borderless button. Inside a ``View/buttonStyle(_:)``
/// it takes that style instead, like any button, as in SwiftUI.
public struct Link<Label: View>: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.buttonStyle) private var buttonStyle
    @Environment(\.primitiveButtonStyle) private var primitiveButtonStyle

    private let destination: URL
    private let label: Label

    /// Creates a link with a custom label.
    ///
    /// - Parameters:
    ///   - destination: The URL to open.
    ///   - label: The link's label.
    public init(destination: URL, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }

    private init(destination: URL, label: Label) {
        self.destination = destination
        self.label = label
    }

    public var body: some View {
        let isStyled = buttonStyle != nil || primitiveButtonStyle != nil
        let button = Button {
            openURL(destination)
        } label: {
            label
        }
        if isStyled {
            button
        } else {
            button
                .buttonStyle(.link)
                .foregroundColor(.tint)
        }
    }
}

extension Link where Label == Text {
    /// Creates a link with a text label.
    ///
    /// - Parameters:
    ///   - title: The link's title.
    ///   - destination: The URL to open.
    public init(_ title: String, destination: URL) {
        self.init(destination: destination, label: Text(title))
    }
}
