// GENERATED FILE -- DO NOT EDIT.
//
// Regenerate with `Scripts/generate-symbol-geometry.py`.

//
// The geometry in this file is derived from the Lucide icon set
// (https://lucide.dev), used under the ISC license reproduced below. Lucide
// icons are drawn on a 24x24 canvas with a stroke width of 2, round caps and
// round joins, and no fills.
//
// ISC License
//
// Copyright (c) for portions of Lucide are held by Cole Bemis 2013-2022 as part
// of Feather (MIT). All other copyright (c) for Lucide are held by Lucide
// Contributors 2022.
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.


/// The vector geometry of every Lucide icon SwiftCrossUI bundles.
///
/// Each icon is expressed in Lucide's native 24x24 coordinate space;
/// ``SymbolGeometry/path(in:)`` scales it to the size a view needs.
enum LucideIconGeometry {
    /// Looks up an icon's geometry by its Lucide name.
    ///
    /// - Parameter name: A kebab-case Lucide icon name.
    /// - Returns: The icon's geometry, or `nil` if it isn't bundled.
    static func geometry(forIcon name: String) -> SymbolGeometry? {
        guard let commands = commands(forIcon: name) else {
            return nil
        }
        return SymbolGeometry(commands: commands)
    }

    /// Every bundled Lucide icon name, sorted.
    static let iconNames: [String] = [
        "arrow-down-to-line",
        "arrow-left-right",
        "arrow-right",
        "arrow-up-down",
        "arrow-up-left",
        "badge",
        "badge-check",
        "ban",
        "box",
        "brush",
        "building-2",
        "captions",
        "check",
        "chevron-down",
        "chevron-left",
        "chevron-right",
        "chevron-up",
        "chevrons-up-down",
        "circle",
        "circle-alert",
        "circle-check",
        "circle-dashed",
        "circle-dot",
        "circle-ellipsis",
        "circle-help",
        "circle-plus",
        "circle-x",
        "clipboard-copy",
        "combine",
        "copy-plus",
        "corner-down-right",
        "crop",
        "crosshair",
        "delete",
        "download",
        "expand",
        "eye",
        "eye-off",
        "file",
        "file-cog",
        "file-down",
        "file-plus",
        "file-text",
        "files",
        "flip-horizontal-2",
        "folder",
        "git-branch",
        "git-merge",
        "grid-2x2",
        "grid-3x3",
        "hammer",
        "hand",
        "history",
        "image",
        "image-off",
        "image-plus",
        "images",
        "inbox",
        "info",
        "keyboard",
        "layers-3",
        "library",
        "link",
        "list",
        "list-filter",
        "locate",
        "lock",
        "lock-open",
        "message-square",
        "message-square-text",
        "minimize-2",
        "minus",
        "mouse-pointer-2",
        "mouse-pointer-click",
        "move",
        "move-3d",
        "move-diagonal",
        "move-diagonal-2",
        "octagon-x",
        "paintbrush",
        "palette",
        "panel-bottom",
        "panel-right",
        "panels-top-left",
        "pen-tool",
        "pencil",
        "pencil-ruler",
        "plus",
        "printer",
        "rectangle-vertical",
        "redo-2",
        "refresh-cw",
        "rotate-ccw",
        "rotate-cw",
        "rows-3",
        "ruler",
        "scan",
        "scan-eye",
        "scissors",
        "settings",
        "shapes",
        "share",
        "shield",
        "shield-check",
        "slash",
        "sliders-horizontal",
        "spline",
        "square",
        "square-arrow-right",
        "square-dashed",
        "square-dashed-mouse-pointer",
        "square-function",
        "square-minus",
        "square-pen",
        "square-plus",
        "square-split-horizontal",
        "square-split-vertical",
        "star",
        "table-2",
        "text-cursor",
        "trash-2",
        "triangle-alert",
        "triangle-right",
        "type",
        "undo-2",
        "wand-sparkles",
        "waypoints",
        "x",
        "zoom-in",
        "zoom-out",
    ]

    private static func commands(
        forIcon name: String
    ) -> [SymbolGeometry.Command]? {
        switch name {
            case "arrow-down-to-line": return arrowDownToLine
            case "arrow-left-right": return arrowLeftRight
            case "arrow-right": return arrowRight
            case "arrow-up-down": return arrowUpDown
            case "arrow-up-left": return arrowUpLeft
            case "badge": return badge
            case "badge-check": return badgeCheck
            case "ban": return ban
            case "box": return box
            case "brush": return brush
            case "building-2": return building2
            case "captions": return captions
            case "check": return check
            case "chevron-down": return chevronDown
            case "chevron-left": return chevronLeft
            case "chevron-right": return chevronRight
            case "chevron-up": return chevronUp
            case "chevrons-up-down": return chevronsUpDown
            case "circle": return circle
            case "circle-alert": return circleAlert
            case "circle-check": return circleCheck
            case "circle-dashed": return circleDashed
            case "circle-dot": return circleDot
            case "circle-ellipsis": return circleEllipsis
            case "circle-help": return circleHelp
            case "circle-plus": return circlePlus
            case "circle-x": return circleX
            case "clipboard-copy": return clipboardCopy
            case "combine": return combine
            case "copy-plus": return copyPlus
            case "corner-down-right": return cornerDownRight
            case "crop": return crop
            case "crosshair": return crosshair
            case "delete": return delete
            case "download": return download
            case "expand": return expand
            case "eye": return eye
            case "eye-off": return eyeOff
            case "file": return file
            case "file-cog": return fileCog
            case "file-down": return fileDown
            case "file-plus": return filePlus
            case "file-text": return fileText
            case "files": return files
            case "flip-horizontal-2": return flipHorizontal2
            case "folder": return folder
            case "git-branch": return gitBranch
            case "git-merge": return gitMerge
            case "grid-2x2": return grid2x2
            case "grid-3x3": return grid3x3
            case "hammer": return hammer
            case "hand": return hand
            case "history": return history
            case "image": return image
            case "image-off": return imageOff
            case "image-plus": return imagePlus
            case "images": return images
            case "inbox": return inbox
            case "info": return info
            case "keyboard": return keyboard
            case "layers-3": return layers3
            case "library": return library
            case "link": return link
            case "list": return list
            case "list-filter": return listFilter
            case "locate": return locate
            case "lock": return lock
            case "lock-open": return lockOpen
            case "message-square": return messageSquare
            case "message-square-text": return messageSquareText
            case "minimize-2": return minimize2
            case "minus": return minus
            case "mouse-pointer-2": return mousePointer2
            case "mouse-pointer-click": return mousePointerClick
            case "move": return move
            case "move-3d": return move3d
            case "move-diagonal": return moveDiagonal
            case "move-diagonal-2": return moveDiagonal2
            case "octagon-x": return octagonX
            case "paintbrush": return paintbrush
            case "palette": return palette
            case "panel-bottom": return panelBottom
            case "panel-right": return panelRight
            case "panels-top-left": return panelsTopLeft
            case "pen-tool": return penTool
            case "pencil": return pencil
            case "pencil-ruler": return pencilRuler
            case "plus": return plus
            case "printer": return printer
            case "rectangle-vertical": return rectangleVertical
            case "redo-2": return redo2
            case "refresh-cw": return refreshCw
            case "rotate-ccw": return rotateCcw
            case "rotate-cw": return rotateCw
            case "rows-3": return rows3
            case "ruler": return ruler
            case "scan": return scan
            case "scan-eye": return scanEye
            case "scissors": return scissors
            case "settings": return settings
            case "shapes": return shapes
            case "share": return share
            case "shield": return shield
            case "shield-check": return shieldCheck
            case "slash": return slash
            case "sliders-horizontal": return slidersHorizontal
            case "spline": return spline
            case "square": return square
            case "square-arrow-right": return squareArrowRight
            case "square-dashed": return squareDashed
            case "square-dashed-mouse-pointer": return squareDashedMousePointer
            case "square-function": return squareFunction
            case "square-minus": return squareMinus
            case "square-pen": return squarePen
            case "square-plus": return squarePlus
            case "square-split-horizontal": return squareSplitHorizontal
            case "square-split-vertical": return squareSplitVertical
            case "star": return star
            case "table-2": return table2
            case "text-cursor": return textCursor
            case "trash-2": return trash2
            case "triangle-alert": return triangleAlert
            case "triangle-right": return triangleRight
            case "type": return type
            case "undo-2": return undo2
            case "wand-sparkles": return wandSparkles
            case "waypoints": return waypoints
            case "x": return x
            case "zoom-in": return zoomIn
            case "zoom-out": return zoomOut
            default: return nil
        }
    }

    private static let arrowDownToLine:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 17)),
            .line(SIMD2(12, 3)),
            .move(SIMD2(6, 11)),
            .line(SIMD2(12, 17)),
            .line(SIMD2(18, 11)),
            .move(SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
        ]

    private static let arrowLeftRight:
        [SymbolGeometry.Command] = [
            .move(SIMD2(8, 3)),
            .line(SIMD2(4, 7)),
            .line(SIMD2(8, 11)),
            .move(SIMD2(4, 7)),
            .line(SIMD2(20, 7)),
            .move(SIMD2(16, 21)),
            .line(SIMD2(20, 17)),
            .line(SIMD2(16, 13)),
            .move(SIMD2(20, 17)),
            .line(SIMD2(4, 17)),
        ]

    private static let arrowRight:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 12)),
            .line(SIMD2(19, 12)),
            .move(SIMD2(12, 5)),
            .line(SIMD2(19, 12)),
            .line(SIMD2(12, 19)),
        ]

    private static let arrowUpDown:
        [SymbolGeometry.Command] = [
            .move(SIMD2(21, 16)),
            .line(SIMD2(17, 20)),
            .line(SIMD2(13, 16)),
            .move(SIMD2(17, 20)),
            .line(SIMD2(17, 4)),
            .move(SIMD2(3, 8)),
            .line(SIMD2(7, 4)),
            .line(SIMD2(11, 8)),
            .move(SIMD2(7, 4)),
            .line(SIMD2(7, 20)),
        ]

    private static let arrowUpLeft:
        [SymbolGeometry.Command] = [
            .move(SIMD2(7, 17)),
            .line(SIMD2(7, 7)),
            .line(SIMD2(17, 7)),
            .move(SIMD2(17, 17)),
            .line(SIMD2(7, 7)),
        ]

    private static let badge:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3.85, 8.62)),
            .cubicCurve(control1: SIMD2(3.5534, 7.2837), control2: SIMD2(3.9606, 5.8886), end: SIMD2(4.9295, 4.9217)),
            .cubicCurve(control1: SIMD2(5.8984, 3.9549), control2: SIMD2(7.2944, 3.5506), end: SIMD2(8.63, 3.85)),
            .cubicCurve(control1: SIMD2(9.3651, 2.7004), control2: SIMD2(10.6355, 2.0048), end: SIMD2(12, 2.0048)),
            .cubicCurve(control1: SIMD2(13.3645, 2.0048), control2: SIMD2(14.6349, 2.7004), end: SIMD2(15.37, 3.85)),
            .cubicCurve(control1: SIMD2(16.7077, 3.5492), control2: SIMD2(18.1063, 3.9546), end: SIMD2(19.0758, 4.9242)),
            .cubicCurve(control1: SIMD2(20.0454, 5.8937), control2: SIMD2(20.4508, 7.2923), end: SIMD2(20.15, 8.63)),
            .cubicCurve(control1: SIMD2(21.2996, 9.3651), control2: SIMD2(21.9952, 10.6355), end: SIMD2(21.9952, 12)),
            .cubicCurve(control1: SIMD2(21.9952, 13.3645), control2: SIMD2(21.2996, 14.6349), end: SIMD2(20.15, 15.37)),
            .cubicCurve(control1: SIMD2(20.4494, 16.7056), control2: SIMD2(20.0451, 18.1016), end: SIMD2(19.0783, 19.0705)),
            .cubicCurve(control1: SIMD2(18.1114, 20.0394), control2: SIMD2(16.7163, 20.4466), end: SIMD2(15.38, 20.15)),
            .cubicCurve(control1: SIMD2(14.6458, 21.3041), control2: SIMD2(13.3728, 22.0031), end: SIMD2(12.005, 22.0031)),
            .cubicCurve(control1: SIMD2(10.6372, 22.0031), control2: SIMD2(9.3642, 21.3041), end: SIMD2(8.63, 20.15)),
            .cubicCurve(control1: SIMD2(7.2944, 20.4494), control2: SIMD2(5.8984, 20.0451), end: SIMD2(4.9295, 19.0783)),
            .cubicCurve(control1: SIMD2(3.9606, 18.1114), control2: SIMD2(3.5534, 16.7163), end: SIMD2(3.85, 15.38)),
            .cubicCurve(control1: SIMD2(2.6914, 14.6468), control2: SIMD2(1.9891, 13.3712), end: SIMD2(1.9891, 12)),
            .cubicCurve(control1: SIMD2(1.9891, 10.6288), control2: SIMD2(2.6914, 9.3532), end: SIMD2(3.85, 8.62)),
            .line(SIMD2(3.85, 8.62)),
        ]

    private static let badgeCheck:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3.85, 8.62)),
            .cubicCurve(control1: SIMD2(3.5534, 7.2837), control2: SIMD2(3.9606, 5.8886), end: SIMD2(4.9295, 4.9217)),
            .cubicCurve(control1: SIMD2(5.8984, 3.9549), control2: SIMD2(7.2944, 3.5506), end: SIMD2(8.63, 3.85)),
            .cubicCurve(control1: SIMD2(9.3651, 2.7004), control2: SIMD2(10.6355, 2.0048), end: SIMD2(12, 2.0048)),
            .cubicCurve(control1: SIMD2(13.3645, 2.0048), control2: SIMD2(14.6349, 2.7004), end: SIMD2(15.37, 3.85)),
            .cubicCurve(control1: SIMD2(16.7077, 3.5492), control2: SIMD2(18.1063, 3.9546), end: SIMD2(19.0758, 4.9242)),
            .cubicCurve(control1: SIMD2(20.0454, 5.8937), control2: SIMD2(20.4508, 7.2923), end: SIMD2(20.15, 8.63)),
            .cubicCurve(control1: SIMD2(21.2996, 9.3651), control2: SIMD2(21.9952, 10.6355), end: SIMD2(21.9952, 12)),
            .cubicCurve(control1: SIMD2(21.9952, 13.3645), control2: SIMD2(21.2996, 14.6349), end: SIMD2(20.15, 15.37)),
            .cubicCurve(control1: SIMD2(20.4494, 16.7056), control2: SIMD2(20.0451, 18.1016), end: SIMD2(19.0783, 19.0705)),
            .cubicCurve(control1: SIMD2(18.1114, 20.0394), control2: SIMD2(16.7163, 20.4466), end: SIMD2(15.38, 20.15)),
            .cubicCurve(control1: SIMD2(14.6458, 21.3041), control2: SIMD2(13.3728, 22.0031), end: SIMD2(12.005, 22.0031)),
            .cubicCurve(control1: SIMD2(10.6372, 22.0031), control2: SIMD2(9.3642, 21.3041), end: SIMD2(8.63, 20.15)),
            .cubicCurve(control1: SIMD2(7.2944, 20.4494), control2: SIMD2(5.8984, 20.0451), end: SIMD2(4.9295, 19.0783)),
            .cubicCurve(control1: SIMD2(3.9606, 18.1114), control2: SIMD2(3.5534, 16.7163), end: SIMD2(3.85, 15.38)),
            .cubicCurve(control1: SIMD2(2.6914, 14.6468), control2: SIMD2(1.9891, 13.3712), end: SIMD2(1.9891, 12)),
            .cubicCurve(control1: SIMD2(1.9891, 10.6288), control2: SIMD2(2.6914, 9.3532), end: SIMD2(3.85, 8.62)),
            .line(SIMD2(3.85, 8.62)),
            .move(SIMD2(9, 12)),
            .line(SIMD2(11, 14)),
            .line(SIMD2(15, 10)),
        ]

    private static let ban:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(4.929, 4.929)),
            .line(SIMD2(19.07, 19.071)),
        ]

    private static let box:
        [SymbolGeometry.Command] = [
            .move(SIMD2(21, 8)),
            .cubicCurve(control1: SIMD2(20.9993, 7.2862), control2: SIMD2(20.6182, 6.6269), end: SIMD2(20, 6.27)),
            .line(SIMD2(13, 2.27)),
            .cubicCurve(control1: SIMD2(12.3812, 1.9127), control2: SIMD2(11.6188, 1.9127), end: SIMD2(11, 2.27)),
            .line(SIMD2(4, 6.27)),
            .cubicCurve(control1: SIMD2(3.3818, 6.6269), control2: SIMD2(3.0007, 7.2862), end: SIMD2(3, 8)),
            .line(SIMD2(3, 16)),
            .cubicCurve(control1: SIMD2(3.0007, 16.7138), control2: SIMD2(3.3818, 17.3731), end: SIMD2(4, 17.73)),
            .line(SIMD2(11, 21.73)),
            .cubicCurve(control1: SIMD2(11.6188, 22.0873), control2: SIMD2(12.3812, 22.0873), end: SIMD2(13, 21.73)),
            .line(SIMD2(20, 17.73)),
            .cubicCurve(control1: SIMD2(20.6182, 17.3731), control2: SIMD2(20.9993, 16.7138), end: SIMD2(21, 16)),
            .line(SIMD2(21, 8)),
            .move(SIMD2(3.3, 7)),
            .line(SIMD2(12, 12)),
            .line(SIMD2(20.7, 7)),
            .move(SIMD2(12, 22)),
            .line(SIMD2(12, 12)),
        ]

    private static let brush:
        [SymbolGeometry.Command] = [
            .move(SIMD2(11, 10)),
            .line(SIMD2(14, 13)),
            .move(SIMD2(6.5, 21)),
            .cubicCurve(control1: SIMD2(8.433, 21), control2: SIMD2(10, 19.433), end: SIMD2(10, 17.5)),
            .cubicCurve(control1: SIMD2(10, 15.567), control2: SIMD2(8.433, 14), end: SIMD2(6.5, 14)),
            .cubicCurve(control1: SIMD2(4.567, 14), control2: SIMD2(3, 15.567), end: SIMD2(3, 17.5)),
            .cubicCurve(control1: SIMD2(3.0002, 18.1656), control2: SIMD2(2.7471, 18.8063), end: SIMD2(2.292, 19.292)),
            .cubicCurve(control1: SIMD2(2.0052, 19.578), control2: SIMD2(1.9193, 20.0088), end: SIMD2(2.0744, 20.3829)),
            .cubicCurve(control1: SIMD2(2.2295, 20.7571), control2: SIMD2(2.595, 21.0007), end: SIMD2(3, 21)),
            .line(SIMD2(6.5, 21)),
            .move(SIMD2(9.969, 17.031)),
            .line(SIMD2(21.378, 5.624)),
            .cubicCurve(control1: SIMD2(22.207, 4.795), control2: SIMD2(22.207, 3.451), end: SIMD2(21.378, 2.622)),
            .cubicCurve(control1: SIMD2(20.549, 1.793), control2: SIMD2(19.205, 1.793), end: SIMD2(18.376, 2.622)),
            .line(SIMD2(6.967, 14.031)),
        ]

    private static let building2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10, 12)),
            .line(SIMD2(14, 12)),
            .move(SIMD2(10, 8)),
            .line(SIMD2(14, 8)),
            .move(SIMD2(14, 21)),
            .line(SIMD2(14, 18)),
            .cubicCurve(control1: SIMD2(14, 16.8954), control2: SIMD2(13.1046, 16), end: SIMD2(12, 16)),
            .cubicCurve(control1: SIMD2(10.8954, 16), control2: SIMD2(10, 16.8954), end: SIMD2(10, 18)),
            .line(SIMD2(10, 21)),
            .move(SIMD2(6, 10)),
            .line(SIMD2(4, 10)),
            .cubicCurve(control1: SIMD2(2.8954, 10), control2: SIMD2(2, 10.8954), end: SIMD2(2, 12)),
            .line(SIMD2(2, 19)),
            .cubicCurve(control1: SIMD2(2, 20.1046), control2: SIMD2(2.8954, 21), end: SIMD2(4, 21)),
            .line(SIMD2(20, 21)),
            .cubicCurve(control1: SIMD2(21.1046, 21), control2: SIMD2(22, 20.1046), end: SIMD2(22, 19)),
            .line(SIMD2(22, 9)),
            .cubicCurve(control1: SIMD2(22, 7.8954), control2: SIMD2(21.1046, 7), end: SIMD2(20, 7)),
            .line(SIMD2(18, 7)),
            .move(SIMD2(6, 21)),
            .line(SIMD2(6, 5)),
            .cubicCurve(control1: SIMD2(6, 3.8954), control2: SIMD2(6.8954, 3), end: SIMD2(8, 3)),
            .line(SIMD2(16, 3)),
            .cubicCurve(control1: SIMD2(17.1046, 3), control2: SIMD2(18, 3.8954), end: SIMD2(18, 5)),
            .line(SIMD2(18, 21)),
        ]

    private static let captions:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 5)),
            .line(SIMD2(19, 5)),
            .cubicCurve(control1: SIMD2(20.1046, 5), control2: SIMD2(21, 5.8954), end: SIMD2(21, 7)),
            .line(SIMD2(21, 17)),
            .cubicCurve(control1: SIMD2(21, 18.1046), control2: SIMD2(20.1046, 19), end: SIMD2(19, 19)),
            .line(SIMD2(5, 19)),
            .cubicCurve(control1: SIMD2(3.8954, 19), control2: SIMD2(3, 18.1046), end: SIMD2(3, 17)),
            .line(SIMD2(3, 7)),
            .cubicCurve(control1: SIMD2(3, 5.8954), control2: SIMD2(3.8954, 5), end: SIMD2(5, 5)),
            .move(SIMD2(7, 15)),
            .line(SIMD2(11, 15)),
            .move(SIMD2(15, 15)),
            .line(SIMD2(17, 15)),
            .move(SIMD2(7, 11)),
            .line(SIMD2(9, 11)),
            .move(SIMD2(13, 11)),
            .line(SIMD2(17, 11)),
        ]

    private static let check:
        [SymbolGeometry.Command] = [
            .move(SIMD2(20, 6)),
            .line(SIMD2(9, 17)),
            .line(SIMD2(4, 12)),
        ]

    private static let chevronDown:
        [SymbolGeometry.Command] = [
            .move(SIMD2(6, 9)),
            .line(SIMD2(12, 15)),
            .line(SIMD2(18, 9)),
        ]

    private static let chevronLeft:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 18)),
            .line(SIMD2(9, 12)),
            .line(SIMD2(15, 6)),
        ]

    private static let chevronRight:
        [SymbolGeometry.Command] = [
            .move(SIMD2(9, 18)),
            .line(SIMD2(15, 12)),
            .line(SIMD2(9, 6)),
        ]

    private static let chevronUp:
        [SymbolGeometry.Command] = [
            .move(SIMD2(18, 15)),
            .line(SIMD2(12, 9)),
            .line(SIMD2(6, 15)),
        ]

    private static let chevronsUpDown:
        [SymbolGeometry.Command] = [
            .move(SIMD2(7, 15)),
            .line(SIMD2(12, 20)),
            .line(SIMD2(17, 15)),
            .move(SIMD2(7, 9)),
            .line(SIMD2(12, 4)),
            .line(SIMD2(17, 9)),
        ]

    private static let circle:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
        ]

    private static let circleAlert:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(12, 8)),
            .line(SIMD2(12, 12)),
            .move(SIMD2(12, 16)),
            .line(SIMD2(12.01, 16)),
        ]

    private static let circleCheck:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(9, 12)),
            .line(SIMD2(11, 14)),
            .line(SIMD2(15, 10)),
        ]

    private static let circleDashed:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10.1, 2.182)),
            .cubicCurve(control1: SIMD2(11.355, 1.9391), control2: SIMD2(12.645, 1.9391), end: SIMD2(13.9, 2.182)),
            .move(SIMD2(13.9, 21.818)),
            .cubicCurve(control1: SIMD2(12.645, 22.0609), control2: SIMD2(11.355, 22.0609), end: SIMD2(10.1, 21.818)),
            .move(SIMD2(17.609, 3.721)),
            .cubicCurve(control1: SIMD2(18.6705, 4.4402), control2: SIMD2(19.5837, 5.3569), end: SIMD2(20.299, 6.421)),
            .move(SIMD2(2.182, 13.9)),
            .cubicCurve(control1: SIMD2(1.9391, 12.645), control2: SIMD2(1.9391, 11.355), end: SIMD2(2.182, 10.1)),
            .move(SIMD2(20.279, 17.609)),
            .cubicCurve(control1: SIMD2(19.5598, 18.6705), control2: SIMD2(18.6431, 19.5837), end: SIMD2(17.579, 20.299)),
            .move(SIMD2(21.818, 10.1)),
            .cubicCurve(control1: SIMD2(22.0609, 11.355), control2: SIMD2(22.0609, 12.645), end: SIMD2(21.818, 13.9)),
            .move(SIMD2(3.721, 6.391)),
            .cubicCurve(control1: SIMD2(4.4402, 5.3295), control2: SIMD2(5.3569, 4.4163), end: SIMD2(6.421, 3.701)),
            .move(SIMD2(6.391, 20.279)),
            .cubicCurve(control1: SIMD2(5.3295, 19.5598), control2: SIMD2(4.4163, 18.6431), end: SIMD2(3.701, 17.579)),
        ]

    private static let circleDot:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .circle(center: SIMD2(12, 12), radius: 1),
        ]

    private static let circleEllipsis:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(17, 12)),
            .line(SIMD2(17.01, 12)),
            .move(SIMD2(12, 12)),
            .line(SIMD2(12.01, 12)),
            .move(SIMD2(7, 12)),
            .line(SIMD2(7.01, 12)),
        ]

    private static let circleHelp:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(9.09, 9)),
            .cubicCurve(control1: SIMD2(9.5754, 7.62), control2: SIMD2(10.9854, 6.7914), end: SIMD2(12.4272, 7.0387)),
            .cubicCurve(control1: SIMD2(13.869, 7.286), control2: SIMD2(14.9222, 8.5372), end: SIMD2(14.92, 10)),
            .cubicCurve(control1: SIMD2(14.92, 12), control2: SIMD2(11.92, 13), end: SIMD2(11.92, 13)),
            .move(SIMD2(12, 17)),
            .line(SIMD2(12.01, 17)),
        ]

    private static let circlePlus:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(8, 12)),
            .line(SIMD2(16, 12)),
            .move(SIMD2(12, 8)),
            .line(SIMD2(12, 16)),
        ]

    private static let circleX:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(15, 9)),
            .line(SIMD2(9, 15)),
            .move(SIMD2(9, 9)),
            .line(SIMD2(15, 15)),
        ]

    private static let clipboardCopy:
        [SymbolGeometry.Command] = [
            .move(SIMD2(9, 2)),
            .line(SIMD2(15, 2)),
            .cubicCurve(control1: SIMD2(15.5523, 2), control2: SIMD2(16, 2.4477), end: SIMD2(16, 3)),
            .line(SIMD2(16, 5)),
            .cubicCurve(control1: SIMD2(16, 5.5523), control2: SIMD2(15.5523, 6), end: SIMD2(15, 6)),
            .line(SIMD2(9, 6)),
            .cubicCurve(control1: SIMD2(8.4477, 6), control2: SIMD2(8, 5.5523), end: SIMD2(8, 5)),
            .line(SIMD2(8, 3)),
            .cubicCurve(control1: SIMD2(8, 2.4477), control2: SIMD2(8.4477, 2), end: SIMD2(9, 2)),
            .move(SIMD2(8, 4)),
            .line(SIMD2(6, 4)),
            .cubicCurve(control1: SIMD2(4.8954, 4), control2: SIMD2(4, 4.8954), end: SIMD2(4, 6)),
            .line(SIMD2(4, 20)),
            .cubicCurve(control1: SIMD2(4, 21.1046), control2: SIMD2(4.8954, 22), end: SIMD2(6, 22)),
            .line(SIMD2(18, 22)),
            .cubicCurve(control1: SIMD2(19.1046, 22), control2: SIMD2(20, 21.1046), end: SIMD2(20, 20)),
            .line(SIMD2(20, 18)),
            .move(SIMD2(16, 4)),
            .line(SIMD2(18, 4)),
            .cubicCurve(control1: SIMD2(19.1046, 4), control2: SIMD2(20, 4.8954), end: SIMD2(20, 6)),
            .line(SIMD2(20, 10)),
            .move(SIMD2(21, 14)),
            .line(SIMD2(11, 14)),
            .move(SIMD2(15, 10)),
            .line(SIMD2(11, 14)),
            .line(SIMD2(15, 18)),
        ]

    private static let combine:
        [SymbolGeometry.Command] = [
            .move(SIMD2(14, 3)),
            .cubicCurve(control1: SIMD2(14.5523, 3), control2: SIMD2(15, 3.4477), end: SIMD2(15, 4)),
            .line(SIMD2(15, 9)),
            .cubicCurve(control1: SIMD2(15, 9.5523), control2: SIMD2(14.5523, 10), end: SIMD2(14, 10)),
            .move(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(19.5523, 3), control2: SIMD2(20, 3.4477), end: SIMD2(20, 4)),
            .line(SIMD2(20, 9)),
            .cubicCurve(control1: SIMD2(20, 9.5523), control2: SIMD2(19.5523, 10), end: SIMD2(19, 10)),
            .move(SIMD2(7, 15)),
            .line(SIMD2(10, 18)),
            .move(SIMD2(7, 21)),
            .line(SIMD2(10, 18)),
            .line(SIMD2(5, 18)),
            .cubicCurve(control1: SIMD2(3.8954, 18), control2: SIMD2(3, 17.1046), end: SIMD2(3, 16)),
            .line(SIMD2(3, 14)),
            .move(SIMD2(15, 14)),
            .line(SIMD2(20, 14)),
            .cubicCurve(control1: SIMD2(20.5523, 14), control2: SIMD2(21, 14.4477), end: SIMD2(21, 15)),
            .line(SIMD2(21, 20)),
            .cubicCurve(control1: SIMD2(21, 20.5523), control2: SIMD2(20.5523, 21), end: SIMD2(20, 21)),
            .line(SIMD2(15, 21)),
            .cubicCurve(control1: SIMD2(14.4477, 21), control2: SIMD2(14, 20.5523), end: SIMD2(14, 20)),
            .line(SIMD2(14, 15)),
            .cubicCurve(control1: SIMD2(14, 14.4477), control2: SIMD2(14.4477, 14), end: SIMD2(15, 14)),
            .move(SIMD2(4, 3)),
            .line(SIMD2(9, 3)),
            .cubicCurve(control1: SIMD2(9.5523, 3), control2: SIMD2(10, 3.4477), end: SIMD2(10, 4)),
            .line(SIMD2(10, 9)),
            .cubicCurve(control1: SIMD2(10, 9.5523), control2: SIMD2(9.5523, 10), end: SIMD2(9, 10)),
            .line(SIMD2(4, 10)),
            .cubicCurve(control1: SIMD2(3.4477, 10), control2: SIMD2(3, 9.5523), end: SIMD2(3, 9)),
            .line(SIMD2(3, 4)),
            .cubicCurve(control1: SIMD2(3, 3.4477), control2: SIMD2(3.4477, 3), end: SIMD2(4, 3)),
        ]

    private static let copyPlus:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 12)),
            .line(SIMD2(15, 18)),
            .move(SIMD2(12, 15)),
            .line(SIMD2(18, 15)),
            .move(SIMD2(10, 8)),
            .line(SIMD2(20, 8)),
            .cubicCurve(control1: SIMD2(21.1046, 8), control2: SIMD2(22, 8.8954), end: SIMD2(22, 10)),
            .line(SIMD2(22, 20)),
            .cubicCurve(control1: SIMD2(22, 21.1046), control2: SIMD2(21.1046, 22), end: SIMD2(20, 22)),
            .line(SIMD2(10, 22)),
            .cubicCurve(control1: SIMD2(8.8954, 22), control2: SIMD2(8, 21.1046), end: SIMD2(8, 20)),
            .line(SIMD2(8, 10)),
            .cubicCurve(control1: SIMD2(8, 8.8954), control2: SIMD2(8.8954, 8), end: SIMD2(10, 8)),
            .move(SIMD2(4, 16)),
            .cubicCurve(control1: SIMD2(2.9, 16), control2: SIMD2(2, 15.1), end: SIMD2(2, 14)),
            .line(SIMD2(2, 4)),
            .cubicCurve(control1: SIMD2(2, 2.9), control2: SIMD2(2.9, 2), end: SIMD2(4, 2)),
            .line(SIMD2(14, 2)),
            .cubicCurve(control1: SIMD2(15.1, 2), control2: SIMD2(16, 2.9), end: SIMD2(16, 4)),
        ]

    private static let cornerDownRight:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 10)),
            .line(SIMD2(20, 15)),
            .line(SIMD2(15, 20)),
            .move(SIMD2(4, 4)),
            .line(SIMD2(4, 11)),
            .cubicCurve(control1: SIMD2(4, 13.2091), control2: SIMD2(5.7909, 15), end: SIMD2(8, 15)),
            .line(SIMD2(20, 15)),
        ]

    private static let crop:
        [SymbolGeometry.Command] = [
            .move(SIMD2(6, 2)),
            .line(SIMD2(6, 16)),
            .cubicCurve(control1: SIMD2(6, 17.1046), control2: SIMD2(6.8954, 18), end: SIMD2(8, 18)),
            .line(SIMD2(22, 18)),
            .move(SIMD2(18, 22)),
            .line(SIMD2(18, 8)),
            .cubicCurve(control1: SIMD2(18, 6.8954), control2: SIMD2(17.1046, 6), end: SIMD2(16, 6)),
            .line(SIMD2(2, 6)),
        ]

    private static let crosshair:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(22, 12)),
            .line(SIMD2(18, 12)),
            .move(SIMD2(6, 12)),
            .line(SIMD2(2, 12)),
            .move(SIMD2(12, 6)),
            .line(SIMD2(12, 2)),
            .move(SIMD2(12, 22)),
            .line(SIMD2(12, 18)),
        ]

    private static let delete:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10, 5)),
            .cubicCurve(control1: SIMD2(9.5031, 5), control2: SIMD2(9.024, 5.185), end: SIMD2(8.656, 5.519)),
            .line(SIMD2(2.328, 11.259)),
            .cubicCurve(control1: SIMD2(2.1192, 11.4485), control2: SIMD2(2.0001, 11.7175), end: SIMD2(2.0001, 11.9995)),
            .cubicCurve(control1: SIMD2(2.0001, 12.2815), control2: SIMD2(2.1192, 12.5505), end: SIMD2(2.328, 12.74)),
            .line(SIMD2(8.656, 18.481)),
            .cubicCurve(control1: SIMD2(9.024, 18.815), control2: SIMD2(9.5031, 19), end: SIMD2(10, 19)),
            .line(SIMD2(20, 19)),
            .cubicCurve(control1: SIMD2(21.1046, 19), control2: SIMD2(22, 18.1046), end: SIMD2(22, 17)),
            .line(SIMD2(22, 7)),
            .cubicCurve(control1: SIMD2(22, 5.8954), control2: SIMD2(21.1046, 5), end: SIMD2(20, 5)),
            .line(SIMD2(10, 5)),
            .move(SIMD2(12, 9)),
            .line(SIMD2(18, 15)),
            .move(SIMD2(18, 9)),
            .line(SIMD2(12, 15)),
        ]

    private static let download:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 15)),
            .line(SIMD2(12, 3)),
            .move(SIMD2(21, 15)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 15)),
            .move(SIMD2(7, 10)),
            .line(SIMD2(12, 15)),
            .line(SIMD2(17, 10)),
        ]

    private static let expand:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 15)),
            .line(SIMD2(21, 21)),
            .move(SIMD2(15, 9)),
            .line(SIMD2(21, 3)),
            .move(SIMD2(21, 16)),
            .line(SIMD2(21, 21)),
            .line(SIMD2(16, 21)),
            .move(SIMD2(21, 8)),
            .line(SIMD2(21, 3)),
            .line(SIMD2(16, 3)),
            .move(SIMD2(3, 16)),
            .line(SIMD2(3, 21)),
            .line(SIMD2(8, 21)),
            .move(SIMD2(3, 21)),
            .line(SIMD2(9, 15)),
            .move(SIMD2(3, 8)),
            .line(SIMD2(3, 3)),
            .line(SIMD2(8, 3)),
            .move(SIMD2(9, 9)),
            .line(SIMD2(3, 3)),
        ]

    private static let eye:
        [SymbolGeometry.Command] = [
            .move(SIMD2(2.062, 12.348)),
            .cubicCurve(control1: SIMD2(1.9787, 12.1235), control2: SIMD2(1.9787, 11.8765), end: SIMD2(2.062, 11.652)),
            .cubicCurve(control1: SIMD2(3.722, 7.6269), control2: SIMD2(7.646, 5.0006), end: SIMD2(12, 5.0006)),
            .cubicCurve(control1: SIMD2(16.354, 5.0006), control2: SIMD2(20.278, 7.6269), end: SIMD2(21.938, 11.652)),
            .cubicCurve(control1: SIMD2(22.0213, 11.8765), control2: SIMD2(22.0213, 12.1235), end: SIMD2(21.938, 12.348)),
            .cubicCurve(control1: SIMD2(20.278, 16.3731), control2: SIMD2(16.354, 18.9994), end: SIMD2(12, 18.9994)),
            .cubicCurve(control1: SIMD2(7.646, 18.9994), control2: SIMD2(3.722, 16.3731), end: SIMD2(2.062, 12.348)),
            .circle(center: SIMD2(12, 12), radius: 3),
        ]

    private static let eyeOff:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10.733, 5.076)),
            .cubicCurve(control1: SIMD2(15.5201, 4.5055), control2: SIMD2(20.1012, 7.1936), end: SIMD2(21.938, 11.651)),
            .cubicCurve(control1: SIMD2(22.0213, 11.8755), control2: SIMD2(22.0213, 12.1225), end: SIMD2(21.938, 12.347)),
            .cubicCurve(control1: SIMD2(21.5705, 13.238), control2: SIMD2(21.0848, 14.0755), end: SIMD2(20.494, 14.837)),
            .move(SIMD2(14.084, 14.158)),
            .cubicCurve(control1: SIMD2(12.9069, 15.2949), control2: SIMD2(11.0357, 15.2787), end: SIMD2(9.8785, 14.1215)),
            .cubicCurve(control1: SIMD2(8.7213, 12.9643), control2: SIMD2(8.7051, 11.0931), end: SIMD2(9.842, 9.916)),
            .move(SIMD2(17.479, 17.499)),
            .cubicCurve(control1: SIMD2(14.7949, 19.0889), control2: SIMD2(11.5525, 19.4345), end: SIMD2(8.5936, 18.4459)),
            .cubicCurve(control1: SIMD2(5.6348, 17.4573), control2: SIMD2(3.2513, 15.2321), end: SIMD2(2.062, 12.348)),
            .cubicCurve(control1: SIMD2(1.9787, 12.1235), control2: SIMD2(1.9787, 11.8765), end: SIMD2(2.062, 11.652)),
            .cubicCurve(control1: SIMD2(2.9486, 9.5019), control2: SIMD2(4.5087, 7.6972), end: SIMD2(6.508, 6.509)),
            .move(SIMD2(2, 2)),
            .line(SIMD2(22, 22)),
        ]

    private static let file:
        [SymbolGeometry.Command] = [
            .move(SIMD2(6, 22)),
            .cubicCurve(control1: SIMD2(4.8954, 22), control2: SIMD2(4, 21.1046), end: SIMD2(4, 20)),
            .line(SIMD2(4, 4)),
            .cubicCurve(control1: SIMD2(4, 2.8954), control2: SIMD2(4.8954, 2), end: SIMD2(6, 2)),
            .line(SIMD2(14, 2)),
            .cubicCurve(control1: SIMD2(14.6394, 1.999), control2: SIMD2(15.2527, 2.2531), end: SIMD2(15.704, 2.706)),
            .line(SIMD2(19.292, 6.294)),
            .cubicCurve(control1: SIMD2(19.7461, 6.7454), control2: SIMD2(20.001, 7.3597), end: SIMD2(20, 8)),
            .line(SIMD2(20, 20)),
            .cubicCurve(control1: SIMD2(20, 21.1046), control2: SIMD2(19.1046, 22), end: SIMD2(18, 22)),
            .line(SIMD2(6, 22)),
            .move(SIMD2(14, 2)),
            .line(SIMD2(14, 7)),
            .cubicCurve(control1: SIMD2(14, 7.5523), control2: SIMD2(14.4477, 8), end: SIMD2(15, 8)),
            .line(SIMD2(20, 8)),
        ]

    private static let fileCog:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 8)),
            .cubicCurve(control1: SIMD2(14.4477, 8), control2: SIMD2(14, 7.5523), end: SIMD2(14, 7)),
            .line(SIMD2(14, 2)),
            .cubicCurve(control1: SIMD2(14.6394, 1.999), control2: SIMD2(15.2527, 2.2531), end: SIMD2(15.704, 2.706)),
            .line(SIMD2(19.292, 6.294)),
            .cubicCurve(control1: SIMD2(19.7461, 6.7454), control2: SIMD2(20.001, 7.3597), end: SIMD2(20, 8)),
            .line(SIMD2(15, 8)),
            .move(SIMD2(20, 8)),
            .line(SIMD2(20, 20)),
            .cubicCurve(control1: SIMD2(20, 21.1046), control2: SIMD2(19.1046, 22), end: SIMD2(18, 22)),
            .line(SIMD2(13.818, 22)),
            .move(SIMD2(3.305, 19.53)),
            .line(SIMD2(4.228, 19.148)),
            .move(SIMD2(4, 10.592)),
            .line(SIMD2(4, 4)),
            .cubicCurve(control1: SIMD2(4, 2.8954), control2: SIMD2(4.8954, 2), end: SIMD2(6, 2)),
            .line(SIMD2(14, 2)),
            .move(SIMD2(4.228, 16.852)),
            .line(SIMD2(3.304, 16.469)),
            .move(SIMD2(5.852, 15.228)),
            .line(SIMD2(5.469, 14.305)),
            .move(SIMD2(5.852, 20.772)),
            .line(SIMD2(5.469, 21.696)),
            .move(SIMD2(8.148, 15.228)),
            .line(SIMD2(8.531, 14.305)),
            .move(SIMD2(8.53, 21.696)),
            .line(SIMD2(8.148, 20.772)),
            .move(SIMD2(9.773, 16.852)),
            .line(SIMD2(10.695, 16.469)),
            .move(SIMD2(9.773, 19.148)),
            .line(SIMD2(10.695, 19.531)),
            .circle(center: SIMD2(7, 18), radius: 3),
        ]

    private static let fileDown:
        [SymbolGeometry.Command] = [
            .move(SIMD2(6, 22)),
            .cubicCurve(control1: SIMD2(4.8954, 22), control2: SIMD2(4, 21.1046), end: SIMD2(4, 20)),
            .line(SIMD2(4, 4)),
            .cubicCurve(control1: SIMD2(4, 2.8954), control2: SIMD2(4.8954, 2), end: SIMD2(6, 2)),
            .line(SIMD2(14, 2)),
            .cubicCurve(control1: SIMD2(14.6394, 1.999), control2: SIMD2(15.2527, 2.2531), end: SIMD2(15.704, 2.706)),
            .line(SIMD2(19.292, 6.294)),
            .cubicCurve(control1: SIMD2(19.7461, 6.7454), control2: SIMD2(20.001, 7.3597), end: SIMD2(20, 8)),
            .line(SIMD2(20, 20)),
            .cubicCurve(control1: SIMD2(20, 21.1046), control2: SIMD2(19.1046, 22), end: SIMD2(18, 22)),
            .line(SIMD2(6, 22)),
            .move(SIMD2(14, 2)),
            .line(SIMD2(14, 7)),
            .cubicCurve(control1: SIMD2(14, 7.5523), control2: SIMD2(14.4477, 8), end: SIMD2(15, 8)),
            .line(SIMD2(20, 8)),
            .move(SIMD2(12, 18)),
            .line(SIMD2(12, 12)),
            .move(SIMD2(9, 15)),
            .line(SIMD2(12, 18)),
            .line(SIMD2(15, 15)),
        ]

    private static let filePlus:
        [SymbolGeometry.Command] = [
            .move(SIMD2(6, 22)),
            .cubicCurve(control1: SIMD2(4.8954, 22), control2: SIMD2(4, 21.1046), end: SIMD2(4, 20)),
            .line(SIMD2(4, 4)),
            .cubicCurve(control1: SIMD2(4, 2.8954), control2: SIMD2(4.8954, 2), end: SIMD2(6, 2)),
            .line(SIMD2(14, 2)),
            .cubicCurve(control1: SIMD2(14.6394, 1.999), control2: SIMD2(15.2527, 2.2531), end: SIMD2(15.704, 2.706)),
            .line(SIMD2(19.292, 6.294)),
            .cubicCurve(control1: SIMD2(19.7461, 6.7454), control2: SIMD2(20.001, 7.3597), end: SIMD2(20, 8)),
            .line(SIMD2(20, 20)),
            .cubicCurve(control1: SIMD2(20, 21.1046), control2: SIMD2(19.1046, 22), end: SIMD2(18, 22)),
            .line(SIMD2(6, 22)),
            .move(SIMD2(14, 2)),
            .line(SIMD2(14, 7)),
            .cubicCurve(control1: SIMD2(14, 7.5523), control2: SIMD2(14.4477, 8), end: SIMD2(15, 8)),
            .line(SIMD2(20, 8)),
            .move(SIMD2(9, 15)),
            .line(SIMD2(15, 15)),
            .move(SIMD2(12, 18)),
            .line(SIMD2(12, 12)),
        ]

    private static let fileText:
        [SymbolGeometry.Command] = [
            .move(SIMD2(6, 22)),
            .cubicCurve(control1: SIMD2(4.8954, 22), control2: SIMD2(4, 21.1046), end: SIMD2(4, 20)),
            .line(SIMD2(4, 4)),
            .cubicCurve(control1: SIMD2(4, 2.8954), control2: SIMD2(4.8954, 2), end: SIMD2(6, 2)),
            .line(SIMD2(14, 2)),
            .cubicCurve(control1: SIMD2(14.6394, 1.999), control2: SIMD2(15.2527, 2.2531), end: SIMD2(15.704, 2.706)),
            .line(SIMD2(19.292, 6.294)),
            .cubicCurve(control1: SIMD2(19.7461, 6.7454), control2: SIMD2(20.001, 7.3597), end: SIMD2(20, 8)),
            .line(SIMD2(20, 20)),
            .cubicCurve(control1: SIMD2(20, 21.1046), control2: SIMD2(19.1046, 22), end: SIMD2(18, 22)),
            .line(SIMD2(6, 22)),
            .move(SIMD2(14, 2)),
            .line(SIMD2(14, 7)),
            .cubicCurve(control1: SIMD2(14, 7.5523), control2: SIMD2(14.4477, 8), end: SIMD2(15, 8)),
            .line(SIMD2(20, 8)),
            .move(SIMD2(10, 9)),
            .line(SIMD2(8, 9)),
            .move(SIMD2(16, 13)),
            .line(SIMD2(8, 13)),
            .move(SIMD2(16, 17)),
            .line(SIMD2(8, 17)),
        ]

    private static let files:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 2)),
            .line(SIMD2(11, 2)),
            .cubicCurve(control1: SIMD2(9.8954, 2), control2: SIMD2(9, 2.8954), end: SIMD2(9, 4)),
            .line(SIMD2(9, 15)),
            .cubicCurve(control1: SIMD2(9, 16.1046), control2: SIMD2(9.8954, 17), end: SIMD2(11, 17)),
            .line(SIMD2(19, 17)),
            .cubicCurve(control1: SIMD2(20.1046, 17), control2: SIMD2(21, 16.1046), end: SIMD2(21, 15)),
            .line(SIMD2(21, 8)),
            .move(SIMD2(16.706, 2.706)),
            .cubicCurve(control1: SIMD2(16.2542, 2.2526), control2: SIMD2(15.6401, 1.9984), end: SIMD2(15, 2)),
            .line(SIMD2(15, 7)),
            .cubicCurve(control1: SIMD2(15, 7.5523), control2: SIMD2(15.4477, 8), end: SIMD2(16, 8)),
            .line(SIMD2(21, 8)),
            .cubicCurve(control1: SIMD2(21.0016, 7.3599), control2: SIMD2(20.7474, 6.7458), end: SIMD2(20.294, 6.294)),
            .line(SIMD2(16.706, 2.706)),
            .move(SIMD2(5, 7)),
            .cubicCurve(control1: SIMD2(3.8954, 7), control2: SIMD2(3, 7.8954), end: SIMD2(3, 9)),
            .line(SIMD2(3, 20)),
            .cubicCurve(control1: SIMD2(3, 21.1046), control2: SIMD2(3.8954, 22), end: SIMD2(5, 22)),
            .line(SIMD2(13, 22)),
            .cubicCurve(control1: SIMD2(13.7145, 22), control2: SIMD2(14.3747, 21.6188), end: SIMD2(14.732, 21)),
        ]

    private static let flipHorizontal2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3, 7)),
            .line(SIMD2(8, 12)),
            .line(SIMD2(3, 17)),
            .line(SIMD2(3, 7)),
            .move(SIMD2(21, 7)),
            .line(SIMD2(16, 12)),
            .line(SIMD2(21, 17)),
            .line(SIMD2(21, 7)),
            .move(SIMD2(12, 20)),
            .line(SIMD2(12, 22)),
            .move(SIMD2(12, 14)),
            .line(SIMD2(12, 16)),
            .move(SIMD2(12, 8)),
            .line(SIMD2(12, 10)),
            .move(SIMD2(12, 2)),
            .line(SIMD2(12, 4)),
        ]

    private static let folder:
        [SymbolGeometry.Command] = [
            .move(SIMD2(20, 20)),
            .cubicCurve(control1: SIMD2(21.1046, 20), control2: SIMD2(22, 19.1046), end: SIMD2(22, 18)),
            .line(SIMD2(22, 8)),
            .cubicCurve(control1: SIMD2(22, 6.8954), control2: SIMD2(21.1046, 6), end: SIMD2(20, 6)),
            .line(SIMD2(12.1, 6)),
            .cubicCurve(control1: SIMD2(11.4203, 6.0067), control2: SIMD2(10.7838, 5.6677), end: SIMD2(10.41, 5.1)),
            .line(SIMD2(9.6, 3.9)),
            .cubicCurve(control1: SIMD2(9.2301, 3.3383), control2: SIMD2(8.6026, 3.0001), end: SIMD2(7.93, 3)),
            .line(SIMD2(4, 3)),
            .cubicCurve(control1: SIMD2(2.8954, 3), control2: SIMD2(2, 3.8954), end: SIMD2(2, 5)),
            .line(SIMD2(2, 18)),
            .cubicCurve(control1: SIMD2(2, 19.1046), control2: SIMD2(2.8954, 20), end: SIMD2(4, 20)),
            .line(SIMD2(20, 20)),
        ]

    private static let gitBranch:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 6)),
            .cubicCurve(control1: SIMD2(10.0294, 6), control2: SIMD2(6, 10.0294), end: SIMD2(6, 15)),
            .line(SIMD2(6, 3)),
            .circle(center: SIMD2(18, 6), radius: 3),
            .circle(center: SIMD2(6, 18), radius: 3),
        ]

    private static let gitMerge:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(18, 18), radius: 3),
            .circle(center: SIMD2(6, 6), radius: 3),
            .move(SIMD2(6, 21)),
            .line(SIMD2(6, 9)),
            .cubicCurve(control1: SIMD2(6, 13.9706), control2: SIMD2(10.0294, 18), end: SIMD2(15, 18)),
        ]

    private static let grid2x2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 3)),
            .line(SIMD2(12, 21)),
            .move(SIMD2(3, 12)),
            .line(SIMD2(21, 12)),
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
        ]

    private static let grid3x3:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(3, 9)),
            .line(SIMD2(21, 9)),
            .move(SIMD2(3, 15)),
            .line(SIMD2(21, 15)),
            .move(SIMD2(9, 3)),
            .line(SIMD2(9, 21)),
            .move(SIMD2(15, 3)),
            .line(SIMD2(15, 21)),
        ]

    private static let hammer:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 12)),
            .line(SIMD2(5.627, 21.373)),
            .cubicCurve(control1: SIMD2(4.7986, 22.2017), control2: SIMD2(3.4552, 22.2019), end: SIMD2(2.6265, 21.3735)),
            .cubicCurve(control1: SIMD2(1.7978, 20.5451), control2: SIMD2(1.7976, 19.2017), end: SIMD2(2.626, 18.373)),
            .line(SIMD2(12, 9)),
            .move(SIMD2(18, 15)),
            .line(SIMD2(22, 11)),
            .move(SIMD2(21.5, 11.5)),
            .line(SIMD2(19.586, 9.586)),
            .cubicCurve(control1: SIMD2(19.2109, 9.211), control2: SIMD2(19.0001, 8.7024), end: SIMD2(19, 8.172)),
            .line(SIMD2(19, 7.828)),
            .cubicCurve(control1: SIMD2(18.9999, 7.2976), control2: SIMD2(18.7891, 6.789), end: SIMD2(18.414, 6.414)),
            .line(SIMD2(16.757, 4.757)),
            .cubicCurve(control1: SIMD2(15.6321, 3.6323), control2: SIMD2(14.1067, 3.0003), end: SIMD2(12.516, 3)),
            .line(SIMD2(9, 3)),
            .line(SIMD2(10.243, 4.243)),
            .cubicCurve(control1: SIMD2(11.3679, 5.3681), control2: SIMD2(11.9999, 6.894), end: SIMD2(12, 8.485)),
            .line(SIMD2(12, 10)),
            .line(SIMD2(14, 12)),
            .line(SIMD2(15.172, 12)),
            .cubicCurve(control1: SIMD2(15.7024, 12.0001), control2: SIMD2(16.211, 12.2109), end: SIMD2(16.586, 12.586)),
            .line(SIMD2(18.5, 14.5)),
        ]

    private static let hand:
        [SymbolGeometry.Command] = [
            .move(SIMD2(18, 11)),
            .line(SIMD2(18, 6)),
            .cubicCurve(control1: SIMD2(18, 4.8954), control2: SIMD2(17.1046, 4), end: SIMD2(16, 4)),
            .cubicCurve(control1: SIMD2(14.8954, 4), control2: SIMD2(14, 4.8954), end: SIMD2(14, 6)),
            .move(SIMD2(14, 10)),
            .line(SIMD2(14, 4)),
            .cubicCurve(control1: SIMD2(14, 2.8954), control2: SIMD2(13.1046, 2), end: SIMD2(12, 2)),
            .cubicCurve(control1: SIMD2(10.8954, 2), control2: SIMD2(10, 2.8954), end: SIMD2(10, 4)),
            .line(SIMD2(10, 6)),
            .move(SIMD2(10, 10.5)),
            .line(SIMD2(10, 6)),
            .cubicCurve(control1: SIMD2(10, 4.8954), control2: SIMD2(9.1046, 4), end: SIMD2(8, 4)),
            .cubicCurve(control1: SIMD2(6.8954, 4), control2: SIMD2(6, 4.8954), end: SIMD2(6, 6)),
            .line(SIMD2(6, 14)),
            .move(SIMD2(18, 8)),
            .cubicCurve(control1: SIMD2(18, 6.8954), control2: SIMD2(18.8954, 6), end: SIMD2(20, 6)),
            .cubicCurve(control1: SIMD2(21.1046, 6), control2: SIMD2(22, 6.8954), end: SIMD2(22, 8)),
            .line(SIMD2(22, 14)),
            .cubicCurve(control1: SIMD2(22, 18.4183), control2: SIMD2(18.4183, 22), end: SIMD2(14, 22)),
            .line(SIMD2(12, 22)),
            .cubicCurve(control1: SIMD2(9.2, 22), control2: SIMD2(7.5, 21.14), end: SIMD2(6.01, 19.66)),
            .line(SIMD2(2.41, 16.06)),
            .cubicCurve(control1: SIMD2(1.6954, 15.2686), control2: SIMD2(1.7274, 14.0556), end: SIMD2(2.4827, 13.303)),
            .cubicCurve(control1: SIMD2(3.2381, 12.5503), control2: SIMD2(4.4511, 12.5226), end: SIMD2(5.24, 13.24)),
            .line(SIMD2(7, 15)),
        ]

    private static let history:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3, 12)),
            .cubicCurve(control1: SIMD2(3, 16.9706), control2: SIMD2(7.0294, 21), end: SIMD2(12, 21)),
            .cubicCurve(control1: SIMD2(16.9706, 21), control2: SIMD2(21, 16.9706), end: SIMD2(21, 12)),
            .cubicCurve(control1: SIMD2(21, 7.0294), control2: SIMD2(16.9706, 3), end: SIMD2(12, 3)),
            .cubicCurve(control1: SIMD2(9.484, 3.0095), control2: SIMD2(7.069, 3.9912), end: SIMD2(5.26, 5.74)),
            .line(SIMD2(3, 8)),
            .move(SIMD2(3, 3)),
            .line(SIMD2(3, 8)),
            .line(SIMD2(8, 8)),
            .move(SIMD2(12, 7)),
            .line(SIMD2(12, 12)),
            .line(SIMD2(16, 14)),
        ]

    private static let image:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .circle(center: SIMD2(9, 9), radius: 2),
            .move(SIMD2(21, 15)),
            .line(SIMD2(17.914, 11.914)),
            .cubicCurve(control1: SIMD2(17.133, 11.1332), control2: SIMD2(15.867, 11.1332), end: SIMD2(15.086, 11.914)),
            .line(SIMD2(6, 21)),
        ]

    private static let imageOff:
        [SymbolGeometry.Command] = [
            .move(SIMD2(2, 2)),
            .line(SIMD2(22, 22)),
            .move(SIMD2(10.41, 10.41)),
            .cubicCurve(control1: SIMD2(9.6285, 11.1915), control2: SIMD2(8.3615, 11.1915), end: SIMD2(7.58, 10.41)),
            .cubicCurve(control1: SIMD2(6.7985, 9.6285), control2: SIMD2(6.7985, 8.3615), end: SIMD2(7.58, 7.58)),
            .move(SIMD2(13.5, 13.5)),
            .line(SIMD2(6, 21)),
            .move(SIMD2(18, 12)),
            .line(SIMD2(21, 15)),
            .move(SIMD2(3.59, 3.59)),
            .cubicCurve(control1: SIMD2(3.2135, 3.9627), control2: SIMD2(3.0011, 4.4702), end: SIMD2(3, 5)),
            .line(SIMD2(3, 19)),
            .cubicCurve(control1: SIMD2(3, 20.1046), control2: SIMD2(3.8954, 21), end: SIMD2(5, 21)),
            .line(SIMD2(19, 21)),
            .cubicCurve(control1: SIMD2(19.55, 21), control2: SIMD2(20.052, 20.78), end: SIMD2(20.41, 20.41)),
            .move(SIMD2(21, 15)),
            .line(SIMD2(21, 5)),
            .cubicCurve(control1: SIMD2(21, 3.8954), control2: SIMD2(20.1046, 3), end: SIMD2(19, 3)),
            .line(SIMD2(9, 3)),
        ]

    private static let imagePlus:
        [SymbolGeometry.Command] = [
            .move(SIMD2(16, 5)),
            .line(SIMD2(22, 5)),
            .move(SIMD2(19, 2)),
            .line(SIMD2(19, 8)),
            .move(SIMD2(21, 11.5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .line(SIMD2(12.5, 3)),
            .move(SIMD2(21, 15)),
            .line(SIMD2(17.914, 11.914)),
            .cubicCurve(control1: SIMD2(17.133, 11.1332), control2: SIMD2(15.867, 11.1332), end: SIMD2(15.086, 11.914)),
            .line(SIMD2(6, 21)),
            .circle(center: SIMD2(9, 9), radius: 2),
        ]

    private static let images:
        [SymbolGeometry.Command] = [
            .move(SIMD2(22, 11)),
            .line(SIMD2(20.704, 9.704)),
            .cubicCurve(control1: SIMD2(20.2534, 9.2496), control2: SIMD2(19.6399, 8.9941), end: SIMD2(19, 8.9941)),
            .cubicCurve(control1: SIMD2(18.3601, 8.9941), control2: SIMD2(17.7466, 9.2496), end: SIMD2(17.296, 9.704)),
            .line(SIMD2(11, 16)),
            .move(SIMD2(4, 8)),
            .cubicCurve(control1: SIMD2(2.8954, 8), control2: SIMD2(2, 8.8954), end: SIMD2(2, 10)),
            .line(SIMD2(2, 20)),
            .cubicCurve(control1: SIMD2(2, 21.1046), control2: SIMD2(2.8954, 22), end: SIMD2(4, 22)),
            .line(SIMD2(14, 22)),
            .cubicCurve(control1: SIMD2(15.1046, 22), control2: SIMD2(16, 21.1046), end: SIMD2(16, 20)),
            .circle(center: SIMD2(13, 7), radius: 1),
            .move(SIMD2(10, 2)),
            .line(SIMD2(20, 2)),
            .cubicCurve(control1: SIMD2(21.1046, 2), control2: SIMD2(22, 2.8954), end: SIMD2(22, 4)),
            .line(SIMD2(22, 14)),
            .cubicCurve(control1: SIMD2(22, 15.1046), control2: SIMD2(21.1046, 16), end: SIMD2(20, 16)),
            .line(SIMD2(10, 16)),
            .cubicCurve(control1: SIMD2(8.8954, 16), control2: SIMD2(8, 15.1046), end: SIMD2(8, 14)),
            .line(SIMD2(8, 4)),
            .cubicCurve(control1: SIMD2(8, 2.8954), control2: SIMD2(8.8954, 2), end: SIMD2(10, 2)),
        ]

    private static let inbox:
        [SymbolGeometry.Command] = [
            .move(SIMD2(22, 12)),
            .line(SIMD2(16, 12)),
            .line(SIMD2(14, 15)),
            .line(SIMD2(10, 15)),
            .line(SIMD2(8, 12)),
            .line(SIMD2(2, 12)),
            .move(SIMD2(5.45, 5.11)),
            .line(SIMD2(2, 12)),
            .line(SIMD2(2, 18)),
            .cubicCurve(control1: SIMD2(2, 19.1046), control2: SIMD2(2.8954, 20), end: SIMD2(4, 20)),
            .line(SIMD2(20, 20)),
            .cubicCurve(control1: SIMD2(21.1046, 20), control2: SIMD2(22, 19.1046), end: SIMD2(22, 18)),
            .line(SIMD2(22, 12)),
            .line(SIMD2(18.55, 5.11)),
            .cubicCurve(control1: SIMD2(18.2123, 4.4303), control2: SIMD2(17.5189, 4.0004), end: SIMD2(16.76, 4)),
            .line(SIMD2(7.24, 4)),
            .cubicCurve(control1: SIMD2(6.4811, 4.0004), control2: SIMD2(5.7877, 4.4303), end: SIMD2(5.45, 5.11)),
            .line(SIMD2(5.45, 5.11)),
        ]

    private static let info:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(12, 12), radius: 10),
            .move(SIMD2(12, 16)),
            .line(SIMD2(12, 12)),
            .move(SIMD2(12, 8)),
            .line(SIMD2(12.01, 8)),
        ]

    private static let keyboard:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10, 8)),
            .line(SIMD2(10.01, 8)),
            .move(SIMD2(12, 12)),
            .line(SIMD2(12.01, 12)),
            .move(SIMD2(14, 8)),
            .line(SIMD2(14.01, 8)),
            .move(SIMD2(16, 12)),
            .line(SIMD2(16.01, 12)),
            .move(SIMD2(18, 8)),
            .line(SIMD2(18.01, 8)),
            .move(SIMD2(6, 8)),
            .line(SIMD2(6.01, 8)),
            .move(SIMD2(7, 16)),
            .line(SIMD2(17, 16)),
            .move(SIMD2(8, 12)),
            .line(SIMD2(8.01, 12)),
            .move(SIMD2(4, 4)),
            .line(SIMD2(20, 4)),
            .cubicCurve(control1: SIMD2(21.1046, 4), control2: SIMD2(22, 4.8954), end: SIMD2(22, 6)),
            .line(SIMD2(22, 18)),
            .cubicCurve(control1: SIMD2(22, 19.1046), control2: SIMD2(21.1046, 20), end: SIMD2(20, 20)),
            .line(SIMD2(4, 20)),
            .cubicCurve(control1: SIMD2(2.8954, 20), control2: SIMD2(2, 19.1046), end: SIMD2(2, 18)),
            .line(SIMD2(2, 6)),
            .cubicCurve(control1: SIMD2(2, 4.8954), control2: SIMD2(2.8954, 4), end: SIMD2(4, 4)),
        ]

    private static let layers3:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12.83, 2.18)),
            .cubicCurve(control1: SIMD2(12.3028, 1.9395), control2: SIMD2(11.6972, 1.9395), end: SIMD2(11.17, 2.18)),
            .line(SIMD2(2.6, 6.08)),
            .cubicCurve(control1: SIMD2(2.2374, 6.2399), control2: SIMD2(2.0035, 6.5987), end: SIMD2(2.0035, 6.995)),
            .cubicCurve(control1: SIMD2(2.0035, 7.3913), control2: SIMD2(2.2374, 7.7501), end: SIMD2(2.6, 7.91)),
            .line(SIMD2(11.18, 11.82)),
            .cubicCurve(control1: SIMD2(11.7072, 12.0605), control2: SIMD2(12.3128, 12.0605), end: SIMD2(12.84, 11.82)),
            .line(SIMD2(21.42, 7.92)),
            .cubicCurve(control1: SIMD2(21.7826, 7.7601), control2: SIMD2(22.0165, 7.4013), end: SIMD2(22.0165, 7.005)),
            .cubicCurve(control1: SIMD2(22.0165, 6.6087), control2: SIMD2(21.7826, 6.2499), end: SIMD2(21.42, 6.09)),
            .line(SIMD2(12.83, 2.18)),
            .move(SIMD2(2, 12)),
            .cubicCurve(control1: SIMD2(1.999, 12.3906), control2: SIMD2(2.2255, 12.746), end: SIMD2(2.58, 12.91)),
            .line(SIMD2(11.18, 16.82)),
            .cubicCurve(control1: SIMD2(11.7044, 17.0574), control2: SIMD2(12.3056, 17.0574), end: SIMD2(12.83, 16.82)),
            .line(SIMD2(21.41, 12.92)),
            .cubicCurve(control1: SIMD2(21.7717, 12.7574), control2: SIMD2(22.0031, 12.3965), end: SIMD2(22, 12)),
            .move(SIMD2(2, 17)),
            .cubicCurve(control1: SIMD2(1.999, 17.3906), control2: SIMD2(2.2255, 17.746), end: SIMD2(2.58, 17.91)),
            .line(SIMD2(11.18, 21.82)),
            .cubicCurve(control1: SIMD2(11.7044, 22.0574), control2: SIMD2(12.3056, 22.0574), end: SIMD2(12.83, 21.82)),
            .line(SIMD2(21.41, 17.92)),
            .cubicCurve(control1: SIMD2(21.7717, 17.7574), control2: SIMD2(22.0031, 17.3965), end: SIMD2(22, 17)),
        ]

    private static let library:
        [SymbolGeometry.Command] = [
            .move(SIMD2(16, 6)),
            .line(SIMD2(20, 20)),
            .move(SIMD2(12, 6)),
            .line(SIMD2(12, 20)),
            .move(SIMD2(8, 8)),
            .line(SIMD2(8, 20)),
            .move(SIMD2(4, 4)),
            .line(SIMD2(4, 20)),
        ]

    private static let link:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10, 13)),
            .cubicCurve(control1: SIMD2(10.869, 14.1617), control2: SIMD2(12.1996, 14.8887), end: SIMD2(13.6466, 14.9923)),
            .cubicCurve(control1: SIMD2(15.0937, 15.096), control2: SIMD2(16.5144, 14.566), end: SIMD2(17.54, 13.54)),
            .line(SIMD2(20.54, 10.54)),
            .cubicCurve(control1: SIMD2(22.4349, 8.5781), control2: SIMD2(22.4078, 5.4596), end: SIMD2(20.4791, 3.5309)),
            .cubicCurve(control1: SIMD2(18.5504, 1.6022), control2: SIMD2(15.4319, 1.5751), end: SIMD2(13.47, 3.47)),
            .line(SIMD2(11.75, 5.18)),
            .move(SIMD2(14, 11)),
            .cubicCurve(control1: SIMD2(13.131, 9.8383), control2: SIMD2(11.8004, 9.1113), end: SIMD2(10.3534, 9.0077)),
            .cubicCurve(control1: SIMD2(8.9063, 8.904), control2: SIMD2(7.4856, 9.434), end: SIMD2(6.46, 10.46)),
            .line(SIMD2(3.46, 13.46)),
            .cubicCurve(control1: SIMD2(1.5651, 15.4219), control2: SIMD2(1.5922, 18.5404), end: SIMD2(3.5209, 20.4691)),
            .cubicCurve(control1: SIMD2(5.4496, 22.3978), control2: SIMD2(8.5681, 22.4249), end: SIMD2(10.53, 20.53)),
            .line(SIMD2(12.24, 18.82)),
        ]

    private static let list:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3, 5)),
            .line(SIMD2(3.01, 5)),
            .move(SIMD2(3, 12)),
            .line(SIMD2(3.01, 12)),
            .move(SIMD2(3, 19)),
            .line(SIMD2(3.01, 19)),
            .move(SIMD2(8, 5)),
            .line(SIMD2(21, 5)),
            .move(SIMD2(8, 12)),
            .line(SIMD2(21, 12)),
            .move(SIMD2(8, 19)),
            .line(SIMD2(21, 19)),
        ]

    private static let listFilter:
        [SymbolGeometry.Command] = [
            .move(SIMD2(2, 5)),
            .line(SIMD2(22, 5)),
            .move(SIMD2(6, 12)),
            .line(SIMD2(18, 12)),
            .move(SIMD2(9, 19)),
            .line(SIMD2(15, 19)),
        ]

    private static let locate:
        [SymbolGeometry.Command] = [
            .move(SIMD2(2, 12)),
            .line(SIMD2(5, 12)),
            .move(SIMD2(19, 12)),
            .line(SIMD2(22, 12)),
            .move(SIMD2(12, 2)),
            .line(SIMD2(12, 5)),
            .move(SIMD2(12, 19)),
            .line(SIMD2(12, 22)),
            .circle(center: SIMD2(12, 12), radius: 7),
        ]

    private static let lock:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 11)),
            .line(SIMD2(19, 11)),
            .cubicCurve(control1: SIMD2(20.1046, 11), control2: SIMD2(21, 11.8954), end: SIMD2(21, 13)),
            .line(SIMD2(21, 20)),
            .cubicCurve(control1: SIMD2(21, 21.1046), control2: SIMD2(20.1046, 22), end: SIMD2(19, 22)),
            .line(SIMD2(5, 22)),
            .cubicCurve(control1: SIMD2(3.8954, 22), control2: SIMD2(3, 21.1046), end: SIMD2(3, 20)),
            .line(SIMD2(3, 13)),
            .cubicCurve(control1: SIMD2(3, 11.8954), control2: SIMD2(3.8954, 11), end: SIMD2(5, 11)),
            .move(SIMD2(7, 11)),
            .line(SIMD2(7, 7)),
            .cubicCurve(control1: SIMD2(7, 4.2386), control2: SIMD2(9.2386, 2), end: SIMD2(12, 2)),
            .cubicCurve(control1: SIMD2(14.7614, 2), control2: SIMD2(17, 4.2386), end: SIMD2(17, 7)),
            .line(SIMD2(17, 11)),
        ]

    private static let lockOpen:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 11)),
            .line(SIMD2(19, 11)),
            .cubicCurve(control1: SIMD2(20.1046, 11), control2: SIMD2(21, 11.8954), end: SIMD2(21, 13)),
            .line(SIMD2(21, 20)),
            .cubicCurve(control1: SIMD2(21, 21.1046), control2: SIMD2(20.1046, 22), end: SIMD2(19, 22)),
            .line(SIMD2(5, 22)),
            .cubicCurve(control1: SIMD2(3.8954, 22), control2: SIMD2(3, 21.1046), end: SIMD2(3, 20)),
            .line(SIMD2(3, 13)),
            .cubicCurve(control1: SIMD2(3, 11.8954), control2: SIMD2(3.8954, 11), end: SIMD2(5, 11)),
            .move(SIMD2(7, 11)),
            .line(SIMD2(7, 7)),
            .cubicCurve(control1: SIMD2(6.9974, 4.4312), control2: SIMD2(8.9417, 2.2784), end: SIMD2(11.4975, 2.0203)),
            .cubicCurve(control1: SIMD2(14.0533, 1.7621), control2: SIMD2(16.3888, 3.4826), end: SIMD2(16.9, 6)),
        ]

    private static let messageSquare:
        [SymbolGeometry.Command] = [
            .move(SIMD2(22, 17)),
            .cubicCurve(control1: SIMD2(22, 18.1046), control2: SIMD2(21.1046, 19), end: SIMD2(20, 19)),
            .line(SIMD2(6.828, 19)),
            .cubicCurve(control1: SIMD2(6.2976, 19.0001), control2: SIMD2(5.789, 19.2109), end: SIMD2(5.414, 19.586)),
            .line(SIMD2(3.212, 21.788)),
            .cubicCurve(control1: SIMD2(3.0089, 21.991), control2: SIMD2(2.7036, 22.0517), end: SIMD2(2.4383, 21.9419)),
            .cubicCurve(control1: SIMD2(2.173, 21.832), control2: SIMD2(2, 21.5731), end: SIMD2(2, 21.286)),
            .line(SIMD2(2, 5)),
            .cubicCurve(control1: SIMD2(2, 3.8954), control2: SIMD2(2.8954, 3), end: SIMD2(4, 3)),
            .line(SIMD2(20, 3)),
            .cubicCurve(control1: SIMD2(21.1046, 3), control2: SIMD2(22, 3.8954), end: SIMD2(22, 5)),
            .line(SIMD2(22, 17)),
        ]

    private static let messageSquareText:
        [SymbolGeometry.Command] = [
            .move(SIMD2(22, 17)),
            .cubicCurve(control1: SIMD2(22, 18.1046), control2: SIMD2(21.1046, 19), end: SIMD2(20, 19)),
            .line(SIMD2(6.828, 19)),
            .cubicCurve(control1: SIMD2(6.2976, 19.0001), control2: SIMD2(5.789, 19.2109), end: SIMD2(5.414, 19.586)),
            .line(SIMD2(3.212, 21.788)),
            .cubicCurve(control1: SIMD2(3.0089, 21.991), control2: SIMD2(2.7036, 22.0517), end: SIMD2(2.4383, 21.9419)),
            .cubicCurve(control1: SIMD2(2.173, 21.832), control2: SIMD2(2, 21.5731), end: SIMD2(2, 21.286)),
            .line(SIMD2(2, 5)),
            .cubicCurve(control1: SIMD2(2, 3.8954), control2: SIMD2(2.8954, 3), end: SIMD2(4, 3)),
            .line(SIMD2(20, 3)),
            .cubicCurve(control1: SIMD2(21.1046, 3), control2: SIMD2(22, 3.8954), end: SIMD2(22, 5)),
            .line(SIMD2(22, 17)),
            .move(SIMD2(7, 11)),
            .line(SIMD2(17, 11)),
            .move(SIMD2(7, 15)),
            .line(SIMD2(13, 15)),
            .move(SIMD2(7, 7)),
            .line(SIMD2(15, 7)),
        ]

    private static let minimize2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(14, 10)),
            .line(SIMD2(21, 3)),
            .move(SIMD2(20, 10)),
            .line(SIMD2(14, 10)),
            .line(SIMD2(14, 4)),
            .move(SIMD2(3, 21)),
            .line(SIMD2(10, 14)),
            .move(SIMD2(4, 14)),
            .line(SIMD2(10, 14)),
            .line(SIMD2(10, 20)),
        ]

    private static let minus:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 12)),
            .line(SIMD2(19, 12)),
        ]

    private static let mousePointer2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(4.037, 4.688)),
            .cubicCurve(control1: SIMD2(3.9562, 4.5016), control2: SIMD2(3.9975, 4.2848), end: SIMD2(4.1412, 4.1412)),
            .cubicCurve(control1: SIMD2(4.2848, 3.9975), control2: SIMD2(4.5016, 3.9562), end: SIMD2(4.688, 4.037)),
            .line(SIMD2(20.688, 10.537)),
            .cubicCurve(control1: SIMD2(20.8875, 10.6183), control2: SIMD2(21.0125, 10.8183), end: SIMD2(20.9982, 11.0332)),
            .cubicCurve(control1: SIMD2(20.9839, 11.2482), control2: SIMD2(20.8335, 11.4299), end: SIMD2(20.625, 11.484)),
            .line(SIMD2(14.501, 13.064)),
            .cubicCurve(control1: SIMD2(13.7963, 13.2452), control2: SIMD2(13.2456, 13.7947), end: SIMD2(13.063, 14.499)),
            .line(SIMD2(11.484, 20.625)),
            .cubicCurve(control1: SIMD2(11.4299, 20.8335), control2: SIMD2(11.2482, 20.9839), end: SIMD2(11.0332, 20.9982)),
            .cubicCurve(control1: SIMD2(10.8183, 21.0125), control2: SIMD2(10.6183, 20.8875), end: SIMD2(10.537, 20.688)),
            .line(SIMD2(4.037, 4.688)),
        ]

    private static let mousePointerClick:
        [SymbolGeometry.Command] = [
            .move(SIMD2(14, 4.1)),
            .line(SIMD2(12, 6)),
            .move(SIMD2(5.1, 8)),
            .line(SIMD2(2.2, 7.2)),
            .move(SIMD2(6, 12)),
            .line(SIMD2(4.1, 14)),
            .move(SIMD2(7.2, 2.2)),
            .line(SIMD2(8, 5.1)),
            .move(SIMD2(9.037, 9.69)),
            .cubicCurve(control1: SIMD2(8.9577, 9.5031), control2: SIMD2(8.9997, 9.2868), end: SIMD2(9.1433, 9.1433)),
            .cubicCurve(control1: SIMD2(9.2868, 8.9997), control2: SIMD2(9.5031, 8.9577), end: SIMD2(9.69, 9.037)),
            .line(SIMD2(20.69, 13.537)),
            .cubicCurve(control1: SIMD2(20.8909, 13.6194), control2: SIMD2(21.0156, 13.822), end: SIMD2(20.9987, 14.0385)),
            .cubicCurve(control1: SIMD2(20.9818, 14.2549), control2: SIMD2(20.8272, 14.4357), end: SIMD2(20.616, 14.486)),
            .line(SIMD2(16.267, 15.527)),
            .cubicCurve(control1: SIMD2(15.9009, 15.6144), control2: SIMD2(15.6149, 15.9), end: SIMD2(15.527, 16.266)),
            .line(SIMD2(14.487, 20.616)),
            .cubicCurve(control1: SIMD2(14.4373, 20.828), control2: SIMD2(14.2561, 20.9834), end: SIMD2(14.0391, 21.0003)),
            .cubicCurve(control1: SIMD2(13.822, 21.0172), control2: SIMD2(13.619, 20.8917), end: SIMD2(13.537, 20.69)),
            .line(SIMD2(9.037, 9.69)),
        ]

    private static let move:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 2)),
            .line(SIMD2(12, 22)),
            .move(SIMD2(15, 19)),
            .line(SIMD2(12, 22)),
            .line(SIMD2(9, 19)),
            .move(SIMD2(19, 9)),
            .line(SIMD2(22, 12)),
            .line(SIMD2(19, 15)),
            .move(SIMD2(2, 12)),
            .line(SIMD2(22, 12)),
            .move(SIMD2(5, 9)),
            .line(SIMD2(2, 12)),
            .line(SIMD2(5, 15)),
            .move(SIMD2(9, 5)),
            .line(SIMD2(12, 2)),
            .line(SIMD2(15, 5)),
        ]

    private static let move3d:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(5, 19)),
            .line(SIMD2(21, 19)),
            .move(SIMD2(5, 19)),
            .line(SIMD2(11, 13)),
            .move(SIMD2(2, 6)),
            .line(SIMD2(5, 3)),
            .line(SIMD2(8, 6)),
            .move(SIMD2(18, 16)),
            .line(SIMD2(21, 19)),
            .line(SIMD2(18, 22)),
        ]

    private static let moveDiagonal:
        [SymbolGeometry.Command] = [
            .move(SIMD2(11, 19)),
            .line(SIMD2(5, 19)),
            .line(SIMD2(5, 13)),
            .move(SIMD2(13, 5)),
            .line(SIMD2(19, 5)),
            .line(SIMD2(19, 11)),
            .move(SIMD2(19, 5)),
            .line(SIMD2(5, 19)),
        ]

    private static let moveDiagonal2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(19, 13)),
            .line(SIMD2(19, 19)),
            .line(SIMD2(13, 19)),
            .move(SIMD2(5, 11)),
            .line(SIMD2(5, 5)),
            .line(SIMD2(11, 5)),
            .move(SIMD2(5, 5)),
            .line(SIMD2(19, 19)),
        ]

    private static let octagonX:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 9)),
            .line(SIMD2(9, 15)),
            .move(SIMD2(2.586, 16.726)),
            .cubicCurve(control1: SIMD2(2.2109, 16.351), control2: SIMD2(2.0001, 15.8424), end: SIMD2(2, 15.312)),
            .line(SIMD2(2, 8.688)),
            .cubicCurve(control1: SIMD2(2.0001, 8.1576), control2: SIMD2(2.2109, 7.649), end: SIMD2(2.586, 7.274)),
            .line(SIMD2(7.274, 2.586)),
            .cubicCurve(control1: SIMD2(7.649, 2.2109), control2: SIMD2(8.1576, 2.0001), end: SIMD2(8.688, 2)),
            .line(SIMD2(15.312, 2)),
            .cubicCurve(control1: SIMD2(15.8424, 2.0001), control2: SIMD2(16.351, 2.2109), end: SIMD2(16.726, 2.586)),
            .line(SIMD2(21.414, 7.274)),
            .cubicCurve(control1: SIMD2(21.7891, 7.649), control2: SIMD2(21.9999, 8.1576), end: SIMD2(22, 8.688)),
            .line(SIMD2(22, 15.312)),
            .cubicCurve(control1: SIMD2(21.9999, 15.8424), control2: SIMD2(21.7891, 16.351), end: SIMD2(21.414, 16.726)),
            .line(SIMD2(16.726, 21.414)),
            .cubicCurve(control1: SIMD2(16.351, 21.7891), control2: SIMD2(15.8424, 21.9999), end: SIMD2(15.312, 22)),
            .line(SIMD2(8.688, 22)),
            .cubicCurve(control1: SIMD2(8.1576, 21.9999), control2: SIMD2(7.649, 21.7891), end: SIMD2(7.274, 21.414)),
            .line(SIMD2(2.586, 16.726)),
            .move(SIMD2(9, 9)),
            .line(SIMD2(15, 15)),
        ]

    private static let paintbrush:
        [SymbolGeometry.Command] = [
            .move(SIMD2(14.622, 17.897)),
            .line(SIMD2(3.942, 14.984)),
            .move(SIMD2(18.376, 2.622)),
            .cubicCurve(control1: SIMD2(18.9123, 2.0857), control2: SIMD2(19.6939, 1.8763), end: SIMD2(20.4264, 2.0726)),
            .cubicCurve(control1: SIMD2(21.1589, 2.2689), control2: SIMD2(21.7311, 2.8411), end: SIMD2(21.9274, 3.5736)),
            .cubicCurve(control1: SIMD2(22.1237, 4.3061), control2: SIMD2(21.9143, 5.0877), end: SIMD2(21.378, 5.624)),
            .line(SIMD2(17.36, 9.643)),
            .cubicCurve(control1: SIMD2(17.1648, 9.8382), control2: SIMD2(17.1648, 10.1548), end: SIMD2(17.36, 10.35)),
            .line(SIMD2(18.304, 11.294)),
            .cubicCurve(control1: SIMD2(19.245, 12.2351), control2: SIMD2(19.245, 13.7609), end: SIMD2(18.304, 14.702)),
            .line(SIMD2(17.36, 15.646)),
            .cubicCurve(control1: SIMD2(17.1648, 15.8412), control2: SIMD2(16.8482, 15.8412), end: SIMD2(16.653, 15.646)),
            .line(SIMD2(8.354, 7.348)),
            .cubicCurve(control1: SIMD2(8.1588, 7.1528), control2: SIMD2(8.1588, 6.8362), end: SIMD2(8.354, 6.641)),
            .line(SIMD2(9.298, 5.697)),
            .cubicCurve(control1: SIMD2(10.2391, 4.756), control2: SIMD2(11.7649, 4.756), end: SIMD2(12.706, 5.697)),
            .line(SIMD2(13.65, 6.641)),
            .cubicCurve(control1: SIMD2(13.8452, 6.8362), control2: SIMD2(14.1618, 6.8362), end: SIMD2(14.357, 6.641)),
            .line(SIMD2(18.376, 2.622)),
            .move(SIMD2(9, 8)),
            .cubicCurve(control1: SIMD2(7.196, 10.71), control2: SIMD2(5.03, 11.46), end: SIMD2(2.417, 11.948)),
            .cubicCurve(control1: SIMD2(2.2406, 11.9802), control2: SIMD2(2.0944, 12.1031), end: SIMD2(2.0324, 12.2713)),
            .cubicCurve(control1: SIMD2(1.9703, 12.4396), control2: SIMD2(2.0018, 12.628), end: SIMD2(2.115, 12.767)),
            .line(SIMD2(9.435, 21.65)),
            .cubicCurve(control1: SIMD2(9.7404, 21.9744), control2: SIMD2(10.2237, 22.0576), end: SIMD2(10.62, 21.854)),
            .cubicCurve(control1: SIMD2(12.735, 20.405), control2: SIMD2(16, 16.792), end: SIMD2(16, 15)),
        ]

    private static let palette:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 22)),
            .cubicCurve(control1: SIMD2(6.4772, 22), control2: SIMD2(2, 17.5228), end: SIMD2(2, 12)),
            .cubicCurve(control1: SIMD2(2, 6.4772), control2: SIMD2(6.4772, 2), end: SIMD2(12, 2)),
            .cubicCurve(control1: SIMD2(14.6522, 2), control2: SIMD2(17.1957, 2.9482), end: SIMD2(19.0711, 4.636)),
            .cubicCurve(control1: SIMD2(20.9464, 6.3239), control2: SIMD2(22, 8.6131), end: SIMD2(22, 11)),
            .cubicCurve(control1: SIMD2(22, 13.7614), control2: SIMD2(19.7614, 16), end: SIMD2(17, 16)),
            .line(SIMD2(14.75, 16)),
            .cubicCurve(control1: SIMD2(14.0871, 16), control2: SIMD2(13.4812, 16.3745), end: SIMD2(13.1848, 16.9674)),
            .cubicCurve(control1: SIMD2(12.8883, 17.5602), control2: SIMD2(12.9523, 18.2697), end: SIMD2(13.35, 18.8)),
            .line(SIMD2(13.65, 19.2)),
            .cubicCurve(control1: SIMD2(14.0477, 19.7303), control2: SIMD2(14.1117, 20.4398), end: SIMD2(13.8152, 21.0326)),
            .cubicCurve(control1: SIMD2(13.5188, 21.6255), control2: SIMD2(12.9129, 22), end: SIMD2(12.25, 22)),
            .line(SIMD2(12, 22)),
            .circle(center: SIMD2(13.5, 6.5), radius: 0.5),
            .circle(center: SIMD2(17.5, 10.5), radius: 0.5),
            .circle(center: SIMD2(6.5, 12.5), radius: 0.5),
            .circle(center: SIMD2(8.5, 7.5), radius: 0.5),
        ]

    private static let panelBottom:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(3, 15)),
            .line(SIMD2(21, 15)),
        ]

    private static let panelRight:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(15, 3)),
            .line(SIMD2(15, 21)),
        ]

    private static let panelsTopLeft:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(3, 9)),
            .line(SIMD2(21, 9)),
            .move(SIMD2(9, 21)),
            .line(SIMD2(9, 9)),
        ]

    private static let penTool:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15.707, 21.293)),
            .cubicCurve(control1: SIMD2(15.3165, 21.6834), control2: SIMD2(14.6835, 21.6834), end: SIMD2(14.293, 21.293)),
            .line(SIMD2(12.707, 19.707)),
            .cubicCurve(control1: SIMD2(12.3166, 19.3165), control2: SIMD2(12.3166, 18.6835), end: SIMD2(12.707, 18.293)),
            .line(SIMD2(18.293, 12.707)),
            .cubicCurve(control1: SIMD2(18.6835, 12.3166), control2: SIMD2(19.3165, 12.3166), end: SIMD2(19.707, 12.707)),
            .line(SIMD2(21.293, 14.293)),
            .cubicCurve(control1: SIMD2(21.6834, 14.6835), control2: SIMD2(21.6834, 15.3165), end: SIMD2(21.293, 15.707)),
            .line(SIMD2(15.707, 21.293)),
            .move(SIMD2(18, 13)),
            .line(SIMD2(16.625, 6.126)),
            .cubicCurve(control1: SIMD2(16.5486, 5.7441), control2: SIMD2(16.2575, 5.4414), end: SIMD2(15.879, 5.35)),
            .line(SIMD2(3.235, 2.028)),
            .cubicCurve(control1: SIMD2(2.8963, 1.9461), control2: SIMD2(2.5393, 2.0465), end: SIMD2(2.2929, 2.2929)),
            .cubicCurve(control1: SIMD2(2.0465, 2.5393), control2: SIMD2(1.9461, 2.8963), end: SIMD2(2.028, 3.235)),
            .line(SIMD2(5.35, 15.879)),
            .cubicCurve(control1: SIMD2(5.4414, 16.2575), control2: SIMD2(5.7441, 16.5486), end: SIMD2(6.126, 16.625)),
            .line(SIMD2(13, 18)),
            .move(SIMD2(2.3, 2.3)),
            .line(SIMD2(9.586, 9.586)),
            .circle(center: SIMD2(11, 11), radius: 2),
        ]

    private static let pencil:
        [SymbolGeometry.Command] = [
            .move(SIMD2(21.174, 6.812)),
            .cubicCurve(control1: SIMD2(22.275, 5.7113), control2: SIMD2(22.2752, 3.9265), end: SIMD2(21.1745, 2.8255)),
            .cubicCurve(control1: SIMD2(20.0738, 1.7245), control2: SIMD2(18.289, 1.7243), end: SIMD2(17.188, 2.825)),
            .line(SIMD2(3.842, 16.174)),
            .cubicCurve(control1: SIMD2(3.6098, 16.4055), control2: SIMD2(3.4381, 16.6905), end: SIMD2(3.342, 17.004)),
            .line(SIMD2(2.021, 21.356)),
            .cubicCurve(control1: SIMD2(1.9683, 21.5322), control2: SIMD2(2.0167, 21.7231), end: SIMD2(2.1468, 21.853)),
            .cubicCurve(control1: SIMD2(2.2769, 21.9829), control2: SIMD2(2.4679, 22.0309), end: SIMD2(2.644, 21.978)),
            .line(SIMD2(6.997, 20.658)),
            .cubicCurve(control1: SIMD2(7.3102, 20.5628), control2: SIMD2(7.5952, 20.3921), end: SIMD2(7.827, 20.161)),
            .line(SIMD2(21.174, 6.812)),
            .move(SIMD2(15, 5)),
            .line(SIMD2(19, 9)),
        ]

    private static let pencilRuler:
        [SymbolGeometry.Command] = [
            .move(SIMD2(13, 7)),
            .line(SIMD2(8.7, 2.7)),
            .cubicCurve(control1: SIMD2(7.7598, 1.7643), control2: SIMD2(6.2402, 1.7643), end: SIMD2(5.3, 2.7)),
            .line(SIMD2(2.7, 5.3)),
            .cubicCurve(control1: SIMD2(1.7643, 6.2402), control2: SIMD2(1.7643, 7.7598), end: SIMD2(2.7, 8.7)),
            .line(SIMD2(7, 13)),
            .move(SIMD2(8, 6)),
            .line(SIMD2(10, 4)),
            .move(SIMD2(18, 16)),
            .line(SIMD2(20, 14)),
            .move(SIMD2(17, 11)),
            .line(SIMD2(21.3, 15.3)),
            .cubicCurve(control1: SIMD2(22.24, 16.24), control2: SIMD2(22.24, 17.76), end: SIMD2(21.3, 18.7)),
            .line(SIMD2(18.7, 21.3)),
            .cubicCurve(control1: SIMD2(17.76, 22.24), control2: SIMD2(16.24, 22.24), end: SIMD2(15.3, 21.3)),
            .line(SIMD2(11, 17)),
            .move(SIMD2(21.174, 6.812)),
            .cubicCurve(control1: SIMD2(22.275, 5.7113), control2: SIMD2(22.2752, 3.9265), end: SIMD2(21.1745, 2.8255)),
            .cubicCurve(control1: SIMD2(20.0738, 1.7245), control2: SIMD2(18.289, 1.7243), end: SIMD2(17.188, 2.825)),
            .line(SIMD2(3.842, 16.174)),
            .cubicCurve(control1: SIMD2(3.6098, 16.4055), control2: SIMD2(3.4381, 16.6905), end: SIMD2(3.342, 17.004)),
            .line(SIMD2(2.021, 21.356)),
            .cubicCurve(control1: SIMD2(1.9683, 21.5322), control2: SIMD2(2.0167, 21.7231), end: SIMD2(2.1468, 21.853)),
            .cubicCurve(control1: SIMD2(2.2769, 21.9829), control2: SIMD2(2.4679, 22.0309), end: SIMD2(2.644, 21.978)),
            .line(SIMD2(6.997, 20.658)),
            .cubicCurve(control1: SIMD2(7.3102, 20.5628), control2: SIMD2(7.5952, 20.3921), end: SIMD2(7.827, 20.161)),
            .line(SIMD2(21.174, 6.812)),
            .move(SIMD2(15, 5)),
            .line(SIMD2(19, 9)),
        ]

    private static let plus:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 12)),
            .line(SIMD2(19, 12)),
            .move(SIMD2(12, 5)),
            .line(SIMD2(12, 19)),
        ]

    private static let printer:
        [SymbolGeometry.Command] = [
            .move(SIMD2(6, 18)),
            .line(SIMD2(4, 18)),
            .cubicCurve(control1: SIMD2(2.8954, 18), control2: SIMD2(2, 17.1046), end: SIMD2(2, 16)),
            .line(SIMD2(2, 11)),
            .cubicCurve(control1: SIMD2(2, 9.8954), control2: SIMD2(2.8954, 9), end: SIMD2(4, 9)),
            .line(SIMD2(20, 9)),
            .cubicCurve(control1: SIMD2(21.1046, 9), control2: SIMD2(22, 9.8954), end: SIMD2(22, 11)),
            .line(SIMD2(22, 16)),
            .cubicCurve(control1: SIMD2(22, 17.1046), control2: SIMD2(21.1046, 18), end: SIMD2(20, 18)),
            .line(SIMD2(18, 18)),
            .move(SIMD2(6, 9)),
            .line(SIMD2(6, 3)),
            .cubicCurve(control1: SIMD2(6, 2.4477), control2: SIMD2(6.4477, 2), end: SIMD2(7, 2)),
            .line(SIMD2(17, 2)),
            .cubicCurve(control1: SIMD2(17.5523, 2), control2: SIMD2(18, 2.4477), end: SIMD2(18, 3)),
            .line(SIMD2(18, 9)),
            .move(SIMD2(7, 14)),
            .line(SIMD2(17, 14)),
            .cubicCurve(control1: SIMD2(17.5523, 14), control2: SIMD2(18, 14.4477), end: SIMD2(18, 15)),
            .line(SIMD2(18, 21)),
            .cubicCurve(control1: SIMD2(18, 21.5523), control2: SIMD2(17.5523, 22), end: SIMD2(17, 22)),
            .line(SIMD2(7, 22)),
            .cubicCurve(control1: SIMD2(6.4477, 22), control2: SIMD2(6, 21.5523), end: SIMD2(6, 21)),
            .line(SIMD2(6, 15)),
            .cubicCurve(control1: SIMD2(6, 14.4477), control2: SIMD2(6.4477, 14), end: SIMD2(7, 14)),
        ]

    private static let rectangleVertical:
        [SymbolGeometry.Command] = [
            .move(SIMD2(8, 2)),
            .line(SIMD2(16, 2)),
            .cubicCurve(control1: SIMD2(17.1046, 2), control2: SIMD2(18, 2.8954), end: SIMD2(18, 4)),
            .line(SIMD2(18, 20)),
            .cubicCurve(control1: SIMD2(18, 21.1046), control2: SIMD2(17.1046, 22), end: SIMD2(16, 22)),
            .line(SIMD2(8, 22)),
            .cubicCurve(control1: SIMD2(6.8954, 22), control2: SIMD2(6, 21.1046), end: SIMD2(6, 20)),
            .line(SIMD2(6, 4)),
            .cubicCurve(control1: SIMD2(6, 2.8954), control2: SIMD2(6.8954, 2), end: SIMD2(8, 2)),
        ]

    private static let redo2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(15, 14)),
            .line(SIMD2(20, 9)),
            .line(SIMD2(15, 4)),
            .move(SIMD2(20, 9)),
            .line(SIMD2(9.5, 9)),
            .cubicCurve(control1: SIMD2(6.4624, 9), control2: SIMD2(4, 11.4624), end: SIMD2(4, 14.5)),
            .cubicCurve(control1: SIMD2(4, 17.5376), control2: SIMD2(6.4624, 20), end: SIMD2(9.5, 20)),
            .line(SIMD2(13, 20)),
        ]

    private static let refreshCw:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3, 12)),
            .cubicCurve(control1: SIMD2(3, 7.0294), control2: SIMD2(7.0294, 3), end: SIMD2(12, 3)),
            .cubicCurve(control1: SIMD2(14.516, 3.0095), control2: SIMD2(16.931, 3.9912), end: SIMD2(18.74, 5.74)),
            .line(SIMD2(21, 8)),
            .move(SIMD2(21, 3)),
            .line(SIMD2(21, 8)),
            .line(SIMD2(16, 8)),
            .move(SIMD2(21, 12)),
            .cubicCurve(control1: SIMD2(21, 16.9706), control2: SIMD2(16.9706, 21), end: SIMD2(12, 21)),
            .cubicCurve(control1: SIMD2(9.484, 20.9905), control2: SIMD2(7.069, 20.0088), end: SIMD2(5.26, 18.26)),
            .line(SIMD2(3, 16)),
            .move(SIMD2(8, 16)),
            .line(SIMD2(3, 16)),
            .line(SIMD2(3, 21)),
        ]

    private static let rotateCcw:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3, 12)),
            .cubicCurve(control1: SIMD2(3, 16.9706), control2: SIMD2(7.0294, 21), end: SIMD2(12, 21)),
            .cubicCurve(control1: SIMD2(16.9706, 21), control2: SIMD2(21, 16.9706), end: SIMD2(21, 12)),
            .cubicCurve(control1: SIMD2(21, 7.0294), control2: SIMD2(16.9706, 3), end: SIMD2(12, 3)),
            .cubicCurve(control1: SIMD2(9.484, 3.0095), control2: SIMD2(7.069, 3.9912), end: SIMD2(5.26, 5.74)),
            .line(SIMD2(3, 8)),
            .move(SIMD2(3, 3)),
            .line(SIMD2(3, 8)),
            .line(SIMD2(8, 8)),
        ]

    private static let rotateCw:
        [SymbolGeometry.Command] = [
            .move(SIMD2(21, 12)),
            .cubicCurve(control1: SIMD2(21, 16.9706), control2: SIMD2(16.9706, 21), end: SIMD2(12, 21)),
            .cubicCurve(control1: SIMD2(7.0294, 21), control2: SIMD2(3, 16.9706), end: SIMD2(3, 12)),
            .cubicCurve(control1: SIMD2(3, 7.0294), control2: SIMD2(7.0294, 3), end: SIMD2(12, 3)),
            .cubicCurve(control1: SIMD2(14.52, 3), control2: SIMD2(16.93, 4), end: SIMD2(18.74, 5.74)),
            .line(SIMD2(21, 8)),
            .move(SIMD2(21, 3)),
            .line(SIMD2(21, 8)),
            .line(SIMD2(16, 8)),
        ]

    private static let rows3:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(21, 9)),
            .line(SIMD2(3, 9)),
            .move(SIMD2(21, 15)),
            .line(SIMD2(3, 15)),
        ]

    private static let ruler:
        [SymbolGeometry.Command] = [
            .move(SIMD2(21.3, 15.3)),
            .cubicCurve(control1: SIMD2(21.7519, 15.7503), control2: SIMD2(22.0059, 16.362), end: SIMD2(22.0059, 17)),
            .cubicCurve(control1: SIMD2(22.0059, 17.638), control2: SIMD2(21.7519, 18.2497), end: SIMD2(21.3, 18.7)),
            .line(SIMD2(18.7, 21.3)),
            .cubicCurve(control1: SIMD2(18.2497, 21.7519), control2: SIMD2(17.638, 22.0059), end: SIMD2(17, 22.0059)),
            .cubicCurve(control1: SIMD2(16.362, 22.0059), control2: SIMD2(15.7503, 21.7519), end: SIMD2(15.3, 21.3)),
            .line(SIMD2(2.7, 8.7)),
            .cubicCurve(control1: SIMD2(1.7643, 7.7598), control2: SIMD2(1.7643, 6.2402), end: SIMD2(2.7, 5.3)),
            .line(SIMD2(5.3, 2.7)),
            .cubicCurve(control1: SIMD2(6.2402, 1.7643), control2: SIMD2(7.7598, 1.7643), end: SIMD2(8.7, 2.7)),
            .line(SIMD2(21.3, 15.3)),
            .move(SIMD2(14.5, 12.5)),
            .line(SIMD2(16.5, 10.5)),
            .move(SIMD2(11.5, 9.5)),
            .line(SIMD2(13.5, 7.5)),
            .move(SIMD2(8.5, 6.5)),
            .line(SIMD2(10.5, 4.5)),
            .move(SIMD2(17.5, 15.5)),
            .line(SIMD2(19.5, 13.5)),
        ]

    private static let scan:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3, 7)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .line(SIMD2(7, 3)),
            .move(SIMD2(17, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 7)),
            .move(SIMD2(21, 17)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(17, 21)),
            .move(SIMD2(7, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 17)),
        ]

    private static let scanEye:
        [SymbolGeometry.Command] = [
            .move(SIMD2(3, 7)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .line(SIMD2(7, 3)),
            .move(SIMD2(17, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 7)),
            .move(SIMD2(21, 17)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(17, 21)),
            .move(SIMD2(7, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 17)),
            .circle(center: SIMD2(12, 12), radius: 1),
            .move(SIMD2(18.944, 12.33)),
            .cubicCurve(control1: SIMD2(19.0187, 12.1163), control2: SIMD2(19.0187, 11.8837), end: SIMD2(18.944, 11.67)),
            .cubicCurve(control1: SIMD2(17.7924, 8.8482), control2: SIMD2(15.0477, 7.0039), end: SIMD2(12, 7.0039)),
            .cubicCurve(control1: SIMD2(8.9523, 7.0039), control2: SIMD2(6.2076, 8.8482), end: SIMD2(5.056, 11.67)),
            .cubicCurve(control1: SIMD2(4.9813, 11.8837), control2: SIMD2(4.9813, 12.1163), end: SIMD2(5.056, 12.33)),
            .cubicCurve(control1: SIMD2(6.2076, 15.1518), control2: SIMD2(8.9523, 16.9961), end: SIMD2(12, 16.9961)),
            .cubicCurve(control1: SIMD2(15.0477, 16.9961), control2: SIMD2(17.7924, 15.1518), end: SIMD2(18.944, 12.33)),
        ]

    private static let scissors:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(6, 6), radius: 3),
            .move(SIMD2(8.12, 8.12)),
            .line(SIMD2(12, 12)),
            .move(SIMD2(20, 4)),
            .line(SIMD2(8.12, 15.88)),
            .circle(center: SIMD2(6, 18), radius: 3),
            .move(SIMD2(14.8, 14.8)),
            .line(SIMD2(20, 20)),
        ]

    private static let settings:
        [SymbolGeometry.Command] = [
            .move(SIMD2(9.671, 4.136)),
            .cubicCurve(control1: SIMD2(9.7852, 2.9348), control2: SIMD2(10.7939, 2.0174), end: SIMD2(12.0005, 2.0174)),
            .cubicCurve(control1: SIMD2(13.2071, 2.0174), control2: SIMD2(14.2158, 2.9348), end: SIMD2(14.33, 4.136)),
            .cubicCurve(control1: SIMD2(14.3972, 4.8959), control2: SIMD2(14.8307, 5.5754), end: SIMD2(15.4915, 5.9567)),
            .cubicCurve(control1: SIMD2(16.1523, 6.3379), control2: SIMD2(16.9574, 6.3731), end: SIMD2(17.649, 6.051)),
            .cubicCurve(control1: SIMD2(18.7452, 5.5533), control2: SIMD2(20.0402, 5.9686), end: SIMD2(20.6425, 7.0111)),
            .cubicCurve(control1: SIMD2(21.2448, 8.0536), control2: SIMD2(20.9577, 9.3829), end: SIMD2(19.979, 10.084)),
            .cubicCurve(control1: SIMD2(19.3547, 10.522), control2: SIMD2(18.983, 11.2369), end: SIMD2(18.983, 11.9995)),
            .cubicCurve(control1: SIMD2(18.983, 12.7621), control2: SIMD2(19.3547, 13.477), end: SIMD2(19.979, 13.915)),
            .cubicCurve(control1: SIMD2(20.9577, 14.6161), control2: SIMD2(21.2448, 15.9454), end: SIMD2(20.6425, 16.9879)),
            .cubicCurve(control1: SIMD2(20.0402, 18.0304), control2: SIMD2(18.7452, 18.4457), end: SIMD2(17.649, 17.948)),
            .cubicCurve(control1: SIMD2(16.9574, 17.6259), control2: SIMD2(16.1523, 17.6611), end: SIMD2(15.4915, 18.0423)),
            .cubicCurve(control1: SIMD2(14.8307, 18.4236), control2: SIMD2(14.3972, 19.1031), end: SIMD2(14.33, 19.863)),
            .cubicCurve(control1: SIMD2(14.2158, 21.0642), control2: SIMD2(13.2071, 21.9816), end: SIMD2(12.0005, 21.9816)),
            .cubicCurve(control1: SIMD2(10.7939, 21.9816), control2: SIMD2(9.7852, 21.0642), end: SIMD2(9.671, 19.863)),
            .cubicCurve(control1: SIMD2(9.6039, 19.1028), control2: SIMD2(9.1703, 18.423), end: SIMD2(8.5092, 18.0417)),
            .cubicCurve(control1: SIMD2(7.8481, 17.6604), control2: SIMD2(7.0427, 17.6254), end: SIMD2(6.351, 17.948)),
            .cubicCurve(control1: SIMD2(5.2548, 18.4457), control2: SIMD2(3.9598, 18.0304), end: SIMD2(3.3575, 16.9879)),
            .cubicCurve(control1: SIMD2(2.7552, 15.9454), control2: SIMD2(3.0423, 14.6161), end: SIMD2(4.021, 13.915)),
            .cubicCurve(control1: SIMD2(4.6453, 13.477), control2: SIMD2(5.017, 12.7621), end: SIMD2(5.017, 11.9995)),
            .cubicCurve(control1: SIMD2(5.017, 11.2369), control2: SIMD2(4.6453, 10.522), end: SIMD2(4.021, 10.084)),
            .cubicCurve(control1: SIMD2(3.0437, 9.3826), control2: SIMD2(2.7574, 8.0544), end: SIMD2(3.359, 7.0127)),
            .cubicCurve(control1: SIMD2(3.9606, 5.971), control2: SIMD2(5.254, 5.5551), end: SIMD2(6.35, 6.051)),
            .cubicCurve(control1: SIMD2(7.0416, 6.3731), control2: SIMD2(7.8467, 6.3379), end: SIMD2(8.5075, 5.9567)),
            .cubicCurve(control1: SIMD2(9.1683, 5.5754), control2: SIMD2(9.6018, 4.8959), end: SIMD2(9.669, 4.136)),
            .circle(center: SIMD2(12, 12), radius: 3),
        ]

    private static let shapes:
        [SymbolGeometry.Command] = [
            .move(SIMD2(8.3, 10)),
            .cubicCurve(control1: SIMD2(8.0372, 10.0143), control2: SIMD2(7.7885, 9.88), end: SIMD2(7.6564, 9.6523)),
            .cubicCurve(control1: SIMD2(7.5243, 9.4246), control2: SIMD2(7.5311, 9.1421), end: SIMD2(7.674, 8.921)),
            .line(SIMD2(11.4, 3)),
            .cubicCurve(control1: SIMD2(11.5191, 2.7856), control2: SIMD2(11.7417, 2.6491), end: SIMD2(11.9869, 2.6403)),
            .cubicCurve(control1: SIMD2(12.232, 2.6315), control2: SIMD2(12.4638, 2.7516), end: SIMD2(12.598, 2.957)),
            .line(SIMD2(16.3, 8.9)),
            .cubicCurve(control1: SIMD2(16.4487, 9.1136), control2: SIMD2(16.4667, 9.392), end: SIMD2(16.3466, 9.623)),
            .cubicCurve(control1: SIMD2(16.2265, 9.8539), control2: SIMD2(15.9883, 9.9991), end: SIMD2(15.728, 10)),
            .line(SIMD2(8.3, 10)),
            .move(SIMD2(4, 14)),
            .line(SIMD2(9, 14)),
            .cubicCurve(control1: SIMD2(9.5523, 14), control2: SIMD2(10, 14.4477), end: SIMD2(10, 15)),
            .line(SIMD2(10, 20)),
            .cubicCurve(control1: SIMD2(10, 20.5523), control2: SIMD2(9.5523, 21), end: SIMD2(9, 21)),
            .line(SIMD2(4, 21)),
            .cubicCurve(control1: SIMD2(3.4477, 21), control2: SIMD2(3, 20.5523), end: SIMD2(3, 20)),
            .line(SIMD2(3, 15)),
            .cubicCurve(control1: SIMD2(3, 14.4477), control2: SIMD2(3.4477, 14), end: SIMD2(4, 14)),
            .circle(center: SIMD2(17.5, 17.5), radius: 3.5),
        ]

    private static let share:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 2)),
            .line(SIMD2(12, 15)),
            .move(SIMD2(16, 6)),
            .line(SIMD2(12, 2)),
            .line(SIMD2(8, 6)),
            .move(SIMD2(4, 12)),
            .line(SIMD2(4, 20)),
            .cubicCurve(control1: SIMD2(4, 21.1046), control2: SIMD2(4.8954, 22), end: SIMD2(6, 22)),
            .line(SIMD2(18, 22)),
            .cubicCurve(control1: SIMD2(19.1046, 22), control2: SIMD2(20, 21.1046), end: SIMD2(20, 20)),
            .line(SIMD2(20, 12)),
        ]

    private static let shield:
        [SymbolGeometry.Command] = [
            .move(SIMD2(20, 13)),
            .cubicCurve(control1: SIMD2(20, 18), control2: SIMD2(16.5, 20.5), end: SIMD2(12.34, 21.95)),
            .cubicCurve(control1: SIMD2(12.1222, 22.0238), control2: SIMD2(11.8855, 22.0203), end: SIMD2(11.67, 21.94)),
            .cubicCurve(control1: SIMD2(7.5, 20.5), control2: SIMD2(4, 18), end: SIMD2(4, 13)),
            .line(SIMD2(4, 6)),
            .cubicCurve(control1: SIMD2(4, 5.4477), control2: SIMD2(4.4477, 5), end: SIMD2(5, 5)),
            .cubicCurve(control1: SIMD2(7, 5), control2: SIMD2(9.5, 3.8), end: SIMD2(11.24, 2.28)),
            .cubicCurve(control1: SIMD2(11.6777, 1.9061), control2: SIMD2(12.3223, 1.9061), end: SIMD2(12.76, 2.28)),
            .cubicCurve(control1: SIMD2(14.51, 3.81), control2: SIMD2(17, 5), end: SIMD2(19, 5)),
            .cubicCurve(control1: SIMD2(19.5523, 5), control2: SIMD2(20, 5.4477), end: SIMD2(20, 6)),
            .line(SIMD2(20, 13)),
        ]

    private static let shieldCheck:
        [SymbolGeometry.Command] = [
            .move(SIMD2(20, 13)),
            .cubicCurve(control1: SIMD2(20, 18), control2: SIMD2(16.5, 20.5), end: SIMD2(12.34, 21.95)),
            .cubicCurve(control1: SIMD2(12.1222, 22.0238), control2: SIMD2(11.8855, 22.0203), end: SIMD2(11.67, 21.94)),
            .cubicCurve(control1: SIMD2(7.5, 20.5), control2: SIMD2(4, 18), end: SIMD2(4, 13)),
            .line(SIMD2(4, 6)),
            .cubicCurve(control1: SIMD2(4, 5.4477), control2: SIMD2(4.4477, 5), end: SIMD2(5, 5)),
            .cubicCurve(control1: SIMD2(7, 5), control2: SIMD2(9.5, 3.8), end: SIMD2(11.24, 2.28)),
            .cubicCurve(control1: SIMD2(11.6777, 1.9061), control2: SIMD2(12.3223, 1.9061), end: SIMD2(12.76, 2.28)),
            .cubicCurve(control1: SIMD2(14.51, 3.81), control2: SIMD2(17, 5), end: SIMD2(19, 5)),
            .cubicCurve(control1: SIMD2(19.5523, 5), control2: SIMD2(20, 5.4477), end: SIMD2(20, 6)),
            .line(SIMD2(20, 13)),
            .move(SIMD2(9, 12)),
            .line(SIMD2(11, 14)),
            .line(SIMD2(15, 10)),
        ]

    private static let slash:
        [SymbolGeometry.Command] = [
            .move(SIMD2(22, 2)),
            .line(SIMD2(2, 22)),
        ]

    private static let slidersHorizontal:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10, 5)),
            .line(SIMD2(3, 5)),
            .move(SIMD2(12, 19)),
            .line(SIMD2(3, 19)),
            .move(SIMD2(14, 3)),
            .line(SIMD2(14, 7)),
            .move(SIMD2(16, 17)),
            .line(SIMD2(16, 21)),
            .move(SIMD2(21, 12)),
            .line(SIMD2(12, 12)),
            .move(SIMD2(21, 19)),
            .line(SIMD2(16, 19)),
            .move(SIMD2(21, 5)),
            .line(SIMD2(14, 5)),
            .move(SIMD2(8, 10)),
            .line(SIMD2(8, 14)),
            .move(SIMD2(8, 12)),
            .line(SIMD2(3, 12)),
        ]

    private static let spline:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(19, 5), radius: 2),
            .circle(center: SIMD2(5, 19), radius: 2),
            .move(SIMD2(5, 17)),
            .cubicCurve(control1: SIMD2(5, 10.3726), control2: SIMD2(10.3726, 5), end: SIMD2(17, 5)),
        ]

    private static let square:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
        ]

    private static let squareArrowRight:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(8, 12)),
            .line(SIMD2(16, 12)),
            .move(SIMD2(12, 16)),
            .line(SIMD2(16, 12)),
            .line(SIMD2(12, 8)),
        ]

    private static let squareDashed:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .cubicCurve(control1: SIMD2(3.8954, 3), control2: SIMD2(3, 3.8954), end: SIMD2(3, 5)),
            .move(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .move(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .move(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .move(SIMD2(9, 3)),
            .line(SIMD2(10, 3)),
            .move(SIMD2(9, 21)),
            .line(SIMD2(10, 21)),
            .move(SIMD2(14, 3)),
            .line(SIMD2(15, 3)),
            .move(SIMD2(14, 21)),
            .line(SIMD2(15, 21)),
            .move(SIMD2(3, 9)),
            .line(SIMD2(3, 10)),
            .move(SIMD2(21, 9)),
            .line(SIMD2(21, 10)),
            .move(SIMD2(3, 14)),
            .line(SIMD2(3, 15)),
            .move(SIMD2(21, 14)),
            .line(SIMD2(21, 15)),
        ]

    private static let squareDashedMousePointer:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12.034, 12.681)),
            .cubicCurve(control1: SIMD2(11.9603, 12.4961), control2: SIMD2(12.0038, 12.2852), end: SIMD2(12.1445, 12.1445)),
            .cubicCurve(control1: SIMD2(12.2852, 12.0038), control2: SIMD2(12.4961, 11.9603), end: SIMD2(12.681, 12.034)),
            .line(SIMD2(21.681, 15.534)),
            .cubicCurve(control1: SIMD2(21.8788, 15.6113), control2: SIMD2(22.0061, 15.805), end: SIMD2(21.9987, 16.0172)),
            .cubicCurve(control1: SIMD2(21.9913, 16.2294), control2: SIMD2(21.8507, 16.4137), end: SIMD2(21.648, 16.477)),
            .line(SIMD2(18.204, 17.545)),
            .cubicCurve(control1: SIMD2(17.8885, 17.6425), control2: SIMD2(17.6415, 17.8895), end: SIMD2(17.544, 18.205)),
            .line(SIMD2(16.477, 21.648)),
            .cubicCurve(control1: SIMD2(16.4137, 21.8507), control2: SIMD2(16.2294, 21.9913), end: SIMD2(16.0172, 21.9987)),
            .cubicCurve(control1: SIMD2(15.805, 22.0061), control2: SIMD2(15.6113, 21.8788), end: SIMD2(15.534, 21.681)),
            .line(SIMD2(12.034, 12.681)),
            .move(SIMD2(5, 3)),
            .cubicCurve(control1: SIMD2(3.8954, 3), control2: SIMD2(3, 3.8954), end: SIMD2(3, 5)),
            .move(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .move(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .move(SIMD2(9, 3)),
            .line(SIMD2(10, 3)),
            .move(SIMD2(9, 21)),
            .line(SIMD2(11, 21)),
            .move(SIMD2(14, 3)),
            .line(SIMD2(15, 3)),
            .move(SIMD2(3, 9)),
            .line(SIMD2(3, 10)),
            .move(SIMD2(21, 9)),
            .line(SIMD2(21, 11)),
            .move(SIMD2(3, 14)),
            .line(SIMD2(3, 15)),
        ]

    private static let squareFunction:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(9, 17)),
            .cubicCurve(control1: SIMD2(11, 17), control2: SIMD2(11.8, 16), end: SIMD2(11.8, 14.2)),
            .line(SIMD2(11.8, 10)),
            .cubicCurve(control1: SIMD2(11.8, 8), control2: SIMD2(12.8, 6.7), end: SIMD2(15, 7)),
            .move(SIMD2(9, 11.2)),
            .line(SIMD2(14.7, 11.2)),
        ]

    private static let squareMinus:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(8, 12)),
            .line(SIMD2(16, 12)),
        ]

    private static let squarePen:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 3)),
            .line(SIMD2(5, 3)),
            .cubicCurve(control1: SIMD2(3.8954, 3), control2: SIMD2(3, 3.8954), end: SIMD2(3, 5)),
            .line(SIMD2(3, 19)),
            .cubicCurve(control1: SIMD2(3, 20.1046), control2: SIMD2(3.8954, 21), end: SIMD2(5, 21)),
            .line(SIMD2(19, 21)),
            .cubicCurve(control1: SIMD2(20.1046, 21), control2: SIMD2(21, 20.1046), end: SIMD2(21, 19)),
            .line(SIMD2(21, 12)),
            .move(SIMD2(18.375, 2.625)),
            .cubicCurve(control1: SIMD2(19.2034, 1.7966), control2: SIMD2(20.5466, 1.7966), end: SIMD2(21.375, 2.625)),
            .cubicCurve(control1: SIMD2(22.2034, 3.4534), control2: SIMD2(22.2034, 4.7966), end: SIMD2(21.375, 5.625)),
            .line(SIMD2(12.362, 14.639)),
            .cubicCurve(control1: SIMD2(12.1245, 14.8762), control2: SIMD2(11.8312, 15.0499), end: SIMD2(11.509, 15.144)),
            .line(SIMD2(8.636, 15.984)),
            .cubicCurve(control1: SIMD2(8.4607, 16.0351), control2: SIMD2(8.2715, 15.9866), end: SIMD2(8.1424, 15.8576)),
            .cubicCurve(control1: SIMD2(8.0134, 15.7285), control2: SIMD2(7.9649, 15.5393), end: SIMD2(8.016, 15.364)),
            .line(SIMD2(8.856, 12.491)),
            .cubicCurve(control1: SIMD2(8.9505, 12.1691), control2: SIMD2(9.1245, 11.8761), end: SIMD2(9.362, 11.639)),
            .line(SIMD2(18.375, 2.625)),
        ]

    private static let squarePlus:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 19)),
            .cubicCurve(control1: SIMD2(21, 20.1046), control2: SIMD2(20.1046, 21), end: SIMD2(19, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 5)),
            .cubicCurve(control1: SIMD2(3, 3.8954), control2: SIMD2(3.8954, 3), end: SIMD2(5, 3)),
            .move(SIMD2(8, 12)),
            .line(SIMD2(16, 12)),
            .move(SIMD2(12, 8)),
            .line(SIMD2(12, 16)),
        ]

    private static let squareSplitHorizontal:
        [SymbolGeometry.Command] = [
            .move(SIMD2(8, 19)),
            .line(SIMD2(5, 19)),
            .cubicCurve(control1: SIMD2(4, 19), control2: SIMD2(3, 18), end: SIMD2(3, 17)),
            .line(SIMD2(3, 7)),
            .cubicCurve(control1: SIMD2(3, 6), control2: SIMD2(4, 5), end: SIMD2(5, 5)),
            .line(SIMD2(8, 5)),
            .move(SIMD2(16, 5)),
            .line(SIMD2(19, 5)),
            .cubicCurve(control1: SIMD2(20, 5), control2: SIMD2(21, 6), end: SIMD2(21, 7)),
            .line(SIMD2(21, 17)),
            .cubicCurve(control1: SIMD2(21, 18), control2: SIMD2(20, 19), end: SIMD2(19, 19)),
            .line(SIMD2(16, 19)),
            .move(SIMD2(12, 4)),
            .line(SIMD2(12, 20)),
        ]

    private static let squareSplitVertical:
        [SymbolGeometry.Command] = [
            .move(SIMD2(5, 8)),
            .line(SIMD2(5, 5)),
            .cubicCurve(control1: SIMD2(5, 4), control2: SIMD2(6, 3), end: SIMD2(7, 3)),
            .line(SIMD2(17, 3)),
            .cubicCurve(control1: SIMD2(18, 3), control2: SIMD2(19, 4), end: SIMD2(19, 5)),
            .line(SIMD2(19, 8)),
            .move(SIMD2(19, 16)),
            .line(SIMD2(19, 19)),
            .cubicCurve(control1: SIMD2(19, 20), control2: SIMD2(18, 21), end: SIMD2(17, 21)),
            .line(SIMD2(7, 21)),
            .cubicCurve(control1: SIMD2(6, 21), control2: SIMD2(5, 20), end: SIMD2(5, 19)),
            .line(SIMD2(5, 16)),
            .move(SIMD2(4, 12)),
            .line(SIMD2(20, 12)),
        ]

    private static let star:
        [SymbolGeometry.Command] = [
            .move(SIMD2(11.525, 2.295)),
            .cubicCurve(control1: SIMD2(11.6144, 2.1144), control2: SIMD2(11.7985, 2.0001), end: SIMD2(12, 2.0001)),
            .cubicCurve(control1: SIMD2(12.2015, 2.0001), control2: SIMD2(12.3856, 2.1144), end: SIMD2(12.475, 2.295)),
            .line(SIMD2(14.785, 6.974)),
            .cubicCurve(control1: SIMD2(15.0939, 7.5991), control2: SIMD2(15.6901, 8.0327), end: SIMD2(16.38, 8.134)),
            .line(SIMD2(21.546, 8.89)),
            .cubicCurve(control1: SIMD2(21.7457, 8.9189), control2: SIMD2(21.9116, 9.0587), end: SIMD2(21.974, 9.2506)),
            .cubicCurve(control1: SIMD2(22.0364, 9.4425), control2: SIMD2(21.9845, 9.6531), end: SIMD2(21.84, 9.794)),
            .line(SIMD2(18.104, 13.432)),
            .cubicCurve(control1: SIMD2(17.6038, 13.9194), control2: SIMD2(17.3754, 14.6216), end: SIMD2(17.493, 15.31)),
            .line(SIMD2(18.375, 20.45)),
            .cubicCurve(control1: SIMD2(18.4103, 20.6496), control2: SIMD2(18.3286, 20.8519), end: SIMD2(18.1645, 20.971)),
            .cubicCurve(control1: SIMD2(18.0005, 21.0901), control2: SIMD2(17.7829, 21.1053), end: SIMD2(17.604, 21.01)),
            .line(SIMD2(12.986, 18.582)),
            .cubicCurve(control1: SIMD2(12.3683, 18.2577), control2: SIMD2(11.6307, 18.2577), end: SIMD2(11.013, 18.582)),
            .line(SIMD2(6.396, 21.01)),
            .cubicCurve(control1: SIMD2(6.2171, 21.1047), control2: SIMD2(6, 21.0893), end: SIMD2(5.8363, 20.9702)),
            .cubicCurve(control1: SIMD2(5.6726, 20.8512), control2: SIMD2(5.591, 20.6493), end: SIMD2(5.626, 20.45)),
            .line(SIMD2(6.507, 15.311)),
            .cubicCurve(control1: SIMD2(6.6251, 14.6223), control2: SIMD2(6.3966, 13.9195), end: SIMD2(5.896, 13.432)),
            .line(SIMD2(2.16, 9.795)),
            .cubicCurve(control1: SIMD2(2.0143, 9.6543), control2: SIMD2(1.9616, 9.4428), end: SIMD2(2.0241, 9.2502)),
            .cubicCurve(control1: SIMD2(2.0866, 9.0575), control2: SIMD2(2.2534, 8.9174), end: SIMD2(2.454, 8.889)),
            .line(SIMD2(7.619, 8.134)),
            .cubicCurve(control1: SIMD2(8.3097, 8.0335), control2: SIMD2(8.9068, 7.5998), end: SIMD2(9.216, 6.974)),
            .line(SIMD2(11.525, 2.295)),
        ]

    private static let table2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(9, 3)),
            .line(SIMD2(5, 3)),
            .cubicCurve(control1: SIMD2(3.8954, 3), control2: SIMD2(3, 3.8954), end: SIMD2(3, 5)),
            .line(SIMD2(3, 9)),
            .move(SIMD2(9, 3)),
            .line(SIMD2(19, 3)),
            .cubicCurve(control1: SIMD2(20.1046, 3), control2: SIMD2(21, 3.8954), end: SIMD2(21, 5)),
            .line(SIMD2(21, 9)),
            .move(SIMD2(9, 3)),
            .line(SIMD2(9, 21)),
            .move(SIMD2(9, 21)),
            .line(SIMD2(19, 21)),
            .cubicCurve(control1: SIMD2(20.1046, 21), control2: SIMD2(21, 20.1046), end: SIMD2(21, 19)),
            .line(SIMD2(21, 9)),
            .move(SIMD2(9, 21)),
            .line(SIMD2(5, 21)),
            .cubicCurve(control1: SIMD2(3.8954, 21), control2: SIMD2(3, 20.1046), end: SIMD2(3, 19)),
            .line(SIMD2(3, 9)),
            .move(SIMD2(3, 9)),
            .line(SIMD2(21, 9)),
        ]

    private static let textCursor:
        [SymbolGeometry.Command] = [
            .move(SIMD2(17, 22)),
            .line(SIMD2(16, 22)),
            .cubicCurve(control1: SIMD2(13.7909, 22), control2: SIMD2(12, 20.2091), end: SIMD2(12, 18)),
            .line(SIMD2(12, 6)),
            .cubicCurve(control1: SIMD2(12, 3.7909), control2: SIMD2(13.7909, 2), end: SIMD2(16, 2)),
            .line(SIMD2(17, 2)),
            .move(SIMD2(7, 22)),
            .line(SIMD2(8, 22)),
            .cubicCurve(control1: SIMD2(10.2091, 22), control2: SIMD2(12, 20.2091), end: SIMD2(12, 18)),
            .move(SIMD2(7, 2)),
            .line(SIMD2(8, 2)),
            .cubicCurve(control1: SIMD2(10.2091, 2), control2: SIMD2(12, 3.7909), end: SIMD2(12, 6)),
        ]

    private static let trash2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10, 11)),
            .line(SIMD2(10, 17)),
            .move(SIMD2(14, 11)),
            .line(SIMD2(14, 17)),
            .move(SIMD2(19, 6)),
            .line(SIMD2(19, 20)),
            .cubicCurve(control1: SIMD2(19, 21.1046), control2: SIMD2(18.1046, 22), end: SIMD2(17, 22)),
            .line(SIMD2(7, 22)),
            .cubicCurve(control1: SIMD2(5.8954, 22), control2: SIMD2(5, 21.1046), end: SIMD2(5, 20)),
            .line(SIMD2(5, 6)),
            .move(SIMD2(3, 6)),
            .line(SIMD2(21, 6)),
            .move(SIMD2(8, 6)),
            .line(SIMD2(8, 4)),
            .cubicCurve(control1: SIMD2(8, 2.8954), control2: SIMD2(8.8954, 2), end: SIMD2(10, 2)),
            .line(SIMD2(14, 2)),
            .cubicCurve(control1: SIMD2(15.1046, 2), control2: SIMD2(16, 2.8954), end: SIMD2(16, 4)),
            .line(SIMD2(16, 6)),
        ]

    private static let triangleAlert:
        [SymbolGeometry.Command] = [
            .move(SIMD2(21.73, 18)),
            .line(SIMD2(13.73, 4)),
            .cubicCurve(control1: SIMD2(13.3749, 3.3734), control2: SIMD2(12.7103, 2.9861), end: SIMD2(11.99, 2.9861)),
            .cubicCurve(control1: SIMD2(11.2697, 2.9861), control2: SIMD2(10.6051, 3.3734), end: SIMD2(10.25, 4)),
            .line(SIMD2(2.25, 18)),
            .cubicCurve(control1: SIMD2(1.8911, 18.6216), control2: SIMD2(1.8928, 19.3878), end: SIMD2(2.2544, 20.0078)),
            .cubicCurve(control1: SIMD2(2.6161, 20.6278), control2: SIMD2(3.2823, 21.0065), end: SIMD2(4, 21)),
            .line(SIMD2(20, 21)),
            .cubicCurve(control1: SIMD2(20.7142, 20.9993), control2: SIMD2(21.3737, 20.6178), end: SIMD2(21.7305, 19.9991)),
            .cubicCurve(control1: SIMD2(22.0873, 19.3804), control2: SIMD2(22.0871, 18.6185), end: SIMD2(21.73, 18)),
            .move(SIMD2(12, 9)),
            .line(SIMD2(12, 13)),
            .move(SIMD2(12, 17)),
            .line(SIMD2(12.01, 17)),
        ]

    private static let triangleRight:
        [SymbolGeometry.Command] = [
            .move(SIMD2(22, 18)),
            .cubicCurve(control1: SIMD2(22, 19.1046), control2: SIMD2(21.1046, 20), end: SIMD2(20, 20)),
            .line(SIMD2(3, 20)),
            .cubicCurve(control1: SIMD2(1.9, 20), control2: SIMD2(1.7, 19.4), end: SIMD2(2.6, 18.7)),
            .line(SIMD2(20.4, 4.3)),
            .cubicCurve(control1: SIMD2(21.3, 3.6), control2: SIMD2(22, 3.9), end: SIMD2(22, 5)),
            .line(SIMD2(22, 18)),
        ]

    private static let type:
        [SymbolGeometry.Command] = [
            .move(SIMD2(12, 4)),
            .line(SIMD2(12, 20)),
            .move(SIMD2(4, 7)),
            .line(SIMD2(4, 5)),
            .cubicCurve(control1: SIMD2(4, 4.4477), control2: SIMD2(4.4477, 4), end: SIMD2(5, 4)),
            .line(SIMD2(19, 4)),
            .cubicCurve(control1: SIMD2(19.5523, 4), control2: SIMD2(20, 4.4477), end: SIMD2(20, 5)),
            .line(SIMD2(20, 7)),
            .move(SIMD2(9, 20)),
            .line(SIMD2(15, 20)),
        ]

    private static let undo2:
        [SymbolGeometry.Command] = [
            .move(SIMD2(9, 14)),
            .line(SIMD2(4, 9)),
            .line(SIMD2(9, 4)),
            .move(SIMD2(4, 9)),
            .line(SIMD2(14.5, 9)),
            .cubicCurve(control1: SIMD2(17.5376, 9), control2: SIMD2(20, 11.4624), end: SIMD2(20, 14.5)),
            .cubicCurve(control1: SIMD2(20, 17.5376), control2: SIMD2(17.5376, 20), end: SIMD2(14.5, 20)),
            .line(SIMD2(11, 20)),
        ]

    private static let wandSparkles:
        [SymbolGeometry.Command] = [
            .move(SIMD2(21.64, 3.64)),
            .line(SIMD2(20.36, 2.36)),
            .cubicCurve(control1: SIMD2(20.1327, 2.1304), control2: SIMD2(19.8231, 2.0012), end: SIMD2(19.5, 2.0012)),
            .cubicCurve(control1: SIMD2(19.1769, 2.0012), control2: SIMD2(18.8673, 2.1304), end: SIMD2(18.64, 2.36)),
            .line(SIMD2(2.36, 18.64)),
            .cubicCurve(control1: SIMD2(2.1304, 18.8673), control2: SIMD2(2.0012, 19.1769), end: SIMD2(2.0012, 19.5)),
            .cubicCurve(control1: SIMD2(2.0012, 19.8231), control2: SIMD2(2.1304, 20.1327), end: SIMD2(2.36, 20.36)),
            .line(SIMD2(3.64, 21.64)),
            .cubicCurve(control1: SIMD2(3.8659, 21.8721), control2: SIMD2(4.1761, 22.0031), end: SIMD2(4.5, 22.0031)),
            .cubicCurve(control1: SIMD2(4.8239, 22.0031), control2: SIMD2(5.1341, 21.8721), end: SIMD2(5.36, 21.64)),
            .line(SIMD2(21.64, 5.36)),
            .cubicCurve(control1: SIMD2(21.8721, 5.1341), control2: SIMD2(22.0031, 4.8239), end: SIMD2(22.0031, 4.5)),
            .cubicCurve(control1: SIMD2(22.0031, 4.1761), control2: SIMD2(21.8721, 3.8659), end: SIMD2(21.64, 3.64)),
            .move(SIMD2(14, 7)),
            .line(SIMD2(17, 10)),
            .move(SIMD2(5, 6)),
            .line(SIMD2(5, 10)),
            .move(SIMD2(19, 14)),
            .line(SIMD2(19, 18)),
            .move(SIMD2(10, 2)),
            .line(SIMD2(10, 4)),
            .move(SIMD2(7, 8)),
            .line(SIMD2(3, 8)),
            .move(SIMD2(21, 16)),
            .line(SIMD2(17, 16)),
            .move(SIMD2(11, 3)),
            .line(SIMD2(9, 3)),
        ]

    private static let waypoints:
        [SymbolGeometry.Command] = [
            .move(SIMD2(10.586, 5.414)),
            .line(SIMD2(5.414, 10.586)),
            .move(SIMD2(18.586, 13.414)),
            .line(SIMD2(13.414, 18.586)),
            .move(SIMD2(6, 12)),
            .line(SIMD2(18, 12)),
            .circle(center: SIMD2(12, 20), radius: 2),
            .circle(center: SIMD2(12, 4), radius: 2),
            .circle(center: SIMD2(20, 12), radius: 2),
            .circle(center: SIMD2(4, 12), radius: 2),
        ]

    private static let x:
        [SymbolGeometry.Command] = [
            .move(SIMD2(18, 6)),
            .line(SIMD2(6, 18)),
            .move(SIMD2(6, 6)),
            .line(SIMD2(18, 18)),
        ]

    private static let zoomIn:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(11, 11), radius: 8),
            .move(SIMD2(21, 21)),
            .line(SIMD2(16.65, 16.65)),
            .move(SIMD2(11, 8)),
            .line(SIMD2(11, 14)),
            .move(SIMD2(8, 11)),
            .line(SIMD2(14, 11)),
        ]

    private static let zoomOut:
        [SymbolGeometry.Command] = [
            .circle(center: SIMD2(11, 11), radius: 8),
            .move(SIMD2(21, 21)),
            .line(SIMD2(16.65, 16.65)),
            .move(SIMD2(8, 11)),
            .line(SIMD2(14, 11)),
        ]

}
