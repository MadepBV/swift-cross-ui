import Foundation

extension MutableCollection where Self: RangeReplaceableCollection {
    /// Moves the elements at `source` so they sit before the element that was
    /// at `destination`, keeping their order, as SwiftUI's list editing
    /// reports a drag (`onMove`).
    ///
    /// - Parameters:
    ///   - source: The offsets of the elements to move.
    ///   - destination: The offset, in the collection before the move, of the
    ///     element the moved ones go in front of; `count` puts them last.
    public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moving = source.map { self[index(startIndex, offsetBy: $0)] }
        let before = source.filter { $0 < destination }.count
        for offset in source.reversed() {
            remove(at: index(startIndex, offsetBy: offset))
        }
        insert(contentsOf: moving, at: index(startIndex, offsetBy: destination - before))
    }
}

extension RangeReplaceableCollection {
    /// Removes the elements at `offsets`, as SwiftUI's list editing reports a
    /// deletion (`onDelete`).
    ///
    /// - Parameter offsets: The offsets of the elements to remove.
    public mutating func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.reversed() {
            remove(at: index(startIndex, offsetBy: offset))
        }
    }
}

extension Array {
    // Arrays are what list editing almost always moves. Spelled on the concrete type as well, so that on Apple
    // platforms, where SwiftUI's own `MutableCollection` extension may also be visible, the call binds here rather
    // than to a SwiftUI symbol an app built against SwiftCrossUI does not link.

    /// See ``Swift/MutableCollection/move(fromOffsets:toOffset:)``.
    public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moving = source.map { self[$0] }
        let before = source.filter { $0 < destination }.count
        for offset in source.reversed() { remove(at: offset) }
        insert(contentsOf: moving, at: destination - before)
    }

    /// See ``Swift/RangeReplaceableCollection/remove(atOffsets:)``.
    public mutating func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.reversed() { remove(at: offset) }
    }
}
