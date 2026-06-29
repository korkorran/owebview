#!/usr/bin/env bash
# Vendor the single-header webview.h compatible with these stubs.
#
# lib/webview_stubs.cpp targets the 0.12 single-header API. In 0.12 the C API
# functions return webview_error_t (the stubs ignore those error codes), and
# the header lives at core/include/webview/webview.h in the repository (it was
# at the repo root in the older 0.10/0.11 releases).
set -euo pipefail

VER="${1:-0.12.0}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/vendor"

mkdir -p "$DEST"
url="https://raw.githubusercontent.com/webview/webview/${VER}/core/include/webview/webview.h"
echo "Fetching webview.h ($VER) -> $DEST/webview.h"
curl -fsSL "$url" -o "$DEST/webview.h"
echo "Done."
