@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.ScrollObservation {
    public func setScrollChangeHandler(
        of scrollContainer: Widget,
        to action: @escaping @MainActor () -> Void
    ) {
        (scrollContainer as! ScrollContainer).scrollChangeHandler = action
    }
}
