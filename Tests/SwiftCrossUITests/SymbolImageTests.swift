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

    @Test("Filled variants are drawn from their outline sibling's icon")
    func testFilledVariantsShareTheirOutlineIcon() {
        // Lucide has no filled counterparts, so a `.fill` name lands on the
        // same icon as its unfilled sibling. What differs is how that icon is
        // drawn, not which icon it is.
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

    // MARK: - Filled symbols

    /// The `.fill` names that carry state or severity in the production app,
    /// with how often they appear, and which must never quietly degrade to an
    /// outline: an outline warning triangle reads as an informational note.
    static let semanticFillNames = [
        "checkmark.circle.fill",  // 27 uses: success
        "exclamationmark.triangle.fill",  // 26 uses: warning
        "exclamationmark.circle.fill",  // 18 uses: error
        "lock.fill",  // 16 uses: locked
    ]

    @Test("The .fill names that carry meaning are drawn solid")
    func testSemanticFillNamesAreFilled() {
        let provider = LucideSymbolProvider(
            drawsPlaceholderForUnknownNames: false
        )

        for name in Self.semanticFillNames {
            #expect(
                SFSymbolLucideMapping.drawsFilled(name),
                "'\(name)' isn't marked as filled"
            )
            let request = SymbolRenderRequest(name: name, pointSize: 17)
            guard case .geometry(let geometry) = provider.resolve(request)
            else {
                Issue.record("'\(name)' didn't resolve")
                continue
            }
            #expect(
                geometry.rendering == .filled,
                "'\(name)' resolved to an outline"
            )
        }
    }

    @Test("A filled symbol differs from its outline sibling")
    func testFilledSymbolsDifferFromTheirOutline() {
        // The whole point of the exercise: the two must not be the same
        // drawing, or the state they encode is invisible to the reader.
        let provider = LucideSymbolProvider(
            drawsPlaceholderForUnknownNames: false
        )
        let pairs = [
            ("checkmark.circle.fill", "checkmark.circle"),
            ("exclamationmark.circle.fill", "exclamationmark.circle"),
            ("exclamationmark.triangle.fill", "exclamationmark.triangle"),
            ("xmark.circle.fill", "xmark.circle"),
            ("circle.fill", "circle"),
        ]

        for (filled, outline) in pairs {
            guard
                case .geometry(let solid) = provider.resolve(
                    SymbolRenderRequest(name: filled, pointSize: 17)
                ),
                case .geometry(let stroked) = provider.resolve(
                    SymbolRenderRequest(name: outline, pointSize: 17)
                )
            else {
                Issue.record("'\(filled)' or '\(outline)' didn't resolve")
                continue
            }
            #expect(solid.rendering == .filled, "'\(filled)' isn't filled")
            #expect(stroked.rendering == .stroked, "'\(outline)' is filled")
            #expect(solid != stroked, "'\(filled)' draws its outline")
        }
    }

    @Test("Only names the table lists are drawn filled")
    func testUnlistedFillNamesStayOutlines() {
        // `pencil.fill` falls back to `pencil`'s geometry, but a fallback is
        // a guess about the name, not a licence to guess at the drawing too.
        #expect(!SFSymbolLucideMapping.drawsFilled("pencil.fill"))

        let provider = LucideSymbolProvider(
            drawsPlaceholderForUnknownNames: false
        )
        guard
            case .geometry(let geometry) = provider.resolve(
                SymbolRenderRequest(name: "pencil.fill", pointSize: 17)
            )
        else {
            Issue.record("'pencil.fill' should still draw something")
            return
        }
        #expect(geometry == LucideIconGeometry.geometry(forIcon: "pencil"))
    }

    @Test("Every name marked filled resolves to filled geometry")
    func testEveryFilledNameResolvesFilled() {
        let provider = LucideSymbolProvider(
            drawsPlaceholderForUnknownNames: false
        )

        for name in SFSymbolLucideMapping.filledSystemNames {
            let request = SymbolRenderRequest(name: name, pointSize: 17)
            guard case .geometry(let geometry) = provider.resolve(request)
            else {
                Issue.record("'\(name)' didn't resolve")
                continue
            }
            #expect(geometry.rendering == .filled, "'\(name)' isn't filled")
            #expect(!geometry.commands.isEmpty, "'\(name)' is empty")
        }
    }

    @Test("Filled geometry is closed subpaths only")
    func testFilledGeometryIsMadeOfClosedSubpaths() {
        // An unclosed subpath in filled geometry would be closed implicitly
        // by a straight chord, which is never what the artwork meant.
        for icon in LucideIconGeometry.filledIconNames {
            guard
                let geometry = LucideIconGeometry.filledGeometry(forIcon: icon)
            else {
                Issue.record("'\(icon)' is listed but not bundled")
                continue
            }

            var start: SIMD2<Double>? = nil
            var current: SIMD2<Double>? = nil
            var subpaths = 0
            for command in geometry.commands {
                switch command {
                    case .move(let point):
                        if let start, let current {
                            #expect(
                                isClosed(current, start),
                                "'\(icon)' has an open subpath at \(start)"
                            )
                        }
                        subpaths += 1
                        start = point
                        current = point
                    case .line(let point):
                        current = point
                    case .quadCurve(_, let end):
                        current = end
                    case .cubicCurve(_, _, let end):
                        current = end
                    case .circle:
                        // A circle is closed by construction, but the derived
                        // geometry spells circles out as cubics so that their
                        // winding direction is under the generator's control.
                        Issue.record("'\(icon)' uses an implicit circle")
                }
            }
            if let start, let current {
                #expect(
                    isClosed(current, start),
                    "'\(icon)' has an open subpath at \(start)"
                )
            }
            #expect(subpaths >= 1, "'\(icon)' has no subpaths")
        }
    }

    @Test("A filled symbol's path is filled rather than stroked")
    func testFilledGeometryProducesAnUnstrokedPath() {
        let bounds = Path.Rect(x: 0, y: 0, width: 24, height: 24)
        let filled = SymbolGeometry(
            commands: [
                .move(SIMD2(0, 0)),
                .line(SIMD2(24, 0)),
                .line(SIMD2(24, 24)),
                .line(SIMD2(0, 0)),
            ],
            rendering: .filled
        )

        // Both renderings need the non-zero rule; filled geometry relies on
        // it to tell a hole from another island.
        #expect(filled.path(in: bounds).fillRule == .winding)
        #expect(
            SymbolGeometry(commands: []).path(in: bounds).fillRule == .winding
        )

        // An outline carries its stroke width onto the path; a fill does not,
        // because nothing is stroked.
        let stroked = SymbolGeometry(commands: [], strokeWidth: 2)
        #expect(stroked.path(in: bounds).strokeStyle.width == 2)
        #expect(filled.path(in: bounds).strokeStyle.width != 2)
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
        let outlines = LucideIconGeometry.iconNames.map {
            ($0, LucideIconGeometry.geometry(forIcon: $0))
        }
        let fills = LucideIconGeometry.filledIconNames.map {
            ($0 + " (filled)", LucideIconGeometry.filledGeometry(forIcon: $0))
        }

        for (icon, geometry) in outlines + fills {
            guard let geometry else {
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
    /// Whether a subpath ended where it began, allowing for the rounding the
    /// generator applies to its coordinate literals.
    fileprivate func isClosed(
        _ end: SIMD2<Double>,
        _ start: SIMD2<Double>
    ) -> Bool {
        let tolerance = 0.001
        return abs(end.x - start.x) <= tolerance
            && abs(end.y - start.y) <= tolerance
    }

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
