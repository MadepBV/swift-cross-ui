/// Identifies one update pass over the view graph.
///
/// A view's body doesn't depend on the size it is proposed, so a node evaluates
/// it once per pass and reuses it for the layout system's minimum and maximum
/// probes, for the proposal its container settles on, and for the commit. What
/// makes that safe is knowing when a *new* pass has begun, because a new pass
/// may be running under a different environment or after a state change.
///
/// A pass begins whenever the graph is entered from outside: a scene computing
/// a window's layout, or a node recomputing itself after its state changed.
/// Everything reached from there shares the token, and a node's cached body is
/// only valid while its token matches.
@MainActor
@_spi(Backends) public enum LayoutPass {
    /// The current pass' token.
    ///
    /// Readable by backends so that work whose result is only valid within one
    /// pass — a measurement a backend is asked for repeatedly while a container
    /// probes its children, say — can be memoised against it.
    public private(set) static var token: UInt64 = 0

    /// Begins a new pass, invalidating every cached body.
    ///
    /// Cheap by design: a counter rather than a walk of the graph, so nodes
    /// that are never reached again cost nothing.
    public static func begin() {
        token &+= 1
    }
}
