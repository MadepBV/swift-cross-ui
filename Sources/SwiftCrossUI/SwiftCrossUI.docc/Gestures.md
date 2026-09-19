# Gestures

## Pointer hit testing

Use ``View/allowsHitTesting(_:)`` to make decorative overlays pass pointer hits
through to the content underneath them:

```swift
Button("Fit") {
    // Fit the document's camera.
}
.overlay {
    RoundedRectangle(cornerRadius: 8)
        .stroke(.gray, style: StrokeStyle(lineWidth: 1))
        .allowsHitTesting(false)
}
```

The modifier excludes its whole subtree. A descendant's `true` cannot override
an ancestor's `false`. Place the modifier on the decoration, rather than on the
containing controls, when only the decoration should be passive. Layout, drawing,
control enabled state and keyboard-focus policy are preserved. Explicitly
transparent shapes keep their ordinary native input behavior unless excluded.
This modifier does not cancel or rewrite an already captured pointer interaction.

AppKitBackend and WinUIBackend implement ``BackendFeatures/HitTesting``. Backends
without this optional capability keep their existing hit-testing behavior.

## Topics

### Taps and hovers

- ``View/onTapGesture(gesture:perform:)``
- ``TapGesture``
- ``View/onHover(perform:)``

### Pointer gestures

- ``Gesture``
- ``DragGesture``
- ``SpatialTapGesture``
- ``CoordinateSpace``
- ``PointerButton``
- ``PointerButtons``
- ``View/gesture(_:)``
- ``View/simultaneousGesture(_:)``
- ``GestureModifier``

### Pointer movement

- ``View/onContinuousHover(coordinateSpace:perform:)``
- ``View/onPointerMove(perform:)``
- ``HoverPhase``
- ``PointerMoveEvent``

### Scrolling and zooming

- ``View/onScrollWheel(perform:)``
- ``View/onMagnify(perform:)``
- ``PointerScrollEvent``
- ``PointerMagnifyEvent``
- ``PointerEventPhase``
- ``PointerModifiers``

### Hit testing

- ``View/allowsHitTesting(_:)``

### Backend support

- ``BackendFeatures/HitTesting``
- ``BackendFeatures/PointerGestures``
- ``PointerGestureEvent``
