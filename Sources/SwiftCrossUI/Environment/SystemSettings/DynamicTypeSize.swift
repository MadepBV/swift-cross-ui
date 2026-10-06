/// A Dynamic Type size, which specifies how large scalable content should
/// be.
public enum DynamicTypeSize: Hashable, Comparable, CaseIterable, Sendable {
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge
    case accessibility1
    case accessibility2
    case accessibility3
    case accessibility4
    case accessibility5

    /// Whether the size is one of the accessibility sizes.
    public var isAccessibilitySize: Bool {
        self >= .accessibility1
    }

    /// How much larger than the default (``large``) size this size draws
    /// body text, following Apple's body text sizes (17 points at `large`).
    var scaleFactor: Double {
        let bodyPointSize: Double =
            switch self {
                case .xSmall: 14
                case .small: 15
                case .medium: 16
                case .large: 17
                case .xLarge: 19
                case .xxLarge: 21
                case .xxxLarge: 23
                case .accessibility1: 28
                case .accessibility2: 33
                case .accessibility3: 40
                case .accessibility4: 47
                case .accessibility5: 53
            }
        return bodyPointSize / 17
    }

    /// The size closest to a system text scale factor, such as Windows'
    /// "Text size" setting (100% to 225%).
    ///
    /// - Parameter textScaleFactor: The scale factor, where `1` is the
    ///   default text size.
    init(textScaleFactor: Double) {
        guard textScaleFactor > 1 else {
            self = .large
            return
        }
        self =
            Self.allCases
            .filter { $0 >= .large }
            .min { abs($0.scaleFactor - textScaleFactor) < abs($1.scaleFactor - textScaleFactor) }
            ?? .large
    }
}

/// A set of values that indicate the visual size available to the view.
public enum UserInterfaceSizeClass: Hashable, Sendable {
    /// The size class for a constrained space, such as an iPhone's width.
    case compact
    /// The size class for an expansive space, such as a desktop window.
    case regular
}
