/// Pure width negotiation shared by HSplitView layout and divider updates.
/// Minimums win when the enclosing window is narrower than their sum.
enum HorizontalSplitLayout {
    struct Bounds: Equatable {
        var minimum: Double
        var ideal: Double
        var maximum: Double

        init(minimum: Double, ideal: Double, maximum: Double) {
            self.minimum = minimum.isFinite ? max(0, minimum) : 0
            self.maximum = maximum.isNaN ? self.minimum : max(self.minimum, maximum)
            self.ideal = min(self.maximum, max(self.minimum, ideal.isFinite ? ideal : self.minimum))
        }
    }

    static func widths(bounds: [Bounds], preferred: [Int: Double], available: Double?) -> [Double] {
        guard let available else { return bounds.map(\.ideal) }
        if available == .infinity { return bounds.map(\.maximum) }
        if available <= 0 { return bounds.map(\.minimum) }
        var result = bounds.enumerated().map { index, bound in
            min(bound.maximum, max(bound.minimum, preferred[index] ?? bound.ideal))
        }
        var remaining = available - result.reduce(0, +)
        if remaining > 0 {
            // A flexible workspace takes the spare width before a bounded
            // inspector grows beyond its ideal or its user's chosen width.
            let flexible = bounds.indices.filter { bounds[$0].maximum == .infinity }
            if !flexible.isEmpty {
                for index in flexible { result[index] += remaining / Double(flexible.count) }
                return result
            }
        }
        // Bounded peers share growth/shrinkage equally until a limit is hit.
        // Every iteration either finishes or saturates at least one pane.
        while abs(remaining) > 0.000_001 {
            let growing = remaining > 0
            let eligible = bounds.indices.filter {
                growing ? result[$0] < bounds[$0].maximum : result[$0] > bounds[$0].minimum
            }
            guard !eligible.isEmpty else { break }
            let share = remaining / Double(eligible.count)
            var consumed = 0.0
            for index in eligible {
                let next = min(bounds[index].maximum, max(bounds[index].minimum, result[index] + share))
                consumed += next - result[index]
                result[index] = next
            }
            guard consumed != 0 else { break }
            remaining -= consumed
        }
        return result
    }

    /// A drag moves only its two neighbouring visible panes. Callers supply
    /// widths at the start of that drag and its total window-space translation.
    static func movedWidths(_ widths: [Double], bounds: [Bounds], left: Int, right: Int,
        delta: Double) -> [Double]? {
        guard delta.isFinite, widths.count == bounds.count,
            widths.indices.contains(left), widths.indices.contains(right), left < right,
            widths[left] > 0, widths[right] > 0 else { return nil }
        let total = widths[left] + widths[right]
        let lower = max(bounds[left].minimum, total - bounds[right].maximum)
        let upper = min(bounds[left].maximum, total - bounds[right].minimum)
        guard lower <= upper else { return nil }
        let leading = min(upper, max(lower, widths[left] + delta))
        var result = widths
        result[left] = leading
        result[right] = total - leading
        return result
    }
}
