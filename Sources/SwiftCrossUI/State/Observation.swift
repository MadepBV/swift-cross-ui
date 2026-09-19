// Only with the polyfill enabled; see SCUI_OBSERVATION_POLYFILL in Package.swift.
#if SCUI_OBSERVATION_POLYFILL && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
    @_exported import ObservationPolyfill
#endif
