import Foundation

extension Text {
    /// How ``Text/init(_:style:)`` and the `\(date, style:)` interpolation
    /// show a date.
    ///
    /// SwiftUI keeps the relative, offset and timer styles counting as time
    /// passes. SwiftCrossUI formats them when the text's view is updated, so
    /// they are current whenever the view is, and otherwise stand still;
    /// drive a once-a-second update (a `TimelineView` or a timer task) when
    /// the seconds matter.
    public struct DateStyle: Hashable, Sendable {
        enum Kind: Hashable, Sendable {
            case time, date, relative, offset, timer
        }

        let kind: Kind

        /// The time of day, e.g. "9:41 AM".
        public static let time = DateStyle(kind: .time)
        /// The date, e.g. "June 3, 2026".
        public static let date = DateStyle(kind: .date)
        /// The time from now to the date, e.g. "2 hours, 23 minutes".
        public static let relative = DateStyle(kind: .relative)
        /// The signed time from now to the date, e.g. "+2 hours".
        public static let offset = DateStyle(kind: .offset)
        /// A count up or down to the date, e.g. "2:23:05".
        public static let timer = DateStyle(kind: .timer)

        /// Formats a date in this style.
        ///
        /// - Parameters:
        ///   - date: The date to format.
        ///   - now: The moment the relative styles measure from.
        /// - Returns: The formatted date.
        func format(_ date: Date, relativeTo now: Date = Date()) -> String {
            let interval = date.timeIntervalSince(now)
            switch kind {
                case .time:
                    return DateFormatter.localizedString(
                        from: date,
                        dateStyle: .none,
                        timeStyle: .short
                    )
                case .date:
                    return DateFormatter.localizedString(
                        from: date,
                        dateStyle: .long,
                        timeStyle: .none
                    )
                case .relative:
                    return Self.duration(abs(interval), units: 2, style: .full)
                case .offset:
                    let sign = interval < 0 ? "-" : "+"
                    return sign + Self.duration(abs(interval), units: 1, style: .full)
                case .timer:
                    // "1:05", "2:23:05": minutes are padded only after hours.
                    let total = Int(abs(interval).rounded(.down))
                    let (hours, minutes, seconds) = (total / 3600, total / 60 % 60, total % 60)
                    let tail = String(format: "%02d", seconds)
                    return hours > 0
                        ? "\(hours):\(String(format: "%02d", minutes)):\(tail)"
                        : "\(minutes):\(tail)"
            }
        }

        /// A duration in words, with its largest units only.
        private static func duration(
            _ seconds: TimeInterval,
            units: Int,
            style: DateComponentsFormatter.UnitsStyle
        ) -> String {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = style
            formatter.maximumUnitCount = units
            formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
            return formatter.string(from: seconds.rounded(.down)) ?? ""
        }
    }

    /// Creates a text view that shows a date in one of SwiftUI's styles.
    ///
    /// ```swift
    /// Text(expiry, style: .relative)
    /// ```
    ///
    /// - Parameters:
    ///   - date: The date to show.
    ///   - style: How to show it.
    public init(_ date: Date, style: DateStyle) {
        self.init(style.format(date))
    }
}

extension DefaultStringInterpolation {
    /// Interpolates a date in one of SwiftUI's styles, SwiftUI's
    /// `Text("Expires \(date, style: .relative)")` spelling.
    ///
    /// SwiftUI provides this on `LocalizedStringKey`; SwiftCrossUI's ``Text``
    /// takes a `String`, so the interpolation is available wherever a string
    /// is interpolated. See ``Text/DateStyle`` for how it keeps time.
    ///
    /// - Parameters:
    ///   - date: The date to show.
    ///   - style: How to show it.
    public mutating func appendInterpolation(_ date: Date, style: Text.DateStyle) {
        appendLiteral(style.format(date))
    }
}
