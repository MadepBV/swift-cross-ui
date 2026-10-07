// GENERATED FILE -- DO NOT EDIT.
//
// Regenerate with `Scripts/generate-symbol-geometry.py`.

//
// The pairings below were reviewed by hand. The table lives in
// `Scripts/generate-symbol-geometry.py`; edit it there.

/// Maps Apple SF Symbol names onto the Lucide icons SwiftCrossUI
/// draws in their place.
///
/// SF Symbols are an Apple-only font. SwiftCrossUI accepts the names
/// so that SwiftUI source compiles unchanged, and renders a reviewed
/// Lucide equivalent on platforms that have no SF Symbols.
enum SFSymbolLucideMapping {
    /// The Lucide icon drawn for an SF Symbol name.
    ///
    /// - Parameter name: An SF Symbol name, e.g. `"square.and.arrow.up"`.
    /// - Returns: A kebab-case Lucide icon name, or `nil` if the
    ///   symbol isn't in the table.
    static func lucideIcon(forSystemName name: String) -> String? {
        table[name]
    }

    /// The icon drawn for a symbol name that isn't in the table.
    ///
    /// Deliberately generic: a reader can tell that an icon is
    /// missing, rather than being shown a confidently wrong one.
    static let placeholderIcon = "square-dashed"

    /// Every SF Symbol name the table covers, sorted.
    static var systemNames: [String] {
        table.keys.sorted()
    }

    /// Whether a symbol is drawn as a solid glyph rather than an
    /// outline.
    ///
    /// Filled and outline SF Symbols usually mean different things --
    /// a filled warning triangle is a warning, an outline one is a
    /// note -- so a name spelled `.fill` is drawn filled wherever the
    /// generator could derive a filled variant for its Lucide icon.
    ///
    /// - Parameter name: An SF Symbol name.
    /// - Returns: `true` if the symbol has a solid glyph.
    static func drawsFilled(_ name: String) -> Bool {
        filledSystemNames.contains(name)
    }

    /// Every SF Symbol name drawn with a solid glyph, sorted.
    static let filledSystemNames: Set<String> = [
        "arrowtriangle.down.fill",
        "checkmark.circle.fill",
        "checkmark.seal.fill",
        "circle.fill",
        "exclamationmark.circle.fill",
        "exclamationmark.triangle.fill",
        "heart.fill",
        "lock.fill",
        "lock.open.fill",
        "lock.shield.fill",
        "play.fill",
        "smallcircle.filled.circle.fill",
        "stop.fill",
        "xmark.circle.fill",
        "xmark.octagon.fill",
    ]

    private static let table: [String: String] = [
        // 4k.tv: Lucide has no 4K television; a plain television is used.
        "4k.tv": "tv",
        "airplay.video": "airplay",
        // angle: Lucide has no angle glyph; a right triangle is the closest shape.
        "angle": "triangle-right",
        // apple.intelligence: Lucide has no Apple Intelligence mark; sparkles are used.
        "apple.intelligence": "sparkles",
        "arrow.clockwise": "refresh-cw",
        // arrow.clockwise.circle: Lucide has no circled clockwise arrow; the bare arrows are used.
        "arrow.clockwise.circle": "refresh-cw",
        // arrow.clockwise.circle.fill: Lucide has no circled refresh arrow; the plain refresh is used. Lucide has no filled variants; the outline icon is used.
        "arrow.clockwise.circle.fill": "refresh-cw",
        "arrow.counterclockwise": "rotate-ccw",
        "arrow.down": "arrow-down",
        "arrow.down.app": "square-arrow-down",
        "arrow.down.circle": "circle-arrow-down",
        "arrow.down.doc": "file-down",
        "arrow.down.right.and.arrow.up.left": "minimize-2",
        "arrow.down.to.line": "arrow-down-to-line",
        "arrow.left.and.right": "arrow-left-right",
        "arrow.left.and.right.righttriangle.left.righttriangle.right": "flip-horizontal-2",
        // arrow.left.and.right.righttriangle.left.righttriangle.right.fill: Lucide has no filled variants; the outline icon is used.
        "arrow.left.and.right.righttriangle.left.righttriangle.right.fill": "flip-horizontal-2",
        // arrow.left.and.right.square: Lucide has no enclosing square for this arrow pair.
        "arrow.left.and.right.square": "arrow-left-right",
        "arrow.left.arrow.right": "arrow-left-right",
        "arrow.right": "arrow-right",
        "arrow.triangle.2.circlepath": "refresh-cw",
        // arrow.triangle.2.circlepath.doc.on.clipboard: Lucide has no refresh-badged clipboard; the plain copy-to-clipboard icon is used.
        "arrow.triangle.2.circlepath.doc.on.clipboard": "clipboard-copy",
        "arrow.triangle.branch": "git-branch",
        "arrow.triangle.merge": "git-merge",
        "arrow.trianglehead.2.clockwise.rotate.90": "rotate-cw",
        "arrow.turn.down.right": "corner-down-right",
        "arrow.up": "arrow-up",
        "arrow.up.and.down": "arrow-up-down",
        "arrow.up.and.down.and.arrow.left.and.right": "move",
        "arrow.up.circle": "circle-arrow-up",
        "arrow.up.left": "arrow-up-left",
        "arrow.up.left.and.arrow.down.right": "move-diagonal",
        "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left": "expand",
        "arrow.up.right.and.arrow.down.left": "move-diagonal-2",
        "arrow.up.to.line": "arrow-up-to-line",
        "arrow.uturn.backward": "undo-2",
        // arrow.uturn.backward.circle: Lucide has no circled u-turn arrow; the uncircled undo arrow is used.
        "arrow.uturn.backward.circle": "undo-2",
        "arrow.uturn.forward": "redo-2",
        // arrowtriangle.down.fill: Lucide has no downward triangle; its upward one is turned half a turn about the canvas centre. Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "arrowtriangle.down.fill": "triangle-down",
        "at": "at-sign",
        "backward.end": "skip-back",
        // backward.end.fill: Lucide has no filled variants; the outline icon is used.
        "backward.end.fill": "skip-back",
        "bell": "bell",
        "books.vertical": "library",
        "bubble.left.and.text.bubble.right": "messages-square",
        "building.2": "building-2",
        // building.2.crop.circle: Lucide has no circle-cropped building; the plain building is used.
        "building.2.crop.circle": "building-2",
        // building.2.fill: Lucide has no filled variants; the outline icon is used.
        "building.2.fill": "building-2",
        "camera.viewfinder": "scan-eye",
        // captions.bubble: Lucide has no captions speech bubble; the captions frame is used.
        "captions.bubble": "captions",
        "cat": "cat",
        "character": "type",
        "character.bubble": "message-square",
        "character.cursor.ibeam": "text-cursor",
        "checklist": "list-checks",
        "checkmark": "check",
        "checkmark.circle": "circle-check",
        // checkmark.circle.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "checkmark.circle.fill": "circle-check",
        "checkmark.seal": "badge-check",
        // checkmark.seal.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "checkmark.seal.fill": "badge-check",
        "checkmark.shield": "shield-check",
        "chevron.backward": "chevron-left",
        "chevron.down": "chevron-down",
        "chevron.forward": "chevron-right",
        "chevron.right": "chevron-right",
        "chevron.up": "chevron-up",
        "chevron.up.chevron.down": "chevrons-up-down",
        "circle": "circle",
        "circle.dashed": "circle-dashed",
        // circle.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "circle.fill": "circle",
        "circle.grid.3x3": "grid-3x3",
        // circle.grid.cross: Lucide has no cross-arranged dot grid; a full 3x3 grid is used.
        "circle.grid.cross": "grid-3x3",
        "circle.lefthalf.filled": "contrast",
        "clock": "clock",
        "clock.arrow.circlepath": "history",
        "crop": "crop",
        "cube": "box",
        // cube.transparent: Lucide has no see-through cube; the solid outline box is used.
        "cube.transparent": "box",
        "cursorarrow": "mouse-pointer-2",
        "cursorarrow.click": "mouse-pointer-click",
        "cursorarrow.click.2": "mouse-pointer-click",
        "cursorarrow.rays": "mouse-pointer-click",
        "delete.left": "delete",
        "doc": "file",
        // doc.badge.ellipsis: Lucide has no badged document; a plain document is used so the icon reads as generic rather than as the wrong action.
        "doc.badge.ellipsis": "file",
        "doc.badge.gearshape": "file-cog",
        "doc.badge.plus": "file-plus",
        // doc.fill: Lucide has no filled variants; the outline icon is used.
        "doc.fill": "file",
        "doc.on.doc": "files",
        "doc.text": "file-text",
        "dot.scope": "locate",
        "ellipsis": "ellipsis",
        "ellipsis.circle": "circle-ellipsis",
        // exclamationmark.arrow.circlepath: Lucide has no warning inside circling arrows; circling arrows with a dot are used.
        "exclamationmark.arrow.circlepath": "refresh-ccw-dot",
        // exclamationmark.arrow.triangle.2.circlepath: Lucide has no warning-badged refresh; the plain refresh is used.
        "exclamationmark.arrow.triangle.2.circlepath": "refresh-cw",
        "exclamationmark.circle": "circle-alert",
        // exclamationmark.circle.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "exclamationmark.circle.fill": "circle-alert",
        "exclamationmark.triangle": "triangle-alert",
        // exclamationmark.triangle.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "exclamationmark.triangle.fill": "triangle-alert",
        "eye": "eye",
        "eye.slash": "eye-off",
        "film": "film",
        // film.stack: Lucide has no stack of film; a single film strip is used.
        "film.stack": "film",
        "folder": "folder",
        "forward.end": "skip-forward",
        // forward.end.fill: Lucide has no filled variants; the outline icon is used.
        "forward.end.fill": "skip-forward",
        "function": "square-function",
        "gearshape": "settings",
        "gift": "gift",
        "globe": "globe",
        "grid": "grid-2x2",
        "hammer": "hammer",
        // hand.draw.fill: Lucide has no filled variants; the outline icon is used.
        "hand.draw.fill": "hand",
        "hand.thumbsdown": "thumbs-down",
        // hand.thumbsdown.fill: Lucide has no filled variants; the outline icon is used.
        "hand.thumbsdown.fill": "thumbs-down",
        "hand.thumbsup": "thumbs-up",
        // hand.thumbsup.fill: Lucide has no filled variants; the outline icon is used.
        "hand.thumbsup.fill": "thumbs-up",
        "heart": "heart",
        // heart.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "heart.fill": "heart",
        // heart.text.square: Lucide has no heart beside text in a square; a page with a heart is used.
        "heart.text.square": "file-heart",
        // i.square: Lucide has no lettered square; a plain square is used. An application needing the letter should supply its own glyph.
        "i.square": "square",
        "icloud.and.arrow.down": "cloud-download",
        "info.circle": "info",
        // iphone.and.arrow.forward: Lucide has no phone with a forward arrow; a phone is used.
        "iphone.and.arrow.forward": "smartphone",
        "keyboard": "keyboard",
        // laurel.leading: Lucide has no laurel branch; an award ribbon is used.
        "laurel.leading": "award",
        "line.3.horizontal.decrease.circle": "list-filter",
        "line.diagonal": "slash",
        "link": "link",
        // link.badge.plus: Lucide has no badged link; the plain link is used.
        "link.badge.plus": "link",
        // link.circle.fill: Lucide has no circled link; the plain link is used.
        "link.circle.fill": "link",
        "list.bullet.clipboard": "clipboard-list",
        "list.bullet.rectangle": "list",
        "list.bullet.rectangle.portrait": "list",
        // lock.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "lock.fill": "lock",
        "lock.open": "lock-open",
        // lock.open.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "lock.open.fill": "lock-open",
        // lock.shield: Lucide has no lock-in-shield icon; a plain shield is used.
        "lock.shield": "shield",
        // lock.shield.fill: Lucide has no lock-in-shield icon; a plain shield is used. Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "lock.shield.fill": "shield",
        "magnifyingglass": "search",
        "minus": "minus",
        "minus.circle": "circle-minus",
        "minus.magnifyingglass": "zoom-out",
        "move.3d": "move-3d",
        "music.note": "music",
        "nosign": "ban",
        "paintbrush": "paintbrush",
        "paintbrush.pointed": "brush",
        "paintpalette": "palette",
        // paintpalette.fill: Lucide has no filled variants; the outline icon is used.
        "paintpalette.fill": "palette",
        "pencil": "pencil",
        "pencil.and.outline": "square-pen",
        "pencil.and.ruler": "pencil-ruler",
        // pencil.and.ruler.fill: Lucide has no filled variants; the outline icon is used.
        "pencil.and.ruler.fill": "pencil-ruler",
        "person": "user",
        "person.crop.circle": "circle-user",
        // person.fill: Lucide has no filled variants; the outline icon is used.
        "person.fill": "user",
        "photo": "image",
        // photo.badge.exclamationmark: Lucide has no image-error icon; the unavailable-image icon is used.
        "photo.badge.exclamationmark": "image-off",
        "photo.badge.plus": "image-plus",
        "photo.on.rectangle.angled": "images",
        "play": "play",
        "play.circle": "circle-play",
        // play.circle.fill: Lucide has no filled variants; the outline icon is used.
        "play.circle.fill": "circle-play",
        // play.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "play.fill": "play",
        "play.rectangle": "square-play",
        // play.rectangle.fill: Lucide has no filled variants; the outline icon is used.
        "play.rectangle.fill": "square-play",
        // play.rectangle.on.rectangle.fill: Lucide has no stacked play rectangles; one play rectangle is used.
        "play.rectangle.on.rectangle.fill": "square-play",
        // play.slash: Lucide has no struck-through play triangle; a struck-through camera is used.
        "play.slash": "video-off",
        "plus": "plus",
        "plus.circle": "circle-plus",
        "plus.magnifyingglass": "zoom-in",
        "plus.rectangle.on.rectangle": "copy-plus",
        "plus.square": "square-plus",
        "plus.square.on.square": "copy-plus",
        "point.3.connected.trianglepath.dotted": "spline",
        "point.3.filled.connected.trianglepath.dotted": "waypoints",
        "point.topleft.down.curvedto.point.bottomright.up": "spline",
        "point.topleft.down.to.point.bottomright.curvepath": "spline",
        "printer": "printer",
        // printer.fill: Lucide has no filled variants; the outline icon is used.
        "printer.fill": "printer",
        // questionmark: Lucide has no bare question mark; a circled one is used.
        "questionmark": "circle-question-mark",
        "questionmark.circle": "circle-help",
        "rectangle.and.hand.point.up.left": "square-dashed-mouse-pointer",
        "rectangle.and.pencil.and.ellipsis": "square-pen",
        // rectangle.badge.minus: Lucide has no badged rectangle; a minus inside a square is used.
        "rectangle.badge.minus": "square-minus",
        // rectangle.badge.plus: Lucide has no badged rectangle; a plus inside a square is used.
        "rectangle.badge.plus": "square-plus",
        "rectangle.bottomthird.inset.filled": "panel-bottom",
        // rectangle.dashed: Lucide's only dashed outline is square rather than oblong.
        "rectangle.dashed": "square-dashed",
        "rectangle.grid.2x2": "grid-2x2",
        // rectangle.inset.filled: Lucide has no inset-fill rectangle; the dashed zone outline is used.
        "rectangle.inset.filled": "square-dashed",
        "rectangle.on.rectangle.angled": "panels-top-left",
        "rectangle.portrait": "rectangle-vertical",
        "rectangle.portrait.and.arrow.forward": "square-arrow-right",
        "rectangle.split.2x1": "square-split-horizontal",
        "rectangle.stack": "layers-2",
        "rectangle.stack.badge.plus": "layers-plus",
        // rectangle.stack.fill: Lucide has no filled variants; the outline icon is used.
        "rectangle.stack.fill": "layers-2",
        "rotate.left": "rotate-ccw",
        "rotate.right": "rotate-cw",
        // rotate.right.fill: Lucide has no filled variants; the outline icon is used.
        "rotate.right.fill": "rotate-cw",
        "ruler": "ruler",
        // ruler.fill: Lucide has no filled variants; the outline icon is used.
        "ruler.fill": "ruler",
        "scissors": "scissors",
        "scope": "crosshair",
        // scribble.variable: Lucide has no freehand scribble; the pen tool is used.
        "scribble.variable": "pen-tool",
        "seal": "badge",
        "server.rack": "server",
        "sidebar.left": "panel-left",
        "sidebar.leading": "panel-left",
        "sidebar.right": "panel-right",
        "sidebar.trailing": "panel-right",
        "slider.horizontal.3": "sliders-horizontal",
        "smallcircle.filled.circle": "circle-dot",
        // smallcircle.filled.circle.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "smallcircle.filled.circle.fill": "circle-dot",
        "sparkle": "sparkle",
        "sparkles": "sparkles",
        "square.3.layers.3d": "layers-3",
        "square.3.stack.3d": "layers-3",
        "square.and.arrow.down": "download",
        "square.and.arrow.up": "share",
        "square.and.pencil": "square-pen",
        "square.dashed": "square-dashed",
        // square.dashed.inset.filled: Lucide has no filled variants; the outline icon is used.
        "square.dashed.inset.filled": "square-dashed",
        "square.grid.2x2": "layout-grid",
        "square.grid.3x1.below.line.grid.1x2": "rows-3",
        "square.grid.3x3": "grid-3x3",
        "square.grid.3x3.square": "grid-3x3",
        "square.on.square.dashed": "shapes",
        "square.on.square.intersection.dashed": "combine",
        "square.split.1x2": "square-split-vertical",
        // square.split.diagonal.2x2: Lucide has no diagonally split square; a quartered square is used.
        "square.split.diagonal.2x2": "grid-2x2",
        "square.stack.3d.up": "layers-3",
        // square.stack.3d.up.fill: Lucide has no filled variants; the outline icon is used.
        "square.stack.3d.up.fill": "layers-3",
        // square.stack.3d.up.slash: Lucide has no struck-through layers icon, so the 'disabled' slash is lost.
        "square.stack.3d.up.slash": "layers-3",
        "star": "star",
        "stop.circle": "circle-stop",
        // stop.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "stop.fill": "square",
        "tablecells": "table-2",
        // tablecells.fill: Lucide has no filled variants; the outline icon is used.
        "tablecells.fill": "table-2",
        // text.below.photo: Lucide has no photo-with-caption icon; a captioned frame is used.
        "text.below.photo": "captions",
        "text.bubble": "message-square-text",
        "text.magnifyingglass": "text-search",
        "text.page": "file-text",
        "text.page.badge.magnifyingglass": "file-search",
        "textformat": "type",
        "trash": "trash-2",
        "tray": "inbox",
        // trophy.fill: Lucide has no filled variants; the outline icon is used.
        "trophy.fill": "trophy",
        "tv": "tv",
        "tv.and.mediabox": "monitor-speaker",
        "video": "video",
        "viewfinder": "scan",
        "wand.and.stars": "wand-sparkles",
        "wifi": "wifi",
        // wifi.exclamationmark: Lucide has no Wi-Fi warning; Wi-Fi off is used.
        "wifi.exclamationmark": "wifi-off",
        "xmark": "x",
        "xmark.circle": "circle-x",
        // xmark.circle.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "xmark.circle.fill": "circle-x",
        // xmark.octagon.fill: Lucide has no filled variants, so the solid glyph is derived from the outline geometry by the generator.
        "xmark.octagon.fill": "octagon-x",
    ]
}
