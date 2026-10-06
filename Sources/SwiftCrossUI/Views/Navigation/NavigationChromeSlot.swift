import Foundation

/// Keeps one modifier's contribution in a ``NavigationChrome`` for as long as
/// the modifier is on screen.
///
/// A modifier holds its slot in `@State`, so the slot lives exactly as long as
/// the modifier's view graph node; when the node goes away (its page is popped,
/// or a conditional branch stops showing it), the slot takes the contribution
/// back out.
@MainActor
final class NavigationChromeSlot {
    /// The chrome contributed to, if any.
    ///
    /// `nonisolated(unsafe)` so that `deinit`, which isn't isolated, can
    /// withdraw from it; it's only ever written on the main actor.
    nonisolated(unsafe) private weak var chrome: NavigationChrome?

    /// Creates a slot that hasn't contributed anything yet.
    init() {}

    /// Contributes to a chrome, replacing this slot's previous contribution.
    ///
    /// Moving to a different chrome (or to none) withdraws from the previous
    /// one first.
    ///
    /// - Parameters:
    ///   - contribution: The contribution.
    ///   - chrome: The chrome to contribute to.
    func contribute(_ contribution: NavigationChrome.Contribution, to chrome: NavigationChrome?) {
        if self.chrome !== chrome {
            self.chrome?.withdraw(ObjectIdentifier(self))
            self.chrome = chrome
        }
        chrome?.contribute(contribution, from: ObjectIdentifier(self))
    }

    deinit {
        guard let chrome else {
            return
        }
        let slot = ObjectIdentifier(self)
        // View graph nodes are released on the main thread; anywhere else, the
        // withdrawal waits for it.
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                chrome.withdraw(slot)
            }
        } else {
            Task { @MainActor in
                chrome.withdraw(slot)
            }
        }
    }
}
