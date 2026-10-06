/// Haptic or audible feedback for an event, played by
/// ``View/sensoryFeedback(_:trigger:)``.
///
/// - Note: Desktop platforms have no haptic engine to play these on (a
///   trackpad's force feedback is reserved for alignment and is not exposed
///   by SwiftCrossUI's backends), so feedback is accepted and not played.
public struct SensoryFeedback: Hashable, Sendable {
    /// How heavy an impact feels.
    public struct Weight: Hashable, Sendable {
        let value: Double

        public static let light = Weight(value: 0.3)
        public static let medium = Weight(value: 0.6)
        public static let heavy = Weight(value: 1)
    }

    /// How rigid the object in an impact feels.
    public struct Flexibility: Hashable, Sendable {
        let value: Double

        public static let rigid = Flexibility(value: 1)
        public static let solid = Flexibility(value: 0.5)
        public static let soft = Flexibility(value: 0)
    }

    enum Kind: Hashable, Sendable {
        case success
        case warning
        case error
        case selection
        case increase
        case decrease
        case start
        case stop
        case alignment
        case levelChange
        case pathComplete
        case impact(weight: Double, flexibility: Double?, intensity: Double)
    }

    let kind: Kind

    public static let success = SensoryFeedback(kind: .success)
    public static let warning = SensoryFeedback(kind: .warning)
    public static let error = SensoryFeedback(kind: .error)
    public static let selection = SensoryFeedback(kind: .selection)
    public static let increase = SensoryFeedback(kind: .increase)
    public static let decrease = SensoryFeedback(kind: .decrease)
    public static let start = SensoryFeedback(kind: .start)
    public static let stop = SensoryFeedback(kind: .stop)
    public static let alignment = SensoryFeedback(kind: .alignment)
    public static let levelChange = SensoryFeedback(kind: .levelChange)
    public static let pathComplete = SensoryFeedback(kind: .pathComplete)
    public static let impact = SensoryFeedback.impact(weight: .medium)

    /// An impact of the given weight.
    public static func impact(weight: Weight = .medium, intensity: Double = 1) -> SensoryFeedback {
        SensoryFeedback(kind: .impact(weight: weight.value, flexibility: nil, intensity: intensity))
    }

    /// An impact against an object of the given rigidity.
    public static func impact(flexibility: Flexibility, intensity: Double = 1) -> SensoryFeedback {
        SensoryFeedback(
            kind: .impact(weight: 0.6, flexibility: flexibility.value, intensity: intensity)
        )
    }
}

extension View {
    /// Plays feedback when `trigger` changes.
    ///
    /// - Note: Not played; see ``SensoryFeedback``.
    ///
    /// - Parameters:
    ///   - feedback: The feedback to play.
    ///   - trigger: The value whose changes play it.
    /// - Returns: The view.
    public func sensoryFeedback<Trigger: Equatable>(
        _ feedback: SensoryFeedback,
        trigger: Trigger
    ) -> some View {
        self
    }

    /// Plays feedback when `trigger` changes and `condition` approves.
    ///
    /// - Note: Not played; see ``SensoryFeedback``.
    ///
    /// - Parameters:
    ///   - feedback: The feedback to play.
    ///   - trigger: The value whose changes play it.
    ///   - condition: Decides, from the old and new values, whether to play.
    /// - Returns: The view.
    public func sensoryFeedback<Trigger: Equatable>(
        _ feedback: SensoryFeedback,
        trigger: Trigger,
        condition: @escaping (Trigger, Trigger) -> Bool
    ) -> some View {
        self
    }
}
