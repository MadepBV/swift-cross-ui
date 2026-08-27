#!/usr/bin/env python3
"""Checks that qualified SwiftCrossUI type references in the backends that
can't be built on this host actually name types that exist.

The host toolchain only builds the backends for its own platform, so a wrong
type name in `WinUIBackend`, `GtkBackend`, `Gtk3Backend` or `AndroidBackend` is
invisible until someone builds on that platform. `swiftc -parse` doesn't help:
it parses without resolving types, so it accepts anything spelled plausibly.

That is not hypothetical. `SwiftCrossUI.Path.FillRule` shipped in a commit and
broke the Windows build; `FillRule` is a top-level type, not nested in `Path`.

This checks the one thing that can be checked from here: that every
`SwiftCrossUI.A.B` reference names a `B` that is really declared inside `A`
(directly or through an extension), and that every `SwiftCrossUI.A` names a
type that is really top level.

Run it before handing work to someone who will build for another platform.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CORE = ROOT / "Sources" / "SwiftCrossUI"

# Backends the host can't be assumed to build.
UNBUILDABLE = ["WinUIBackend", "GtkBackend", "Gtk3Backend", "AndroidBackend"]

DECLARATION = re.compile(
    r"^(?P<indent>\s*)"
    r"(?:@[\w.]+(?:\([^)]*\))?\s+)*"
    r"(?:(?:public|internal|package|private|fileprivate|open)\s+)*"
    r"(?:final\s+)?"
    r"(?:struct|enum|class|actor|protocol|typealias)\s+"
    r"(?P<name>[A-Za-z_]\w*)"
)
SCOPE = re.compile(
    r"^(?P<indent>\s*)"
    r"(?:[^/\n]*?\b)"
    r"(?:struct|enum|class|actor|protocol|extension)\s+"
    # Dotted, because `extension Font.TextStyle` contributes two levels.
    r"(?P<name>[A-Za-z_][\w.]*)"
)
REFERENCE = re.compile(r"\bSwiftCrossUI((?:\.[A-Za-z_]\w*)+)")
# `BackendFeatures` is reached without the module prefix but is just as easy to
# mis-nest, and the backends are full of references to it.
BARE_REFERENCE = re.compile(r"\b(BackendFeatures(?:\.[A-Za-z_]\w*)+)")


def declarations():
    """Every type declared in the core, mapped to the types enclosing it."""
    found = {}
    for path in CORE.rglob("*.swift"):
        lines = path.read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(lines):
            match = DECLARATION.match(line)
            if not match:
                continue
            indent = len(match.group("indent"))
            enclosing = []
            for previous in reversed(lines[:index]):
                scope = SCOPE.match(previous)
                if scope and len(scope.group("indent")) < indent:
                    enclosing.extend(reversed(scope.group("name").split(".")))
                    indent = len(scope.group("indent"))
                    if indent == 0:
                        break
            found.setdefault(match.group("name"), []).append(
                list(reversed(enclosing))
            )
    return found


def main():
    known = declarations()
    problems = []

    for backend in UNBUILDABLE:
        directory = ROOT / "Sources" / backend
        if not directory.is_dir():
            continue
        for path in sorted(directory.rglob("*.swift")):
            for number, line in enumerate(
                path.read_text(encoding="utf-8").splitlines(), start=1
            ):
                if line.lstrip().startswith("//"):
                    continue
                candidates = [
                    match.group(1).lstrip(".")
                    for match in REFERENCE.finditer(line)
                ] + [match.group(1) for match in BARE_REFERENCE.finditer(line)]
                for candidate in candidates:
                    names = candidate.split(".")
                    # A lowercase component is a member, not a type; stop there.
                    types = []
                    for name in names:
                        if not name[:1].isupper():
                            break
                        types.append(name)
                    if not types:
                        continue

                    head = types[0]
                    if head not in known:
                        problems.append(
                            f"{path.relative_to(ROOT)}:{number}: "
                            f"SwiftCrossUI.{head} is not declared in SwiftCrossUI"
                        )
                        continue
                    if not any(chain == [] for chain in known[head]):
                        problems.append(
                            f"{path.relative_to(ROOT)}:{number}: "
                            f"SwiftCrossUI.{head} is not a top-level type"
                        )
                        continue

                    for depth in range(1, len(types)):
                        outer, inner = types[depth - 1], types[depth]
                        chains = known.get(inner, [])
                        if not any(
                            chain and chain[-1] == outer for chain in chains
                        ):
                            where = (
                                ", ".join(
                                    ".".join(chain) or "<top level>"
                                    for chain in chains
                                )
                                or "nowhere"
                            )
                            problems.append(
                                f"{path.relative_to(ROOT)}:{number}: "
                                f"SwiftCrossUI.{'.'.join(types[:depth + 1])} — "
                                f"{inner} is not nested in {outer} "
                                f"(it is declared in: {where})"
                            )
                            break

    if problems:
        print("Cross-module reference problems:\n")
        for problem in sorted(set(problems)):
            print("  " + problem)
        print(
            f"\n{len(set(problems))} problem(s). These break the build on the "
            "backend's own platform, where this host cannot see them."
        )
        return 1

    print("Cross-module references OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
