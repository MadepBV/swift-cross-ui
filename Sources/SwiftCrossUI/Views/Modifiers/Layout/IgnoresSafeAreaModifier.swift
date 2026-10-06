/// The kinds of safe area a view can extend into.
public struct SafeAreaRegions: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The area under the window's bars and the device's insets.
    public static let container = SafeAreaRegions(rawValue: 1 << 0)
    /// The area under the software keyboard.
    public static let keyboard = SafeAreaRegions(rawValue: 1 << 1)
    /// Every safe area.
    public static let all: SafeAreaRegions = [.container, .keyboard]
}

extension View {
    /// Extends this view into the safe areas of its container.
    ///
    /// - Note: No effect. SwiftCrossUI's desktop windows lay content out in
    ///   their whole content area, with no bars or device insets for a view to
    ///   extend under, so every view already fills the space this would give
    ///   it. Insets added with ``View/safeAreaInset(edge:alignment:spacing:content:)``
    ///   are part of the layout and stay respected.
    ///
    /// - Parameters:
    ///   - regions: The kinds of safe area to extend into.
    ///   - edges: The edges to extend past.
    /// - Returns: The view.
    public func ignoresSafeArea(
        _ regions: SafeAreaRegions = .all,
        edges: Edge.Set = .all
    ) -> some View {
        self
    }
}
