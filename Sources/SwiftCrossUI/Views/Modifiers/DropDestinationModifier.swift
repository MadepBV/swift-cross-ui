import Foundation  // for CGPoint

extension View {
    /// Defines the destination of a drag-and-drop operation that handles the
    /// dropped payload with a closure.
    ///
    /// ## This modifier is inert
    ///
    /// SwiftCrossUI has no drag-and-drop surface at all: no backend declares a
    /// drop target, none reports a drag entering or leaving a widget, and
    /// there is no payload representation to decode a dropped item from. A
    /// view carrying this modifier therefore never becomes a drop target, and
    /// `action` is never called.
    ///
    /// The modifier exists so that application source written against SwiftUI
    /// compiles unchanged. It deliberately does *not* pretend to handle drops:
    /// the closure is dropped on the floor rather than being invoked with
    /// fabricated payloads.
    ///
    /// ## What real support would need
    ///
    /// Three things, in this order:
    ///
    /// 1. A payload protocol. SwiftUI constrains `T` to `Transferable` and
    ///    reaches the bytes through a `TransferRepresentation`. SwiftCrossUI
    ///    has neither, so this overload is generic over an unconstrained
    ///    `T` — the one deliberate divergence from Apple's signature, made
    ///    so that an application's existing `CoreTransferable.Transferable`
    ///    payload types keep working instead of colliding with a second
    ///    protocol of the same name.
    /// 2. Backend registration. Each backend needs to register a widget as a
    ///    drop target for a set of content types, and to report drag-enter,
    ///    drag-move, drag-leave and drop, each with a location in the widget's
    ///    coordinate space. On AppKit that is `NSView.registerForDraggedTypes`
    ///    plus `NSDraggingDestination`; on GTK a `GtkDropTarget`; on Win32 an
    ///    `IDropTarget`.
    /// 3. A matching drag *source* (`draggable(_:)`), since a drop destination
    ///    on its own can only receive drags that originate outside the app.
    ///
    /// - Parameters:
    ///   - payloadType: The type of the payload the view accepts.
    ///   - action: A closure receiving the dropped items and the drop location
    ///     in the view's coordinate space, returning whether the drop was
    ///     accepted. Never called; see above.
    ///   - isTargeted: A closure told whether a compatible drag is currently
    ///     over the view. Never called; see above.
    /// - Returns: The view, unchanged.
    public func dropDestination<T>(
        for payloadType: T.Type = T.self,
        action: @escaping @MainActor ([T], CGPoint) -> Bool,
        isTargeted: @escaping @MainActor (Bool) -> Void = { _ in }
    ) -> some View {
        self
    }
}
