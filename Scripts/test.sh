#!/bin/sh

cd "$(dirname "$0")"/../

# `swift test` builds all targets in the package (even those not depended upon
# by any test targets), which leads to `swift test` on its own being broken
# for SwiftCrossUI
# The host only builds its own platform's backend, so a wrong type name in the
# others is invisible here and breaks their build instead. Cheap to check, and
# it has caught a real one.
python3 Scripts/check_cross_module_references.py || exit 1

swift test --test-product swift-cross-uiPackageTests
