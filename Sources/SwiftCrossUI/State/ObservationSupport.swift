#if SCUI_OBSERVATION_POLYFILL
    import ObservationPolyfillCore
#elseif canImport(Observation)
    import Observation
#endif

/// The one place SwiftCrossUI installs observation tracking, so that the rest
/// of the framework doesn't care which implementation is behind it.
///
/// With `SCUI_OBSERVATION_POLYFILL` defined (always, outside Apple platforms;
/// opt-in on them, see `Package.swift`) tracking goes through
/// `ObservationPolyfillCore`, which forwards to the standard library's
/// `Observation` wherever that is available and otherwise falls back to its
/// own tracking, so models declared with either `@Observable` macro are seen
/// by the one call.
///
/// Without it, tracking goes straight to the standard library's `Observation`,
/// behind a runtime availability check: its declarations are annotated as
/// macOS 14 / iOS 17 / tvOS 17 / watchOS 10 and SwiftCrossUI supports
/// deployment targets older than that. On those older systems `apply` just
/// runs untracked, and views fall back to the ``ObservableObject`` and
/// ``State`` invalidation paths.
enum ObservationSupport {
    /// Runs `apply` while recording every `@Observable` property it reads, and
    /// calls `onChange` — at most once, on whichever thread performs the
    /// mutation, before the mutation lands — when one of them changes.
    ///
    /// - Parameters:
    ///   - apply: The work to track.
    ///   - onChange: Called when a tracked property is about to change.
    /// - Returns: The result of `apply`.
    static func withTracking<Result>(
        _ apply: () -> Result,
        onChange: @escaping @Sendable () -> Void
    ) -> Result {
        #if SCUI_OBSERVATION_POLYFILL
            return ObservationPolyfillCore.withObservationTracking(
                apply,
                onChange: onChange
            )
        #elseif canImport(Observation)
            guard #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) else {
                return apply()
            }
            return Observation.withObservationTracking(apply, onChange: onChange)
        #else
            return apply()
        #endif
    }
}
