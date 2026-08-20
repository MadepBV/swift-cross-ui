#!/usr/bin/env python3
"""Generate SwiftCrossUI's bundled symbol geometry from Lucide icons.

SwiftCrossUI's ``Image(systemName:)`` accepts Apple SF Symbol names so that
SwiftUI source compiles unchanged on Linux and Windows. SF Symbols are an
Apple-only font, so on other platforms the names are resolved against the
Lucide icon set (https://lucide.dev, ISC licensed).

This script reads Lucide's icon definitions and emits two generated Swift
files:

* ``Sources/SwiftCrossUI/Values/Symbols/LucideIconGeometry.swift``
  -- the vector geometry of every Lucide icon referenced by the mapping,
  expressed as ``SymbolGeometry`` command lists in Lucide's native 24x24
  coordinate space.
* ``Sources/SwiftCrossUI/Values/Symbols/SFSymbolLucideMapping.swift``
  -- the SF Symbol name to Lucide icon name mapping.

Usage:

    Scripts/generate-symbol-geometry.py [--lucide-dir PATH] [--check]

``--lucide-dir`` may point at either of:

* a ``lucide-react`` package's ``dist/esm/icons`` directory (``*.mjs`` files
  containing an ``__iconNode`` array), or
* an upstream ``lucide-icons/lucide`` checkout's ``icons`` directory
  (``*.svg`` files).

If it is omitted the script searches ``LUCIDE_ICONS_DIR`` and then a handful
of well-known locations. ``--check`` reports which mapped icons are missing
without writing any files.
"""

from __future__ import annotations

import argparse
import math
import os
import re
import sys
import xml.etree.ElementTree as ElementTree
from pathlib import Path
from typing import Iterable

# --------------------------------------------------------------------------
# Mapping
# --------------------------------------------------------------------------

# Each entry maps an SF Symbol name to a Lucide icon name and an optional note.
#
# A note means the pairing is *not* an exact equivalent. It is copied into the
# generated Swift as documentation so the compromise stays visible to anybody
# reading the table. Where no honest Lucide equivalent exists at all, the
# mapping deliberately picks a visibly generic icon rather than a confidently
# wrong one.
#
# Lucide is a stroke-only icon set: it has no filled counterparts. A name
# ending in `.fill` therefore resolves to the same outline icon as its
# unfilled sibling, and is drawn filled only where the generator could derive
# a filled variant from that icon's geometry (see FILL_RECIPES). Entries that
# could not be derived keep the FILL note; the rest get DERIVED_FILL.
FILL = "Lucide has no filled variants; the outline icon is used."
DERIVED_FILL = (
    "Lucide has no filled variants, so the solid glyph is derived from the "
    "outline geometry by the generator."
)

SYMBOL_MAP: dict[str, tuple[str, str | None]] = {
    # -- 27..10 occurrences ------------------------------------------------
    "checkmark.circle.fill": ("circle-check", FILL),
    "exclamationmark.triangle.fill": ("triangle-alert", FILL),
    "checkmark": ("check", None),
    "xmark": ("x", None),
    "plus": ("plus", None),
    "trash": ("trash-2", None),
    "exclamationmark.circle.fill": ("circle-alert", FILL),
    "lock.fill": ("lock", FILL),
    "arrow.uturn.backward": ("undo-2", None),
    "scope": ("crosshair", None),
    "ruler": ("ruler", None),
    "ellipsis.circle": ("circle-ellipsis", None),
    "rectangle.badge.plus": (
        "square-plus",
        "Lucide has no badged rectangle; a plus inside a square is used.",
    ),
    "point.3.connected.trianglepath.dotted": ("spline", None),
    # -- 9..5 occurrences --------------------------------------------------
    "arrow.counterclockwise": ("rotate-ccw", None),
    "square.stack.3d.up": ("layers-3", None),
    "slider.horizontal.3": ("sliders-horizontal", None),
    "paintpalette": ("palette", None),
    "line.diagonal": ("slash", None),
    "pencil": ("pencil", None),
    "exclamationmark.circle": ("circle-alert", None),
    "cube.transparent": (
        "box",
        "Lucide has no see-through cube; the solid outline box is used.",
    ),
    "arrow.triangle.2.circlepath": ("refresh-cw", None),
    "exclamationmark.triangle": ("triangle-alert", None),
    "doc.text": ("file-text", None),
    "building.2": ("building-2", None),
    "textformat": ("type", None),
    "square.on.square.intersection.dashed": ("combine", None),
    "square.and.arrow.up": ("share", None),
    "square.3.stack.3d": ("layers-3", None),
    "rectangle.grid.2x2": ("grid-2x2", None),
    "rectangle.badge.minus": (
        "square-minus",
        "Lucide has no badged rectangle; a minus inside a square is used.",
    ),
    "pencil.and.outline": ("square-pen", None),
    "info.circle": ("info", None),
    "eye": ("eye", None),
    "dot.scope": ("locate", None),
    "doc.badge.gearshape": ("file-cog", None),
    "cube": ("box", None),
    "checkmark.circle": ("circle-check", None),
    "arrow.turn.down.right": ("corner-down-right", None),
    # -- 4 occurrences -----------------------------------------------------
    "viewfinder": ("scan", None),
    "tablecells": ("table-2", None),
    "square.3.layers.3d": ("layers-3", None),
    "scribble.variable": (
        "pen-tool",
        "Lucide has no freehand scribble; the pen tool is used.",
    ),
    "plus.square.on.square": ("copy-plus", None),
    "gearshape": ("settings", None),
    "doc.on.doc": ("files", None),
    "doc.badge.ellipsis": (
        "file",
        "Lucide has no badged document; a plain document is used so the icon "
        "reads as generic rather than as the wrong action.",
    ),
    "chevron.up.chevron.down": ("chevrons-up-down", None),
    "arrow.uturn.forward": ("redo-2", None),
    # -- 3 occurrences -----------------------------------------------------
    "square.stack.3d.up.fill": ("layers-3", FILL),
    "square.dashed": ("square-dashed", None),
    "rotate.right": ("rotate-cw", None),
    "rectangle.and.hand.point.up.left": ("square-dashed-mouse-pointer", None),
    "point.topleft.down.to.point.bottomright.curvepath": ("spline", None),
    "photo": ("image", None),
    "link": ("link", None),
    "hand.draw.fill": ("hand", FILL),
    "chevron.right": ("chevron-right", None),
    "checkmark.seal.fill": ("badge-check", FILL),
    "books.vertical": ("library", None),
    "arrowtriangle.down.fill": (
        "triangle-down",
        "Lucide has no downward triangle; its upward one is turned half a "
        "turn about the canvas centre.",
    ),
    "arrow.up.left.and.arrow.down.right": ("move-diagonal", None),
    "arrow.right": ("arrow-right", None),
    # -- 2 occurrences -----------------------------------------------------
    "wand.and.stars": ("wand-sparkles", None),
    "square.grid.3x3.square": ("grid-3x3", None),
    "square.grid.3x3": ("grid-3x3", None),
    "square.dashed.inset.filled": ("square-dashed", FILL),
    "square.and.arrow.down": ("download", None),
    "scissors": ("scissors", None),
    "rectangle.portrait.and.arrow.forward": ("square-arrow-right", None),
    "rectangle.dashed": (
        "square-dashed",
        "Lucide's only dashed outline is square rather than oblong.",
    ),
    "rectangle.bottomthird.inset.filled": ("panel-bottom", None),
    "rectangle.and.pencil.and.ellipsis": ("square-pen", None),
    "questionmark.circle": ("circle-help", None),
    "point.3.filled.connected.trianglepath.dotted": ("waypoints", None),
    "move.3d": ("move-3d", None),
    "minus": ("minus", None),
    "list.bullet.rectangle": ("list", None),
    "link.badge.plus": (
        "link",
        "Lucide has no badged link; the plain link is used.",
    ),
    "doc.badge.plus": ("file-plus", None),
    "doc": ("file", None),
    "cursorarrow": ("mouse-pointer-2", None),
    "clock.arrow.circlepath": ("history", None),
    "circle": ("circle", None),
    "character.cursor.ibeam": ("text-cursor", None),
    "camera.viewfinder": ("scan-eye", None),
    "arrow.uturn.backward.circle": (
        "undo-2",
        "Lucide has no circled u-turn arrow; the uncircled undo arrow is used.",
    ),
    "arrow.up.and.down.and.arrow.left.and.right": ("move", None),
    "arrow.up.and.down": ("arrow-up-down", None),
    "arrow.left.arrow.right": ("arrow-left-right", None),
    "arrow.left.and.right.square": (
        "arrow-left-right",
        "Lucide has no enclosing square for this arrow pair.",
    ),
    "arrow.left.and.right.righttriangle.left.righttriangle.right": (
        "flip-horizontal-2",
        None,
    ),
    "arrow.left.and.right": ("arrow-left-right", None),
    "arrow.down.right.and.arrow.up.left": ("minimize-2", None),
    "arrow.down.doc": ("file-down", None),
    "arrow.clockwise": ("refresh-cw", None),
    # -- 1 occurrence ------------------------------------------------------
    "xmark.octagon.fill": ("octagon-x", FILL),
    "xmark.circle.fill": ("circle-x", FILL),
    "xmark.circle": ("circle-x", None),
    "tray": ("inbox", None),
    "text.bubble": ("message-square-text", None),
    "text.below.photo": (
        "captions",
        "Lucide has no photo-with-caption icon; a captioned frame is used.",
    ),
    "star": ("star", None),
    "square.stack.3d.up.slash": (
        "layers-3",
        "Lucide has no struck-through layers icon, so the 'disabled' slash is "
        "lost.",
    ),
    "square.split.diagonal.2x2": (
        "grid-2x2",
        "Lucide has no diagonally split square; a quartered square is used.",
    ),
    "square.split.1x2": ("square-split-vertical", None),
    "square.on.square.dashed": ("shapes", None),
    "square.grid.3x1.below.line.grid.1x2": ("rows-3", None),
    "smallcircle.filled.circle": ("circle-dot", None),
    "sidebar.trailing": ("panel-right", None),
    "sidebar.right": ("panel-right", None),
    "seal": ("badge", None),
    "rotate.left": ("rotate-ccw", None),
    "rectangle.portrait": ("rectangle-vertical", None),
    "rectangle.on.rectangle.angled": ("panels-top-left", None),
    "rectangle.inset.filled": (
        "square-dashed",
        "Lucide has no inset-fill rectangle; the dashed zone outline is used.",
    ),
    "point.topleft.down.curvedto.point.bottomright.up": ("spline", None),
    "plus.magnifyingglass": ("zoom-in", None),
    "plus.circle": ("circle-plus", None),
    "photo.on.rectangle.angled": ("images", None),
    "photo.badge.plus": ("image-plus", None),
    "photo.badge.exclamationmark": (
        "image-off",
        "Lucide has no image-error icon; the unavailable-image icon is used.",
    ),
    "pencil.and.ruler.fill": ("pencil-ruler", FILL),
    "pencil.and.ruler": ("pencil-ruler", None),
    "paintpalette.fill": ("palette", FILL),
    "paintbrush.pointed": ("brush", None),
    "paintbrush": ("paintbrush", None),
    "nosign": ("ban", None),
    "minus.magnifyingglass": ("zoom-out", None),
    "lock.shield.fill": (
        "shield",
        "Lucide has no lock-in-shield icon; a plain shield is used.",
    ),
    "lock.open.fill": ("lock-open", FILL),
    "list.bullet.rectangle.portrait": ("list", None),
    "link.circle.fill": (
        "link",
        "Lucide has no circled link; the plain link is used.",
    ),
    "line.3.horizontal.decrease.circle": ("list-filter", None),
    "keyboard": ("keyboard", None),
    "hammer": ("hammer", None),
    "grid": ("grid-2x2", None),
    "function": ("square-function", None),
    "folder": ("folder", None),
    "exclamationmark.arrow.triangle.2.circlepath": (
        "refresh-cw",
        "Lucide has no warning-badged refresh; the plain refresh is used.",
    ),
    "doc.fill": ("file", FILL),
    "delete.left": ("delete", None),
    "cursorarrow.rays": ("mouse-pointer-click", None),
    "cursorarrow.click.2": ("mouse-pointer-click", None),
    "crop": ("crop", None),
    "circle.grid.cross": (
        "grid-3x3",
        "Lucide has no cross-arranged dot grid; a full 3x3 grid is used.",
    ),
    "circle.grid.3x3": ("grid-3x3", None),
    "circle.dashed": ("circle-dashed", None),
    "chevron.up": ("chevron-up", None),
    "chevron.forward": ("chevron-right", None),
    "chevron.down": ("chevron-down", None),
    "chevron.backward": ("chevron-left", None),
    "checkmark.shield": ("shield-check", None),
    "checkmark.seal": ("badge-check", None),
    "character.bubble": ("message-square", None),
    "building.2.fill": ("building-2", FILL),
    "building.2.crop.circle": (
        "building-2",
        "Lucide has no circle-cropped building; the plain building is used.",
    ),
    "arrow.up.right.and.arrow.down.left": ("move-diagonal-2", None),
    "arrow.up.left": ("arrow-up-left", None),
    "arrow.trianglehead.2.clockwise.rotate.90": ("rotate-cw", None),
    "arrow.triangle.merge": ("git-merge", None),
    "arrow.triangle.branch": ("git-branch", None),
    "arrow.triangle.2.circlepath.doc.on.clipboard": (
        "clipboard-copy",
        "Lucide has no refresh-badged clipboard; the plain copy-to-clipboard "
        "icon is used.",
    ),
    "arrow.down.to.line": ("arrow-down-to-line", None),
    "arrow.clockwise.circle.fill": (
        "refresh-cw",
        "Lucide has no circled refresh arrow; the plain refresh is used. "
        + FILL,
    ),
    "angle": (
        "triangle-right",
        "Lucide has no angle glyph; a right triangle is the closest shape.",
    ),
    # -- Extra names commonly referenced by desktop application catalogs --
    # These do not appear in the current call-site census but the catalog
    # pairs them with a Lucide icon, so covering them costs nothing and stops
    # near-miss names from falling through to the placeholder.
    "arrow.left.and.right.righttriangle.left.righttriangle.right.fill": (
        "flip-horizontal-2",
        FILL,
    ),
    "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left": (
        "expand",
        None,
    ),
    "circle.fill": ("circle", FILL),
    "cursorarrow.click": ("mouse-pointer-click", None),
    "eye.slash": ("eye-off", None),
    "i.square": (
        "square",
        "Lucide has no lettered square; a plain square is used. An "
        "application needing the letter should supply its own glyph.",
    ),
    "lock.open": ("lock-open", None),
    "plus.square": ("square-plus", None),
    "printer": ("printer", None),
    "printer.fill": ("printer", FILL),
    "rectangle.split.2x1": ("square-split-horizontal", None),
    "rotate.right.fill": ("rotate-cw", FILL),
    "ruler.fill": ("ruler", FILL),
    "smallcircle.filled.circle.fill": ("circle-dot", FILL),
    "tablecells.fill": ("table-2", FILL),
}

# The icon drawn for a name the mapping doesn't know. A visibly generic mark
# is much safer than a confidently wrong one: it tells the reader "there is a
# symbol here and we don't have it" rather than lying about the action.
PLACEHOLDER_ICON = "square-dashed"

# Lucide's drawing conventions, shared by every icon in the set.
CANVAS_SIZE = 24.0
STROKE_WIDTH = 2.0


def _rotate_half_turn(point: tuple[float, float]) -> tuple[float, float]:
    """Turn a point half a turn about the centre of the canvas."""
    return (CANVAS_SIZE - point[0], CANVAS_SIZE - point[1])


# Icons built by rigidly transforming another Lucide icon. Lucide draws its
# triangle pointing up and has no downward one, and a half turn about the
# canvas centre is an exact, reversible operation on the same artwork rather
# than a redrawing of it.
DERIVED_ICONS: dict[str, tuple[str, str]] = {
    "triangle-down": ("triangle", "half turn about the canvas centre"),
}

DERIVED_TRANSFORMS = {
    "triangle-down": _rotate_half_turn,
}

LUCIDE_LICENSE = """\
ISC License

Copyright (c) for portions of Lucide are held by Cole Bemis 2013-2022 as part
of Feather (MIT). All other copyright (c) for Lucide are held by Lucide
Contributors 2022.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.\
"""

# --------------------------------------------------------------------------
# Locating the icon sources
# --------------------------------------------------------------------------

CANDIDATE_DIRS = [
    "node_modules/lucide-react/dist/esm/icons",
    "node_modules/lucide-react/dist/esm/icons",
    "../lucide/icons",
]


def find_lucide_dir(explicit: str | None, repo_root: Path) -> Path:
    """Return the directory holding Lucide's icon definitions."""
    candidates: list[Path] = []
    if explicit:
        candidates.append(Path(explicit))
    if os.environ.get("LUCIDE_ICONS_DIR"):
        candidates.append(Path(os.environ["LUCIDE_ICONS_DIR"]))
    candidates.extend((repo_root / c).resolve() for c in CANDIDATE_DIRS)

    for candidate in candidates:
        if candidate.is_dir() and (
            any(candidate.glob("*.mjs")) or any(candidate.glob("*.svg"))
        ):
            return candidate

    raise SystemExit(
        "Could not find Lucide's icons. Pass --lucide-dir, set "
        "LUCIDE_ICONS_DIR, or check out lucide-icons/lucide next to this "
        "repository.\nLooked in:\n  "
        + "\n  ".join(str(c) for c in candidates)
    )


# --------------------------------------------------------------------------
# Reading icon definitions
# --------------------------------------------------------------------------

Element = tuple[str, dict[str, str]]

# Matches `["path", { d: "...", key: "..." }]` entries inside `__iconNode`.
_ELEMENT_RE = re.compile(
    r'\[\s*"(?P<tag>[a-zA-Z]+)"\s*,\s*\{(?P<attrs>[^{}]*)\}\s*\]',
    re.DOTALL,
)
_ATTR_RE = re.compile(r'(?P<name>[a-zA-Z0-9_-]+)\s*:\s*"(?P<value>[^"]*)"')


# Lucide keeps deprecated names alive as modules that just re-export another
# icon, e.g. `history.mjs` re-exports `rotate-ccw-clock.mjs`.
_ALIAS_RE = re.compile(r"export\s*\{\s*default\s*\}\s*from\s*'\./([\w-]+)\.mjs'")


def read_icon(
    directory: Path, name: str, depth: int = 0
) -> list[Element] | None:
    """Read one Lucide icon's elements, or `None` if it isn't present."""
    if depth > 8:
        raise SystemExit(f"alias loop while resolving Lucide icon {name!r}")

    mjs = directory / f"{name}.mjs"
    if mjs.is_file():
        source = mjs.read_text(encoding="utf-8")
        alias = _ALIAS_RE.search(source)
        if alias:
            return read_icon(directory, alias.group(1), depth + 1)
        return _parse_icon_node(source)

    svg = directory / f"{name}.svg"
    if svg.is_file():
        return _parse_svg(svg.read_text(encoding="utf-8"))

    return None


def _parse_icon_node(source: str) -> list[Element]:
    """Parse the `__iconNode` array out of a compiled lucide-react module."""
    start = source.find("__iconNode")
    if start < 0:
        return []
    body = source[start:]
    elements: list[Element] = []
    for match in _ELEMENT_RE.finditer(body):
        attributes = {
            attr.group("name"): attr.group("value")
            for attr in _ATTR_RE.finditer(match.group("attrs"))
        }
        attributes.pop("key", None)
        elements.append((match.group("tag"), attributes))
    return elements


def _parse_svg(source: str) -> list[Element]:
    """Parse the drawable children out of an upstream Lucide SVG file."""
    root = ElementTree.fromstring(source)
    elements: list[Element] = []
    for child in root.iter():
        tag = child.tag.rsplit("}", 1)[-1]
        if tag in {"svg", "g", "title", "desc"}:
            continue
        elements.append((tag, dict(child.attrib)))
    return elements


# --------------------------------------------------------------------------
# Converting SVG geometry into SymbolGeometry commands
# --------------------------------------------------------------------------

Point = tuple[float, float]

# A rigid point map applied to an icon's geometry as it is emitted. Only
# distance-preserving maps are allowed, because circles stay circles and
# stroke offsets stay symmetric only under those.
Transform = "callable"


class CommandBuilder:
    """Accumulates ``SymbolGeometry.Command`` values for one icon."""

    def __init__(self, transform=None) -> None:
        self.commands: list[str] = []
        self.current: Point = (0.0, 0.0)
        self.subpath_start: Point = (0.0, 0.0)
        self.last_control: Point | None = None
        self.last_command: str = ""
        # Applied on the way out only: `current` and `subpath_start` stay in
        # the source's own coordinates so that relative path data still works.
        self.transform = transform

    def place(self, point: Point) -> Point:
        """Map a source-space point into output space."""
        return self.transform(point) if self.transform else point

    def move(self, point: Point) -> None:
        self.commands.append(f".move({_point(self.place(point))})")
        self.current = point
        self.subpath_start = point
        self.last_control = None

    def line(self, point: Point) -> None:
        self.commands.append(f".line({_point(self.place(point))})")
        self.current = point
        self.last_control = None

    def quad(self, control: Point, end: Point) -> None:
        self.commands.append(
            f".quadCurve(control: {_point(self.place(control))}, "
            f"end: {_point(self.place(end))})"
        )
        self.current = end
        self.last_control = control

    def cubic(self, control1: Point, control2: Point, end: Point) -> None:
        self.commands.append(
            f".cubicCurve(control1: {_point(self.place(control1))}, "
            f"control2: {_point(self.place(control2))}, "
            f"end: {_point(self.place(end))})"
        )
        self.current = end
        self.last_control = control2

    def circle(self, center: Point, radius: float) -> None:
        self.commands.append(
            f".circle(center: {_point(self.place(center))}, "
            f"radius: {_number(radius)})"
        )
        self.last_control = None

    def close(self) -> None:
        # `SwiftCrossUI.Path` has no explicit close action, so a closed
        # subpath is closed with an explicit line back to its start. With
        # Lucide's round caps and joins the difference is invisible.
        if self.current != self.subpath_start:
            self.line(self.subpath_start)
        self.current = self.subpath_start
        self.last_control = None


def _number(value: float) -> str:
    """Format a coordinate as a compact Swift `Double` literal."""
    rounded = round(value, 4)
    if rounded == 0.0:
        rounded = 0.0  # Normalise -0.0.
    if rounded == int(rounded):
        return f"{int(rounded)}"
    return repr(rounded)


def _point(point: Point) -> str:
    return f"SIMD2({_number(point[0])}, {_number(point[1])})"


_TOKEN_RE = re.compile(r"[-+]?(?:\d*\.\d+(?:[eE][-+]?\d+)?|\d+(?:[eE][-+]?\d+)?)|[A-Za-z]")


def _tokenize_path(data: str) -> list[str]:
    return _TOKEN_RE.findall(data)


def append_path_data(builder: CommandBuilder, data: str) -> None:
    """Append an SVG `d` attribute's geometry to `builder`."""
    tokens = _tokenize_path(data)
    index = 0
    command = ""

    def take(count: int) -> list[float]:
        nonlocal index
        values = [float(token) for token in tokens[index:index + count]]
        index += count
        return values

    while index < len(tokens):
        token = tokens[index]
        if token.isalpha():
            command = token
            index += 1
            if command in "Zz":
                builder.close()
                continue
        elif command == "":
            raise ValueError(f"path data starts with a number: {data!r}")
        elif command == "M":
            command = "L"
        elif command == "m":
            command = "l"

        relative = command.islower()
        origin = builder.current if relative else (0.0, 0.0)
        upper = command.upper()

        if upper == "M":
            x, y = take(2)
            builder.move((origin[0] + x, origin[1] + y))
        elif upper == "L":
            x, y = take(2)
            builder.line((origin[0] + x, origin[1] + y))
        elif upper == "H":
            (x,) = take(1)
            builder.line((origin[0] + x, builder.current[1]))
        elif upper == "V":
            (y,) = take(1)
            builder.line((builder.current[0], origin[1] + y))
        elif upper == "C":
            x1, y1, x2, y2, x, y = take(6)
            builder.cubic(
                (origin[0] + x1, origin[1] + y1),
                (origin[0] + x2, origin[1] + y2),
                (origin[0] + x, origin[1] + y),
            )
        elif upper == "S":
            x2, y2, x, y = take(4)
            control1 = _reflected_control(builder, {"C", "S"})
            builder.cubic(
                control1,
                (origin[0] + x2, origin[1] + y2),
                (origin[0] + x, origin[1] + y),
            )
        elif upper == "Q":
            x1, y1, x, y = take(4)
            builder.quad(
                (origin[0] + x1, origin[1] + y1),
                (origin[0] + x, origin[1] + y),
            )
        elif upper == "T":
            x, y = take(2)
            control = _reflected_control(builder, {"Q", "T"})
            builder.quad(control, (origin[0] + x, origin[1] + y))
        elif upper == "A":
            rx, ry, rotation, large_arc, sweep, x, y = take(7)
            _append_arc(
                builder,
                rx,
                ry,
                rotation,
                large_arc != 0.0,
                sweep != 0.0,
                (origin[0] + x, origin[1] + y),
            )
        else:
            raise ValueError(f"unsupported path command {command!r}")

        builder.last_command = upper


def _reflected_control(builder: CommandBuilder, curves: set[str]) -> Point:
    """The control point implied by a smooth (`S`/`T`) curve command."""
    if builder.last_control is None or builder.last_command not in curves:
        return builder.current
    return (
        2.0 * builder.current[0] - builder.last_control[0],
        2.0 * builder.current[1] - builder.last_control[1],
    )


def _append_arc(
    builder: CommandBuilder,
    rx: float,
    ry: float,
    rotation_degrees: float,
    large_arc: bool,
    sweep: bool,
    end: Point,
) -> None:
    """Append an SVG elliptical arc, approximated by cubic Béziers.

    Backends differ in how they interpret arc parameters, so arcs are baked
    into cubics at generation time to keep every backend pixel-identical.
    """
    start = builder.current
    if start == end:
        return
    if rx == 0.0 or ry == 0.0:
        builder.line(end)
        return

    rx, ry = abs(rx), abs(ry)
    phi = math.radians(rotation_degrees)
    cos_phi, sin_phi = math.cos(phi), math.sin(phi)

    dx = (start[0] - end[0]) / 2.0
    dy = (start[1] - end[1]) / 2.0
    x1 = cos_phi * dx + sin_phi * dy
    y1 = -sin_phi * dx + cos_phi * dy

    # Scale the radii up if they're too small to span the two endpoints.
    lam = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
    if lam > 1.0:
        scale = math.sqrt(lam)
        rx *= scale
        ry *= scale

    numerator = max(
        rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1, 0.0
    )
    denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
    factor = math.sqrt(numerator / denominator) if denominator else 0.0
    if large_arc == sweep:
        factor = -factor

    cx1 = factor * rx * y1 / ry
    cy1 = -factor * ry * x1 / rx
    cx = cos_phi * cx1 - sin_phi * cy1 + (start[0] + end[0]) / 2.0
    cy = sin_phi * cx1 + cos_phi * cy1 + (start[1] + end[1]) / 2.0

    def angle_of(x: float, y: float) -> float:
        return math.atan2((y - cy1) / ry, (x - cx1) / rx)

    theta1 = angle_of(x1, y1)
    theta2 = angle_of(-x1, -y1)
    delta = theta2 - theta1
    if not sweep and delta > 0.0:
        delta -= 2.0 * math.pi
    elif sweep and delta < 0.0:
        delta += 2.0 * math.pi

    segments = max(1, int(math.ceil(abs(delta) / (math.pi / 2.0))))
    step = delta / segments
    alpha = (4.0 / 3.0) * math.tan(step / 4.0)

    theta = theta1
    for _ in range(segments):
        next_theta = theta + step
        cos1, sin1 = math.cos(theta), math.sin(theta)
        cos2, sin2 = math.cos(next_theta), math.sin(next_theta)

        def to_user(px: float, py: float) -> Point:
            return (
                cos_phi * rx * px - sin_phi * ry * py + cx,
                sin_phi * rx * px + cos_phi * ry * py + cy,
            )

        point1 = to_user(cos1, sin1)
        point2 = to_user(cos2, sin2)
        control1 = to_user(cos1 - alpha * sin1, sin1 + alpha * cos1)
        control2 = to_user(cos2 + alpha * sin2, sin2 - alpha * cos2)
        builder.cubic(control1, control2, point2)
        _ = point1
        theta = next_theta


# Magic constant for approximating a quarter circle with a cubic Bézier.
KAPPA = 0.5522847498307936


def append_element(builder: CommandBuilder, tag: str, attrs: dict[str, str]) -> None:
    """Append one SVG element's geometry to `builder`."""

    def number(name: str, default: float = 0.0) -> float:
        value = attrs.get(name)
        return float(value) if value is not None else default

    if tag == "path":
        # Every SVG element starts a fresh coordinate context, so a leading
        # relative `m` in this element's `d` is really absolute.
        builder.current = (0.0, 0.0)
        builder.subpath_start = (0.0, 0.0)
        builder.last_control = None
        builder.last_command = ""
        append_path_data(builder, attrs["d"])
    elif tag == "line":
        builder.move((number("x1"), number("y1")))
        builder.line((number("x2"), number("y2")))
    elif tag == "circle":
        builder.circle((number("cx"), number("cy")), number("r"))
    elif tag == "ellipse":
        _append_ellipse(
            builder,
            (number("cx"), number("cy")),
            number("rx"),
            number("ry"),
        )
    elif tag in {"polyline", "polygon"}:
        points = [float(value) for value in re.findall(r"[-+]?[\d.]+", attrs["points"])]
        pairs = list(zip(points[0::2], points[1::2]))
        if not pairs:
            return
        builder.move(pairs[0])
        for pair in pairs[1:]:
            builder.line(pair)
        if tag == "polygon":
            builder.close()
    elif tag == "rect":
        _append_rect(
            builder,
            number("x"),
            number("y"),
            number("width"),
            number("height"),
            number("rx", number("ry")),
            number("ry", number("rx")),
        )
    else:
        raise ValueError(f"unsupported SVG element {tag!r}")


def _append_ellipse(builder: CommandBuilder, center: Point, rx: float, ry: float) -> None:
    if rx == ry:
        builder.circle(center, rx)
        return
    cx, cy = center
    builder.move((cx + rx, cy))
    builder.cubic(
        (cx + rx, cy + ry * KAPPA), (cx + rx * KAPPA, cy + ry), (cx, cy + ry)
    )
    builder.cubic(
        (cx - rx * KAPPA, cy + ry), (cx - rx, cy + ry * KAPPA), (cx - rx, cy)
    )
    builder.cubic(
        (cx - rx, cy - ry * KAPPA), (cx - rx * KAPPA, cy - ry), (cx, cy - ry)
    )
    builder.cubic(
        (cx + rx * KAPPA, cy - ry), (cx + rx, cy - ry * KAPPA), (cx + rx, cy)
    )


def _append_rect(
    builder: CommandBuilder,
    x: float,
    y: float,
    width: float,
    height: float,
    rx: float,
    ry: float,
) -> None:
    rx = min(rx, width / 2.0)
    ry = min(ry, height / 2.0)
    if rx <= 0.0 or ry <= 0.0:
        builder.move((x, y))
        builder.line((x + width, y))
        builder.line((x + width, y + height))
        builder.line((x, y + height))
        builder.close()
        return

    right, bottom = x + width, y + height
    builder.move((x + rx, y))
    builder.line((right - rx, y))
    builder.cubic(
        (right - rx + rx * KAPPA, y), (right, y + ry - ry * KAPPA), (right, y + ry)
    )
    builder.line((right, bottom - ry))
    builder.cubic(
        (right, bottom - ry + ry * KAPPA),
        (right - rx + rx * KAPPA, bottom),
        (right - rx, bottom),
    )
    builder.line((x + rx, bottom))
    builder.cubic(
        (x + rx - rx * KAPPA, bottom), (x, bottom - ry + ry * KAPPA), (x, bottom - ry)
    )
    builder.line((x, y + ry))
    builder.cubic((x, y + ry - ry * KAPPA), (x + rx - rx * KAPPA, y), (x + rx, y))


def build_commands(elements: Iterable[Element], transform=None) -> list[str]:
    builder = CommandBuilder(transform=transform)
    for tag, attrs in elements:
        append_element(builder, tag, attrs)
    return builder.commands


# --------------------------------------------------------------------------
# Deriving filled variants
# --------------------------------------------------------------------------
#
# Lucide draws outlines only, so a filled glyph has to be constructed. SF
# Symbols builds its own `.fill` variants the same way this does: a solid
# enclosure with the inner glyph punched straight through it, so that whatever
# is behind the symbol shows through the punched-out part.
#
# The construction is entirely geometric, and relies on one property of the
# non-zero winding rule: subpaths wound the same way union for free, no matter
# how they overlap, and a subpath wound the other way subtracts. So a filled
# variant is a list of closed contours, each carrying a sign:
#
#   +1  solid: the enclosure, and any stroke that is part of the solid body.
#   -1  punched out: the inner glyph, converted from a stroke to its outline.
#
# The one case the winding rule cannot handle by itself is two punched-out
# contours that overlap each other (the two bars of an X cross in the middle):
# -1 + -1 is still non-zero, so the crossing would fill back in. Those are
# fixed by inclusion-exclusion, adding the overlap back as a +1 contour.

HALF_STROKE = STROKE_WIDTH / 2.0

# How far flattened geometry may stray from the true curve, in canvas units.
# A symbol is drawn from a 24-unit canvas at 16-32pt, so 0.008 units is well
# under a hundredth of a pixel and cannot be seen at any realistic size.
FLATTEN_TOLERANCE = 0.008
# How far dropping a near-collinear point may move an edge, in canvas units.
# Deliberately tighter than the flattening tolerance so that simplification
# only ever removes points that flattening did not need to add.
SIMPLIFY_TOLERANCE = 0.002
# How far past a corner the inward side of an offset may be cut back, as a
# multiple of the offset distance. Anything sharper than this would need a
# bevel to stay tidy, and no bundled icon comes close, so it is refused rather
# than quietly drawn wrong.
INNER_JOIN_LIMIT = 6.0
EPSILON = 1e-9


class FillRecipe:
    """How to build one icon's filled variant from its outline elements.

    `body` and `knockout` are indices into the icon's element list, in the
    order Lucide declares them. Everything in `body` becomes solid; everything
    in `knockout` is punched out of it.
    """

    def __init__(
        self,
        body: Iterable[int],
        knockout: Iterable[int] = (),
        note: str | None = None,
    ) -> None:
        self.body = tuple(body)
        self.knockout = tuple(knockout)
        self.note = note


# Filled variants are only derived for icons whose construction is
# unambiguous: a closed enclosure, optionally with an inner glyph to punch out
# of it. Icons that are a loose collection of strokes (a printer, a palette, a
# ruler) have no "inside" to fill, so they keep their outline and the mapping
# says so. A wrong fill reads as a different symbol; a missing one only reads
# as a less emphatic version of the right symbol.
FILL_RECIPES: dict[str, FillRecipe] = {
    "badge-check": FillRecipe(body=(0,), knockout=(1,)),
    "circle": FillRecipe(body=(0,)),
    "circle-alert": FillRecipe(body=(0,), knockout=(1, 2)),
    "circle-check": FillRecipe(body=(0,), knockout=(1,)),
    "circle-dot": FillRecipe(body=(0,), knockout=(1,)),
    "circle-x": FillRecipe(body=(0,), knockout=(1, 2)),
    # The shackle is an open stroke rather than an enclosure, so it joins the
    # solid body as its own outline instead of being filled.
    "lock": FillRecipe(body=(0, 1)),
    "lock-open": FillRecipe(body=(0, 1)),
    # Lucide declares the octagon between the two bars of the cross.
    "octagon-x": FillRecipe(body=(1,), knockout=(0, 2)),
    "shield": FillRecipe(body=(0,)),
    "triangle-alert": FillRecipe(body=(0,), knockout=(1, 2)),
    "triangle-down": FillRecipe(body=(0,)),
}


class FlatSubpath:
    """One contour of an icon element, flattened into straight segments.

    Circles keep their exact centre and radius alongside the polygon, because
    a circular enclosure can be offset exactly rather than approximated.
    """

    def __init__(self, points: list[Point], closed: bool) -> None:
        self.points = points
        self.closed = closed
        self.circle: tuple[Point, float] | None = None

    @classmethod
    def from_circle(cls, center: Point, radius: float) -> "FlatSubpath":
        subpath = cls(_circle_polygon(center, radius, 1), True)
        subpath.circle = (center, radius)
        return subpath


class FlatteningBuilder(CommandBuilder):
    """A ``CommandBuilder`` that collects flattened contours, not Swift.

    Reusing ``CommandBuilder``'s bookkeeping means the SVG parser above feeds
    the outline and the fill derivation from exactly the same code path, so
    the two can never disagree about what an icon's geometry is.
    """

    def __init__(self, transform=None) -> None:
        super().__init__(transform=transform)
        self.subpaths: list[FlatSubpath] = []
        self._points: list[Point] = []
        self._closed = False

    def move(self, point: Point) -> None:
        self._flush()
        self.current = point
        self.subpath_start = point
        self.last_control = None
        self._points = [point]

    def line(self, point: Point) -> None:
        self._start_if_needed()
        self._points.append(point)
        self.current = point
        self.last_control = None

    def quad(self, control: Point, end: Point) -> None:
        self._start_if_needed()
        self._points.extend(
            _flatten_quad(self.current, control, end)[1:]
        )
        self.current = end
        self.last_control = control

    def cubic(self, control1: Point, control2: Point, end: Point) -> None:
        self._start_if_needed()
        self._points.extend(
            _flatten_cubic(self.current, control1, control2, end)[1:]
        )
        self.current = end
        self.last_control = control2

    def circle(self, center: Point, radius: float) -> None:
        self._flush()
        self.subpaths.append(
            FlatSubpath.from_circle(self.place(center), radius)
        )
        self.last_control = None

    def close(self) -> None:
        self._start_if_needed()
        if self._points and self._points[0] != self._points[-1]:
            self._points.append(self.subpath_start)
        self._closed = True
        self._flush()
        self.current = self.subpath_start
        self.last_control = None

    def finish(self) -> list[FlatSubpath]:
        """Flush the contour in progress and return everything collected."""
        self._flush()
        return self.subpaths

    def _start_if_needed(self) -> None:
        # Path data may carry on drawing after a `Z`, starting again from the
        # subpath's start point.
        if not self._points:
            self._points = [self.current]

    def _flush(self) -> None:
        points = _drop_repeated(
            [self.place(point) for point in self._points]
        )
        if len(points) >= 2:
            # Lucide closes most shapes by drawing back to where they
            # started rather than with an explicit `Z`, and the two mean the
            # same thing to a renderer.
            closed = self._closed or (
                len(points) > 2 and _distance(points[0], points[-1]) <= 1e-6
            )
            self.subpaths.append(FlatSubpath(points, closed))
        self._points = []
        self._closed = False


def flatten_element(
    tag: str, attrs: dict[str, str], transform=None
) -> list[FlatSubpath]:
    """Flatten one SVG element into contours."""
    builder = FlatteningBuilder(transform=transform)
    append_element(builder, tag, attrs)
    return builder.finish()


# -- Flattening -------------------------------------------------------------


def _flatten_cubic(
    start: Point, control1: Point, control2: Point, end: Point
) -> list[Point]:
    """Split a cubic Bézier into straight segments within tolerance."""
    steps = _bezier_steps(
        _distance(start, control1)
        + _distance(control1, control2)
        + _distance(control2, end)
    )
    points = [start]
    for step in range(1, steps + 1):
        t = step / steps
        u = 1.0 - t
        points.append(
            (
                u * u * u * start[0]
                + 3 * u * u * t * control1[0]
                + 3 * u * t * t * control2[0]
                + t * t * t * end[0],
                u * u * u * start[1]
                + 3 * u * u * t * control1[1]
                + 3 * u * t * t * control2[1]
                + t * t * t * end[1],
            )
        )
    return points


def _flatten_quad(start: Point, control: Point, end: Point) -> list[Point]:
    """Split a quadratic Bézier into straight segments within tolerance."""
    steps = _bezier_steps(
        _distance(start, control) + _distance(control, end)
    )
    points = [start]
    for step in range(1, steps + 1):
        t = step / steps
        u = 1.0 - t
        points.append(
            (
                u * u * start[0] + 2 * u * t * control[0] + t * t * end[0],
                u * u * start[1] + 2 * u * t * control[1] + t * t * end[1],
            )
        )
    return points


def _bezier_steps(control_polygon_length: float) -> int:
    """How many segments a Bézier of the given size needs.

    The control polygon bounds the curve's length, and a curve deviates from
    its chords by at most a fixed fraction of that bound per segment, so this
    is a conservative count rather than an adaptive subdivision.
    """
    if control_polygon_length <= EPSILON:
        return 1
    steps = math.ceil(
        math.sqrt(control_polygon_length / (8.0 * FLATTEN_TOLERANCE))
    )
    return max(1, min(steps, 200))


def _arc_steps(radius: float, sweep: float) -> int:
    """How many segments an arc of the given radius and sweep needs."""
    if radius <= EPSILON:
        return 1
    ratio = max(-1.0, min(1.0, 1.0 - FLATTEN_TOLERANCE / radius))
    step = 2.0 * math.acos(ratio)
    if step <= EPSILON:
        return 1
    return max(1, min(int(math.ceil(abs(sweep) / step)), 512))


def _circle_polygon(center: Point, radius: float, sign: int) -> list[Point]:
    """A regular polygon approximating a circle, wound to match `sign`."""
    steps = max(8, _arc_steps(radius, 2.0 * math.pi))
    direction = 1.0 if sign >= 0 else -1.0
    return [
        (
            center[0] + radius * math.cos(direction * 2.0 * math.pi * i / steps),
            center[1] + radius * math.sin(direction * 2.0 * math.pi * i / steps),
        )
        for i in range(steps)
    ]


# -- Polygon helpers --------------------------------------------------------


def _distance(a: Point, b: Point) -> float:
    return math.hypot(b[0] - a[0], b[1] - a[1])


def _drop_repeated(points: list[Point]) -> list[Point]:
    """Remove consecutive duplicate points."""
    result: list[Point] = []
    for point in points:
        if not result or _distance(result[-1], point) > EPSILON:
            result.append(point)
    return result


def _signed_area(points: list[Point]) -> float:
    """Twice the signed area of a closed polygon.

    Positive means the polygon is wound clockwise on screen, since SVG's y
    axis points down.
    """
    total = 0.0
    for i, (x0, y0) in enumerate(points):
        x1, y1 = points[(i + 1) % len(points)]
        total += x0 * y1 - x1 * y0
    return total / 2.0


def _orient(points: list[Point], sign: int) -> list[Point]:
    """Wind a polygon so that its signed area matches `sign`."""
    if (_signed_area(points) >= 0.0) == (sign >= 0):
        return points
    return list(reversed(points))


def _simplify(points: list[Point]) -> list[Point]:
    """Drop points that barely bend the contour they sit on."""
    if len(points) < 4:
        return points
    result: list[Point] = []
    for index, point in enumerate(points):
        previous = result[-1] if result else points[-1]
        following = points[(index + 1) % len(points)]
        if _point_line_distance(point, previous, following) > SIMPLIFY_TOLERANCE:
            result.append(point)
    return result if len(result) >= 3 else points


def _point_line_distance(point: Point, start: Point, end: Point) -> float:
    """The distance from `point` to the segment `start`-`end`."""
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dy)
    if length <= EPSILON:
        return _distance(point, start)
    t = ((point[0] - start[0]) * dx + (point[1] - start[1]) * dy) / (
        length * length
    )
    t = max(0.0, min(1.0, t))
    return _distance(point, (start[0] + t * dx, start[1] + t * dy))


def _offset_ring(ring: list[Point], distance: float) -> list[Point]:
    """Offset a closed ring outwards by `distance`, with round joins.

    The ring must be wound so that its signed area is positive; the offset is
    then taken on its outward side.

    Corners are handled the way a stroke rasteriser handles them. On the
    outward side of a corner the offset edges pull apart, and an arc rounds
    the gap off. On the inward side they overlap, and both are cut back to
    where they cross, so the contour stays simple. Letting them run past each
    other instead would leave a loop wound against the rest of the contour,
    which the non-zero rule would punch out as a notch.
    """
    starts: list[Point] = []
    ends: list[Point] = []
    vertices: list[Point] = []
    directions: list[Point] = []
    normals: list[Point] = []
    count = len(ring)
    for index in range(count):
        start = ring[index]
        end = ring[(index + 1) % count]
        direction = _normalised((end[0] - start[0], end[1] - start[1]))
        if direction is None:
            continue
        # The outward side of a positively wound ring, i.e. the source
        # direction turned a quarter turn anticlockwise on screen.
        normal = (direction[1] * distance, -direction[0] * distance)
        starts.append((start[0] + normal[0], start[1] + normal[1]))
        ends.append((end[0] + normal[0], end[1] + normal[1]))
        vertices.append(end)
        directions.append(direction)
        normals.append(normal)

    edges = len(starts)
    if edges == 0:
        return []

    arcs: list[list[Point]] = [[] for _ in range(edges)]
    for index in range(edges):
        following = (index + 1) % edges
        turn = _turn_between(directions[index], directions[following])
        if turn > EPSILON:
            arcs[index] = _join_arc(vertices[index], normals[index], turn)
        elif turn < -EPSILON:
            crossing = _line_intersection(
                starts[index], ends[index], starts[following], ends[following]
            )
            if _distance(crossing, vertices[index]) > INNER_JOIN_LIMIT * abs(
                distance
            ):
                raise SystemExit(
                    "an inward corner is too sharp to offset cleanly at "
                    f"{vertices[index]}"
                )
            ends[index] = crossing
            starts[following] = crossing

    result: list[Point] = []
    for index in range(edges):
        result.append(starts[index])
        result.append(ends[index])
        result.extend(arcs[index])
    return _drop_repeated(result)


def _turn_between(before: Point, after: Point) -> float:
    """The signed angle from one unit direction to the next."""
    cross = before[0] * after[1] - before[1] * after[0]
    dot = before[0] * after[0] + before[1] * after[1]
    if abs(cross) <= EPSILON and dot < 0.0:
        # An exact reversal, which is what the end of a stroke looks like once
        # it has been walked out and back. Whether that counts as turning left
        # or right is down to the sign of a zero, so say left and round the
        # end off rather than pinching it shut.
        return math.pi
    return math.atan2(cross, dot)


def _join_arc(center: Point, normal: Point, turn: float) -> list[Point]:
    """The arc that rounds off an outward corner of an offset ring."""
    radius = math.hypot(normal[0], normal[1])
    steps = _arc_steps(radius, turn)
    points: list[Point] = []
    for step in range(1, steps):
        angle = turn * step / steps
        cos_a, sin_a = math.cos(angle), math.sin(angle)
        points.append(
            (
                center[0] + normal[0] * cos_a - normal[1] * sin_a,
                center[1] + normal[0] * sin_a + normal[1] * cos_a,
            )
        )
    return points


def _normalised(vector: Point) -> Point | None:
    length = math.hypot(vector[0], vector[1])
    if length <= EPSILON:
        return None
    return (vector[0] / length, vector[1] / length)


def _outset_closed(points: list[Point], distance: float) -> list[Point]:
    """Grow a closed contour outwards by `distance`."""
    ring = _drop_repeated(points)
    if len(ring) > 1 and _distance(ring[0], ring[-1]) <= EPSILON:
        ring = ring[:-1]
    return _simplify(_offset_ring(_orient(ring, 1), distance))


def _stroke_outline(points: list[Point], half_width: float) -> list[Point]:
    """The outline of an open polyline stroked with round caps and joins.

    Walking the polyline out and back gives a zero-area ring whose outward
    offset is exactly the stroked region: the 180-degree turns at each end
    become the round caps, and each interior corner is rounded on its outer
    side and crossed on its inner side.
    """
    ring = _drop_repeated(points)
    if len(ring) < 2:
        raise ValueError("cannot outline a polyline with no length")
    ring = ring + list(reversed(ring[1:-1]))
    return _simplify(_offset_ring(ring, half_width))


def _convex_clip(subject: list[Point], clip: list[Point]) -> list[Point]:
    """Intersect a polygon with a convex one (Sutherland-Hodgman).

    Both polygons must be wound positively; `clip` must be convex.
    """
    output = list(subject)
    for index in range(len(clip)):
        if not output:
            return []
        start = clip[index]
        end = clip[(index + 1) % len(clip)]

        def inside(point: Point) -> bool:
            return (end[0] - start[0]) * (point[1] - start[1]) - (
                end[1] - start[1]
            ) * (point[0] - start[0]) >= -EPSILON

        clipped: list[Point] = []
        for edge_index, current in enumerate(output):
            previous = output[edge_index - 1]
            if inside(current):
                if not inside(previous):
                    clipped.append(_line_intersection(previous, current, start, end))
                clipped.append(current)
            elif inside(previous):
                clipped.append(_line_intersection(previous, current, start, end))
        output = _drop_repeated(clipped)
    return output


def _line_intersection(a: Point, b: Point, c: Point, d: Point) -> Point:
    """Where the line through `a`-`b` meets the line through `c`-`d`."""
    denominator = (b[0] - a[0]) * (d[1] - c[1]) - (b[1] - a[1]) * (d[0] - c[0])
    if abs(denominator) <= EPSILON:
        return b
    t = ((c[0] - a[0]) * (d[1] - c[1]) - (c[1] - a[1]) * (d[0] - c[0])) / denominator
    return (a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1]))


def _is_convex(points: list[Point]) -> bool:
    """Whether a polygon turns the same way at every vertex."""
    sign = 0
    count = len(points)
    for index in range(count):
        a = points[index]
        b = points[(index + 1) % count]
        c = points[(index + 2) % count]
        cross = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
        if abs(cross) <= 1e-7:
            continue
        if sign == 0:
            sign = 1 if cross > 0 else -1
        elif (cross > 0) != (sign > 0):
            return False
    return True


def _contains(polygon: list[Point], point: Point) -> bool:
    """Whether a point is inside a polygon, by the even-odd rule."""
    inside = False
    count = len(polygon)
    for index in range(count):
        x0, y0 = polygon[index]
        x1, y1 = polygon[(index + 1) % count]
        if (y0 > point[1]) != (y1 > point[1]):
            crossing = x0 + (point[1] - y0) * (x1 - x0) / (y1 - y0)
            if crossing > point[0]:
                inside = not inside
    return inside


def _centroid(points: list[Point]) -> Point:
    return (
        sum(point[0] for point in points) / len(points),
        sum(point[1] for point in points) / len(points),
    )


# -- Assembling a filled variant --------------------------------------------


class Contour:
    """One closed contour of a filled symbol, with its winding sign."""

    def __init__(self, commands: list[str], polygon: list[Point], sign: int):
        self.commands = commands
        self.polygon = polygon
        self.sign = sign


def _polygon_contour(points: list[Point], sign: int) -> Contour:
    """A contour drawn as straight segments."""
    wound = _orient(_drop_repeated(points), sign)
    if len(wound) < 3:
        raise SystemExit("a filled contour collapsed to fewer than 3 points")
    commands = [f".move({_point(wound[0])})"]
    commands.extend(f".line({_point(point)})" for point in wound[1:])
    commands.append(f".line({_point(wound[0])})")
    return Contour(commands, wound, sign)


def _circle_contour(center: Point, radius: float, sign: int) -> Contour:
    """A contour drawn as four cubic Béziers, exactly circular.

    Enclosures are almost always circles, and they are the most visible part
    of a filled symbol, so they are kept exact rather than flattened.
    """
    direction = 1.0 if sign >= 0 else -1.0
    handle = KAPPA * radius
    reach = handle * direction
    right = (center[0] + radius, center[1])
    bottom = (center[0], center[1] + radius * direction)
    left = (center[0] - radius, center[1])
    top = (center[0], center[1] - radius * direction)
    commands = [f".move({_point(right)})"]
    for control1, control2, end in (
        ((right[0], right[1] + reach), (bottom[0] + handle, bottom[1]), bottom),
        ((bottom[0] - handle, bottom[1]), (left[0], left[1] + reach), left),
        ((left[0], left[1] - reach), (top[0] - handle, top[1]), top),
        ((top[0] + handle, top[1]), (right[0], right[1] - reach), right),
    ):
        commands.append(
            f".cubicCurve(control1: {_point(control1)}, "
            f"control2: {_point(control2)}, end: {_point(end)})"
        )
    return Contour(commands, _circle_polygon(center, radius, sign), sign)


def _solid_contours(icon: str, subpath: FlatSubpath) -> list[Contour]:
    """The solid contours one body element contributes.

    A closed contour grows by half a stroke width so that the filled symbol
    has exactly the silhouette the outline symbol's stroke covers. An open
    one is a stroke that is part of the body -- a padlock's shackle -- and
    becomes its own outline.
    """
    if subpath.circle is not None:
        center, radius = subpath.circle
        return [_circle_contour(center, radius + HALF_STROKE, 1)]
    if subpath.closed:
        return [_polygon_contour(_outset_closed(subpath.points, HALF_STROKE), 1)]
    return [_polygon_contour(_stroke_outline(subpath.points, HALF_STROKE), 1)]


def _knockout_contours(icon: str, subpath: FlatSubpath) -> list[Contour]:
    """The contours one knocked-out element contributes.

    A stroke has to become the area it covers before it can be punched out,
    which is what stroking a circle into a ring, or a polyline into its
    outline, does here.
    """
    if subpath.circle is not None:
        center, radius = subpath.circle
        contours = [_circle_contour(center, radius + HALF_STROKE, -1)]
        if radius - HALF_STROKE > EPSILON:
            # A ring, not a disc: put the middle back.
            contours.append(_circle_contour(center, radius - HALF_STROKE, 1))
        return contours
    if subpath.closed:
        raise SystemExit(
            f"{icon}: punching out a closed contour isn't supported; it would "
            "need a ring rather than a stroke outline"
        )
    return [_polygon_contour(_stroke_outline(subpath.points, HALF_STROKE), -1)]


def _overlap_corrections(icon: str, knockouts: list[Contour]) -> list[Contour]:
    """Contours that undo double-subtraction where knockouts overlap.

    Two punched-out contours that cross would subtract twice and fill their
    crossing back in, so the overlap is added back once. Three overlapping
    knockouts would need a third-order term, which no bundled icon has, so
    that case is refused rather than drawn wrongly.
    """
    negatives = [contour for contour in knockouts if contour.sign < 0]
    overlaps: dict[tuple[int, int], list[Point]] = {}
    for i in range(len(negatives)):
        for j in range(i + 1, len(negatives)):
            first = _orient(negatives[i].polygon, 1)
            second = _orient(negatives[j].polygon, 1)
            if _is_convex(second):
                overlap = _convex_clip(first, second)
            elif _is_convex(first):
                overlap = _convex_clip(second, first)
            else:
                raise SystemExit(
                    f"{icon}: two knocked-out contours overlap and neither is "
                    "convex, so their union can't be computed"
                )
            if len(overlap) >= 3 and abs(_signed_area(overlap)) > 1e-6:
                overlaps[(i, j)] = overlap

    for i in range(len(negatives)):
        for j in range(i + 1, len(negatives)):
            for k in range(j + 1, len(negatives)):
                if all(
                    pair in overlaps for pair in ((i, j), (i, k), (j, k))
                ):
                    raise SystemExit(
                        f"{icon}: three knocked-out contours overlap, which "
                        "needs an inclusion-exclusion term this script "
                        "doesn't emit"
                    )

    return [_polygon_contour(overlap, 1) for overlap in overlaps.values()]


def build_filled_commands(
    icon: str,
    elements: list[Element],
    recipe: FillRecipe,
    transform=None,
) -> list[str]:
    """Derive an icon's filled variant from its outline elements."""
    body: list[Contour] = []
    for index in recipe.body:
        if index >= len(elements):
            raise SystemExit(f"{icon}: fill recipe names element {index}")
        tag, attrs = elements[index]
        for subpath in flatten_element(tag, attrs, transform=transform):
            body.extend(_solid_contours(icon, subpath))
    if not body:
        raise SystemExit(f"{icon}: fill recipe produced no solid body")

    knockouts: list[Contour] = []
    for index in recipe.knockout:
        if index >= len(elements):
            raise SystemExit(f"{icon}: fill recipe names element {index}")
        tag, attrs = elements[index]
        for subpath in flatten_element(tag, attrs, transform=transform):
            knockouts.extend(_knockout_contours(icon, subpath))

    # A knockout outside the body would punch a hole in nothing, which always
    # means the recipe named the wrong element.
    for contour in knockouts:
        if contour.sign >= 0:
            continue
        centre = _centroid(contour.polygon)
        if not any(_contains(solid.polygon, centre) for solid in body):
            raise SystemExit(
                f"{icon}: a knocked-out contour lies outside the solid body"
            )

    contours = body + knockouts + _overlap_corrections(icon, knockouts)
    commands: list[str] = []
    for contour in contours:
        commands.extend(contour.commands)
    return commands


# --------------------------------------------------------------------------
# Emitting Swift
# --------------------------------------------------------------------------

GENERATED_HEADER = """\
// GENERATED FILE -- DO NOT EDIT.
//
// Regenerate with `Scripts/generate-symbol-geometry.py`.
"""

LUCIDE_ATTRIBUTION = """\
//
// The geometry in this file is derived from the Lucide icon set
// (https://lucide.dev), used under the ISC license reproduced below. Lucide
// icons are drawn on a 24x24 canvas with a stroke width of 2, round caps and
// round joins, and no fills.
//
{license}
"""


def swift_identifier(icon: str) -> str:
    """Turn a kebab-case Lucide icon name into a Swift function name."""
    head, *tail = icon.split("-")
    return head + "".join(part.capitalize() for part in tail)


def emit_geometry(
    icons: dict[str, list[str]], filled: dict[str, list[str]]
) -> str:
    license_comment = "\n".join(
        ("// " + line).rstrip() for line in LUCIDE_LICENSE.splitlines()
    )
    lines = [
        GENERATED_HEADER,
        LUCIDE_ATTRIBUTION.format(license=license_comment),
        "",
        "/// The vector geometry of every Lucide icon SwiftCrossUI bundles.",
        "///",
        "/// Each icon is expressed in Lucide's native 24x24 coordinate space;",
        "/// ``SymbolGeometry/path(in:)`` scales it to the size a view needs.",
        "enum LucideIconGeometry {",
        "    /// Looks up an icon's outline geometry by its Lucide name.",
        "    ///",
        "    /// - Parameter name: A kebab-case Lucide icon name.",
        "    /// - Returns: The icon's geometry, or `nil` if it isn't bundled.",
        "    static func geometry(forIcon name: String) -> SymbolGeometry? {",
        "        guard let commands = commands(forIcon: name) else {",
        "            return nil",
        "        }",
        "        return SymbolGeometry(commands: commands)",
        "    }",
        "",
        "    /// Looks up an icon's filled variant by its Lucide name.",
        "    ///",
        "    /// Lucide draws outlines only, so these are derived from the",
        "    /// outline geometry by the generator: the enclosure is made",
        "    /// solid and the inner glyph is punched through it, which is how",
        "    /// SF Symbols builds its own `.fill` variants. Only icons whose",
        "    /// construction is unambiguous have one.",
        "    ///",
        "    /// - Parameter name: A kebab-case Lucide icon name.",
        "    /// - Returns: The icon's filled geometry, or `nil` if it has no",
        "    ///   derived filled variant.",
        "    static func filledGeometry(",
        "        forIcon name: String",
        "    ) -> SymbolGeometry? {",
        "        guard let commands = filledCommands(forIcon: name) else {",
        "            return nil",
        "        }",
        "        return SymbolGeometry(commands: commands, rendering: .filled)",
        "    }",
        "",
        "    /// Every bundled Lucide icon name, sorted.",
        "    static let iconNames: [String] = [",
    ]
    for icon in sorted(icons):
        lines.append(f'        "{icon}",')
    lines.append("    ]")
    lines.append("")
    lines.append("    /// Every bundled icon that has a filled variant, sorted.")
    lines.append("    static let filledIconNames: [String] = [")
    for icon in sorted(filled):
        lines.append(f'        "{icon}",')
    lines.append("    ]")
    lines.append("")
    lines.append("    private static func commands(")
    lines.append("        forIcon name: String")
    lines.append("    ) -> [SymbolGeometry.Command]? {")
    lines.append("        switch name {")
    for icon in sorted(icons):
        lines.append(f'            case "{icon}": return {swift_identifier(icon)}')
    lines.append("            default: return nil")
    lines.append("        }")
    lines.append("    }")
    lines.append("")
    lines.append("    private static func filledCommands(")
    lines.append("        forIcon name: String")
    lines.append("    ) -> [SymbolGeometry.Command]? {")
    lines.append("        switch name {")
    for icon in sorted(filled):
        identifier = swift_identifier(icon) + "Filled"
        lines.append(f'            case "{icon}": return {identifier}')
    lines.append("            default: return nil")
    lines.append("        }")
    lines.append("    }")
    lines.append("")
    for icon in sorted(icons):
        commands = icons[icon]
        lines.append(f"    private static let {swift_identifier(icon)}:")
        lines.append("        [SymbolGeometry.Command] = [")
        for command in commands:
            lines.append(f"            {command},")
        lines.append("        ]")
        lines.append("")
    for icon in sorted(filled):
        commands = filled[icon]
        lines.append(f"    private static let {swift_identifier(icon)}Filled:")
        lines.append("        [SymbolGeometry.Command] = [")
        for command in commands:
            lines.append(f"            {command},")
        lines.append("        ]")
        lines.append("")
    lines.append("}")
    return "\n".join(lines) + "\n"


def filled_system_names(filled: dict[str, list[str]]) -> set[str]:
    """The SF Symbol names that will actually be drawn filled.

    A name asks to be filled by its spelling, and gets it only if the Lucide
    icon it maps to has a derived filled variant.
    """
    return {
        symbol
        for symbol, (icon, _) in SYMBOL_MAP.items()
        if wants_filled_variant(symbol) and icon in filled
    }


def wants_filled_variant(symbol: str) -> bool:
    """Whether an SF Symbol name asks for a filled glyph."""
    return symbol.endswith(".fill") or symbol.endswith(".filled")


def emit_mapping(
    mapping: dict[str, tuple[str, str | None]], filled: set[str]
) -> str:
    lines = [
        GENERATED_HEADER,
        "//",
        "// The pairings below were reviewed by hand. The table lives in",
        "// `Scripts/generate-symbol-geometry.py`; edit it there.",
        "",
        "/// Maps Apple SF Symbol names onto the Lucide icons SwiftCrossUI",
        "/// draws in their place.",
        "///",
        "/// SF Symbols are an Apple-only font. SwiftCrossUI accepts the names",
        "/// so that SwiftUI source compiles unchanged, and renders a reviewed",
        "/// Lucide equivalent on platforms that have no SF Symbols.",
        "enum SFSymbolLucideMapping {",
        "    /// The Lucide icon drawn for an SF Symbol name.",
        "    ///",
        "    /// - Parameter name: An SF Symbol name, e.g. `\"square.and.arrow.up\"`.",
        "    /// - Returns: A kebab-case Lucide icon name, or `nil` if the",
        "    ///   symbol isn't in the table.",
        "    static func lucideIcon(forSystemName name: String) -> String? {",
        "        table[name]",
        "    }",
        "",
        "    /// The icon drawn for a symbol name that isn't in the table.",
        "    ///",
        "    /// Deliberately generic: a reader can tell that an icon is",
        "    /// missing, rather than being shown a confidently wrong one.",
        f'    static let placeholderIcon = "{PLACEHOLDER_ICON}"',
        "",
        "    /// Every SF Symbol name the table covers, sorted.",
        "    static var systemNames: [String] {",
        "        table.keys.sorted()",
        "    }",
        "",
        "    /// Whether a symbol is drawn as a solid glyph rather than an",
        "    /// outline.",
        "    ///",
        "    /// Filled and outline SF Symbols usually mean different things --",
        "    /// a filled warning triangle is a warning, an outline one is a",
        "    /// note -- so a name spelled `.fill` is drawn filled wherever the",
        "    /// generator could derive a filled variant for its Lucide icon.",
        "    ///",
        "    /// - Parameter name: An SF Symbol name.",
        "    /// - Returns: `true` if the symbol has a solid glyph.",
        "    static func drawsFilled(_ name: String) -> Bool {",
        "        filledSystemNames.contains(name)",
        "    }",
        "",
        "    /// Every SF Symbol name drawn with a solid glyph, sorted.",
        "    static let filledSystemNames: Set<String> = [",
    ]
    for symbol in sorted(filled):
        lines.append(f'        "{symbol}",')
    lines.append("    ]")
    lines.append("")
    lines.append("    private static let table: [String: String] = [")
    for symbol in sorted(mapping):
        icon, note = mapping[symbol]
        if symbol in filled:
            if note is None:
                note = DERIVED_FILL
            elif FILL in note:
                note = note.replace(FILL, DERIVED_FILL)
            else:
                note = note.rstrip() + " " + DERIVED_FILL
        if note:
            lines.append(f'        // {symbol}: {note}')
        lines.append(f'        "{symbol}": "{icon}",')
    lines.append("    ]")
    lines.append("}")
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lucide-dir", default=None)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    directory = find_lucide_dir(arguments.lucide_dir, repo_root)
    print(f"Reading Lucide icons from {directory}")

    wanted = sorted({icon for icon, _ in SYMBOL_MAP.values()} | {PLACEHOLDER_ICON})
    icons: dict[str, list[str]] = {}
    filled: dict[str, list[str]] = {}
    missing: list[str] = []
    empty: list[str] = []
    for icon in wanted:
        derived = DERIVED_ICONS.get(icon)
        source = derived[0] if derived else icon
        transform = DERIVED_TRANSFORMS.get(icon)
        elements = read_icon(directory, source)
        if elements is None:
            missing.append(source)
            continue
        commands = build_commands(elements, transform=transform)
        if not commands:
            empty.append(source)
            continue
        icons[icon] = commands

        recipe = FILL_RECIPES.get(icon)
        if recipe is not None:
            filled[icon] = build_filled_commands(
                icon, elements, recipe, transform=transform
            )

    if missing:
        print("Missing Lucide icons:", ", ".join(missing), file=sys.stderr)
    if empty:
        # An icon that parses to nothing means the source file had a shape
        # this script doesn't understand -- never ship a blank glyph.
        print("Lucide icons parsed to nothing:", ", ".join(empty), file=sys.stderr)
    if missing or empty:
        return 1

    unused = sorted(set(FILL_RECIPES) - set(filled))
    if unused:
        # A recipe for an icon nothing maps to is dead weight that no visual
        # check would ever cover.
        print("Fill recipes for unmapped icons:", ", ".join(unused), file=sys.stderr)
        return 1

    filled_symbols = filled_system_names(filled)

    if arguments.check:
        print(
            f"All {len(icons)} Lucide icons resolved for {len(SYMBOL_MAP)} "
            f"symbols, {len(filled)} of them with a derived filled variant "
            f"covering {len(filled_symbols)} `.fill` names."
        )
        return 0

    output = repo_root / "Sources/SwiftCrossUI/Values/Symbols"
    output.mkdir(parents=True, exist_ok=True)
    (output / "LucideIconGeometry.swift").write_text(
        emit_geometry(icons, filled), encoding="utf-8"
    )
    (output / "SFSymbolLucideMapping.swift").write_text(
        emit_mapping(SYMBOL_MAP, filled_symbols), encoding="utf-8"
    )
    print(
        f"Wrote {len(icons)} icons covering {len(SYMBOL_MAP)} SF Symbol "
        f"names, {len(filled)} with filled variants used by "
        f"{len(filled_symbols)} `.fill` names."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
