import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// SwiftUI's launch rule: `WindowGroup` opens at launch, `Window` only on
/// `openWindow` unless it asks to be presented.
@Suite("Testing for scene launch behaviour")
@MainActor
struct SceneLaunchTests {
    private func environment(
        _ behavior: SceneLaunchBehavior,
        backend: DummyBackend
    ) -> EnvironmentValues {
        EnvironmentValues(backend: backend).with(\.defaultLaunchBehavior, behavior)
    }

    @Test("A Window scene doesn't open at launch unless presented")
    func testWindowSceneStaysClosedAtLaunch() {
        let backend = DummyBackend()
        let scene = Window("Help", id: "help") {
            Text("Shortcuts")
        }

        let automatic = WindowNode(
            from: scene,
            backend: backend,
            environment: environment(.automatic, backend: backend)
        )
        #expect(automatic.windowReference == nil)

        let suppressed = WindowNode(
            from: scene,
            backend: backend,
            environment: environment(.suppressed, backend: backend)
        )
        #expect(suppressed.windowReference == nil)

        let presented = WindowNode(
            from: scene,
            backend: backend,
            environment: environment(.presented, backend: backend)
        )
        #expect(presented.windowReference != nil)
    }

    @Test("defaultLaunchBehavior(.suppressed) reaches the Window node it's applied to")
    func testSuppressedLaunchBehaviorIsScoped() {
        let backend = DummyBackend()
        let scene = Window("Help", id: "help") {
            Text("Shortcuts")
        }
        // What `.defaultLaunchBehavior(.suppressed)` builds, spelled out so the
        // node's content stays inspectable.
        let modified = SceneEnvironmentModifier(scene) { environment in
            environment.with(\.defaultLaunchBehavior, .suppressed)
        }

        let node = SceneEnvironmentModifierNode(
            from: modified,
            backend: backend,
            environment: environment(.presented, backend: backend)
        )
        #expect(node.contentNode.windowReference == nil)
    }
}
