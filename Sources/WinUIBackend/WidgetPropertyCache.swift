@_spi(Backends) import SwiftCrossUI
import UWP
import WinUI

/// Remembers the last value SwiftCrossUI wrote to each widget property that it
/// rewrites on every update pass.
///
/// Every dependency property set on a WinUI element crosses the WinRT
/// projection and invalidates that element's measure and arrange passes, even
/// when the value being written is the one the property already holds. A
/// CAD-shaped window has thousands of widgets whose size, position, text,
/// fonts and colours are identical from one update pass to the next, so the
/// backend writes tens of thousands of properties per pass for no visual
/// effect. Comparing a remembered value costs one dictionary lookup.
///
/// ## What may and may not be cached
///
/// An entry is only valid while the backend is the sole writer of the property
/// it describes. Code that writes one of these properties directly must call
/// ``invalidate(_:)`` for that widget afterwards.
///
/// Entries are keyed by the identity of the Swift object SwiftCrossUI holds
/// onto for a widget's whole lifetime. They must never be keyed by an object
/// obtained from a WinRT collection (such as `Canvas.children.getAt(_:)`),
/// because the projection hands back a fresh Swift object each time, which
/// would both miss on every lookup and grow the table without bound. Child
/// positions are therefore stored against the *container*, indexed by child
/// index, and invalidated whenever the container's children are rearranged.
@MainActor
final class WidgetPropertyCache {
    static let shared = WidgetPropertyCache()

    /// The values last written to one widget.
    final class Entry {
        /// The widget the entry describes. Weak so that a closed window's
        /// widgets can be deallocated.
        weak var widget: WinUI.FrameworkElement?

        /// The last size written by ``WinUIBackend/setSize(of:to:)``.
        var size: SIMD2<Int>?

        /// The last positions written by
        /// ``WinUIBackend/setPosition(ofChildAt:in:to:)``, keyed by child
        /// index. Stored on the container; see the note on the enclosing type.
        var childPositions: [Int: SIMD2<Int>] = [:]

        /// The last text written to a text block.
        var text: String?
        /// The last text selection setting written to a text block.
        var isTextSelectionEnabled: Bool?
        /// The last font applied to a text block or control.
        var font: SwiftCrossUI.Font.Resolved?
        /// The last foreground colour applied to a text block or control.
        var foregroundColor: SwiftCrossUI.Color.Resolved?
        /// The last enabled state applied to a control.
        var isEnabled: Bool?
        /// The last colour scheme applied to a control.
        var colorScheme: SwiftCrossUI.ColorScheme?

        /// The last background colour written to a colourable rectangle.
        var backgroundColor: SwiftCrossUI.Color.Resolved?

        /// The last stroke colour written to a path widget.
        var pathStrokeColor: SwiftCrossUI.Color.Resolved?
        /// The last fill colour written to a path widget.
        var pathFillColor: SwiftCrossUI.Color.Resolved?
        /// The last stroke style written to a path widget.
        var pathStrokeStyle: SwiftCrossUI.StrokeStyle?

        /// The label element of a button.
        ///
        /// Held so that the label isn't re-activated on every update pass, and
        /// so that there is always one Swift object for it: reading it back out
        /// of `Button.content` would hand back a fresh projection each time,
        /// which can't be used as a cache key.
        var buttonLabel: WinUI.TextBlock?

        /// The accessibility metadata last written to a widget.
        var accessibility: BackendFeatures.AccessibilityProperties?

        /// The tooltip text last written to a tooltip container.
        var tooltip: String?

        /// The keyboard shortcut last written to a shortcut target, and whether
        /// it was enabled. `.some(nil)` means "no shortcut".
        var keyboardShortcut: (shortcut: SwiftCrossUI.KeyboardShortcut?, isEnabled: Bool)?

        init(widget: WinUI.FrameworkElement) {
            self.widget = widget
        }
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    /// The number of entries at the last sweep of dead entries.
    ///
    /// Sweeping is O(number of widgets), so it happens when the table has
    /// doubled rather than on every miss; otherwise building a window's widgets
    /// would be quadratic in the number of widgets.
    private var entryCountAtLastSweep = 0

    private init() {}

    /// The cache entry for a widget, creating one if this is the first time the
    /// widget has been seen.
    ///
    /// - Parameter widget: The widget. Must be an object SwiftCrossUI holds for
    ///   the widget's lifetime, not one just fetched from a WinRT collection.
    /// - Returns: The widget's entry.
    func entry(for widget: WinUI.FrameworkElement) -> Entry {
        let key = ObjectIdentifier(widget)
        if let entry = entries[key], entry.widget === widget {
            return entry
        }

        if entries.count >= max(entryCountAtLastSweep * 2, 64) {
            entries = entries.filter { _, entry in entry.widget != nil }
            entryCountAtLastSweep = entries.count
        }

        let entry = Entry(widget: widget)
        entries[key] = entry
        return entry
    }

    /// Forgets everything remembered about a widget.
    ///
    /// Call this after writing one of the cached properties without going
    /// through the backend method that owns it.
    ///
    /// - Parameter widget: The widget to forget.
    func invalidate(_ widget: WinUI.FrameworkElement) {
        entries.removeValue(forKey: ObjectIdentifier(widget))
    }

    /// Forgets the remembered child positions of a container.
    ///
    /// Positions are stored against a child's index, so rearranging a
    /// container's children makes them meaningless.
    ///
    /// - Parameter container: The container whose children changed.
    func invalidateChildPositions(of container: WinUI.FrameworkElement) {
        entries[ObjectIdentifier(container)]?.childPositions.removeAll()
    }
}

/// Hands out one `SolidColorBrush` per colour instead of allocating a new WinRT
/// object for every property write.
///
/// `updateTextView`, `renderPath` and `setColor(ofColorableRectangle:to:)` each
/// used to construct a fresh brush per call, which means a COM activation and a
/// property set for a value that is nearly always one of a handful of colours.
/// Brushes are immutable as far as this backend is concerned — nothing mutates
/// one after it has been handed out — so sharing them between elements is safe,
/// which is what XAML theme resources do too.
@MainActor
enum SolidColorBrushCache {
    /// Brushes keyed by their packed ARGB value.
    private static var brushes: [UInt32: WinUI.SolidColorBrush] = [:]

    /// A fully transparent brush.
    ///
    /// Gesture targets paint themselves with one so that their empty areas are
    /// hit-testable.
    static var transparent: WinUI.SolidColorBrush {
        brush(for: SwiftCrossUI.Color.Resolved(red: 0, green: 0, blue: 0, opacity: 0))
    }

    /// A brush for a colour.
    ///
    /// - Parameter color: The colour the brush should paint.
    /// - Returns: A shared brush for `color`.
    static func brush(for color: SwiftCrossUI.Color.Resolved) -> WinUI.SolidColorBrush {
        let uwpColor = color.uwpColor
        let key =
            UInt32(uwpColor.a) << 24 | UInt32(uwpColor.r) << 16 | UInt32(uwpColor.g) << 8
            | UInt32(uwpColor.b)
        if let brush = brushes[key] {
            return brush
        }

        let brush = WinUI.SolidColorBrush(uwpColor)
        // A UI only ever uses a bounded palette; the bound is generous purely
        // so that a pathological gradient-per-frame app can't grow forever.
        if brushes.count >= 512 {
            brushes.removeAll(keepingCapacity: true)
        }
        brushes[key] = brush
        return brush
    }
}

/// Caches text measurements so that repeating a measurement doesn't repeat the
/// WinRT layout pass that produced it.
///
/// Measuring a string means writing the shared measurement block's text and
/// font across the projection and then running a real WinUI measure pass. The
/// layout system asks for a view's size up to three times per update pass (a
/// minimum probe, a maximum probe and a final proposal) and asks again on the
/// next pass even when nothing changed, so a window of static labels re-runs
/// every one of those measures every frame.
@MainActor
enum TextMeasurementCache {
    /// Everything a measurement depends on.
    ///
    /// Deliberately spells out each input rather than hashing the environment,
    /// so that adding an input that measurement starts to depend on is a
    /// compile-time decision rather than a silent stale result.
    struct Key: Hashable {
        var text: String
        var proposedWidth: Int?
        var proposedHeight: Int?
        var font: SwiftCrossUI.Font.Resolved
        var lineLimit: SwiftCrossUI.LineLimit?
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
        // Text content is unbounded (a text field's contents change on every
        // keystroke), so the cache is bounded and simply emptied when it grows
        // too large rather than maintaining a recency order.
        if measurements.count >= 8192 {
            measurements.removeAll(keepingCapacity: true)
        }
        measurements[key] = size
    }

    /// Empties the cache.
    ///
    /// Called when something that measurements depend on but that isn't part of
    /// ``Key`` changes, such as the system's text scale.
    static func invalidate() {
        measurements.removeAll(keepingCapacity: true)
    }
}
