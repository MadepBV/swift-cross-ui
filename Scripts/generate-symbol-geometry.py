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
# Lucide is a stroke-only icon set: it has no filled counterparts. Every SF
# Symbol name ending in `.fill` therefore resolves to the same outline icon as
# its unfilled sibling. Those entries carry the FILL note.
FILL = "Lucide has no filled variants; the outline icon is used."

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
        "chevron-down",
        "Lucide has no solid triangle glyph; a downward chevron is used.",
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
    # -- Extra names referenced by Barform's design-approved glyph catalog --
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
        "Lucide has no lettered square; a plain square is used. Barform draws "
        "its own steel-member glyph for this on other hosts.",
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
    "../rebar/apps/BarformTauri/node_modules/lucide-react/dist/esm/icons",
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


class CommandBuilder:
    """Accumulates ``SymbolGeometry.Command`` values for one icon."""

    def __init__(self) -> None:
        self.commands: list[str] = []
        self.current: Point = (0.0, 0.0)
        self.subpath_start: Point = (0.0, 0.0)
        self.last_control: Point | None = None
        self.last_command: str = ""

    def move(self, point: Point) -> None:
        self.commands.append(f".move({_point(point)})")
        self.current = point
        self.subpath_start = point
        self.last_control = None

    def line(self, point: Point) -> None:
        self.commands.append(f".line({_point(point)})")
        self.current = point
        self.last_control = None

    def quad(self, control: Point, end: Point) -> None:
        self.commands.append(
            f".quadCurve(control: {_point(control)}, end: {_point(end)})"
        )
        self.current = end
        self.last_control = control

    def cubic(self, control1: Point, control2: Point, end: Point) -> None:
        self.commands.append(
            f".cubicCurve(control1: {_point(control1)}, "
            f"control2: {_point(control2)}, end: {_point(end)})"
        )
        self.current = end
        self.last_control = control2

    def circle(self, center: Point, radius: float) -> None:
        self.commands.append(
            f".circle(center: {_point(center)}, radius: {_number(radius)})"
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


def build_commands(elements: Iterable[Element]) -> list[str]:
    builder = CommandBuilder()
    for tag, attrs in elements:
        append_element(builder, tag, attrs)
    return builder.commands


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


def emit_geometry(icons: dict[str, list[str]]) -> str:
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
        "    /// Looks up an icon's geometry by its Lucide name.",
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
        "    /// Every bundled Lucide icon name, sorted.",
        "    static let iconNames: [String] = [",
    ]
    for icon in sorted(icons):
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
    for icon in sorted(icons):
        commands = icons[icon]
        lines.append(f"    private static let {swift_identifier(icon)}:")
        lines.append("        [SymbolGeometry.Command] = [")
        for command in commands:
            lines.append(f"            {command},")
        lines.append("        ]")
        lines.append("")
    lines.append("}")
    return "\n".join(lines) + "\n"


def emit_mapping(mapping: dict[str, tuple[str, str | None]]) -> str:
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
        "    private static let table: [String: String] = [",
    ]
    for symbol in sorted(mapping):
        icon, note = mapping[symbol]
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
    missing: list[str] = []
    empty: list[str] = []
    for icon in wanted:
        elements = read_icon(directory, icon)
        if elements is None:
            missing.append(icon)
            continue
        commands = build_commands(elements)
        if not commands:
            empty.append(icon)
            continue
        icons[icon] = commands

    if missing:
        print("Missing Lucide icons:", ", ".join(missing), file=sys.stderr)
    if empty:
        # An icon that parses to nothing means the source file had a shape
        # this script doesn't understand -- never ship a blank glyph.
        print("Lucide icons parsed to nothing:", ", ".join(empty), file=sys.stderr)
    if missing or empty:
        return 1

    if arguments.check:
        print(f"All {len(icons)} Lucide icons resolved for {len(SYMBOL_MAP)} symbols.")
        return 0

    output = repo_root / "Sources/SwiftCrossUI/Values/Symbols"
    output.mkdir(parents=True, exist_ok=True)
    (output / "LucideIconGeometry.swift").write_text(
        emit_geometry(icons), encoding="utf-8"
    )
    (output / "SFSymbolLucideMapping.swift").write_text(
        emit_mapping(SYMBOL_MAP), encoding="utf-8"
    )
    print(
        f"Wrote {len(icons)} icons covering {len(SYMBOL_MAP)} SF Symbol names."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
