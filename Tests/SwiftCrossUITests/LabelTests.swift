import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

/// A label style defined outside of SwiftCrossUI, standing in for one that an
/// app would write.
///
/// Places the title before the icon, which no built-in style does, so a label
/// rendered with it is unmistakably laid out by this style.
struct ReversedLabelStyle: LabelStyle {
    nonisolated init() {}

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == ReversedLabelStyle {
    /// A label style that places the title before the icon.
    static var reversed: Self { Self() }
}

@Suite("Testing for Label")
@MainActor
struct LabelTests {
    @Test("Labels show their icon before their title by default")
    func testDefaultStyleShowsIconAndTitle() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("Icon")
        }

        #expect(render(label).text == ["Icon", "Title"])
    }

    @Test("The automatic style resolves to title and icon")
    func testAutomaticStyleShowsIconAndTitle() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("Icon")
        }

        let rendered = render(label, labelStyle: .automatic)
        #expect(rendered.text == ["Icon", "Title"])
    }

    @Test("The titleAndIcon style shows both parts")
    func testTitleAndIconStyle() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("Icon")
        }

        let rendered = render(label, labelStyle: .titleAndIcon)
        #expect(rendered.text == ["Icon", "Title"])
    }

    @Test("The iconOnly style hides the title")
    func testIconOnlyStyle() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("Icon")
        }

        #expect(render(label, labelStyle: .iconOnly).text == ["Icon"])
    }

    @Test("The titleOnly style hides the icon")
    func testTitleOnlyStyle() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("Icon")
        }

        #expect(render(label, labelStyle: .titleOnly).text == ["Title"])
    }

    @Test("labelStyle(_:) propagates to nested labels")
    func testLabelStyleModifierPropagates() {
        let view = VStack {
            Label {
                Text("Title")
            } icon: {
                Text("Icon")
            }
        }
        .labelStyle(.iconOnly)

        #expect(render(view).text == ["Icon"])
    }

    @Test("The innermost labelStyle(_:) wins")
    func testInnermostLabelStyleWins() {
        let view = VStack {
            Label {
                Text("Title")
            } icon: {
                Text("Icon")
            }
            .labelStyle(.titleOnly)
        }
        .labelStyle(.iconOnly)

        #expect(render(view).text == ["Title"])
    }

    @Test("System image labels show their title alongside a symbol")
    func testSystemImageLabelShowsTitleAndIcon() {
        let label = Label("Duplicate", systemImage: "trash")
        let titleOnly = Label("Duplicate", systemImage: "trash")

        let both = render(label)
        let withoutIcon = render(titleOnly, labelStyle: .titleOnly)

        #expect(both.text == ["Duplicate"])
        // The symbol occupies real space beside the title, so the label is
        // wider than the same label with its icon hidden.
        #expect(both.size.x > withoutIcon.size.x)
    }

    @Test("System image labels show their symbol under iconOnly")
    func testSystemImageLabelShowsIconUnderIconOnly() {
        // Before Image gained systemName support this degraded to the title.
        // Now the symbol resolves, so the title is genuinely hidden and the
        // label still occupies space -- an empty label would make an
        // enclosing button unclickable.
        let label = Label("Cancel", systemImage: "xmark")

        let rendered = render(label, labelStyle: .iconOnly)
        #expect(rendered.text.isEmpty)
        #expect(rendered.size.x > 0)
        #expect(rendered.size.y > 0)
        // The symbol is sized from the default font, which works out to the
        // 16x16 that the toolbar call sites are laid out around.
        #expect(rendered.size == SIMD2(16, 16))
    }

    @Test("Image resource labels fall back to their title under iconOnly")
    func testImageResourceLabelFallsBackToTitle() {
        // There's no asset catalog, so init(_:image:) has no icon to show and
        // must keep showing its title no matter which style is in effect.
        let label = Label("Cancel", image: "CancelIcon")

        #expect(render(label, labelStyle: .iconOnly).text == ["Cancel"])
        #expect(render(label, labelStyle: .titleOnly).text == ["Cancel"])
        #expect(render(label).text == ["Cancel"])
    }

    @Test("Icon names are preserved for a native symbol provider")
    func testIconNamesArePreserved() {
        let systemImageLabel = Label("Cancel", systemImage: "xmark")
        #expect(systemImageLabel.systemImageName == "xmark")
        #expect(systemImageLabel.imageName == nil)

        let imageLabel = Label("Cancel", image: "CancelIcon")
        #expect(imageLabel.imageName == "CancelIcon")
        #expect(imageLabel.systemImageName == nil)
    }

    @Test("System image labels resolve to real symbol geometry")
    func testSystemImageNamesResolve() {
        // Guards the Label -> Image -> SymbolProvider integration for the
        // symbol names used by the call sites Label was written for.
        for name in ["xmark", "cube", "trash"] {
            #expect(
                LucideSymbolProvider.lucideIcon(forSystemName: name) != nil,
                "\(name) should map to a real Lucide icon"
            )
        }
    }

    @Test("The built-in accessors name the built-in styles")
    func testBuiltInStyleAccessors() {
        // Each accessor has to keep vending its own type so that apps can
        // name the styles they extend or match against.
        let automatic: any LabelStyle = .automatic
        let titleAndIcon: any LabelStyle = .titleAndIcon
        let iconOnly: any LabelStyle = .iconOnly
        let titleOnly: any LabelStyle = .titleOnly

        #expect(automatic is DefaultLabelStyle)
        #expect(titleAndIcon is TitleAndIconLabelStyle)
        #expect(iconOnly is IconOnlyLabelStyle)
        #expect(titleOnly is TitleOnlyLabelStyle)
    }

    @Test("Each built-in style shows the parts it names")
    func testBuiltInStyleVisibility() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("Icon")
        }

        // The automatic style is deliberately indistinguishable from
        // titleAndIcon; SwiftCrossUI has no context in which it resolves to
        // anything else.
        #expect(render(label, labelStyle: .automatic).text == ["Icon", "Title"])
        #expect(render(label, labelStyle: .titleAndIcon).text == ["Icon", "Title"])
        #expect(render(label, labelStyle: .iconOnly).text == ["Icon"])
        #expect(render(label, labelStyle: .titleOnly).text == ["Title"])
    }

    @Test("The default label style is automatic")
    func testDefaultEnvironmentLabelStyle() {
        let backend = DummyBackend()
        let environment = EnvironmentValues(backend: backend)

        #expect(environment.labelStyle is DefaultLabelStyle)
    }

    @Test("A label style defined outside SwiftCrossUI lays labels out")
    func testUserDefinedLabelStyle() {
        // The whole point of LabelStyle being a protocol: an app can supply a
        // style that SwiftCrossUI has never heard of.
        let label = Label {
            Text("Title")
        } icon: {
            Text("Icon")
        }

        #expect(render(label, labelStyle: .reversed).text == ["Title", "Icon"])
        #expect(
            render(label, labelStyle: ReversedLabelStyle()).text == ["Title", "Icon"]
        )
    }

    @Test("labelStyle(_:) accepts a style defined outside SwiftCrossUI")
    func testUserDefinedLabelStylePropagates() {
        let view = VStack {
            Label {
                Text("Title")
            } icon: {
                Text("Icon")
            }
        }
        .labelStyle(.reversed)

        #expect(render(view).text == ["Title", "Icon"])
    }
}

/// The outcome of rendering a view with a ``DummyBackend``.
private struct RenderResult {
    /// The content of every rendered text view, in breadth-first order.
    var text: [String]
    /// The size that the view laid out at.
    var size: SIMD2<Int>
}

/// Renders `view` with a ``DummyBackend``, leaving the environment's default
/// label style in place.
///
/// - Parameter view: The view to render.
/// - Returns: The rendered text and the view's laid out size.
@MainActor
private func render<Content: View>(_ view: Content) -> RenderResult {
    renderView(view, labelStyle: nil)
}

/// Renders `view` with a ``DummyBackend`` and the given label style.
///
/// - Parameters:
///   - view: The view to render.
///   - labelStyle: The label style to seed the environment with.
/// - Returns: The rendered text and the view's laid out size.
@MainActor
private func render<Content: View>(
    _ view: Content,
    labelStyle: any LabelStyle
) -> RenderResult {
    renderView(view, labelStyle: labelStyle)
}

/// Renders `view` with a ``DummyBackend`` and reports what it produced.
///
/// - Parameters:
///   - view: The view to render.
///   - labelStyle: The label style to seed the environment with, or `nil` to
///     leave the environment's default in place.
/// - Returns: The rendered text and the view's laid out size.
@MainActor
private func renderView<Content: View>(
    _ view: Content,
    labelStyle: (any LabelStyle)?
) -> RenderResult {
    let backend = DummyBackend()
    let window = backend.createWindow(withDefaultSize: nil, id: "window")
    var environment = EnvironmentValues(backend: backend).with(\.window, window)
    if let labelStyle {
        environment = environment.with(\.labelStyle, labelStyle)
    }

    let node = ViewGraphNode(
        for: view,
        backend: backend,
        environment: environment
    )
    let layout = node.computeLayout(
        proposedSize: .unspecified,
        environment: environment
    )
    _ = node.commit()

    return RenderResult(
        text: textContent(in: node.widget),
        size: layout.size.vector
    )
}

/// Collects the content of every text view in a widget hierarchy.
///
/// - Parameter widget: The root of the hierarchy to search.
/// - Returns: The content of each text view, in breadth-first order.
private func textContent(in widget: DummyBackend.Widget) -> [String] {
    var content: [String] = []
    var queue = [widget]
    while let next = queue.first {
        queue.removeFirst()
        if let textView = next as? DummyBackend.TextView {
            content.append(textView.content)
        }
        queue.append(contentsOf: next.getChildren())
    }
    return content
}
