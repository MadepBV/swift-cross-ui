import Foundation
import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite("Styling modifiers")
@MainActor
struct StylingModifierTests {
    private func render<V: View>(
        _ view: V,
        size: SIMD2<Int> = SIMD2(200, 100)
    ) -> (DummyBackend.Widget, ViewLayoutResult) {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)
            .with(\.window, backend.createWindow(withDefaultSize: nil, id: "styling"))
        let graph = ViewGraph(for: view, backend: backend, environment: environment)
        let result = graph.computeLayout(
            proposedSize: ProposedViewSize(Double(size.x), Double(size.y)),
            environment: environment
        )
        graph.commit()
        return (graph.rootNode.concreteNode(for: DummyBackend.self).widget, result)
    }

    @Test("Opacity reaches the backend, clamped, and keeps the layout")
    func opacityReachesBackend() {
        let (widget, result) = render(Color.red.frame(width: 50, height: 20).opacity(0.25))
        #expect(widget.opacity == 0.25)
        #expect(result.size == ViewSize(50, 20))

        let (clamped, _) = render(Color.red.opacity(2.0).frame(width: 10, height: 10).opacity(-1))
        #expect(clamped.opacity == 0)
    }

    @Test("Clip shapes become corner radii sized to the frame")
    func clipShapeCornerRadius() {
        let (capsule, _) = render(Color.red.frame(width: 80, height: 30).clipShape(Capsule()))
        #expect(capsule.cornerRadius == 15)

        let (rounded, _) = render(
            Color.red.frame(width: 80, height: 30)
                .clipShape(.rect(cornerRadius: 12, style: .continuous))
        )
        #expect(rounded.cornerRadius == 12)

        let (circle, _) = render(Color.red.frame(width: 40, height: 40).clipShape(Circle()))
        #expect(circle.cornerRadius == 20)
    }

    @Test("A visual effect's opacity is applied from the view's geometry")
    func visualEffectOpacity() {
        let (widget, _) = render(
            Color.red.frame(width: 40, height: 10)
                .visualEffect { content, proxy in
                    content.opacity(proxy.size.width > 20 ? 0.5 : 1).scaleEffect(2)
                }
        )
        #expect(widget.opacity == 0.5)
    }

    @Test("A content shape keeps the view's layout")
    func contentShapeKeepsLayout() {
        let (_, result) = render(
            Text("Row").frame(width: 120, height: 30).contentShape(Rectangle())
        )
        #expect(result.size == ViewSize(120, 30))
    }

    @Test("Glass button styles draw the platform's bordered chrome")
    func glassButtonStyles() {
        #expect(GlassButtonStyle().kind == .bordered)
        #expect(GlassProminentButtonStyle().kind == BorderedProminentButtonStyle().kind)
    }

    @Test("Animations run their state change at once")
    func withAnimationRunsBody() {
        var value = 0
        let result = withAnimation(.easeInOut(duration: 0.3).repeatForever()) {
            value += 1
            return value * 10
        }
        #expect(value == 1)
        #expect(result == 10)

        var completed = false
        withAnimation(.smooth) { value += 1 } completion: { completed = true }
        #expect(value == 2)
        #expect(completed)
    }

    @Test("A primitive button style builds the control and triggers the action")
    func primitiveButtonStyleBuildsControl() throws {
        struct Wrapping: PrimitiveButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                Button {
                    configuration.trigger()
                } label: {
                    configuration.label
                }
                .buttonStyle(.borderless)
            }
        }
        final class Counter { var count = 0 }
        let counter = Counter()
        let (root, _) = render(
            Button("Go") { counter.count += 1 }.buttonStyle(Wrapping())
        )

        // The outer native button is chromeless and inert; the style's own
        // button, nested inside it, carries the action.
        let outer = try #require(root.firstWidget(ofType: DummyBackend.Button.self))
        #expect(outer.buttonStyle.kind == .plain)
        outer.action?()
        #expect(counter.count == 0)

        let inner = try #require(
            outer.label?.firstWidget(ofType: DummyBackend.Button.self)
        )
        #expect(inner !== outer)
        #expect(inner.buttonStyle.kind == .borderless)
        inner.action?()
        #expect(counter.count == 1)
    }

    @Test("A named image is a resource file of the bundle, or nothing")
    func namedImageResource() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("scui-named-image-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("badge.webp")
        try Data([0]).write(to: file)
        let bundle = try #require(Bundle(path: directory.path))

        #expect(Image.resourceURL(named: "badge", in: bundle)?.lastPathComponent == "badge.webp")
        #expect(Image.resourceURL(named: "missing", in: bundle) == nil)

        let (_, result) = render(Image("missing", bundle: bundle))
        #expect(result.size == ViewSize(0, 0))
    }

    #if canImport(CoreGraphics)
        @Test("Core Graphics images are copied as straight-alpha RGBA")
        func cgImageIsCopied() throws {
            let pixels: [UInt8] = [255, 0, 0, 255, 0, 64, 0, 128]
            let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
            let provider = try #require(CGDataProvider(data: Data(pixels) as CFData))
            let cgImage = try #require(
                CGImage(
                    width: 2,
                    height: 1,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: 8,
                    space: space,
                    bitmapInfo: CGBitmapInfo(
                        rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                    ),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: .defaultIntent
                )
            )
            let image = Image.rgbaImage(from: cgImage)
            #expect(image.width == 2)
            #expect(image.height == 1)
            #expect(Array(image.bytes[0..<4]) == [255, 0, 0, 255])
            // Premultiplied green 64 at alpha 128 is straight green 127.
            #expect(image.bytes[5] == 127)
            #expect(image.bytes[7] == 128)
        }
    #endif
}
