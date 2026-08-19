import Testing

import DummyBackend
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Testing for Image(systemName:)")
@MainActor
struct SymbolImageTests {
    /// The twenty most-used SF Symbols in the production app this support was
    /// built for, which between them account for most of its call sites.
    ///
    /// The full mapping is generated, so this list guards the names that
    /// matter most rather than restating the whole table.
    static let mostUsedSystemNames = [
        "checkmark.circle.fill",
        "exclamationmark.triangle.fill",
        "checkmark",
        "xmark",
        "plus",
        "trash",
        "exclamationmark.circle.fill",
        "lock.fill",
        "arrow.uturn.backward",
        "scope",
        "ruler",
        "ellipsis.circle",
        "rectangle.badge.plus",
        "point.3.connected.trianglepath.dotted",
        "arrow.counterclockwise",
        "square.stack.3d.up",
        "slider.horizontal.3",
        "paintpalette",
        "line.diagonal",
        "pencil",
    ]

    // MARK: - Mapping table

    @Test("Every mapped symbol resolves to drawable geometry")
    func testEveryMappedSymbolResolves() {
        let provider = LucideSymbolProvider(
            drawsPlaceholderForUnknownNames: false
        )

        for name in LucideSymbolProvider.systemNames {
            let request = SymbolRenderRequest(name: name, pointSize: 17)
            guard case .geometry(let geometry) = provider.resolve(request)
            else {
                Issue.record("'\(name)' didn't resolve to any geometry")
                continue
            }
            #expect(!geometry.commands.isEmpty, "'\(name)' resolved to nothing")
        }
    }

    @Test("The most-used symbols are all covered")
    func testMostUsedSymbolsAreCovered() {
        for name in Self.mostUsedSystemNames {
            #expect(
                LucideSymbolProvider.lucideIcon(forSystemName: name) != nil,
                "'\(name)' isn't in the mapping table"
            )
        }
    }

    @Test("The mapping table never points at a missing icon")
    func testMappingTableHasNoDanglingIcons() {
        let bundled = Set(LucideIconGeometry.iconNames)

        for name in SFSymbolLucideMapping.systemNames {
            let icon = SFSymbolLucideMapping.lucideIcon(forSystemName: name)
            guard let icon else {
                Issue.record("'\(name)' vanished from the mapping table")
                continue
            }
            #expect(bundled.contains(icon), "'\(name)' maps to missing '\(icon)'")
        }

        #expect(bundled.contains(SFSymbolLucideMapping.placeholderIcon))
    }

    @Test("Filled variants resolve to their outline sibling")
    func testFilledVariantsShareTheirOutlineIcon() {
        // Lucide has no filled counterparts, so `.fill` names deliberately
        // land on the same icon as their unfilled siblings.
        let pairs = [
            ("checkmark.circle.fill", "checkmark.circle"),
            ("exclamationmark.circle.fill", "exclamationmark.circle"),
            ("lock.open.fill", "lock.open"),
            ("doc.fill", "doc"),
        ]

        for (filled, outline) in pairs {
            let filledIcon = LucideSymbolProvider.lucideIcon(
                forSystemName: filled
            )
            let outlineIcon = LucideSymbolProvider.lucideIcon(
                forSystemName: outline
            )
            #expect(filledIcon == outlineIcon, "'\(filled)' diverged")
        }
    }

    @Test("An unlisted .fill name falls back to its unfilled sibling")
    func testUnlistedFillNamesFallBack() {
        // `pencil.fill` isn't in the table, but `pencil` is, and Lucide would
        // draw both identically anyway.
        #expect(
            LucideSymbolProvider.lucideIcon(forSystemName: "pencil.fill")
                == LucideSymbolProvider.lucideIcon(forSystemName: "pencil")
        )
        #expect(
            LucideSymbolProvider.lucideIcon(forSystemName: "nonsense.fill")
                == nil
        )
    }

    // MARK: - Unknown names

    @Test("Unknown names draw a generic placeholder by default")
    func testUnknownNameDrawsPlaceholder() {
        let request = SymbolRenderRequest(
            name: "definitely.not.a.symbol",
            pointSize: 17
        )
        guard
            case .geometry(let geometry) = LucideSymbolProvider.shared
                .resolve(request)
        else {
            Issue.record("An unknown name should still draw something")
            return
        }

        let placeholder = LucideIconGeometry.geometry(
            forIcon: SFSymbolLucideMapping.placeholderIcon
        )
        #expect(geometry == placeholder)
    }

    @Test("Placeholders can be turned off")
    func testUnknownNameCanResolveToNothing() {
        let provider = LucideSymbolProvider(
            drawsPlaceholderForUnknownNames: false
        )
        let request = SymbolRenderRequest(
            name: "definitely.not.a.symbol",
            pointSize: 17
        )

        #expect(provider.resolve(request) == nil)
    }

    // MARK: - Geometry

    @Test("Every bundled icon stays inside its canvas")
    func testGeometryStaysWithinItsCanvas() {
        for icon in LucideIconGeometry.iconNames {
            guard let geometry = LucideIconGeometry.geometry(forIcon: icon)
            else {
                Issue.record("'\(icon)' is listed but not bundled")
                continue
            }

            // Half a stroke width of overhang is expected and fine; anything
            // beyond that means a coordinate was mis-parsed.
            let margin = geometry.strokeWidth
            let range = -margin...(geometry.canvasSize + margin)
            for point in points(in: geometry) {
                #expect(
                    range.contains(point.x) && range.contains(point.y),
                    "'\(icon)' has a point outside its canvas: \(point)"
                )
            }
        }
    }

    @Test("Geometry scales into the bounds it's drawn in")
    func testGeometryScalesIntoBounds() {
        let geometry = SymbolGeometry(
            commands: [
                .move(SIMD2(0, 0)),
                .line(SIMD2(24, 24)),
                .circle(center: SIMD2(12, 12), radius: 6),
            ]
        )
        let bounds = Path.Rect(x: 0, y: 0, width: 48, height: 48)

        #expect(geometry.scale(in: bounds) == 2)
        #expect(
            geometry.path(in: bounds).actions == [
                .moveTo(SIMD2(0, 0)),
                .lineTo(SIMD2(48, 48)),
                .circle(center: SIMD2(24, 24), radius: 12),
            ]
        )
    }

    @Test("Geometry is centred when the bounds aren't square")
    func testGeometryIsCentredInNonSquareBounds() {
        let geometry = SymbolGeometry(commands: [.move(SIMD2(0, 0))])
        let bounds = Path.Rect(x: 0, y: 0, width: 48, height: 24)

        // The symbol fits the 24pt height, leaving 12pt of slack each side.
        #expect(geometry.scale(in: bounds) == 1)
        #expect(geometry.path(in: bounds).actions == [.moveTo(SIMD2(12, 0))])
    }

    @Test("Stroke width scales with the symbol")
    func testStrokeWidthScalesWithTheSymbol() {
        let geometry = SymbolGeometry(commands: [])

        let doubled = Path.Rect(x: 0, y: 0, width: 48, height: 48)
        #expect(geometry.strokeStyle(in: doubled).width == 4)

        let halved = Path.Rect(x: 0, y: 0, width: 12, height: 12)
        #expect(geometry.strokeStyle(in: halved).width == 1)
    }

    @Test("An empty canvas doesn't divide by zero")
    func testZeroCanvasSizeIsHandled() {
        let geometry = SymbolGeometry(commands: [], canvasSize: 0)
        let bounds = Path.Rect(x: 0, y: 0, width: 24, height: 24)

        #expect(geometry.scale(in: bounds) == 1)
    }

    // MARK: - Layout

    @Test("A symbol sizes itself from the current font")
    func testSymbolSizesFromFont() {
        let size = renderedSize(of: Image(systemName: "checkmark"))
        let expected = expectedSymbolSize()

        #expect(size.width == expected)
        #expect(size.height == expected)
    }

    @Test("A resizable symbol accepts the proposed size")
    func testResizableSymbolAcceptsProposal() {
        let size = renderedSize(
            of: Image(systemName: "checkmark").resizable(),
            proposedSize: ProposedViewSize(64, 64)
        )

        #expect(size.width == 64)
        #expect(size.height == 64)
    }

    @Test("A symbol ignores the proposal unless it's resizable")
    func testNonResizableSymbolIgnoresProposal() {
        let size = renderedSize(
            of: Image(systemName: "checkmark"),
            proposedSize: ProposedViewSize(64, 64)
        )

        #expect(size.width == expectedSymbolSize())
    }

    @Test("A symbol nothing can resolve takes up no space")
    func testUnresolvableSymbolTakesNoSpace() {
        let size = renderedSize(
            of: Image(systemName: "checkmark"),
            provider: EmptySymbolProvider()
        )

        #expect(size.width == 0)
        #expect(size.height == 0)
    }

    // MARK: - Providers

    @Test("symbolProvider(_:) overrides how names are resolved")
    func testSymbolProviderModifierIsUsed() {
        let provider = FixedSymbolProvider(
            geometry: SymbolGeometry(
                commands: [.move(SIMD2(0, 0))],
                canvasSize: 10
            )
        )
        let size = renderedSize(
            of: Image(systemName: "checkmark").resizable(),
            proposedSize: ProposedViewSize(30, 30),
            provider: provider
        )

        #expect(size.width == 30)
    }

    @Test("A fallback provider is consulted when the first declines")
    func testFallbackProviderChaining() {
        let provider = FallbackSymbolProvider(
            EmptySymbolProvider(),
            fallingBackTo: LucideSymbolProvider.shared
        )
        let request = SymbolRenderRequest(name: "checkmark", pointSize: 17)

        guard case .geometry(let geometry) = provider.resolve(request) else {
            Issue.record("The fallback provider wasn't consulted")
            return
        }
        #expect(geometry == LucideIconGeometry.geometry(forIcon: "check"))
    }

    @Test("The default provider is the bundled Lucide one")
    func testDefaultProviderIsLucide() {
        let environment = EnvironmentValues(backend: DummyBackend())

        #expect(environment.symbolProvider is LucideSymbolProvider)
    }

    @Test("Requests carry the tint and scale factor providers need")
    func testRequestCarriesRenderingContext() {
        let request = SymbolRenderRequest(
            name: "trash",
            pointSize: 17,
            scaleFactor: 2,
            color: .red
        )

        #expect(request == SymbolRenderRequest(
            name: "trash",
            pointSize: 17,
            scaleFactor: 2,
            color: .red
        ))
        #expect(
            request != SymbolRenderRequest(
                name: "trash",
                pointSize: 17,
                scaleFactor: 1,
                color: .red
            )
        )
    }
}

// MARK: - Helpers

/// A provider that never resolves anything, used to exercise fallbacks.
private struct EmptySymbolProvider: SymbolProvider {
    func resolve(_ request: SymbolRenderRequest) -> SymbolResolution? {
        nil
    }
}

/// A provider that answers every name with the same geometry.
private struct FixedSymbolProvider: SymbolProvider {
    var geometry: SymbolGeometry

    func resolve(_ request: SymbolRenderRequest) -> SymbolResolution? {
        .geometry(geometry)
    }
}

extension SymbolImageTests {
    /// Every point referenced by a symbol's commands.
    private func points(in geometry: SymbolGeometry) -> [SIMD2<Double>] {
        geometry.commands.flatMap { command -> [SIMD2<Double>] in
            switch command {
                case .move(let point), .line(let point):
                    return [point]
                case .quadCurve(let control, let end):
                    return [control, end]
                case .cubicCurve(let control1, let control2, let end):
                    return [control1, control2, end]
                case .circle(let center, let radius):
                    return [
                        center - SIMD2(radius, radius),
                        center + SIMD2(radius, radius),
                    ]
            }
        }
    }

    /// The side length a non-resizable symbol takes under the default font.
    private func expectedSymbolSize() -> Double {
        let environment = EnvironmentValues(backend: DummyBackend())
        return environment.resolvedFont.pointSize * 1.2
    }

    /// Lays out `view` with a ``DummyBackend`` and returns its size.
    ///
    /// - Parameters:
    ///   - view: The view to lay out.
    ///   - proposedSize: The size to propose to the view.
    ///   - provider: A symbol provider to install, or `nil` for the default.
    /// - Returns: The size the view chose.
    private func renderedSize<Content: View>(
        of view: Content,
        proposedSize: ProposedViewSize = .unspecified,
        provider: (any SymbolProvider)? = nil
    ) -> ViewSize {
        let backend = DummyBackend()
        let window = backend.createWindow(withDefaultSize: nil, id: "window")
        var environment = EnvironmentValues(backend: backend)
            .with(\.window, window)
        if let provider {
            environment = environment.with(\.symbolProvider, provider)
        }

        let node = ViewGraphNode(
            for: view,
            backend: backend,
            environment: environment
        )
        let layout = node.computeLayout(
            proposedSize: proposedSize,
            environment: environment
        )
        _ = node.commit()
        return layout.size
    }
}
