import AppKit
@_spi(Backends) import SwiftCrossUI

/// Caches text measurements so that repeating a measurement doesn't repeat the
/// Core Text layout that produced it.
///
/// Measuring a string means bridging it to an `NSString`, building a fresh
/// attributes dictionary (a paragraph style, a resolved colour and a font
/// lookup) and running `boundingRect(with:options:attributes:)`. The layout
/// system asks a view for its size up to three times per update pass — a
/// minimum probe, a maximum probe and a final proposal — and asks again on the
/// next pass even when nothing about the view changed, so a window full of
/// static labels re-runs every one of those measurements every frame.
///
/// The `PerformanceHarness` target measures the effect: with a real backend
/// attached, text measurement is the single largest cost in the layout phase of
/// a CAD-shaped window.
@MainActor
enum TextMeasurementCache {
    /// Everything a measurement depends on.
    ///
    /// Deliberately spells out each input rather than hashing the environment,
    /// so that an input that measurement starts to depend on has to be added
    /// here explicitly rather than silently producing a stale result. The
    /// foreground colour is not an input: it is part of the attributes
    /// dictionary but has no effect on text metrics.
    struct Key: Hashable {
        var text: String
        var proposedWidth: Int?
        var proposedHeight: Int?
        var font: Font.Resolved
        var alignment: SwiftCrossUI.HorizontalAlignment
        var lineLimit: LineLimit?
    }

    private static var measurements: [Key: SIMD2<Int>] = [:]

    /// The cached measurement for a key, if there is one.
    ///
    /// - Parameter key: The measurement's inputs.
    /// - Returns: The measured size, or `nil` if it hasn't been measured yet.
    static func measurement(for key: Key) -> SIMD2<Int>? {
        measurements[key]
    }

    /// Records a measurement.
    ///
    /// - Parameters:
    ///   - size: The measured size.
    ///   - key: The measurement's inputs.
    static func record(_ size: SIMD2<Int>, for key: Key) {
        // Text content is unbounded — a text field's contents change on every
        // keystroke — so the cache is bounded and simply emptied when it grows
        // too large rather than maintaining a recency order.
        if measurements.count >= 8192 {
            measurements.removeAll(keepingCapacity: true)
        }
        measurements[key] = size
    }
}

/// Remembers what was last written to each text field, so that rewriting an
/// unchanged label doesn't rebuild its attributed string.
///
/// `Text.computeLayout` updates its widget on every layout computation (see the
/// TODO there: GTK needs the widget updated in order to measure through it), so
/// a label is written up to three times per update pass and again on every pass
/// after that, each time allocating a fresh `NSAttributedString`, paragraph
/// style and attributes dictionary.
@MainActor
enum TextViewStateCache {
    /// What was last written to a text field.
    struct State: Equatable {
        var content: String
        var font: Font.Resolved
        var color: SwiftCrossUI.Color.Resolved
        var alignment: SwiftCrossUI.HorizontalAlignment
        var isSelectable: Bool
    }

    private static let association = ObjectAssociation<Box>()

    /// A box so that the state can live in an object association.
    final class Box {
        var state: State

        init(_ state: State) {
            self.state = state
        }
    }

    /// Whether a text field already holds the given state, recording it if not.
    ///
    /// - Parameters:
    ///   - state: The state that is about to be written.
    ///   - field: The field it would be written to.
    /// - Returns: `true` if the field already holds `state`, in which case the
    ///   write can be skipped.
    static func isUpToDate(_ state: State, for field: NSTextField) -> Bool {
        if let box = association[field] {
            if box.state == state {
                return true
            }
            box.state = state
            return false
        }
        association[field] = Box(state)
        return false
    }
}
