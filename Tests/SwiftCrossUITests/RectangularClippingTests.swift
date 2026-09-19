import Foundation
import Testing
import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI
#if canImport(AppKitBackend)
import AppKit
@testable import AppKitBackend
#endif

@Suite("Rectangular clipping")
@MainActor
struct RectangularClippingTests {
    @Test("Clipping keeps its layout and child identity through collapse and restoration")
    func sharedLayoutAndIdentity() throws {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend).with(\.window,
            backend.createWindow(withDefaultSize: nil, id: "rectangular-clip"))
        func content(width: CGFloat, height: CGFloat) -> some View {
            Color.red.frame(width: CGFloat(300), height: CGFloat(200))
                .frame(width: width, height: height).clipped()
        }
        let graph = ViewGraph(for: content(width: 120, height: 80), backend: backend, environment: environment)
        let root = graph.rootNode.concreteNode(for: DummyBackend.self).widget
        var original: DummyBackend.Rectangle?
        for size in [SIMD2(120, 80), SIMD2(0, 80), SIMD2(120, 0), SIMD2(0, 0), SIMD2(120, 80)] {
            let result = graph.computeLayout(with: content(width: CGFloat(size.x), height: CGFloat(size.y)),
                proposedSize: .init(400, 300), environment: environment)
            graph.commit()
            #expect(result.size.vector == size)
            #expect(root.size == size)
            #expect(root.cornerRadius == 0)
            let rectangle = try #require(root.firstWidget(ofType: DummyBackend.Rectangle.self))
            if let original { #expect(rectangle === original) } else { original = rectangle }
            // The content keeps its own layout; the clip defines visibility.
            #expect(rectangle.size == SIMD2(300, 200))
        }
    }

    #if canImport(AppKitBackend)
    @Test("Shared clipped installs a real native rectangular clip at every allocated size")
    func appKitModifierUsesNativeClipping() throws {
        let backend = AppKitBackend()
        let window = backend.createWindow(withDefaultSize: SIMD2(400, 300), id: "native-rectangular-clip")
        let environment = EnvironmentValues(backend: backend).with(\.window, window)
        func content(width: CGFloat, height: CGFloat) -> some View {
            Color.red.frame(width: CGFloat(300), height: CGFloat(200))
                .frame(width: width, height: height).clipped()
        }
        let graph = ViewGraph(for: content(width: 120, height: 80), backend: backend, environment: environment)
        let root = graph.rootNode.concreteNode(for: AppKitBackend.self).widget
        let original = root.subviews.first
        for size in [SIMD2(120, 80), SIMD2(0, 80), SIMD2(120, 0), SIMD2(0, 0), SIMD2(120, 80)] {
            let result = graph.computeLayout(with: content(width: CGFloat(size.x), height: CGFloat(size.y)),
                proposedSize: .init(400, 300), environment: environment)
            graph.commit()
            #expect(result.size.vector == size)
            #expect(root.clipsToBounds)
            #expect(root.layer?.cornerRadius == 0)
            // AppKitBackend allocates using constraints. Read those directly;
            // an unordered test window has not performed a native arrange pass.
            let width = try #require(root.constraints.first { $0.isActive && $0.firstAnchor === root.widthAnchor })
            let height = try #require(root.constraints.first { $0.isActive && $0.firstAnchor === root.heightAnchor })
            #expect(width.constant == CGFloat(size.x))
            #expect(height.constant == CGFloat(size.y))
            #expect(root.subviews.first === original)
        }
    }

    @Test("Radius zero retains native clip semantics while bounds collapse and grow")
    func appKitNativeBoundsTransition() {
        let backend = AppKitBackend()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 120, height: 80))
        let child = NSView(frame: NSRect(x: -100, y: -100, width: 300, height: 200))
        view.addSubview(child)
        let clipped = backend.createCornerRadiusContainer(wrapping: view)
        backend.setCornerRadius(of: clipped, to: 0)
        for size in [NSSize(width: 120, height: 80), NSSize(width: 0, height: 80),
                     NSSize.zero, NSSize(width: 120, height: 80)] {
            clipped.setFrameSize(size)
            #expect(clipped.clipsToBounds)
            #expect(clipped.bounds.size == size)
            #expect(clipped.layer?.cornerRadius == 0)
            #expect(child.superview === view)
        }
    }
    #endif
}
